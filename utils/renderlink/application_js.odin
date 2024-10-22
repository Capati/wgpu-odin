#+private
#+build js
package renderlink

// STD Library
import "core:mem"
import "core:sync"

Application_JS :: struct {
	using _app: Application_Context,
	mutex:      sync.Mutex,
}

@(private)
g_app: Application_JS

@(require_results)
_init :: proc(
	state: ^$T,
	settings: Settings,
	loc := #caller_location,
) -> (
	ok: bool,
) where intr.type_is_specialization_of(T, Context) {
	unimplemented()
}

_destroy :: proc() {
	unimplemented()
}
