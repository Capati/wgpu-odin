package application

// Packages
import intr "base:intrinsics"

// Local packages
import "./../../wgpu"
import im "./../imgui"

ENABLE_IMGUI :: #config(APP_ENABLE_IMGUI, false)

when ENABLE_IMGUI {
	@(require_results)
	imgui_init :: proc(app: ^Application) -> (ok: bool) {
		app.im_ctx = im.create_context()
		defer if !ok {
			im.destroy_context(app.im_ctx)
		}

		im.style_colors_dark()

		ensure(im.glfw_init(app.window, true))
		defer if !ok {
			im.glfw_shutdown()
		}

		init_info := im.DEFAULT_WGPU_INIT_INFO
		init_info.device = app.gpu.device
		init_info.render_target_format = app.gpu.config.format

		ensure(im.wgpu_init(init_info))
		defer if !ok {
			im.wgpu_shutdown()
		}

		return true
	}

	imgui_destroy :: proc(app: ^Application) {
		im.wgpu_shutdown()
		im.glfw_shutdown()
		im.destroy_context(app.im_ctx)
	}

	@(require_results)
	imgui_is_initialized :: #force_inline proc(app: ^Application) -> bool {
		return app.im_ctx != nil
	}

	@(require_results)
	imgui_new_frame :: proc(app: ^Application) -> (ok: bool) {
		im.wgpu_new_frame() or_return
		im.glfw_new_frame()
		im.new_frame()
		return true
	}

	imgui_end_frame :: proc(app: ^Application) {
		im.render()
	}

	@(require_results)
	imgui_draw :: proc(app: ^Application, render_pass: wgpu.Render_Pass) -> bool {
		return im.wgpu_render_draw_data(im.get_draw_data(), render_pass)
	}
} else {
	_ :: im
	imgui_init :: proc(app: ^Application) -> (ok: bool) {return true}
	imgui_destroy :: proc(app: ^Application) {}
	imgui_is_initialized :: #force_inline proc(app: ^Application) -> bool {return false}
	imgui_new_frame :: proc(app: ^Application) -> (ok: bool) {return true}
	imgui_end_frame :: proc(app: ^Application) {}
	imgui_draw :: proc(app: ^Application, render_pass: wgpu.Render_Pass) -> bool {return true}
}
