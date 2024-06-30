package wgpu_microui

// Vendor
import mu "vendor:microui"

// Package
import wgpu "./../../wrapper"

// Constants for buffer sizes and atlas dimensions
MAX_QUADS_PER_BATCH: u32 : 16384
INITIAL_VERTEX_CAPACITY :: MAX_QUADS_PER_BATCH
ATLAS_WIDTH_INVERSE: f32 : 1.0 / mu.DEFAULT_ATLAS_WIDTH
ATLAS_HEIGHT_INVERSE: f32 : 1.0 / mu.DEFAULT_ATLAS_HEIGHT
NUM_BUFFERS: u32 : 2 // Double buffering

Vertex :: struct {
	position:  [2]f32,
	tex_coord: [2]f32,
	color:     [4]f32,
}

Renderer :: struct {
	device:                  wgpu.Device,
	queue:                   wgpu.Queue,
	atlas_texture:           wgpu.Texture,
	atlas_view:              wgpu.Texture_View,
	atlas_sampler:           wgpu.Sampler,
	bind_group:              wgpu.Bind_Group,
	render_pipeline:         wgpu.Render_Pipeline,
	vertex_buffer:           wgpu.Buffer,
	index_buffer:            wgpu.Buffer,
	vertices:                [dynamic]Vertex,
	indices:                 [dynamic]u32,
	use_command_encoder:     bool,
	current_pass:            wgpu.Render_Pass_Encoder,
	viewport_rect:           mu.Rect,
	current_clip_rect:       mu.Rect,
	quad_count:              u32,
	viewport_width_inverse:  f32,
	viewport_height_inverse: f32,
	vertex_buffer_offset:    u64,
	index_buffer_offset:     u64,
	frame_index:             u32,
}

// Global renderer instance
r: Renderer

