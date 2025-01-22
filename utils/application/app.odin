package application

// Packages
import intr "base:intrinsics"
import "core:log"
import "core:time"
import "vendor:glfw"
import mu "vendor:microui"

// Local packages
import wgpu "./../../wgpu"
import im "./../imgui"

WINDOW_TITLE_BUFFER_LEN :: #config(WINDOW_TITLE_BUFFER_LEN, 256)

Window :: glfw.WindowHandle
Monitor :: glfw.MonitorHandle

Application :: struct {
	// Settings
	settings:          Settings,

	// Platform
	monitor:           Monitor,
	window:            Window,
	aspect:            f32,

	// Renderer
	gpu:               Graphics_Context,
	should_resize:     bool,
	framebuffer_size:  Framebuffer_Size,
	frame:             Frame_Texture,
	cmd:               wgpu.Command_Encoder,
	rpass:             wgpu.Render_Pass,
	cpass:             wgpu.Compute_Pass,
	cmdbuf:            wgpu.Command_Buffer,
	depth_stencil:     struct {
		enabled:    bool,
		format:     wgpu.Texture_Format,
		texture:    wgpu.Texture,
		view:       wgpu.Texture_View,
		descriptor: wgpu.Render_Pass_Depth_Stencil_Attachment,
	},

	// UI
	_mu_ctx:            ^mu.Context,
	_im_ctx:            ^im.Context,

	// State
	title_buffer:      [WINDOW_TITLE_BUFFER_LEN]byte,
	timer:             Timer,
	keyboard:          Keyboard_State,
	mouse:             Mouse_State,
	exit_key:          Key,
	target_frame_time: time.Duration,
	prepared:          bool,

	// Events
	events:            Event_State,
	minimized:         bool,

	// Debug
	logger:            log.Logger, // For use outside of Odin context
}

Context :: struct($T: typeid) where intr.type_is_struct(T) {
	using app:   Application,
	using state: T,
	callbacks:   Callback_List(T),
}

Depth_Stencil_Texture_Creation_Options :: struct {
	format:       wgpu.Texture_Format,
	sample_count: u32,
}

set_target_frame_time :: proc(app: ^Application, d: time.Duration) {
	app.target_frame_time = d
}

set_aspect_framebuffer :: proc(app: ^Application) {
	app.aspect = f32(app.framebuffer_size.w) / f32(app.framebuffer_size.h)
}

set_aspect_from_value :: proc(app: ^Application, aspect: f32) {
	app.aspect = aspect
}

set_aspect_from_size :: proc(app: ^Application, size: Window_Size) {
	app.aspect = f32(size.w) / f32(size.h)
}

set_aspect :: proc {
	set_aspect_framebuffer,
	set_aspect_from_value,
	set_aspect_from_size,
}

quit :: proc(app: ^Application) {
	glfw.SetWindowShouldClose(app.window, true)
}

Depth_Stencil_State_Descriptor :: struct {
	format:              wgpu.Texture_Format,
	depth_write_enabled: bool,
}

create_depth_stencil_state :: proc(
	app: ^Application,
	descriptor: Depth_Stencil_State_Descriptor = {DEFAULT_DEPTH_FORMAT, true},
) -> wgpu.Depth_Stencil_State {
	stencil_state_face_descriptor := wgpu.Stencil_Face_State {
		compare       = .Always,
		fail_op       = .Keep,
		depth_fail_op = .Keep,
		pass_op       = .Keep,
	}

	format := descriptor.format
	if format == .Undefined {
		format = DEFAULT_DEPTH_FORMAT
	}

	return {
		format = format,
		depth_write_enabled = descriptor.depth_write_enabled,
		stencil = {
			front = stencil_state_face_descriptor,
			back = stencil_state_face_descriptor,
			read_mask = max(u32),
			write_mask = max(u32),
		},
	}
}

setup_depth_stencil :: proc(
	app: ^Application,
	options: Depth_Stencil_Texture_Creation_Options = {},
) -> (
	ok: bool,
) {
	if app.depth_stencil.enabled {
		wgpu.release(app.depth_stencil.texture)
		wgpu.release(app.depth_stencil.view)
	}

	format := options.format
	if format == .Undefined {
		format = DEFAULT_DEPTH_FORMAT
	}
	app.depth_stencil.format = format

	sample_count := options.sample_count
	if sample_count == 0 {
		sample_count = 1
	}

	texture_descriptor := wgpu.Texture_Descriptor {
		usage = {.Render_Attachment, .Copy_Dst},
		format = format,
		dimension = .D2,
		mip_level_count = 1,
		sample_count = sample_count,
		size = {
			width = app.gpu.config.width,
			height = app.gpu.config.height,
			depth_or_array_layers = 1,
		},
	}

	app.depth_stencil.texture = wgpu.device_create_texture(
		app.gpu.device,
		texture_descriptor,
	) or_return
	defer if !ok {
		wgpu.release(app.depth_stencil.texture)
	}

	texture_view_descriptor := wgpu.Texture_View_Descriptor {
		format            = texture_descriptor.format,
		dimension         = .D2,
		base_mip_level    = 0,
		mip_level_count   = 1,
		base_array_layer  = 0,
		array_layer_count = 1,
		aspect            = .All,
	}

	app.depth_stencil.view = wgpu.texture_create_view(
		app.depth_stencil.texture,
		texture_view_descriptor,
	) or_return
	defer if !ok {
		wgpu.release(app.depth_stencil.view)
	}

	app.depth_stencil.descriptor = {
		view                = app.depth_stencil.view,
		depth_load_op       = .Clear,
		depth_store_op      = .Store,
		depth_clear_value   = 1.0,
		stencil_clear_value = 0.0,
	}

	app.depth_stencil.enabled = true

	return true
}

release :: proc {
	texture_release,
}

destroy :: proc(self: ^Application) {
	when ENABLE_IMGUI {
		if imgui_is_initialized(self) {
			imgui_destroy(self)
		}
	}

	if microui_is_initialized(self) {
		microui_destroy(self)
	}

	if self.depth_stencil.enabled {
		wgpu.release(self.depth_stencil.texture)
		wgpu.release(self.depth_stencil.view)
	}

	wgpu.surface_capabilities_free_members(self.gpu.caps)

	wgpu.queue_release(self.gpu.queue)
	wgpu.device_release(self.gpu.device)
	wgpu.adapter_release(self.gpu.adapter)
	wgpu.surface_release(self.gpu.surface)
	wgpu.instance_release(self.gpu.instance)

	glfw.DestroyWindow(self.window)
	glfw.Terminate()

	delete(self.events.data.data)

	free(self)
}
