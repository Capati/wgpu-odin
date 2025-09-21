package imgui_utils

// Core
import "core:slice"
import intr "base:intrinsics"
import la "core:math/linalg"

// Local packages
import wgpu "../../"
import im "../../libs/imgui"

/* WGPU render-specific resources required for ImGui integration with WGPU backend. */
Render_Resources :: struct {
	font_texture:            wgpu.Texture, /* Font texture */
	font_texture_view:       wgpu.TextureView, /* Texture view for font texture */
	sampler:                 wgpu.Sampler, /* Sampler for the font texture */
	uniforms:                wgpu.Buffer, /* Shader uniforms */
	common_bind_group:       wgpu.BindGroup, /* Resources bind-group to bind the common resources to pipeline */
	image_bind_groups:       map[im.Texture_ID]wgpu.BindGroup, /* Resources bind-group to bind the font/image resources to pipeline */
	image_bind_group_layout: wgpu.BindGroupLayout, /* Cache layout used for the image bind group. Avoids allocating unnecessary JS objects when working with WebASM */
}

/* GPU and host resources required for rendering ImGui frames. */
Frame_Resources :: struct {
	index_buffer:       wgpu.Buffer, /* WebGPU buffer containing indices for rendering */
	vertex_buffer:      wgpu.Buffer, /* WebGPU buffer containing vertices for rendering */
	index_buffer_host:  []im.Draw_Idx, /* Host-side array of draw indices */
	vertex_buffer_host: []im.Draw_Vert, /* Host-side array of draw vertices */
	index_buffer_size:  i32, /* Size of the index buffer in bytes */
	vertex_buffer_size: i32, /* Size of the vertex buffer in bytes */
}

Uniforms :: struct {
	mvp:   la.Matrix4f32,
	gamma: f32,
}

Init_Info :: struct {
	device:                     wgpu.Device,
	num_frames_in_flight:       u32,
	render_target_format:       wgpu.TextureFormat,
	depth_stencil_format:       wgpu.TextureFormat,
	pipeline_multisample_state: wgpu.MultisampleState,
}

DEFAULT_WGPU_FRAMES_IN_FLIGHT :: #config(IMGUI_WGPU_FRAMES_IN_FLIGHT, 3)

INIT_INFO_DEFAULT :: Init_Info {
	num_frames_in_flight       = DEFAULT_WGPU_FRAMES_IN_FLIGHT,
	render_target_format       = .Undefined,
	depth_stencil_format       = .Undefined,
	pipeline_multisample_state = wgpu.MULTISAMPLE_STATE_DEFAULT,
}

/* Backend data stored in `io.backend_renderer_user_data` */
Data :: struct {
	init_info:            Init_Info,
	device:               wgpu.Device,
	default_queue:        wgpu.Queue,
	render_target_format: wgpu.TextureFormat,
	depth_stencil_format: wgpu.TextureFormat,
	pipeline_state:       wgpu.RenderPipeline,
	render_resources:     Render_Resources,
	frame_resources:      [dynamic]Frame_Resources,
	num_frames_in_flight: u32,
	frame_index:          u32,
}

Render_State :: struct {
	device:              wgpu.Device,
	render_pass_encoder: wgpu.RenderPass,
}

WGPU_INDEX_BUFFER_SIZE :: #config(IMGUI_WGPU_INDEX_BUFFER_SIZE, 10000)
WGPU_VERTEX_BUFFER_SIZE :: #config(IMGUI_WGPU_VERTEX_BUFFER_SIZE, 5000)

/* Retrieves a pointer to the `Data` structure. */
@(require_results)
get_backend_data :: proc "contextless" () -> ^Data {
	if ctx := im.get_current_context(); ctx != nil {
		return cast(^Data)(im.get_io().backend_renderer_user_data)
	}
	return nil
}

