package wgpu_microui

// Core
import sa "core:container/small_array"

// Vendor
import mu "vendor:microui"

// Local packages
import wgpu "../../"

BUFFER_SIZE  :: 16384
MAX_VERTICES :: BUFFER_SIZE * 4  // 4 vertices per quad
MAX_INDICES  :: BUFFER_SIZE * 6  // 6 indices per quad

Vertex :: struct {
	position:  [2]f32,
	tex_coord: [2]f32,
	color:     [4]f32,
}

/* Information about the WebGPU context. */
Init_Info :: struct {
	num_frames_in_flight:       u32,
	surface_config:             wgpu.SurfaceConfiguration,
	depth_stencil_format:       wgpu.TextureFormat,
	pipeline_multisample_state: wgpu.MultisampleState,
}

/* Global renderer state */
@(private = "file")
r := struct {
	// Settings
	info:                    Init_Info,

	// WGPU Context
	device:                  wgpu.Device,
	queue:                   wgpu.Queue,

	// Initialization
	atlas_texture:           wgpu.Texture,
	atlas_view:              wgpu.TextureView,
	atlas_sampler:           wgpu.Sampler,
	bind_group:              wgpu.BindGroup,
	render_pipeline:         wgpu.RenderPipeline,
	vertex_buffer:           wgpu.Buffer,
	index_buffer:            wgpu.Buffer,

	// Buffers
	vertices:                sa.Small_Array(MAX_VERTICES, Vertex),
	indices:                 sa.Small_Array(MAX_INDICES, u32),

	// State
	current_pass:            wgpu.RenderPass,
	viewport_rect:           mu.Rect,
	current_clip_rect:       mu.Rect,
	quad_count:              u32,
	viewport_width_inverse:  f32,
	viewport_height_inverse: f32,
	vertex_buffer_offset:    u64,
	index_buffer_offset:     u64,
	frame_index:             u32,
}{}

MICROUI_FRAMES_IN_FLIGHT_DEFAULT :: #config(MICROUI_FRAMES_IN_FLIGHT, 3)

MICROUI_INIT_INFO_DEFAULT :: Init_Info {
	num_frames_in_flight        = MICROUI_FRAMES_IN_FLIGHT_DEFAULT,
	depth_stencil_format       = .Undefined,
	pipeline_multisample_state = wgpu.MULTISAMPLE_STATE_DEFAULT,
}

