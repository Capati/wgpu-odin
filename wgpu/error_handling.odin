package wgpu

// Packages
import "base:runtime"
import "core:mem"
import "core:time"

/* Enable the global error handling. */
ENABLE_ERROR_HANDLING :: #config(WGPU_ENABLE_ERROR_HANDLING, true)
/* Logging when an error is captured. */
LOG_ON_ERROR :: #config(WGPU_LOG_ON_ERROR, true)
/* Panic as soon an error is encountered (will log too if enabled). */
PANIC_ON_ERROR :: #config(WGPU_PANIC_ON_ERROR, false)
/* A "safe" value for the maximum message length in bytes for error messages. */
ERROR_MESSAGE_BUFFER_LEN :: #config(WGPU_ERROR_MESSAGE_BUFFER_LEN, 1024)

LOG_ENABLED :: ENABLE_ERROR_HANDLING && LOG_ON_ERROR

IOError :: enum {
	None,
	ReadFileFailed,
	LoadImageFailed,
}

/* General WGPU error types "merged" with custom types. */
Error :: union #shared_nil {
	ErrorType,
	RequestAdapterStatus,
	RequestDeviceStatus,
	MapAsyncStatus,
	CompilationInfoRequestStatus,
	CreatePipelineAsyncStatus,
	QueueWorkDoneStatus,
	SurfaceStatus,
	mem.Allocator_Error,
	IOError,
}

ErrorDataInfo :: struct {
	error:     Error, /*  */
	message:   [ERROR_MESSAGE_BUFFER_LEN]byte, /* Last message from the error callback */
	loc:       runtime.Source_Code_Location, /* Where the api was called */
	timestamp: time.Time, /* The time when the api was called */
	thread_id: int, /* The thread that called the api */
}

ErrorData :: struct {
	using info: ErrorDataInfo,
	user_cb:    UncapturedErrorCallback,
	userdata1:  rawptr,
	userdata2:  rawptr,
}

@(thread_local, private = "file")
g_error: ErrorData

@(disabled = !ENABLE_ERROR_HANDLING)
error_reset_data :: proc "contextless" (loc: runtime.Source_Code_Location) {
	g_error.error = nil
	g_error.loc = loc
}

_error_update_data :: proc "contextless" (error: Error, message: string) #no_bounds_check {
	mem.zero_slice(g_error.message[:]) // previous error message was valid until here

	src_message := transmute([]u8)message
	src_len := len(message)

	if src_len >= ERROR_MESSAGE_BUFFER_LEN {
		src_len = max(0, ERROR_MESSAGE_BUFFER_LEN - 4)
		copy(g_error.message[:src_len], src_message[:src_len])
		copy(g_error.message[src_len:], "...")
	} else {
		copy(g_error.message[:], src_message)
	}

	g_error.error = error
	g_error.timestamp = time.now()

	when LOG_ENABLED {
		print_last_error()
	}

	when PANIC_ON_ERROR {
		panic("nWGPU error occurred!", g_error.loc)
	}
}

@(disabled = !ENABLE_ERROR_HANDLING)
error_update_data :: proc "contextless" (error: Error, message: string) {
	_error_update_data(error, message)
}

@(disabled = !ENABLE_ERROR_HANDLING)
error_reset_and_update :: proc "contextless" (
	error: Error,
	message: string,
	loc: runtime.Source_Code_Location,
) {
	error_reset_data(loc)
	_error_update_data(error, message)
}

/* Callback procedure for handling uncaptured errors from the api. */
uncaptured_error_data_callback :: proc "c" (
	device: ^Device,
	type: ErrorType,
	message: StringView,
	userdata1: rawptr,
	userdata2: rawptr,
) {
	if type == .NoError {
		return
	}

	error := type // Uncaptured error type is the current general error

	if g_error.user_cb != nil {
		g_error.user_cb(device, type, message, g_error.userdata1, g_error.userdata2)
	}

	_error_update_data(error, string_view_get_string(message))
}

set_uncaptured_error_callback :: proc "contextless" (
	device: Device,
	user_callback: UncapturedErrorCallback,
	userdata1: rawptr,
	userdata2: rawptr,
) {
	g_error.user_cb = user_callback
	g_error.userdata1 = userdata1
	g_error.userdata2 = userdata2
}

/*---------------------------------------------------------------------------
Public procedures
-----------------------------------------------------------------------------*/

// odinfmt: disable
when ENABLE_ERROR_HANDLING {
/*
Get last error message.

**Notes**
1. Ownership not transferred.
2. String valid until next API call.
*/
get_last_error_message :: #force_inline proc "contextless" () -> string #no_bounds_check {
	return string(g_error.message[:])
}

/*
Get the last error value.

**Returns**
- The error occurred in the last procedure/API call. Returns nil if error handling is disabled or
no error has occurred.

**Notes**
1. Error is set to nil in the next procedure/API all.
*/
get_last_error :: #force_inline proc "contextless" () -> Error {
	return g_error.error
}

has_no_error :: #force_inline proc "contextless" () -> bool {
	return g_error.error == nil
}

has_error :: #force_inline proc "contextless" () -> bool {
	return g_error.error != nil
}

/*
Get more information about the last error.

**Returns**

	ErrorDataInfo :: struct {
		id        : int,
		type      : Error_Data_Type,
		error     : Error,
		message   : string,
		loc       : runtime.Source_Code_Location,
		timestamp : time.Time,
		thread_id : int,
	}

- The last error data as an `ErrorDataInfo`. Returns an empty struct if error handling is
disabled or no error has occurred.

**Notes**
1. Error data is set to `{}` in the next procedure/API all.
*/
get_last_error_data :: #force_inline proc "contextless" (
) -> ErrorDataInfo #no_bounds_check {
	current_err := g_error
	return {
		error = current_err.error,
		message = current_err.message,
		loc = current_err.loc,
		timestamp = current_err.timestamp,
		thread_id = current_err.thread_id,
	}
}

/*
Print the last error message.

**Notes**
1. Disabled if error handling or logging is disabled.
2. For more information, check `get_last_error_data`.
*/
print_last_error :: proc "contextless" () #no_bounds_check {
	data := &g_error
	runtime.print_string("WGPU error: ")
	runtime.print_string(get_last_error_message())
	runtime.print_byte('\n')
	runtime.print_caller_location(data.loc)
	runtime.print_byte('\n')
}
} else {
	get_last_error_message :: #force_inline proc "contextless" () -> string {return ""}
	get_last_error :: #force_inline proc "contextless" () -> Error {return nil}
	has_no_error :: #force_inline proc "contextless" () -> bool {return true}
	has_error :: #force_inline proc "contextless" () -> bool {return false}
	get_last_error_data :: #force_inline proc "contextless" () -> ErrorDataInfo {return {}}
	@(disabled = true)
	print_last_error :: proc "contextless" () {}
}
// odinfmt: enable