@(require_results)
create_device_objects :: proc() -> (ok: bool) {
	bd := get_backend_data()
	if bd.device == nil {
		return
	}
	if bd.pipeline_state != nil {
		invalidate_device_objects()
	}

	// Create render pipeline
	graphics_pipeline_desc: wgpu.RenderPipelineDescriptor
	graphics_pipeline_desc.primitive = {
		topology         = .TriangleList,
		stripIndexFormat = .Undefined,
		frontFace        = .CW,
		cullMode         = .None,
	}
	graphics_pipeline_desc.multisample = bd.init_info.pipeline_multisample_state

	// Bind group layouts
	common_bg_layout_entries := [2]wgpu.BindGroupLayoutEntry {
		{
			binding = 0,
			visibility = {.Vertex, .Fragment},
			type = wgpu.BufferBindingLayout{type = .Uniform},
		},
		{
			binding = 1,
			visibility = {.Fragment},
			type = wgpu.SamplerBindingLayout{type = .Filtering},
		},
	}

	image_bg_layout_entries := [1]wgpu.BindGroupLayoutEntry {
		{
			binding = 0,
			visibility = {.Fragment},
			type = wgpu.TextureBindingLayout {
				sampleType    = .Float,
				viewDimension = ._2D,
				multisampled  = false,
			},
		},
	}

	common_bg_layout_desc := wgpu.BindGroupLayoutDescriptor {
		entries = common_bg_layout_entries[:],
	}

	image_bg_layout_desc := wgpu.BindGroupLayoutDescriptor {
		entries = image_bg_layout_entries[:],
	}

	bg_layouts := [2]wgpu.BindGroupLayout {
		wgpu.DeviceCreateBindGroupLayout(bd.device, common_bg_layout_desc),
		wgpu.DeviceCreateBindGroupLayout(bd.device, image_bg_layout_desc),
	}
	defer {
		wgpu.BindGroupLayoutRelease(bg_layouts[0])
		// wgpu.BindGroupLayoutRelease(bg_layouts[1])
	}

	layout_desc := wgpu.PipelineLayoutDescriptor {
		bindGroupLayouts = bg_layouts[:],
	}

	graphics_pipeline_desc.layout = wgpu.DeviceCreatePipelineLayout(bd.device, layout_desc)
	defer wgpu.PipelineLayoutRelease(graphics_pipeline_desc.layout)

	// Create the shader module
	IMGUI_IMPL_WGPU_WGSL :: #load("imgui_impl_wgpu.wgsl", string)
	shader_module := wgpu.DeviceCreateShaderModule(
		bd.device,
		{label = "imgui_shader_module", source = IMGUI_IMPL_WGPU_WGSL},
	)
	defer wgpu.Release(shader_module)
	graphics_pipeline_desc.vertex.module = shader_module
	graphics_pipeline_desc.vertex.entryPoint = "vs_main"

	// Vertex input configuration
	attribute_desc := [3]wgpu.VertexAttribute {
		{format = .Float32x2, offset = u64(offset_of(im.Draw_Vert, pos)), shaderLocation = 0},
		{format = .Float32x2, offset = u64(offset_of(im.Draw_Vert, uv)), shaderLocation = 1},
		{format = .Unorm8x4, offset = u64(offset_of(im.Draw_Vert, col)), shaderLocation = 2},
	}

	buffer_layouts := [1]wgpu.VertexBufferLayout {
		{
			arrayStride = size_of(im.Draw_Vert),
			stepMode    = .Vertex,
			attributes  = attribute_desc[:],
		},
	}

	graphics_pipeline_desc.vertex.buffers = buffer_layouts[:]

	// Setup blending
	blend_state := wgpu.BlendState {
		alpha = {operation = .Add, srcFactor = .One, dstFactor = .OneMinusSrcAlpha},
		color = {operation = .Add, srcFactor = .SrcAlpha, dstFactor = .OneMinusSrcAlpha},
	}

	color_state := wgpu.ColorTargetState {
		format    = bd.render_target_format,
		blend     = &blend_state,
		writeMask = wgpu.COLOR_WRITES_ALL,
	}

	fragment_state := wgpu.FragmentState {
		module     = shader_module,
		entryPoint = "fs_main",
		targets    = []wgpu.ColorTargetState{color_state},
	}

	graphics_pipeline_desc.fragment = &fragment_state

	// Depth-stencil state
	depth_stencil_state := wgpu.DepthStencilState {
		format = bd.depth_stencil_format,
		depthWriteEnabled = false,
		depthCompare = .Always,
		stencil = {
			front = {compare = .Always, failOp = .Keep, depthFailOp = .Keep, passOp = .Keep},
			back = {compare = .Always, failOp = .Keep, depthFailOp = .Keep, passOp = .Keep},
		},
	}

	graphics_pipeline_desc.depthStencil =
		{} if bd.depth_stencil_format == .Undefined else depth_stencil_state

	bd.pipeline_state = wgpu.DeviceCreateRenderPipeline(
		bd.device,
		graphics_pipeline_desc,
	)

	create_fonts_texture() or_return
	create_uniform_buffer() or_return

	// Create resource bind group
	common_bg_entries := [2]wgpu.BindGroupEntry {
		{
			binding = 0,
			resource = wgpu.BufferBinding {
				buffer = bd.render_resources.uniforms,
				size = wgpu.AlignSize(size_of(Uniforms), 16),
			},
		},
		{binding = 1, resource = bd.render_resources.sampler},
	}

	common_bg_descriptor := wgpu.BindGroupDescriptor {
		layout  = bg_layouts[0],
		entries = common_bg_entries[:],
	}

	bd.render_resources.common_bind_group = wgpu.DeviceCreateBindGroup(
		bd.device,
		common_bg_descriptor,
	)

	bd.render_resources.image_bind_group_layout = bg_layouts[1]

	return true
}

