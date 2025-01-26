package imgui

// Packages
import intr "base:intrinsics"
import la "core:math/linalg"
import "core:slice"

// Local packages
import "./../../wgpu"

/* WGPU render-specific resources required for ImGui integration with WGPU backend. */
WGPURenderResources :: struct {
	font_texture:            wgpu.Texture, /* Font texture */
	font_texture_view:       wgpu.Texture_View, /* Texture view for font texture */
	sampler:                 wgpu.Sampler, /* Sampler for the font texture */
	uniforms:                wgpu.Buffer, /* Shader uniforms */
	common_bind_group:       wgpu.Bind_Group, /* Resources bind-group to bind the common resources to pipeline */
	image_bind_groups:       map[Texture_ID]wgpu.Bind_Group, /* Resources bind-group to bind the font/image resources to pipeline */
	image_bind_group:        wgpu.Bind_Group, /* Default font-resource of Dear ImGui */
	image_bind_group_layout: wgpu.Bind_Group_Layout, /* Cache layout used for the image bind group. Avoids allocating unnecessary JS objects when working with WebASM */
}

/* GPU and host resources required for rendering ImGui frames. */
WGPUFrameResources :: struct {
	index_buffer:       wgpu.Buffer, /* WebGPU buffer containing indices for rendering */
	vertex_buffer:      wgpu.Buffer, /* WebGPU buffer containing vertices for rendering */
	index_buffer_host:  []Draw_Idx, /* Host-side array of draw indices */
	vertex_buffer_host: []Draw_Vert, /* Host-side array of draw vertices */
	index_buffer_size:  i32, /* Size of the index buffer in bytes */
	vertex_buffer_size: i32, /* Size of the vertex buffer in bytes */
}

WGPUUniforms :: struct {
	mvp:   la.Matrix4f32,
	gamma: f32,
}

WGPUInitInfo :: struct {
	device:                     wgpu.Device,
	num_frames_in_flight:       u32,
	render_target_format:       wgpu.Texture_Format,
	depth_stencil_format:       wgpu.Texture_Format,
	pipeline_multisample_state: wgpu.Multisample_State,
}

DEFAULT_WGPU_FRAMES_IN_FLIGHT :: #config(IMGUI_WGPU_FRAMES_IN_FLIGHT, 3)

DEFAULT_WGPU_INIT_INFO :: WGPUInitInfo {
	num_frames_in_flight       = DEFAULT_WGPU_FRAMES_IN_FLIGHT,
	render_target_format       = .Undefined,
	depth_stencil_format       = .Undefined,
	pipeline_multisample_state = wgpu.DEFAULT_MULTISAMPLE_STATE,
}

/* Backend data stored in `io.backend_renderer_user_data` */
WGPUData :: struct {
	init_info:            WGPUInitInfo,
	device:               wgpu.Device,
	default_queue:        wgpu.Queue,
	render_target_format: wgpu.Texture_Format,
	depth_stencil_format: wgpu.Texture_Format,
	pipeline_state:       wgpu.Render_Pipeline,
	render_resources:     WGPURenderResources,
	frame_resources:      [dynamic]WGPUFrameResources,
	num_frames_in_flight: u32,
	frame_index:          u32,
}

WGPU_INDEX_BUFFER_SIZE :: #config(IMGUI_WGPU_INDEX_BUFFER_SIZE, 10000)
WGPU_VERTEX_BUFFER_SIZE :: #config(IMGUI_WGPU_VERTEX_BUFFER_SIZE, 5000)

/* Retrieves a pointer to the `WGPUData` structure. */
@(require_results)
wgpu_get_backend_data :: proc "contextless" () -> ^WGPUData {
	if ctx := get_current_context(); ctx != nil {
		return cast(^WGPUData)(get_io().backend_renderer_user_data)
	}
	return nil
}

