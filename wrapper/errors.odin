package wgpu

// Core
import "core:runtime"
import "core:strings"

Error_Data :: struct {
	type:      Error_Type,
	user_cb:   Error_Callback,
	user_data: rawptr,
}

@(private = "file")
last_error_message: string

@(fini, private = "file")
cleanup :: proc() {
	delete(last_error_message)
}

@(private)
update_error_message :: proc(message: string) {
	delete(last_error_message)
	last_error_message = strings.clone(message)
}

// Get last error message. Ownership not transferred. String valid until next error
get_error_message :: proc() -> string {
	return last_error_message
}

uncaptured_error_callback := proc "c" (type: Error_Type, message: cstring, user_data: rawptr) {
	if type == .No_Error {
		return
	}

	context = runtime.default_context()

	error := cast(^Error_Data)user_data
	error.type = type

	if error.user_cb != nil do error.user_cb(type, message, error.user_data)

	update_error_message(string(message))
}