/*
Initializes the WebGPU renderer for MicroUI.
*/
init :: proc(
	device: ^wgpu.Device,
	queue: ^wgpu.Queue,
	surface_config: ^wgpu.Surface_Configuration,
	allocator := context.allocator,
) -> (
	mu_ctx: ^mu.Context,
	err: wgpu.Error,
) {
	r.device = device^
	wgpu.device_reference(device)

	r.queue = queue^
	wgpu.queue_reference(queue)

	r.atlas_texture = wgpu.device_create_texture(
		device,
		&{
			label = "microui atlas",
			usage = {.Texture_Binding, .Copy_Dst},
			dimension = .D2,
			size = {mu.DEFAULT_ATLAS_WIDTH, mu.DEFAULT_ATLAS_HEIGHT, 1},
			format = .Rgba8_Unorm,
			mip_level_count = 1,
			sample_count = 1,
		},
	) or_return
	defer if err != .No_Error do wgpu.texture_release(&r.atlas_texture)

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

	atlas_image_copy := wgpu.texture_as_image_copy(&r.atlas_texture)

	wgpu.queue_write_texture(
		queue,
		&atlas_image_copy,
		wgpu.to_bytes(pixels),
		&{bytes_per_row = bytes_per_row, rows_per_image = mu.DEFAULT_ATLAS_HEIGHT},
		&{mu.DEFAULT_ATLAS_WIDTH, mu.DEFAULT_ATLAS_HEIGHT, 1},
	) or_return
	defer if err != .No_Error do wgpu.texture_destroy(&r.atlas_texture)

	r.atlas_view = wgpu.texture_create_view(&r.atlas_texture) or_return
	defer if err != .No_Error do wgpu.texture_view_release(&r.atlas_view)

	sampler_descriptor := wgpu.Default_Sampler_Descriptor
	// FIXME(Capati): Ideally, we would use LINEAR filtering for improved text rendering,
	// especially on high DPI displays. However, this causes texture bleeding. This is likely due
	// to the tight packing of glyphs in the texture atlas.
	sampler_descriptor.min_filter = .Nearest
	sampler_descriptor.mag_filter = .Nearest

	r.atlas_sampler = wgpu.device_create_sampler(device, &sampler_descriptor) or_return
	defer if err != .No_Error do wgpu.sampler_release(&r.atlas_sampler)

	bind_group_layout := wgpu.device_create_bind_group_layout(
		device,
		&{
			label = "microui bind group layout",
			entries = {
				{
					binding = 0,
					visibility = {.Fragment},
					type = wgpu.Texture_Binding_Layout {
						multisampled = false,
						view_dimension = .D2,
						sample_type = .Float,
					},
				},
				{
					binding = 1,
					visibility = {.Fragment},
					type = wgpu.Sampler_Binding_Layout{type = .Filtering},
				},
			},
		},
	) or_return
	defer wgpu.bind_group_layout_release(&bind_group_layout)

	r.bind_group = wgpu.device_create_bind_group(
		device,
		&{
			label = "microui bind group",
			layout = bind_group_layout.ptr,
			entries = {
				{binding = 0, resource = r.atlas_view.ptr},
				{binding = 1, resource = r.atlas_sampler.ptr},
			},
		},
	) or_return
	defer if err != .No_Error do wgpu.bind_group_release(&r.bind_group)

	pipeline_layout := wgpu.device_create_pipeline_layout(
		device,
		&{label = "microui pipeline layout", bind_group_layouts = {bind_group_layout.ptr}},
	) or_return
	defer wgpu.pipeline_layout_release(&pipeline_layout)

	microui_shader_source := #load("./microui.wgsl")

	microui_shader_module := wgpu.device_create_shader_module(
		device,
		&{label = "microui shader", source = cstring(raw_data(microui_shader_source))},
	) or_return
	defer wgpu.shader_module_release(&microui_shader_module)

	r.render_pipeline = wgpu.device_create_render_pipeline(
		device,
		&wgpu.Render_Pipeline_Descriptor {
			label = "microui pipeline",
			layout = pipeline_layout.ptr,
			vertex = {
				module = microui_shader_module.ptr,
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
			fragment = &wgpu.Fragment_State {
				module = microui_shader_module.ptr,
				entry_point = "fs_main",
				targets = {
					{
						format = surface_config.format,
						blend = &wgpu.Blend_State_Normal,
						write_mask = wgpu.Color_Write_Mask_All,
					},
				},
			},
			primitive = {
				topology = .Triangle_List,
				strip_index_format = .Undefined,
				front_face = .CCW,
				cull_mode = .None,
			},
			depth_stencil = nil,
			multisample = wgpu.Default_Multisample_State,
		},
	) or_return
	defer if err != .No_Error do wgpu.render_pipeline_release(&r.render_pipeline)

	// set_viewport_rect({100, 100, 400, 400})
	set_viewport_rect({0, 0, i32(surface_config.width), i32(surface_config.height)})

	r.vertex_buffer = wgpu.device_create_buffer(
		device,
		&{
			label = "Vertex Buffer",
			usage = {.Vertex, .Copy_Dst},
			size = u64(INITIAL_VERTEX_CAPACITY) * u64(size_of(Vertex)) * u64(NUM_BUFFERS),
		},
	) or_return

	r.index_buffer = wgpu.device_create_buffer(
		device,
		&{
			label = "Index Buffer",
			usage = {.Index, .Copy_Dst},
			size = u64(INITIAL_VERTEX_CAPACITY) * 6 * u64(NUM_BUFFERS),
		},
	) or_return

	// Initial capacity of vertices
	reserve(&r.vertices, INITIAL_VERTEX_CAPACITY)
	// Each quad needs 6 indices
	reserve(&r.indices, INITIAL_VERTEX_CAPACITY * 6)

	mu_ctx = new(mu.Context, allocator) or_return
	mu.init(mu_ctx)
	mu_ctx.text_width = mu.default_atlas_text_width
	mu_ctx.text_height = mu.default_atlas_text_height

	return
}

/*
Renders the MicroUI context using a command encoder.
*/
render_with_command_encoder :: proc(
	ctx: ^mu.Context,
	encoder: ^wgpu.Command_Encoder,
	color_view: ^wgpu.Texture_View,
) -> (
	err: wgpu.Error,
) {
	pass := wgpu.command_encoder_begin_render_pass(
		encoder,
		&wgpu.Render_Pass_Descriptor {
			label             = "MicroUI Render Pass",
			color_attachments = []wgpu.Render_Pass_Color_Attachment {
				{
					view     = color_view.ptr,
					load_op  = .Load, // Load existing content
					store_op = .Store,
				},
			},
		},
	)

	r.use_command_encoder = true

	return begin_rendering(ctx, &pass)
}

/*
Renders the MicroUI context using a render pass encoder.
*/
render_with_render_pass :: proc(
	ctx: ^mu.Context,
	pass: ^wgpu.Render_Pass_Encoder,
) -> (
	err: wgpu.Error,
) {
	return begin_rendering(ctx, pass)
}

render :: proc {
	render_with_command_encoder,
	render_with_render_pass,
}

reset_state :: proc() {
	r.frame_index = (r.frame_index + 1) % NUM_BUFFERS
	r.vertex_buffer_offset = r.vertex_buffer.size / u64(NUM_BUFFERS) * u64(r.frame_index)
	r.index_buffer_offset = r.index_buffer.size / u64(NUM_BUFFERS) * u64(r.frame_index)
	r.quad_count = 0
	r.current_clip_rect = r.viewport_rect
	clear(&r.vertices)
	clear(&r.indices)
}

begin_rendering :: proc(ctx: ^mu.Context, pass: ^wgpu.Render_Pass_Encoder) -> wgpu.Error {
	reset_state()
	r.current_pass = pass^
	setup_render_pass(pass)

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

	return prepare_and_draw(pass)
}

setup_render_pass :: proc(pass: ^wgpu.Render_Pass_Encoder) {
	wgpu.render_pass_encoder_set_viewport(
		pass,
		0,
		0,
		f32(r.viewport_rect.w),
		f32(r.viewport_rect.h),
		0,
		1,
	)

	wgpu.render_pass_encoder_set_scissor_rect(
		pass,
		u32(r.viewport_rect.x),
		u32(r.viewport_rect.y),
		u32(r.viewport_rect.w),
		u32(r.viewport_rect.h),
	)

	wgpu.render_pass_encoder_set_pipeline(pass, r.render_pipeline.ptr)
	wgpu.render_pass_encoder_set_bind_group(pass, 0, r.bind_group.ptr)
	wgpu.render_pass_encoder_set_vertex_buffer(pass, 0, r.vertex_buffer.ptr)
	wgpu.render_pass_encoder_set_index_buffer(pass, r.index_buffer.ptr, .Uint32)
}

/*
Writes the accumulated vertex and index data to the GPU and issues the draw call.
*/
prepare_and_draw :: proc(pass: ^wgpu.Render_Pass_Encoder) -> (err: wgpu.Error) {
	if r.quad_count == 0 do return

	update_gpu_buffer(&r.vertex_buffer, r.vertices[:], r.vertex_buffer_offset) or_return
	update_gpu_buffer(&r.index_buffer, r.indices[:], r.index_buffer_offset) or_return

	wgpu.render_pass_encoder_set_vertex_buffer(
		pass,
		0,
		r.vertex_buffer.ptr,
		r.vertex_buffer_offset,
	)
	wgpu.render_pass_encoder_set_index_buffer(
		pass,
		r.index_buffer.ptr,
		.Uint32,
		r.index_buffer_offset,
	)

	wgpu.render_pass_encoder_draw_indexed(pass, u32(r.quad_count * 6))

	if r.use_command_encoder {
		wgpu.render_pass_encoder_end(pass) or_return
	}

	return
}

/*
Updates an existing buffer.
*/
update_gpu_buffer :: proc(buffer: ^wgpu.Buffer, data: $T, offset: u64) -> (err: wgpu.Error) {
	assert(
		buffer.size >= offset + u64(len(data) * size_of(type_of(data[0]))),
		"Buffer is not large enough for the data",
	)

	wgpu.queue_write_buffer(&r.queue, buffer.ptr, offset, wgpu.to_bytes(data)) or_return

	return
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

push_quad :: proc(dst, src: mu.Rect, color: mu.Color) -> wgpu.Error #no_bounds_check {
	clipped_dst, clipped_src, should_render := calculate_clipped_rects(
		dst,
		src,
		r.current_clip_rect,
	)

	if !should_render do return nil

	// Check if we need to flush
	if r.quad_count == MAX_QUADS_PER_BATCH / NUM_BUFFERS {
		prepare_and_draw(&r.current_pass) or_return
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

	return nil
}

draw_text :: proc(text: string, pos: mu.Vec2, color: mu.Color) {
	dst := mu.Rect{pos.x, pos.y, 0, 0}
	for ch in text do if ch & 0xc0 != 0x80 {
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

set_clip_rect :: proc(rect: mu.Rect) {
	viewport := &r.viewport_rect

	x := clamp(rect.x, 0, viewport.w)
	y := clamp(rect.y, 0, viewport.h)

	// Calculate the right and bottom edges of the rectangle
	right := min(rect.x + rect.w, viewport.w)
	bottom := min(rect.y + rect.h, viewport.h)

	w := max(0, right - x)
	h := max(0, bottom - y)

	r.current_clip_rect = {x, y, w, h}

	wgpu.render_pass_encoder_set_scissor_rect(
		&r.current_pass,
		u32(r.current_clip_rect.x),
		u32(r.current_clip_rect.y),
		u32(r.current_clip_rect.w),
		u32(r.current_clip_rect.h),
	)
}

resize :: proc(width, height: i32) {
	r.viewport_rect.w = width
	r.viewport_rect.h = height
	calculate_viewport_inverses(width, height)
}

set_viewport_rect :: proc(rect: mu.Rect) {
	r.viewport_rect.x = rect.x
	r.viewport_rect.y = rect.y
	resize(rect.w, rect.h)
}

/*
Calculates and stores the inverse of the width and height for efficient coordinate
calculations during rendering.
*/
calculate_viewport_inverses :: proc(width, height: i32) {
	r.viewport_width_inverse = 1.0 / f32(width)
	r.viewport_height_inverse = 1.0 / f32(height)
}

destroy :: proc() {
	wgpu.buffer_destroy(&r.vertex_buffer)
	wgpu.buffer_release(&r.vertex_buffer)
	wgpu.buffer_destroy(&r.index_buffer)
	wgpu.buffer_release(&r.index_buffer)
	wgpu.render_pipeline_release(&r.render_pipeline)
	wgpu.bind_group_release(&r.bind_group)
	wgpu.sampler_release(&r.atlas_sampler)
	wgpu.texture_view_release(&r.atlas_view)
	wgpu.texture_destroy(&r.atlas_texture)
	wgpu.texture_release(&r.atlas_texture)

	wgpu.queue_release(&r.queue)
	wgpu.device_release(&r.device)

	delete(r.vertices)
	delete(r.indices)
}