@(require_results)
wgpu_create_device_objects :: proc() -> (ok: bool) {
	bd := wgpu_get_backend_data()
	if bd.device == nil {
		return
	}
	if bd.pipeline_state != nil {
		wgpu_invalidate_device_objects()
	}

	// Create render pipeline
	graphics_pipeline_desc: wgpu.Render_Pipeline_Descriptor
	graphics_pipeline_desc.primitive = {
		topology           = .Triangle_List,
		strip_index_format = .Undefined,
		front_face         = .CW,
		cull_mode          = .None,
	}
	graphics_pipeline_desc.multisample = bd.init_info.pipeline_multisample_state

	// Bind group layouts
	common_bg_layout_entries := [2]wgpu.Bind_Group_Layout_Entry {
		{
			binding = 0,
			visibility = {.Vertex, .Fragment},
			type = wgpu.Buffer_Binding_Layout{type = .Uniform},
		},
		{
			binding = 1,
			visibility = {.Fragment},
			type = wgpu.Sampler_Binding_Layout{type = .Filtering},
		},
	}

	image_bg_layout_entries := [1]wgpu.Bind_Group_Layout_Entry {
		{
			binding = 0,
			visibility = {.Fragment},
			type = wgpu.Texture_Binding_Layout {
				sample_type = .Float,
				view_dimension = .D2,
				multisampled = false,
			},
		},
	}

	common_bg_layout_desc := wgpu.Bind_Group_Layout_Descriptor {
		entries = common_bg_layout_entries[:],
	}

	image_bg_layout_desc := wgpu.Bind_Group_Layout_Descriptor {
		entries = image_bg_layout_entries[:],
	}

	bg_layouts := [2]wgpu.Bind_Group_Layout {
		wgpu.device_create_bind_group_layout(bd.device, common_bg_layout_desc) or_return,
		wgpu.device_create_bind_group_layout(bd.device, image_bg_layout_desc) or_return,
	}
	defer {
		wgpu.bind_group_layout_release(bg_layouts[0])
		// wgpu.bind_group_layout_release(bg_layouts[1])
	}

	layout_desc := wgpu.Pipeline_Layout_Descriptor {
		bind_group_layouts = bg_layouts[:],
	}

	graphics_pipeline_desc.layout = wgpu.device_create_pipeline_layout(
		bd.device,
		layout_desc,
	) or_return
	defer wgpu.pipeline_layout_release(graphics_pipeline_desc.layout)

	// Create the shader module
	IMGUI_IMPL_WGPU_WGSL :: #load("imgui_impl_wgpu.wgsl", string)
	shader_module := wgpu.device_create_shader_module(
		bd.device,
		{label = "imgui_shader_module", source = IMGUI_IMPL_WGPU_WGSL},
	) or_return
	defer wgpu.release(shader_module)
	graphics_pipeline_desc.vertex.module = shader_module
	graphics_pipeline_desc.vertex.entry_point = "vs_main"

	// Vertex input configuration
	attribute_desc := [3]wgpu.Vertex_Attribute {
		{format = .Float32x2, offset = u64(offset_of(Draw_Vert, pos)), shader_location = 0},
		{format = .Float32x2, offset = u64(offset_of(Draw_Vert, uv)), shader_location = 1},
		{format = .Unorm8x4, offset = u64(offset_of(Draw_Vert, col)), shader_location = 2},
	}

	buffer_layouts := [1]wgpu.Vertex_Buffer_Layout {
		{array_stride = size_of(Draw_Vert), step_mode = .Vertex, attributes = attribute_desc[:]},
	}

	graphics_pipeline_desc.vertex.buffers = buffer_layouts[:]

	// Setup blending
	blend_state := wgpu.Blend_State {
		alpha = {operation = .Add, src_factor = .One, dst_factor = .One_Minus_Src_Alpha},
		color = {operation = .Add, src_factor = .Src_Alpha, dst_factor = .One_Minus_Src_Alpha},
	}

	color_state := wgpu.Color_Target_State {
		format     = bd.render_target_format,
		blend      = &blend_state,
		write_mask = wgpu.COLOR_WRITES_ALL,
	}

	fragment_state := wgpu.Fragment_State {
		module      = shader_module,
		entry_point = "fs_main",
		targets     = []wgpu.Color_Target_State{color_state},
	}

	graphics_pipeline_desc.fragment = &fragment_state

	// Depth-stencil state
	depth_stencil_state := wgpu.Depth_Stencil_State {
		format = bd.depth_stencil_format,
		depth_write_enabled = false,
		depth_compare = .Always,
		stencil = {
			front = {compare = .Always, fail_op = .Keep, depth_fail_op = .Keep, pass_op = .Keep},
			back = {compare = .Always, fail_op = .Keep, depth_fail_op = .Keep, pass_op = .Keep},
		},
	}

	graphics_pipeline_desc.depth_stencil =
		{} if bd.depth_stencil_format == .Undefined else depth_stencil_state

	bd.pipeline_state = wgpu.device_create_render_pipeline(
		bd.device,
		graphics_pipeline_desc,
	) or_return

	wgpu_create_fonts_texture() or_return
	wgpu_create_uniform_buffer() or_return

	// Create resource bind group
	common_bg_entries := [2]wgpu.Bind_Group_Entry {
		{
			binding = 0,
			resource = wgpu.Buffer_Binding {
				buffer = bd.render_resources.uniforms,
				size = wgpu.align_size(size_of(WGPUUniforms), 16),
			},
		},
		{binding = 1, resource = bd.render_resources.sampler},
	}

	common_bg_descriptor := wgpu.Bind_Group_Descriptor {
		layout  = bg_layouts[0],
		entries = common_bg_entries[:],
	}

	bd.render_resources.common_bind_group = wgpu.device_create_bind_group(
		bd.device,
		common_bg_descriptor,
	) or_return

	image_bind_group := wgpu_create_image_bind_group(
		bg_layouts[1],
		bd.render_resources.font_texture_view,
	) or_return

	bd.render_resources.image_bind_group = image_bind_group
	bd.render_resources.image_bind_group_layout = bg_layouts[1]
	image_bind_group_id := Texture_ID(uintptr(bd.render_resources.font_texture_view))
	bd.render_resources.image_bind_groups[image_bind_group_id] = image_bind_group

	return true
}