@(require_results)
create_fonts_texture :: proc() -> (ok: bool) {
	bd := get_backend_data()
	io := im.get_io()

	// Build texture atlas
	pixels: ^u8 = ---
	width, height, size_pp: i32
	// The memory is owned and managed by ImGui's font atlas
	im.font_atlas_get_tex_data_as_rgba32(io.fonts, &pixels, &width, &height, &size_pp)
	pixel_slice := slice.bytes_from_ptr(pixels, int(width * height * size_pp))

	// Upload texture to graphics system
	tex_desc := wgpu.TextureDescriptor {
		label         = "Dear ImGui Font Texture",
		dimension     = ._2D,
		size          = {width = u32(width), height = u32(height), depthOrArrayLayers = 1},
		sampleCount   = 1,
		format        = .RGBA8Unorm,
		mipLevelCount = 1,
		usage         = {.CopyDst, .TextureBinding},
	}
	bd.render_resources.font_texture = wgpu.DeviceCreateTexture(bd.device, tex_desc)

	tex_view_desc := wgpu.TextureViewDescriptor {
		format          = tex_desc.format,
		dimension       = ._2D,
		baseMipLevel    = 0,
		mipLevelCount   = 1,
		baseArrayLayer  = 0,
		arrayLayerCount = 1,
		aspect          = .All,
	}
	bd.render_resources.font_texture_view = wgpu.TextureCreateView(
		bd.render_resources.font_texture,
		tex_view_desc,
	)

	// Upload texture data
	dst_view := wgpu.TexelCopyTextureInfo {
		texture  = bd.render_resources.font_texture,
		mipLevel = 0,
		origin   = {0, 0, 0},
		aspect   = .All,
	}
	layout := wgpu.TexelCopyBufferLayout {
		offset       = 0,
		bytesPerRow  = u32(width * size_pp),
		rowsPerImage = u32(height),
	}
	size := wgpu.Extent3D{u32(width), u32(height), 1}

	wgpu.QueueWriteTexture(bd.default_queue, dst_view, pixel_slice, layout, size)

	// Create the associated sampler
	sampler_desc := wgpu.SamplerDescriptor {
		minFilter     = .Linear,
		magFilter     = .Linear,
		mipmapFilter  = .Linear,
		addressModeU  = .Repeat,
		addressModeV  = .Repeat,
		addressModeW  = .Repeat,
		maxAnisotropy = 1,
	}
	bd.render_resources.sampler = wgpu.DeviceCreateSampler(bd.device, sampler_desc)

	#assert(
		size_of(im.Texture_ID) >= size_of(bd.render_resources.font_texture),
		"Can't pack descriptor handle into TexID, 32-bit not supported yet.",
	)

	im.font_atlas_set_tex_id(
		io.fonts,
		im.Texture_ID(uintptr(bd.render_resources.font_texture_view)),
	)

	return true
}

@(require_results)
create_uniform_buffer :: proc() -> (ok: bool) {
	bd := get_backend_data()

	ub_dec := wgpu.BufferDescriptor {
		label            = "Dear ImGui Uniform buffer",
		usage            = {.CopyDst, .Uniform},
		size             = wgpu.AlignSize(size_of(Uniforms), 16),
		mappedAtCreation = false,
	}
	bd.render_resources.uniforms = wgpu.DeviceCreateBuffer(bd.device, ub_dec)

	return true
}