/* Initializes the WebGPU renderer for MicroUI. */
init :: proc(info: Init_Info) {
	r.info = info

	r.device = r.info.surface_config.device
	wgpu.AddRef(r.device)

	r.queue = wgpu.DeviceGetQueue(r.device)

	r.atlas_texture = wgpu.DeviceCreateTexture(
		r.device,
		{
			label         = "MicroUI Atlas",
			usage         = {.TextureBinding, .CopyDst},
			dimension     = ._2D,
			size          = {mu.DEFAULT_ATLAS_WIDTH, mu.DEFAULT_ATLAS_HEIGHT, 1},
			format        = .RGBA8Unorm,
			mipLevelCount = 1,
			sampleCount   = 1,
		},
	)

	// The mu.default_atlas_alpha contains only alpha channel data for the Atlas
	// image We need to convert this single-channel (alpha) data to full RGBA
	// format. This involves expanding each alpha value into a complete RGBA
	// pixel where R, G, and B will be set to white by default and the original
	// alpha value will be used for the A channel
	pixels := make([][4]u8, mu.DEFAULT_ATLAS_WIDTH * mu.DEFAULT_ATLAS_HEIGHT)
	for alpha, i in mu.default_atlas_alpha {
		pixels[i] = {0xff, 0xff, 0xff, alpha}
	}
	defer delete(pixels)

	bytes_per_row: u32 = mu.DEFAULT_ATLAS_WIDTH * 4 // 4 bytes per pixel for RGBA8

	wgpu.QueueWriteTexture(
		r.queue,
		wgpu.TextureAsImageCopy(r.atlas_texture),
		wgpu.ToBytes(pixels),
		{ bytesPerRow = bytes_per_row, rowsPerImage = mu.DEFAULT_ATLAS_HEIGHT },
		{ mu.DEFAULT_ATLAS_WIDTH, mu.DEFAULT_ATLAS_HEIGHT, 1 },
	)

	r.atlas_view = wgpu.TextureCreateView(r.atlas_texture)

	sampler_descriptor := wgpu.SAMPLER_DESCRIPTOR_DEFAULT
	// FIXME(Capati): Ideally, we would use LINEAR filtering for improved text
	// rendering, especially on high DPI displays. However, this causes texture
	// bleeding. This is likely due to the tight packing of glyphs in the
	// texture atlas.
	sampler_descriptor.minFilter = .Nearest
	sampler_descriptor.magFilter = .Nearest

	r.atlas_sampler = wgpu.DeviceCreateSampler(r.device, sampler_descriptor)

	bind_group_layout := wgpu.DeviceCreateBindGroupLayout(
		r.device,
		wgpu.BindGroupLayoutDescriptor {
			label = "MicroUI Bind Group Layout",
			entries = {
				{
					binding = 0,
					visibility = {.Fragment},
					type = wgpu.TextureBindingLayout {
						multisampled = false,
						viewDimension = ._2D,
						sampleType = .Float,
					},
				},
				{
					binding = 1,
					visibility = {.Fragment},
					type = wgpu.SamplerBindingLayout{type = .Filtering},
				},
			},
		},
	)
	defer wgpu.Release(bind_group_layout)

	r.bind_group = wgpu.DeviceCreateBindGroup(
		r.device,
		{
			label = "MicroUI Bind Group",
			layout = bind_group_layout,
			entries = {
				{ binding = 0, resource = r.atlas_view },
				{ binding = 1, resource = r.atlas_sampler },
			},
		},
	)

	pipeline_layout := wgpu.DeviceCreatePipelineLayout(
		r.device,
		{
			label = "MicroUI Pipeline Layout",
			bindGroupLayouts = { bind_group_layout },
		},
	)
	defer wgpu.Release(pipeline_layout)

	SHADER_SRC :: #load("./microui.wgsl", string)
	microui_shader_module := wgpu.DeviceCreateShaderModule(
		r.device,
		{ label = "MicroUI Shader", source = SHADER_SRC },
	)
	defer wgpu.Release(microui_shader_module)

	// Depth-stencil state (if available)
	depth_stencil_state := wgpu.DepthStencilState {
		format = r.info.depth_stencil_format,
		depthWriteEnabled = false,
		depthCompare = .Always,
		stencil = {
			front = {
				compare = .Always,
				failOp = .Keep,
				depthFailOp = .Keep,
				passOp = .Keep,
			},
			back = {
				compare = .Always,
				failOp = .Keep,
				depthFailOp = .Keep,
				passOp = .Keep,
			},
		},
	}

	r.render_pipeline = wgpu.DeviceCreateRenderPipeline(
		r.device,
		wgpu.RenderPipelineDescriptor {
			label = "MicroUI Pipeline",
			layout = pipeline_layout,
			vertex = {
				module = microui_shader_module,
				entryPoint = "vs_main",
				buffers = {
					{
						arrayStride = size_of(Vertex),
						stepMode = .Vertex,
						attributes = {
							{
								offset = 0,
								shaderLocation = 0,
								format = .Float32x2,
							},
							{
								offset = u64(offset_of(Vertex, tex_coord)),
								shaderLocation = 1,
								format = .Float32x2,
							},
							{
								offset = u64(offset_of(Vertex, color)),
								shaderLocation = 2,
								format = .Float32x4,
							},
						},
					},
				},
			},
			fragment = &wgpu.FragmentState {
				module = microui_shader_module,
				entryPoint = "fs_main",
				targets = {
					{
						format = r.info.surface_config.format,
						blend = &wgpu.BLEND_STATE_NORMAL,
						writeMask = wgpu.COLOR_WRITES_ALL,
					},
				},
			},
			depthStencil = depth_stencil_state,
			primitive = {
				topology = .TriangleList,
				stripIndexFormat = .Undefined,
				frontFace = .CCW,
				cullMode = .None,
			},
			multisample = wgpu.MULTISAMPLE_STATE_DEFAULT,
		},
	)

	set_viewport_rect({0, 0, i32(r.info.surface_config.width), i32(r.info.surface_config.height)})

	vertex_buffer_size :=
		u64(MAX_VERTICES) * u64(size_of(Vertex)) * u64(r.info.num_frames_in_flight)
	r.vertex_buffer = wgpu.DeviceCreateBuffer(
		r.device,
		{label = "MicroUI Vertex Buffer", usage = {.Vertex, .CopyDst}, size = vertex_buffer_size},
	)

	r.index_buffer = wgpu.DeviceCreateBuffer(
		r.device,
		{
			label = "MicroUI Index Buffer",
			usage = { .Index, .CopyDst },
			size = u64(MAX_INDICES) * size_of(u32) * u64(r.info.num_frames_in_flight),
		},
	)

	sa.clear(&r.vertices)
	sa.clear(&r.indices)
}