@(require_results)
wgpu_create_fonts_texture :: proc() -> (ok: bool) {
	bd := wgpu_get_backend_data()
	io := get_io()

	// Build texture atlas
	pixels: ^u8 = ---
	width, height, size_pp: i32
	// The memory is owned and managed by ImGui's font atlas
	font_atlas_get_tex_data_as_rgba32(io.fonts, &pixels, &width, &height, &size_pp)
	pixel_slice := slice.bytes_from_ptr(pixels, int(width * height * size_pp))

	// Upload texture to graphics system
	tex_desc := wgpu.Texture_Descriptor {
		label = "Dear ImGui Font Texture",
		dimension = .D2,
		size = {width = u32(width), height = u32(height), depth_or_array_layers = 1},
		sample_count = 1,
		format = .Rgba8_Unorm,
		mip_level_count = 1,
		usage = {.Copy_Dst, .Texture_Binding},
	}
	bd.render_resources.font_texture = wgpu.device_create_texture(bd.device, tex_desc) or_return

	tex_view_desc := wgpu.Texture_View_Descriptor {
		format            = tex_desc.format,
		dimension         = .D2,
		base_mip_level    = 0,
		mip_level_count   = 1,
		base_array_layer  = 0,
		array_layer_count = 1,
		aspect            = .All,
	}
	bd.render_resources.font_texture_view = wgpu.texture_create_view(
		bd.render_resources.font_texture,
		tex_view_desc,
	) or_return

	// Upload texture data
	dst_view := wgpu.Texel_Copy_Texture_Info {
		texture   = bd.render_resources.font_texture,
		mip_level = 0,
		origin    = {0, 0, 0},
		aspect    = .All,
	}
	layout := wgpu.Texel_Copy_Buffer_Layout {
		offset         = 0,
		bytes_per_row  = u32(width * size_pp),
		rows_per_image = u32(height),
	}
	size := wgpu.Extent_3D{u32(width), u32(height), 1}

	wgpu.queue_write_texture(bd.default_queue, dst_view, pixel_slice, layout, size) or_return

	// Create the associated sampler
	sampler_desc := wgpu.Sampler_Descriptor {
		min_filter     = .Linear,
		mag_filter     = .Linear,
		mipmap_filter  = .Linear,
		address_mode_u = .Repeat,
		address_mode_v = .Repeat,
		address_mode_w = .Repeat,
		max_anisotropy = 1,
	}
	bd.render_resources.sampler = wgpu.device_create_sampler(bd.device, sampler_desc) or_return

	#assert(
		size_of(Texture_ID) >= size_of(bd.render_resources.font_texture),
		"Can't pack descriptor handle into TexID, 32-bit not supported yet.",
	)

	font_atlas_set_tex_id(io.fonts, Texture_ID(uintptr(bd.render_resources.font_texture_view)))

	return true
}