@(require_results)
create_image_bind_group :: proc(
	layout: wgpu.BindGroupLayout,
	texture: wgpu.TextureView,
) -> (
	bind_group: wgpu.BindGroup,
	ok: bool,
) {
	bd := get_backend_data()

	image_bg_entries := [1]wgpu.BindGroupEntry{{binding = 0, resource = texture}}

	image_bg_descriptor := wgpu.BindGroupDescriptor {
		layout  = layout,
		entries = image_bg_entries[:],
	}

	bind_group = wgpu.DeviceCreateBindGroup(bd.device, image_bg_descriptor)

	return bind_group, true
}

@(require_results)
setup_render_state :: proc(
	draw_data: ^im.Draw_Data,
	encoder: wgpu.RenderPass,
	fr: ^Frame_Resources,
) -> (
	ok: bool,
) {
	bd := get_backend_data()

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
	wgpu.QueueWriteBuffer(
		bd.default_queue,
		bd.render_resources.uniforms,
		u64(offset_of(Uniforms, mvp)),
		wgpu.ToBytes(mvp),
	)

	// TODO(Capati): Fix color in the shader
	gamma: f32 = 1.0
	if wgpu.TextureFormatIsSrgb(bd.render_target_format) {
		gamma = 2.2
	}

	wgpu.QueueWriteBuffer(
		bd.default_queue,
		bd.render_resources.uniforms,
		u64(offset_of(Uniforms, gamma)),
		wgpu.ToBytes(gamma),
	)

	// Setup viewport
	wgpu.RenderPassSetViewport(
		encoder,
		0,
		0,
		draw_data.framebuffer_scale.x * draw_data.display_size.x,
		draw_data.framebuffer_scale.y * draw_data.display_size.y,
		0,
		1,
	)

	// Bind vertex/index buffers
	wgpu.RenderPassSetVertexBuffer(
		encoder,
		0,
		{buffer = fr.vertex_buffer, size = u64(fr.vertex_buffer_size * size_of(im.Draw_Vert))},
	)
	wgpu.RenderPassSetIndexBuffer(
		encoder,
		{buffer = fr.index_buffer, size = u64(fr.index_buffer_size * size_of(im.Draw_Idx))},
		.Uint16,
	)

	// Set pipeline and bind group
	wgpu.RenderPassSetPipeline(encoder, bd.pipeline_state)
	wgpu.RenderPassSetBindGroup(encoder, 0, bd.render_resources.common_bind_group)

	// Setup blend factor
	blend_color := wgpu.Color{0, 0, 0, 0}
	wgpu.RenderPassSetBlendConstant(encoder, blend_color)

	return true
}