/* Renders the MicroUI context. */
render :: proc "contextless" (ctx: ^mu.Context, pass: wgpu.RenderPass) -> (ok: bool) {
	r.current_pass = pass

	reset_state()
	setup_render_pass()

	cmd: ^mu.Command
	for variant in mu.next_command_iterator(ctx, &cmd) {
		#partial switch cmd in variant {
		case ^mu.Command_Text:
			draw_text(cmd.str, cmd.pos, cmd.color)
		case ^mu.Command_Rect:
			draw_rect(cmd.rect, cmd.color)
		case ^mu.Command_Icon:
			draw_icon(cmd.id, cmd.rect, cmd.color)
		case ^mu.Command_Clip:
			set_clip_rect(cmd.rect)
		case ^mu.Command_Jump:
			unreachable()
		}
	}

	return prepare_and_draw()
}

reset_state :: proc "contextless" () {
	r.frame_index = (r.frame_index + 1) % r.info.num_frames_in_flight
	r.vertex_buffer_offset =
		wgpu.BufferGetSize(r.vertex_buffer) / u64(r.info.num_frames_in_flight) * u64(r.frame_index)
	r.index_buffer_offset =
		wgpu.BufferGetSize(r.index_buffer) / u64(r.info.num_frames_in_flight) * u64(r.frame_index)
	r.quad_count = 0
	r.current_clip_rect = r.viewport_rect
	sa.clear(&r.vertices)
	sa.clear(&r.indices)
}

setup_render_pass :: proc "contextless" () {
	wgpu.RenderPassSetViewport(
		r.current_pass,
		0,
		0,
		f32(r.viewport_rect.w),
		f32(r.viewport_rect.h),
		0,
		1,
	)

	wgpu.RenderPassSetScissorRect(
		r.current_pass,
		u32(r.viewport_rect.x),
		u32(r.viewport_rect.y),
		u32(r.viewport_rect.w),
		u32(r.viewport_rect.h),
	)

	wgpu.RenderPassSetPipeline(r.current_pass, r.render_pipeline)
	wgpu.RenderPassSetBindGroup(r.current_pass, 0, r.bind_group)
}

/* Writes the accumulated vertex and index data to the GPU and issues the draw call. */
prepare_and_draw :: proc "contextless" () -> (ok: bool) {
	if r.quad_count == 0 {
		return true
	}

	vertices_slice := sa.slice(&r.vertices)
	indices_slice := sa.slice(&r.indices)

	wgpu.QueueWriteBuffer(
		r.queue,
		r.vertex_buffer,
		r.vertex_buffer_offset,
		wgpu.SliceToBytesContextless(vertices_slice),
	)

	wgpu.QueueWriteBuffer(
		r.queue,
		r.index_buffer,
		r.index_buffer_offset,
		wgpu.SliceToBytesContextless(indices_slice),
	)

	wgpu.RenderPassSetVertexBuffer(
		r.current_pass,
		0,
		{buffer = r.vertex_buffer, offset = r.vertex_buffer_offset},
	)
	wgpu.RenderPassSetIndexBuffer(
		r.current_pass,
		{buffer = r.index_buffer, offset = r.index_buffer_offset},
		.Uint32,
	)

	wgpu.RenderPassDrawIndexed(r.current_pass, {0, u32(r.quad_count * 6)})

	return true
}