@(require_results)
wgpu_create_uniform_buffer :: proc() -> (ok: bool) {
	bd := wgpu_get_backend_data()

	ub_dec := wgpu.Buffer_Descriptor {
		label              = "Dear ImGui Uniform buffer",
		usage              = {.Copy_Dst, .Uniform},
		size               = wgpu.align_size(size_of(WGPUUniforms), 16),
		mapped_at_creation = false,
	}
	bd.render_resources.uniforms = wgpu.device_create_buffer(bd.device, ub_dec) or_return

	return true
}

@(require_results)
wgpu_create_image_bind_group :: proc(
	layout: wgpu.Bind_Group_Layout,
	texture: wgpu.Texture_View,
) -> (
	bind_group: wgpu.Bind_Group,
	ok: bool,
) {
	bd := wgpu_get_backend_data()

	image_bg_entries := [1]wgpu.Bind_Group_Entry{{binding = 0, resource = texture}}

	image_bg_descriptor := wgpu.Bind_Group_Descriptor {
		layout  = layout,
		entries = image_bg_entries[:],
	}

	bind_group = wgpu.device_create_bind_group(bd.device, image_bg_descriptor) or_return

	return bind_group, true
}

@(require_results)
wgpu_setup_render_state :: proc(
	draw_data: ^Draw_Data,
	encoder: wgpu.Render_Pass,
	fr: ^WGPUFrameResources,
) -> (
	ok: bool,
) {
	bd := wgpu_get_backend_data()

	// Setup orthographic projection matrix
	mvp := la.matrix_ortho3d_f32(
		left = draw_data.display_pos.x,
		right = draw_data.display_pos.x + draw_data.display_size.x,
		bottom = draw_data.display_pos.y + draw_data.display_size.y,
		top = draw_data.display_pos.y,
		near = -1,
		far = 1,
	)

	// Write uniforms
	wgpu.queue_write_buffer(
		bd.default_queue,
		bd.render_resources.uniforms,
		u64(offset_of(WGPUUniforms, mvp)),
		wgpu.to_bytes(mvp),
	) or_return

	// TODO(Capati): Fix color in the shader
	gamma: f32 = 1.0
	if wgpu.texture_format_is_srgb(bd.render_target_format) {
		gamma = 2.2
	}

	wgpu.queue_write_buffer(
		bd.default_queue,
		bd.render_resources.uniforms,
		u64(offset_of(WGPUUniforms, gamma)),
		wgpu.to_bytes(gamma),
	) or_return

	// Setup viewport
	wgpu.render_pass_set_viewport(
		encoder,
		0,
		0,
		draw_data.framebuffer_scale.x * draw_data.display_size.x,
		draw_data.framebuffer_scale.y * draw_data.display_size.y,
		0,
		1,
	)

	// Bind vertex/index buffers
	wgpu.render_pass_set_vertex_buffer(
		encoder,
		0,
		{buffer = fr.vertex_buffer, size = u64(fr.vertex_buffer_size * size_of(Draw_Vert))},
	)
	wgpu.render_pass_set_index_buffer(
		encoder,
		{buffer = fr.index_buffer, size = u64(fr.index_buffer_size * size_of(Draw_Idx))},
		.Uint16,
	)

	// Set pipeline and bind group
	wgpu.render_pass_set_pipeline(encoder, bd.pipeline_state)
	wgpu.render_pass_set_bind_group(encoder, 0, bd.render_resources.common_bind_group)

	// Setup blend factor
	blend_color := wgpu.Color{0, 0, 0, 0}
	wgpu.render_pass_set_blend_constant(encoder, blend_color)

	return true
}

