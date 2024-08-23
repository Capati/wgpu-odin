//+private
//+build linux, darwin, windows
package application

// STD Library
import intr "base:intrinsics"
import "core:mem"
import "core:sync"
@(require) import "core:log"
@(require) import "core:time"

Application_Native :: struct {
	using _app : Application_Context,
	heap_block : []byte,
	arena      : mem.Arena,
	events     : Event_State,
	window     : Window_State,
	renderer   : Renderer,
	keyboard   : Keyboard_State,
	mouse      : Mouse_State,
	joystick   : Joystick_State,
	mutex      : sync.Mutex,
}

@(private)
g_app: Application_Native

@(require_results)
_init :: proc(
	state: ^$T,
	settings: Settings,
	loc := #caller_location,
) -> (
	ok: bool,
) where intr.type_is_specialization_of(T, Context) {
	app := &g_app

	assert(!app.initialized, "Application already initialized!", loc)

	app.heap_block = make([]byte, 4 * mem.Megabyte)
	assert(app.heap_block != nil, "Failed to allocate application memory block")
	defer if !ok do delete(app.heap_block)
	mem.arena_init(&app.arena, app.heap_block[:])

	state.app = &app._app // Set the application subtype for this state

	settings := settings

	ally := mem.arena_allocator(&app.arena)

	when EVENT_PACKAGE {
		_event_init(ally) or_return
		defer if !ok do _event_destroy()
	}

	when WINDOW_PACKAGE {
		_window_init(settings.window, ally) or_return
		defer if !ok do _window_destroy()
	}

	when GRAPHICS_PACKAGE {
		_graphics_init(settings.renderer, ally) or_return
		defer if !ok do _graphics_destroy()
		state.gpu = _graphics_get_gpu() // Set the graphics context for this state
	}

	when KEYBOARD_PACKAGE {
		_keyboard_init(ally) or_return
		defer if !ok do _keyboard_destroy()
	}

	when MOUSE_PACKAGE {
		_mouse_init(ally) or_return
		defer if !ok do _mouse_destroy()
	}

	when JOYSTICK_PACKAGE {
		_joystick_init(ally) or_return
		defer if !ok do _joystick_destroy()
	}

	app.settings = settings
	app.target_frame_time = time.Millisecond // 1000 FPS target (1ms per frame)

	// Initialize application specific
	if state.callbacks.init != nil {
		log.infof("Initializing '%s'", settings.title)
		if !state.callbacks.init(state) {
			log.fatal(
				"Failed to initialize application specific. " +
				"Make sure your 'init' procedure is returning 'true'.",
			)
			return
		}
	}

	app.initialized = true

	log.info("Application initialized successfully!")

	return true
}

_destroy :: proc() {
	when JOYSTICK_PACKAGE do _joystick_destroy()
	when MOUSE_PACKAGE do _mouse_destroy()
	when KEYBOARD_PACKAGE do _keyboard_destroy()
	when GRAPHICS_PACKAGE do _graphics_destroy()
	when WINDOW_PACKAGE do _window_destroy()
	when EVENT_PACKAGE do _event_destroy()
	delete(g_app.heap_block)
}