@(private)
_intersect_rects :: proc "contextless" (r1, r2: mu.Rect) -> mu.Rect {
	x1 := max(r1.x, r2.x)
	y1 := max(r1.y, r2.y)
	x2 := min(r1.x + r1.w, r2.x + r2.w)
	y2 := min(r1.y + r1.h, r2.y + r2.h)
	if x2 < x1 { x2 = x1 }
	if y2 < y1 { y2 = y1 }
	return mu.Rect{x1, y1, x2 - x1, y2 - y1}
}

/*
Calculates the intersection between a destination rectangle, a source rectangle,
and a clip rectangle.
*/
calculate_clipped_rects :: proc "contextless" (
	dst_r, src_r, clip_r: mu.Rect,
) -> (
	dst, src: mu.Rect,
	should_render: bool,
) {
	rect := _intersect_rects(dst_r, clip_r)

	// If there's no intersection at all, we don't need to render
	if rect.w <= 0 || rect.h <= 0 {
		return dst_r, src_r, false
	}

	// If the intersection is the same as the original dst_r, no clipping needed
	if rect == dst_r {
		return dst_r, src_r, true
	}

	// Handle the case where dst_r has zero width or height
	if dst_r.w == 0 || dst_r.h == 0 {
		return rect, src_r, false
	}

	// Calculate clipping ratios
	dx, dy := f32(dst_r.x), f32(dst_r.y)
	dw, dh := f32(dst_r.w), f32(dst_r.h)
	rx, ry := f32(rect.x), f32(rect.y)
	rw, rh := f32(rect.w), f32(rect.h)

	tx := (rx - dx) / dw
	ty := (ry - dy) / dh
	tw := rw / dw
	th := rh / dh

	// Apply clipping to source rectangle
	sx, sy := f32(src_r.x), f32(src_r.y)
	sw, sh := f32(src_r.w), f32(src_r.h)

	dst = rect
	src = mu.Rect {
		x = i32(sx + tx * sw),
		y = i32(sy + ty * sh),
		w = i32(tw * sw),
		h = i32(th * sh),
	}

	return dst, src, true
}

/*
The inverse of the default atlas width from the microui library.
It is used for texture coordinate calculations to avoid doing the division each time.
*/
ATLAS_WIDTH_INVERSE :: 1.0 / mu.DEFAULT_ATLAS_WIDTH

/*
The inverse of the default atlas height from the microui library.
It is used for texture coordinate calculations to avoid doing the division each time.
*/
ATLAS_HEIGHT_INVERSE :: 1.0 / mu.DEFAULT_ATLAS_HEIGHT

push_quad :: proc "contextless" (dst, src: mu.Rect, color: mu.Color) -> bool #no_bounds_check {
	clipped_dst, clipped_src, should_render := calculate_clipped_rects(
		dst,
		src,
		r.current_clip_rect,
	)

	if !should_render {
		return true
	}

	// Check if we need to flush
	if r.quad_count == BUFFER_SIZE / r.info.num_frames_in_flight {
		prepare_and_draw() or_return
		reset_state()
	}

	// Calculate texture coordinates
	x := f32(clipped_src.x) * ATLAS_WIDTH_INVERSE
	y := f32(clipped_src.y) * ATLAS_HEIGHT_INVERSE
	w := f32(clipped_src.w) * ATLAS_WIDTH_INVERSE
	h := f32(clipped_src.h) * ATLAS_HEIGHT_INVERSE

	// Calculate vertex positions
	dx := f32(clipped_dst.x) * r.viewport_width_inverse * 2 - 1
	dy := 1 - f32(clipped_dst.y) * r.viewport_height_inverse * 2
	dw := f32(clipped_dst.w) * r.viewport_width_inverse * 2
	dh := f32(clipped_dst.h) * r.viewport_height_inverse * 2

	// Create vertices
	vertices := [4]Vertex {
		{{dx, dy}, {x, y}, {}},
		{{dx + dw, dy}, {x + w, y}, {}},
		{{dx, dy - dh}, {x, y + h}, {}},
		{{dx + dw, dy - dh}, {x + w, y + h}, {}},
	}

	// Set color for all vertices
	color_f32 := [4]f32 {
		f32(color.r) / 255.0,
		f32(color.g) / 255.0,
		f32(color.b) / 255.0,
		f32(color.a) / 255.0,
	}
	for &v in vertices {
		v.color = color_f32
	}

	// Append vertices and indices using Small_Array functions
	sa.append_elems(&r.vertices, ..vertices[:])
	element_idx := u32(r.quad_count * 4)
	quad_indices := [6]u32{
		element_idx,
		element_idx + 1,
		element_idx + 2,
		element_idx + 2,
		element_idx + 3,
		element_idx + 1,
	}
	sa.append_elems(&r.indices, ..quad_indices[:])

	r.quad_count += 1

	return true
}

