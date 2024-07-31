//+private
//+build linux, darwin, windows
package application

// STD Library
import intr "base:intrinsics"
import "core:log"
import "core:sync"
import "core:time"

_ :: log
_ :: time

Application_Native :: struct {
	using _app: Application_Context,
	renderer:   Renderer,
	mutex:      sync.Mutex,
}

_app_context: Application_Native
g_app := &_app_context

@(require_results)
_init :: proc(
	state: ^$T,
	settings: Settings,
	allocator := context.allocator,
) -> (
	err: Error,
) where intr.type_is_specialization_of(T, Context) {
	if g_app.initialized {
		log.warn("Application already initialized! Ignoring...")
		return
	}

	log.infof("Initializing '%s'", settings.title)

	state.app = g_app // Set the application for this state

	g_app.allocator = allocator

	settings := settings

	when EVENT_PACKAGE {
		_event_init(allocator = allocator) or_return
		defer if err != nil do _event_destroy()
	}

	when WINDOW_PACKAGE {
		_window_init(settings.window, allocator) or_return
		defer if err != nil do _window_destroy()
	}

	when GRAPHICS_PACKAGE {
		_graphics_init(settings.renderer, allocator) or_return
		defer if err != nil do _graphics_destroy()
		state.gpu = _graphics_get_gpu() // Set the graphics context for this state
	}

	when KEYBOARD_PACKAGE {
		_keyboard_init(allocator) or_return
		defer if err != nil do _keyboard_destroy()
	}

	when MOUSE_PACKAGE {
		_mouse_init(allocator) or_return
		defer if err != nil do _mouse_destroy()
	}

	when JOYSTICK_PACKAGE {
		_joystick_init(allocator) or_return
		defer if err != nil do _joystick_destroy()
	}

	g_app.settings = settings
	g_app.target_frame_time = time.Millisecond // 1000 FPS target (1ms per frame)

	// Initialize application specific
	if state.callbacks.init != nil {
		state.callbacks.init(state)
	}

	free_all(context.temp_allocator)

	g_app.initialized = true

	log.info("Application initialized successfully!")

	return
}

_destroy :: proc() {
	when JOYSTICK_PACKAGE do _joystick_destroy()
	when MOUSE_PACKAGE do _mouse_destroy()
	when KEYBOARD_PACKAGE do _keyboard_destroy()
	when GRAPHICS_PACKAGE do _graphics_destroy()
	when WINDOW_PACKAGE do _window_destroy()
	when EVENT_PACKAGE do _event_destroy()
}