render_draw_data :: proc(
	draw_data: ^im.Draw_Data,
	pass_encoder: wgpu.RenderPass,
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
	bd := get_backend_data()
	bd.frame_index += 1
	fr := &bd.frame_resources[bd.frame_index % bd.num_frames_in_flight]

	// Create and grow vertex/index buffers if needed
	if fr.vertex_buffer == nil || fr.vertex_buffer_size < draw_data.total_vtx_count {
		if fr.vertex_buffer != nil {
			wgpu.BufferDestroy(fr.vertex_buffer)
			wgpu.BufferRelease(fr.vertex_buffer)
		}
		if fr.vertex_buffer_host != nil {
			delete(fr.vertex_buffer_host)
		}
		fr.vertex_buffer_size = draw_data.total_vtx_count + WGPU_VERTEX_BUFFER_SIZE

		vb_desc := wgpu.BufferDescriptor {
			label              = "Dear ImGui Vertex buffer",
			usage              = {.CopyDst, .Vertex},
			size               = wgpu.AlignSize(
				u64(fr.vertex_buffer_size * size_of(im.Draw_Vert)), 4),
			mappedAtCreation = false,
		}
		fr.vertex_buffer = wgpu.DeviceCreateBuffer(bd.device, vb_desc)

		fr.vertex_buffer_host = make([]im.Draw_Vert, fr.vertex_buffer_size)
	}

	if fr.index_buffer == nil || fr.index_buffer_size < draw_data.total_idx_count {
		if fr.index_buffer != nil {
			wgpu.BufferDestroy(fr.index_buffer)
			wgpu.BufferRelease(fr.index_buffer)
		}
		if fr.index_buffer_host != nil {
			delete(fr.index_buffer_host)
		}
		fr.index_buffer_size = draw_data.total_idx_count + WGPU_INDEX_BUFFER_SIZE

		ib_desc := wgpu.BufferDescriptor {
			label              = "Dear ImGui Index buffer",
			usage              = {.CopyDst, .Index},
			size               = wgpu.AlignSize(
				u64(fr.index_buffer_size * size_of(im.Draw_Vert)),4),
			mappedAtCreation = false,
		}
		fr.index_buffer = wgpu.DeviceCreateBuffer(bd.device, ib_desc)

		fr.index_buffer_host = make([]im.Draw_Idx, fr.index_buffer_size)
	}

	// Upload vertex/index data into a single contiguous GPU buffer
	vtx_write_offset: i32
	idx_write_offset: i32

	for i in 0 ..< draw_data.cmd_lists_count {
		vector := draw_data.cmd_lists
		draw_lists := ([^]^im.Draw_List)(vector.data)[:vector.size]
		cmd_list := draw_lists[i]

		intr.mem_copy(
			raw_data(fr.vertex_buffer_host[vtx_write_offset:]),
			cmd_list.vtx_buffer.data,
			cmd_list.vtx_buffer.size * size_of(im.Draw_Vert),
		)
		intr.mem_copy(
			raw_data(fr.index_buffer_host[idx_write_offset:]),
			cmd_list.idx_buffer.data,
			cmd_list.idx_buffer.size * size_of(im.Draw_Idx),
		)

		vtx_write_offset += cmd_list.vtx_buffer.size
		idx_write_offset += cmd_list.idx_buffer.size
	}

	wgpu.QueueWriteBuffer(
		bd.default_queue,
		fr.vertex_buffer,
		0,
		wgpu.ToBytes(fr.vertex_buffer_host),
	)
	wgpu.QueueWriteBuffer(
		bd.default_queue,
		fr.index_buffer,
		0,
		wgpu.ToBytes(fr.index_buffer_host),
	)

	// Setup desired render state
	setup_render_state(draw_data, pass_encoder, fr) or_return

	// Setup render state structure (for callbacks and custom texture bindings)
	platform_io := im.get_platform_io()
	render_state := Render_State {
		device              = bd.device,
		render_pass_encoder = pass_encoder,
	}
	platform_io.renderer_render_state = &render_state

	// Render command lists
	global_vtx_offset: i32
	global_idx_offset: i32
	clip_scale := draw_data.framebuffer_scale
	clip_off := draw_data.display_pos

	for i in 0 ..< draw_data.cmd_lists_count {
		vector := draw_data.cmd_lists
		draw_lists := ([^]^im.Draw_List)(vector.data)[:vector.size]
		cmd_list := draw_lists[i]

		for cmd_i in 0 ..< cmd_list.cmd_buffer.size {
			cmd_buffer_vector := cmd_list.cmd_buffer
			cmd_buffer_lists := ([^]im.Draw_Cmd)(cmd_buffer_vector.data)[:cmd_buffer_vector.size]
			pcmd := &cmd_buffer_lists[cmd_i]

			if pcmd.user_callback != nil {
				pcmd.user_callback(cmd_list, pcmd)
			} else {
				tex_id := im.draw_cmd_get_tex_id(pcmd)
				if bg, bg_ok := bd.render_resources.image_bind_groups[tex_id]; bg_ok {
					wgpu.RenderPassSetBindGroup(pass_encoder, 1, bg)
				} else {
					// Bind custom texture
					image_bind_group := create_image_bind_group(
						bd.render_resources.image_bind_group_layout,
						(wgpu.TextureView)(uintptr(tex_id)),
					) or_return
					bd.render_resources.image_bind_groups[tex_id] = image_bind_group
					wgpu.RenderPassSetBindGroup(pass_encoder, 1, image_bind_group)
				}

				// Project scissor/clipping rectangles into framebuffer space
				clip_min := im.Vec2 {
					(pcmd.clip_rect.x - clip_off.x) * clip_scale.x,
					(pcmd.clip_rect.y - clip_off.y) * clip_scale.y,
				}
				clip_max := im.Vec2 {
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
				wgpu.RenderPassSetScissorRect(
					pass_encoder,
					u32(clip_min.x),
					u32(clip_min.y),
					u32(clip_max.x - clip_min.x),
					u32(clip_max.y - clip_min.y),
				)

				wgpu.RenderPassDrawIndexed(
					pass_encoder,
					indices = {
						start = pcmd.idx_offset + u32(global_idx_offset), // first_index
						end   = pcmd.idx_offset + u32(global_idx_offset) + pcmd.elem_count, // first_index + index_count
					},
					baseVertex = i32(pcmd.vtx_offset) + i32(global_vtx_offset),
				)
			}
		}
		global_idx_offset += cmd_list.idx_buffer.size
		global_vtx_offset += cmd_list.vtx_buffer.size
	}

	for _, &v in bd.render_resources.image_bind_groups {
		wgpu.ReleaseSafe(&v)
	}
	clear(&bd.render_resources.image_bind_groups)

	platform_io.renderer_render_state = nil

	return true
}

invalidate_device_objects :: proc() {
	bd := get_backend_data()
	if bd.device == nil {
		return
	}

	wgpu.ReleaseSafe(&bd.pipeline_state)
	release(&bd.render_resources)

	io := im.get_io()
	// We copied g_pFontTextureView to io.Fonts->TexID so let's clear that as well.
	im.font_atlas_set_tex_id(io.fonts, 0)

	release_frame_resources(&bd.frame_resources)
}

recreate_device_objects :: proc() -> (ok: bool) {
	invalidate_device_objects()
	create_device_objects() or_return
	return true
}

@(require_results)
init :: proc(init_info: Init_Info, loc := #caller_location) -> (ok: bool) {
	ensure(init_info.device != nil, "Invalid device", loc = loc)

	io := im.get_io()
	assert(io.backend_renderer_user_data == nil, "Already initialized a renderer backend!")

	bd := new(Data)
	ensure(bd != nil, "Failed to allocate Data")
	io.backend_renderer_user_data = bd
	io.backend_renderer_name = "imgui_impl_webgpu"
	io.backend_flags += {.Renderer_Has_Vtx_Offset}

	bd.init_info = init_info
	bd.device = init_info.device
	wgpu.AddRef(bd.device)
	bd.default_queue = wgpu.DeviceGetQueue(bd.device)
	bd.render_target_format = init_info.render_target_format
	bd.depth_stencil_format = init_info.depth_stencil_format
	bd.num_frames_in_flight = init_info.num_frames_in_flight
	bd.frame_index = max(u32)

	bd.render_resources.image_bind_groups = make(map[im.Texture_ID]wgpu.BindGroup, 100)

	bd.frame_resources = make([dynamic]Frame_Resources, bd.num_frames_in_flight)
	for &fr in bd.frame_resources {
		fr.index_buffer_size = WGPU_INDEX_BUFFER_SIZE
		fr.vertex_buffer_size = WGPU_VERTEX_BUFFER_SIZE
	}

	return true
}

new_frame :: proc() -> (ok: bool) {
	bd := get_backend_data()
	if bd.pipeline_state == nil {
		create_device_objects() or_return
	}
	return true
}

release_frame_resources :: proc(resources: ^[dynamic]Frame_Resources) {
	for &fr in resources {
		frame_resources_release(&fr)
	}
}

delete_frame_resources :: proc(resources: ^[dynamic]Frame_Resources) {
	release_frame_resources(resources)
	delete(resources^)
}

frame_resources_release :: proc(res: ^Frame_Resources) {
	wgpu.ReleaseSafe(&res.index_buffer)
	wgpu.ReleaseSafe(&res.vertex_buffer)
	if res.index_buffer_host != nil {
		delete(res.index_buffer_host)
		res.index_buffer_host = nil
	}
	if res.vertex_buffer_host != nil {
		delete(res.vertex_buffer_host)
		res.vertex_buffer_host = nil
	}
}

render_resources_release :: proc(res: ^Render_Resources) {
	wgpu.ReleaseSafe(&res.font_texture)
	wgpu.ReleaseSafe(&res.font_texture_view)
	wgpu.ReleaseSafe(&res.sampler)
	wgpu.ReleaseSafe(&res.uniforms)
	wgpu.ReleaseSafe(&res.common_bind_group)
	wgpu.ReleaseSafe(&res.image_bind_group_layout)
}

delete_render_resources :: proc(res: ^Render_Resources) {
	render_resources_release(res)
	delete(res.image_bind_groups)
}

release :: proc {
	render_resources_release,
	frame_resources_release,
}

shutdown :: proc() {
	bd := get_backend_data()
	assert(bd != nil, "No renderer backend to shutdown, or already shutdown?")
	io := im.get_io()

	io.backend_renderer_name = nil
	io.backend_renderer_user_data = nil
	io.backend_flags -= {.Renderer_Has_Vtx_Offset}

	delete_frame_resources(&bd.frame_resources)
	delete_render_resources(&bd.render_resources)

	wgpu.Release(bd.pipeline_state)
	wgpu.Release(bd.default_queue)
	wgpu.Release(bd.device) // decrease ref count

	free(bd)
}
