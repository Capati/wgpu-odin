package wgpu_microui

// Packages
import mu "vendor:microui"

// Local packages
import "./../../wgpu"

/* Maximum number of quads that can be processed in a single batch. */
MAX_QUADS_PER_BATCH: u32 : 16384

/* Initial capacity for vertex/index buffers to help in pre-allocating memory. */
INITIAL_VERTEX_CAPACITY :: MAX_QUADS_PER_BATCH

Vertex :: struct {
	position:  [2]f32,
	tex_coord: [2]f32,
	color:     [4]f32,
}

/* Information about the WebGPU context. */
InitInfo :: struct {
	num_frames_in_flight:       u32,
	surface_config:             wgpu.SurfaceConfiguration,
	depth_stencil_format:       wgpu.TextureFormat,
	pipeline_multisample_state: wgpu.MultisampleState,
}

/* Global renderer state */
@(private = "file")
r := struct {
	// Settings
	using init_info:         InitInfo,

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
	vertices:                [dynamic]Vertex,
	indices:                 [dynamic]u32,

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

DEFAULT_MICROUI_FRAMES_IN_FLIGHT :: #config(MICROUI_FRAMES_IN_FLIGHT, 3)

DEFAULT_MICROUI_INIT_INFO :: InitInfo {
	num_frames_in_flight       = DEFAULT_MICROUI_FRAMES_IN_FLIGHT,
	depth_stencil_format       = .Undefined,
	pipeline_multisample_state = wgpu.DEFAULT_MULTISAMPLE_STATE,
}

/* Initializes the WebGPU renderer for MicroUI. */
init :: proc(init_info: InitInfo, loc := #caller_location) -> (ok: bool) {
	r.init_info = init_info

	r.device = r.surface_config.device
	wgpu.device_add_ref(r.device)

	r.queue = wgpu.device_get_queue(r.device)

	r.atlas_texture = wgpu.device_create_texture(
		r.device,
		{
			label = "MicroUI Atlas",
			usage = {.TextureBinding, .CopyDst},
			dimension = .D2,
			size = {mu.DEFAULT_ATLAS_WIDTH, mu.DEFAULT_ATLAS_HEIGHT, 1},
			format = .Rgba8Unorm,
			mip_level_count = 1,
			sample_count = 1,
		},
	) or_return
	defer if !ok {
		wgpu.release(r.atlas_texture)
	}

	// The mu.default_atlas_alpha contains only alpha channel data for the Atlas image
	// We need to convert this single-channel (alpha) data to full RGBA format.
	// This involves expanding each alpha value into a complete RGBA pixel where R, G, and B
	// will be set to white by default and the original alpha value will be used for the A channel
	pixels := make([][4]u8, mu.DEFAULT_ATLAS_WIDTH * mu.DEFAULT_ATLAS_HEIGHT)
	for alpha, i in mu.default_atlas_alpha {
		pixels[i] = {0xff, 0xff, 0xff, alpha}
	}
	defer delete(pixels)

	bytes_per_row: u32 = mu.DEFAULT_ATLAS_WIDTH * 4 // 4 bytes per pixel for RGBA8

	atlas_image_copy := wgpu.texture_as_image_copy(r.atlas_texture)

	wgpu.queue_write_texture(
		r.queue,
		atlas_image_copy,
		wgpu.to_bytes(pixels),
		{bytes_per_row = bytes_per_row, rows_per_image = mu.DEFAULT_ATLAS_HEIGHT},
		{mu.DEFAULT_ATLAS_WIDTH, mu.DEFAULT_ATLAS_HEIGHT, 1},
	) or_return
	defer if !ok {
		wgpu.texture_destroy(r.atlas_texture)
	}

	r.atlas_view = wgpu.texture_create_view(r.atlas_texture) or_return
	defer if !ok {
		wgpu.release(r.atlas_view)
	}

	sampler_descriptor := wgpu.DEFAULT_SAMPLER_DESCRIPTOR
	// FIXME(Capati): Ideally, we would use LINEAR filtering for improved text rendering,
	// especially on high DPI displays. However, this causes texture bleeding. This is likely due
	// to the tight packing of glyphs in the texture atlas.
	sampler_descriptor.min_filter = .Nearest
	sampler_descriptor.mag_filter = .Nearest

	r.atlas_sampler = wgpu.device_create_sampler(r.device, sampler_descriptor) or_return
	defer if !ok {
		wgpu.release(r.atlas_sampler)
	}

	bind_group_layout := wgpu.device_create_bind_group_layout(
		r.device,
		wgpu.BindGroupLayoutDescriptor {
			label = "MicroUI Bind Group Layout",
			entries = {
				{
					binding = 0,
					visibility = {.Fragment},
					type = wgpu.TextureBindingLayout {
						multisampled = false,
						view_dimension = .D2,
						sample_type = .Float,
					},
				},
				{
					binding = 1,
					visibility = {.Fragment},
					type = wgpu.SamplerBindingLayout{type = .Filtering},
				},
			},
		},
	) or_return
	defer wgpu.release(bind_group_layout)

	r.bind_group = wgpu.device_create_bind_group(
		r.device,
		{
			label = "MicroUI Bind Group",
			layout = bind_group_layout,
			entries = {
				{binding = 0, resource = r.atlas_view},
				{binding = 1, resource = r.atlas_sampler},
			},
		},
	) or_return
	defer if !ok {
		wgpu.release(r.bind_group)
	}

	pipeline_layout := wgpu.device_create_pipeline_layout(
		r.device,
		{label = "MicroUI Pipeline Layout", bind_group_layouts = {bind_group_layout}},
	) or_return
	defer wgpu.release(pipeline_layout)

	SHADER_SRC :: #load("./microui.wgsl", string)
	microui_shader_module := wgpu.device_create_shader_module(
		r.device,
		{label = "MicroUI Shader", source = SHADER_SRC},
	) or_return
	defer wgpu.release(microui_shader_module)

	// Depth-stencil state (if available)
	depth_stencil_state := wgpu.DepthStencilState {
		format = r.depth_stencil_format,
		depth_write_enabled = false,
		depth_compare = .Always,
		stencil = {
			front = {compare = .Always, fail_op = .Keep, depth_fail_op = .Keep, pass_op = .Keep},
			back = {compare = .Always, fail_op = .Keep, depth_fail_op = .Keep, pass_op = .Keep},
		},
	}

	r.render_pipeline = wgpu.device_create_render_pipeline(
		r.device,
		wgpu.RenderPipelineDescriptor {
			label = "MicroUI Pipeline",
			layout = pipeline_layout,
			vertex = {
				module = microui_shader_module,
				entry_point = "vs_main",
				buffers = {
					{
						array_stride = size_of(Vertex),
						step_mode = .Vertex,
						attributes = {
							{offset = 0, shader_location = 0, format = .Float32x2},
							{
								offset = u64(offset_of(Vertex, tex_coord)),
								shader_location = 1,
								format = .Float32x2,
							},
							{
								offset = u64(offset_of(Vertex, color)),
								shader_location = 2,
								format = .Float32x4,
							},
						},
					},
				},
			},
			fragment = &wgpu.FragmentState {
				module = microui_shader_module,
				entry_point = "fs_main",
				targets = {
					{
						format = r.surface_config.format,
						blend = &wgpu.BLEND_STATE_NORMAL,
						write_mask = wgpu.COLOR_WRITES_ALL,
					},
				},
			},
			depth_stencil = depth_stencil_state,
			primitive = {
				topology = .TriangleList,
				strip_index_format = .Undefined,
				front_face = .CCW,
				cull_mode = .None,
			},
			multisample = wgpu.DEFAULT_MULTISAMPLE_STATE,
		},
	) or_return
	defer if !ok {
		wgpu.release(r.render_pipeline)
	}

	set_viewport_rect({0, 0, i32(r.surface_config.width), i32(r.surface_config.height)})

	vertex_buffer_size :=
		u64(INITIAL_VERTEX_CAPACITY) * u64(size_of(Vertex)) * u64(r.num_frames_in_flight)
	r.vertex_buffer = wgpu.device_create_buffer(
		r.device,
		{label = "MicroUI Vertex Buffer", usage = {.Vertex, .CopyDst}, size = vertex_buffer_size},
	) or_return

	r.index_buffer = wgpu.device_create_buffer(
		r.device,
		{
			label = "MicroUI Index Buffer",
			usage = {.Index, .CopyDst},
			size = u64(INITIAL_VERTEX_CAPACITY) * 6 * u64(r.num_frames_in_flight),
		},
	) or_return

	// Pre-allocate initial capacity of vertices
	reserve(&r.vertices, INITIAL_VERTEX_CAPACITY)
	// Pre-allocate initial capacity of indices, each quad needs 6 indices
	reserve(&r.indices, INITIAL_VERTEX_CAPACITY * 6)

	return true
}

/* Renders the MicroUI context. */
render :: proc(ctx: ^mu.Context, pass: wgpu.RenderPass) -> (ok: bool) {
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
	r.frame_index = (r.frame_index + 1) % r.num_frames_in_flight
	r.vertex_buffer_offset =
		wgpu.buffer_size(r.vertex_buffer) / u64(r.num_frames_in_flight) * u64(r.frame_index)
	r.index_buffer_offset =
		wgpu.buffer_size(r.index_buffer) / u64(r.num_frames_in_flight) * u64(r.frame_index)
	r.quad_count = 0
	r.current_clip_rect = r.viewport_rect
	clear(&r.vertices)
	clear(&r.indices)
}

setup_render_pass :: proc "contextless" () {
	wgpu.render_pass_set_viewport(
		r.current_pass,
		0,
		0,
		f32(r.viewport_rect.w),
		f32(r.viewport_rect.h),
		0,
		1,
	)

	wgpu.render_pass_set_scissor_rect(
		r.current_pass,
		u32(r.viewport_rect.x),
		u32(r.viewport_rect.y),
		u32(r.viewport_rect.w),
		u32(r.viewport_rect.h),
	)

	wgpu.render_pass_set_pipeline(r.current_pass, r.render_pipeline)
	wgpu.render_pass_set_bind_group(r.current_pass, 0, r.bind_group)
}

/* Writes the accumulated vertex and index data to the GPU and issues the draw call. */
prepare_and_draw :: proc "contextless" () -> (ok: bool) {
	if r.quad_count == 0 {
		return true
	}

	wgpu.queue_write_buffer(
		r.queue,
		r.vertex_buffer,
		r.vertex_buffer_offset,
		wgpu.slice_to_bytes_contextless(r.vertices[:]),
	) or_return

	wgpu.queue_write_buffer(
		r.queue,
		r.index_buffer,
		r.index_buffer_offset,
		wgpu.slice_to_bytes_contextless(r.indices[:]),
	) or_return

	wgpu.render_pass_set_vertex_buffer(
		r.current_pass,
		0,
		{buffer = r.vertex_buffer, offset = r.vertex_buffer_offset},
	)
	wgpu.render_pass_set_index_buffer(
		r.current_pass,
		{buffer = r.index_buffer, offset = r.index_buffer_offset},
		.Uint32,
	)

	wgpu.render_pass_draw_indexed(r.current_pass, {0, u32(r.quad_count * 6)})

	return true
}

/*
Calculates the intersection between a destination rectangle, a source rectangle,
and a clip rectangle.
*/
calculate_clipped_rects :: proc(
	dst_r, src_r, clip_r: mu.Rect,
) -> (
	dst, src: mu.Rect,
	should_render: bool,
) {
	rect := mu.intersect_rects(dst_r, clip_r)

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

push_quad :: proc(dst, src: mu.Rect, color: mu.Color) -> bool #no_bounds_check {
	clipped_dst, clipped_src, should_render := calculate_clipped_rects(
		dst,
		src,
		r.current_clip_rect,
	)

	if !should_render {
		return true
	}

	// Check if we need to flush
	if r.quad_count == MAX_QUADS_PER_BATCH / r.num_frames_in_flight {
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

	// Append vertices and indices
	append(&r.vertices, ..vertices[:])
	element_idx := u32(r.quad_count * 4)
	append(
		&r.indices,
		element_idx,
		element_idx + 1,
		element_idx + 2,
		element_idx + 2,
		element_idx + 3,
		element_idx + 1,
	)

	r.quad_count += 1

	return true
}

draw_text :: proc(text: string, pos: mu.Vec2, color: mu.Color) {
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

draw_rect :: proc(rect: mu.Rect, color: mu.Color) {
	push_quad(rect, mu.default_atlas[mu.DEFAULT_ATLAS_WHITE], color)
}

draw_icon :: proc(id: mu.Icon, rect: mu.Rect, color: mu.Color) {
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

		wgpu.render_pass_set_scissor_rect(
			r.current_pass,
			u32(r.current_clip_rect.x),
			u32(r.current_clip_rect.y),
			u32(r.current_clip_rect.w),
			u32(r.current_clip_rect.h),
		)
	}
}

resize :: proc "contextless" (width, height: i32) {
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

destroy :: proc() {
	wgpu.release(r.index_buffer)
	wgpu.release(r.vertex_buffer)
	wgpu.release(r.render_pipeline)
	wgpu.release(r.bind_group)
	wgpu.release(r.atlas_sampler)
	wgpu.release(r.atlas_view)
	wgpu.release(r.atlas_texture)

	wgpu.release(r.queue)
	wgpu.release(r.device)

	delete(r.vertices)
	delete(r.indices)
}