@(require_results)
wgpu_render_draw_data :: proc(
	draw_data: ^Draw_Data,
	pass_encoder: wgpu.Render_Pass,
) -> (
	ok: bool,
) #no_bounds_check {
	// Avoid rendering when minimized
	fb_width := int(draw_data.display_size.x * draw_data.framebuffer_scale.x)
	fb_height := int(draw_data.display_size.y * draw_data.framebuffer_scale.y)
	if fb_width <= 0 || fb_height <= 0 || draw_data.cmd_lists_count == 0 {
		return true
	}

	// FIXME: Assuming that this only gets called once per frame!
	bd := wgpu_get_backend_data()
	bd.frame_index += 1
	fr := &bd.frame_resources[bd.frame_index % bd.num_frames_in_flight]

	// Create and grow vertex/index buffers if needed
	if fr.vertex_buffer == nil || fr.vertex_buffer_size < draw_data.total_vtx_count {
		if fr.vertex_buffer != nil {
			wgpu.buffer_destroy(fr.vertex_buffer)
			wgpu.buffer_release(fr.vertex_buffer)
		}
		if fr.vertex_buffer_host != nil {
			delete(fr.vertex_buffer_host)
		}
		fr.vertex_buffer_size = draw_data.total_vtx_count + WGPU_VERTEX_BUFFER_SIZE

		vb_desc := wgpu.Buffer_Descriptor {
			label              = "Dear ImGui Vertex buffer",
			usage              = {.Copy_Dst, .Vertex},
			size               = wgpu.align_size(
				u64(fr.vertex_buffer_size * size_of(Draw_Vert)),
				4,
			),
			mapped_at_creation = false,
		}
		fr.vertex_buffer = wgpu.device_create_buffer(bd.device, vb_desc) or_return

		fr.vertex_buffer_host = make([]Draw_Vert, fr.vertex_buffer_size)
	}

	if fr.index_buffer == nil || fr.index_buffer_size < draw_data.total_idx_count {
		if fr.index_buffer != nil {
			wgpu.buffer_destroy(fr.index_buffer)
			wgpu.buffer_release(fr.index_buffer)
		}
		if fr.index_buffer_host != nil {
			delete(fr.index_buffer_host)
		}
		fr.index_buffer_size = draw_data.total_idx_count + WGPU_INDEX_BUFFER_SIZE

		ib_desc := wgpu.Buffer_Descriptor {
			label              = "Dear ImGui Index buffer",
			usage              = {.Copy_Dst, .Index},
			size               = wgpu.align_size(u64(fr.index_buffer_size * size_of(Draw_Vert)), 4),
			mapped_at_creation = false,
		}
		fr.index_buffer = wgpu.device_create_buffer(bd.device, ib_desc) or_return

		fr.index_buffer_host = make([]Draw_Idx, fr.index_buffer_size)
	}

	// Upload vertex/index data into a single contiguous GPU buffer
	vtx_write_offset: i32
	idx_write_offset: i32

	for i in 0 ..< draw_data.cmd_lists_count {
		vector := draw_data.cmd_lists
		draw_lists := ([^]^Draw_List)(vector.data)[:vector.size]
		cmd_list := draw_lists[i]

		intr.mem_copy(
			raw_data(fr.vertex_buffer_host[vtx_write_offset:]),
			cmd_list.vtx_buffer.data,
			cmd_list.vtx_buffer.size * size_of(Draw_Vert),
		)
		intr.mem_copy(
			raw_data(fr.index_buffer_host[idx_write_offset:]),
			cmd_list.idx_buffer.data,
			cmd_list.idx_buffer.size * size_of(Draw_Idx),
		)

		vtx_write_offset += cmd_list.vtx_buffer.size
		idx_write_offset += cmd_list.idx_buffer.size
	}

	wgpu.queue_write_buffer(
		bd.default_queue,
		fr.vertex_buffer,
		0,
		wgpu.to_bytes(fr.vertex_buffer_host),
	) or_return
	wgpu.queue_write_buffer(
		bd.default_queue,
		fr.index_buffer,
		0,
		wgpu.to_bytes(fr.index_buffer_host),
	) or_return

	// Setup desired render state
	wgpu_setup_render_state(draw_data, pass_encoder, fr) or_return

	// Render command lists
	global_vtx_offset: i32
	global_idx_offset: i32
	clip_scale := draw_data.framebuffer_scale
	clip_off := draw_data.display_pos

	for i in 0 ..< draw_data.cmd_lists_count {
		vector := draw_data.cmd_lists
		draw_lists := ([^]^Draw_List)(vector.data)[:vector.size]
		cmd_list := draw_lists[i]

		for cmd_i in 0 ..< cmd_list.cmd_buffer.size {
			cmd_buffer_vector := cmd_list.cmd_buffer
			cmd_buffer_lists := ([^]Draw_Cmd)(cmd_buffer_vector.data)[:cmd_buffer_vector.size]
			pcmd := &cmd_buffer_lists[cmd_i]

			if pcmd.user_callback != nil {
				pcmd.user_callback(cmd_list, pcmd)
			} else {
				tex_id := draw_cmd_get_tex_id(pcmd)
				if bg, bg_ok := bd.render_resources.image_bind_groups[tex_id]; bg_ok {
					wgpu.render_pass_set_bind_group(pass_encoder, 1, bg)
				} else {
					// Bind custom texture
					image_bind_group := wgpu_create_image_bind_group(
						bd.render_resources.image_bind_group_layout,
						(wgpu.Texture_View)(uintptr(tex_id)),
					) or_return
					bd.render_resources.image_bind_groups[tex_id] = image_bind_group
					wgpu.render_pass_set_bind_group(pass_encoder, 1, image_bind_group)
				}

				// Project scissor/clipping rectangles into framebuffer space
				clip_min := Vec2 {
					(pcmd.clip_rect.x - clip_off.x) * clip_scale.x,
					(pcmd.clip_rect.y - clip_off.y) * clip_scale.y,
				}
				clip_max := Vec2 {
					(pcmd.clip_rect.z - clip_off.x) * clip_scale.x,
					(pcmd.clip_rect.w - clip_off.y) * clip_scale.y,
				}

				// Clamp to viewport
				clip_min.x = max(clip_min.x, 0)
				clip_min.y = max(clip_min.y, 0)
				clip_max.x = min(clip_max.x, f32(fb_width))
				clip_max.y = min(clip_max.y, f32(fb_height))

				if clip_max.x <= clip_min.x || clip_max.y <= clip_min.y {
					continue
				}

				// Apply scissor/clipping rectangle and draw
				wgpu.render_pass_set_scissor_rect(
					pass_encoder,
					u32(clip_min.x),
					u32(clip_min.y),
					u32(clip_max.x - clip_min.x),
					u32(clip_max.y - clip_min.y),
				)

				wgpu.render_pass_draw_indexed(
					pass_encoder,
					indices = {
						start = pcmd.idx_offset + u32(global_idx_offset), // first_index
						end   = pcmd.idx_offset + u32(global_idx_offset) + pcmd.elem_count, // first_index + index_count
					},
					base_vertex = i32(pcmd.vtx_offset) + i32(global_vtx_offset),
				)
			}
		}
		global_idx_offset += cmd_list.idx_buffer.size
		global_vtx_offset += cmd_list.vtx_buffer.size
	}

	return true
}