draw_text :: proc "contextless" (text: string, pos: mu.Vec2, color: mu.Color) {
	dst := mu.Rect{pos.x, pos.y, 0, 0}
	for ch in text {
		if ch & 0xc0 == 0x80 {
			break
		}
		r := min(int(ch), 127)
		src := mu.default_atlas[mu.DEFAULT_ATLAS_FONT + r]
		dst.w = src.w
		dst.h = src.h
		push_quad(dst, src, color)
		dst.x += dst.w
	}
}

draw_rect :: proc "contextless" (rect: mu.Rect, color: mu.Color) {
	push_quad(rect, mu.default_atlas[mu.DEFAULT_ATLAS_WHITE], color)
}

draw_icon :: proc "contextless" (id: mu.Icon, rect: mu.Rect, color: mu.Color) {
	src := mu.default_atlas[id]
	x := rect.x + (rect.w - src.w) / 2
	y := rect.y + (rect.h - src.h) / 2
	push_quad({x, y, src.w, src.h}, src, color)
}

set_clip_rect :: proc "contextless" (rect: mu.Rect) {
	viewport := &r.viewport_rect

	x := clamp(rect.x, 0, viewport.w)
	y := clamp(rect.y, 0, viewport.h)

	// Calculate the right and bottom edges of the rectangle
	right := min(rect.x + rect.w, viewport.w)
	bottom := min(rect.y + rect.h, viewport.h)

	w := max(0, right - x)
	h := max(0, bottom - y)

	new_clip_rect := mu.Rect{x, y, w, h}

	if r.current_clip_rect != new_clip_rect {
		r.current_clip_rect = new_clip_rect

		wgpu.RenderPassSetScissorRect(
			r.current_pass,
			u32(r.current_clip_rect.x),
			u32(r.current_clip_rect.y),
			u32(r.current_clip_rect.w),
			u32(r.current_clip_rect.h),
		)
	}
}

resize :: proc "contextless" (#any_int width, height: i32) {
	r.viewport_rect.w = width
	r.viewport_rect.h = height
	calculate_viewport_inverses(width, height)
}

set_viewport_rect :: proc "contextless" (rect: mu.Rect) {
	r.viewport_rect.x = rect.x
	r.viewport_rect.y = rect.y
	resize(rect.w, rect.h)
}

/*
Calculates and stores the inverse of the width and height for efficient coordinate
calculations during rendering.
*/
calculate_viewport_inverses :: proc "contextless" (width, height: i32) {
	r.viewport_width_inverse = 1.0 / f32(width)
	r.viewport_height_inverse = 1.0 / f32(height)
}

destroy :: proc "contextless" () {
	wgpu.Release(r.index_buffer)
	wgpu.Release(r.vertex_buffer)
	wgpu.Release(r.render_pipeline)
	wgpu.Release(r.bind_group)
	wgpu.Release(r.atlas_sampler)
	wgpu.Release(r.atlas_view)
	wgpu.Release(r.atlas_texture)

	wgpu.Release(r.queue)
	wgpu.Release(r.device)
}
