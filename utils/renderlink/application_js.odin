//+private
//+build js
package application

// STD Library
import "core:mem"
import "core:sync"

Engine_Context_Js :: struct {
	using _app: Application_Context,
	mutex:      sync.Mutex,
}

_engine_context: Engine_Context_Js
g_app := &_engine_context

_init_platform :: proc(settings: ^Settings, allocator: runtime.Allocator) -> (err: Error) {
	unimplemented()
}

_platform_destroy :: proc() {
	unimplemented()
}
