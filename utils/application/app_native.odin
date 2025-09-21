#+build !js
package application

// Core
import "base:runtime"

// Vendor
import "vendor:glfw"

@(private, init)
_init :: proc "contextless" () {
	when ODIN_DEBUG {
		_glfw_error_proc :: proc "c" (error: i32, description: cstring) {
			runtime.print_string("[GLFW] --- [")
			runtime.print_int(int(error))
			runtime.print_string("]: ")
			runtime.print_string(string(description))
			runtime.print_string("\n")
		}
		glfw.SetErrorCallback(_glfw_error_proc)
	}
	ensure_contextless(bool(glfw.Init()), "Failed to initialize GLFW")
}

@(private, fini)
_fini :: proc "contextless" () {
	glfw.Terminate()
}