wgpu_invalidate_device_objects :: proc() {
	bd := wgpu_get_backend_data()
	if bd.device == nil {
		return
	}

	wgpu.release_safe(&bd.pipeline_state)
	release(&bd.render_resources)

	io := get_io()
	// We copied g_pFontTextureView to io.Fonts->TexID so let's clear that as well.
	font_atlas_set_tex_id(io.fonts, 0)

	wgpu_release_frame_resources(&bd.frame_resources)
}

wgpu_recreate_device_objects :: proc() -> (ok: bool) {
	wgpu_invalidate_device_objects()
	wgpu_create_device_objects() or_return
	return true
}

@(require_results)
wgpu_init :: proc(init_info: WGPUInitInfo, loc := #caller_location) -> (ok: bool) {
	ensure(init_info.device != nil, "Invalid device", loc = loc)

	io := get_io()
	assert(io.backend_renderer_user_data == nil, "Already initialized a renderer backend!")

	bd := new(WGPUData)
	ensure(bd != nil, "Failed to allocate WGPUData")
	io.backend_renderer_user_data = bd
	io.backend_renderer_name = "imgui_impl_webgpu"
	io.backend_flags += {.Renderer_Has_Vtx_Offset}

	bd.init_info = init_info
	bd.device = init_info.device
	wgpu.add_ref(bd.device)
	bd.default_queue = wgpu.device_get_queue(bd.device)
	bd.render_target_format = init_info.render_target_format
	bd.depth_stencil_format = init_info.depth_stencil_format
	bd.num_frames_in_flight = init_info.num_frames_in_flight
	bd.frame_index = max(u32)

	bd.render_resources.image_bind_groups = make(map[Texture_ID]wgpu.Bind_Group, 100)

	bd.frame_resources = make([dynamic]WGPUFrameResources, bd.num_frames_in_flight)
	for &fr in bd.frame_resources {
		fr.index_buffer_size = WGPU_INDEX_BUFFER_SIZE
		fr.vertex_buffer_size = WGPU_VERTEX_BUFFER_SIZE
	}

	return true
}

@(require_results)
wgpu_new_frame :: proc() -> (ok: bool) {
	bd := wgpu_get_backend_data()
	if bd.pipeline_state == nil {
		wgpu_create_device_objects() or_return
	}
	return true
}

wgpu_release_frame_resources :: proc(resources: ^[dynamic]WGPUFrameResources) {
	for &fr in resources {
		frame_resources_release(&fr)
	}
}

wgpu_delete_frame_resources :: proc(resources: ^[dynamic]WGPUFrameResources) {
	wgpu_release_frame_resources(resources)
	delete(resources^)
}

frame_resources_release :: proc(res: ^WGPUFrameResources) {
	wgpu.release_safe(&res.index_buffer)
	wgpu.release_safe(&res.vertex_buffer)
	if res.index_buffer_host != nil {
		delete(res.index_buffer_host)
		res.index_buffer_host = nil
	}
	if res.vertex_buffer_host != nil {
		delete(res.vertex_buffer_host)
		res.vertex_buffer_host = nil
	}
}

render_resources_release :: proc(res: ^WGPURenderResources) {
	wgpu.release_safe(&res.font_texture)
	wgpu.release_safe(&res.font_texture_view)
	wgpu.release_safe(&res.sampler)
	wgpu.release_safe(&res.uniforms)
	wgpu.release_safe(&res.common_bind_group)
	wgpu.release_safe(&res.image_bind_group)
	wgpu.release_safe(&res.image_bind_group_layout)
}

wgpu_delete_render_resources :: proc(res: ^WGPURenderResources) {
	render_resources_release(res)
	delete(res.image_bind_groups)
}

release :: proc {
	render_resources_release,
	frame_resources_release,
}

wgpu_shutdown :: proc() {
	bd := wgpu_get_backend_data()
	assert(bd != nil, "No renderer backend to shutdown, or already shutdown?")
	io := get_io()

	io.backend_renderer_name = nil
	io.backend_renderer_user_data = nil
	io.backend_flags -= {.Renderer_Has_Vtx_Offset}

	wgpu_delete_frame_resources(&bd.frame_resources)
	wgpu_delete_render_resources(&bd.render_resources)

	wgpu.release(bd.pipeline_state)
	wgpu.release(bd.default_queue)
	wgpu.release(bd.device) // decrease ref count

	free(bd)
}
