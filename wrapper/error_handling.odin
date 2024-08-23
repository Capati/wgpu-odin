package wgpu

// STD Library
import intr "base:intrinsics"
import "base:builtin"
import "base:runtime"
import "core:mem"
import "core:sync"
import "core:time"

/* Enable the global error handling. */
ENABLE_ERROR_HANDLING :: #config(WGPU_ENABLE_ERROR_HANDLING, true)
/* Logging when an error is captured. */
LOG_ON_ERROR :: #config(WGPU_LOG_ON_ERROR, true)
/* Panic as soon an error is encountered (will log too if enabled). */
PANIC_ON_ERROR :: #config(WGPU_PANIC_ON_ERROR, false)
/* An attempt to ensure thread safe for errors. */
ENABLE_MUTEX_ERROR_HANDLING :: #config(WGPU_ENABLE_MUTEX_ERROR_HANDLING, false)
/* A "safe" value for the maximum message length in bytes for error messages. */
ERROR_MESSAGE_BUFFER_LEN ::  #config(WGPU_ERROR_MESSAGE_BUFFER_LEN, 1024)

LOG_ENABLED :: ENABLE_ERROR_HANDLING && LOG_ON_ERROR
MUTEX_ENABLED :: ENABLE_ERROR_HANDLING && ENABLE_MUTEX_ERROR_HANDLING

IO_Error :: enum {
	None,
	Read_File_Failed,
	Load_Image_Failed,
}

/* General WGPU error types "merged" with custom types. */
Error :: union #shared_nil {
	Error_Type,
	Request_Adapter_Status,
	Request_Device_Status,
	Buffer_Map_Async_Status,
	Compilation_Info_Request_Status,
	Create_Pipeline_Async_Status,
	Queue_Work_Done_Status,
	Surface_Get_Current_Texture_Status,
	mem.Allocator_Error,
	IO_Error,
}

Error_Data_Info :: struct {
	error     : Error,                          /*  */
	message   : [ERROR_MESSAGE_BUFFER_LEN]byte, /* Last message from the error callback */
	loc       : runtime.Source_Code_Location,   /* Where the api was called */
	timestamp : time.Time,                      /* The time when the api was called */
	thread_id : int,                            /* The thread that called the api */
}

@(private)
Error_Data :: struct {
	using _info : Error_Data_Info,
	user_cb     : Error_Callback,
	user_data   : rawptr,
}

@(private)
Error_Data_Storage :: struct {
	mutex : sync.Mutex,
	data  : Error_Data,
}

@(thread_local, private = "file")
g_error : Error_Data_Storage

@(private, disabled = !ENABLE_ERROR_HANDLING)
_error_reset_data :: proc "contextless" (loc: runtime.Source_Code_Location) {
	when MUTEX_ENABLED do sync.guard(&g_error.mutex)

	data := &g_error.data
	data.error     = nil
	data.loc       = loc
	data.thread_id = sync.current_thread_id()
}

@(private)
_error_update_data :: proc "contextless" (
	error: Error,
	message: string,
) #no_bounds_check {
	when MUTEX_ENABLED do sync.guard(&g_error.mutex)

	data := &g_error.data

	mem.zero_slice(data.message[:]) // previous error message was valid until here

	src_message := transmute([]u8)message
	src_len := len(message)

	if src_len >= ERROR_MESSAGE_BUFFER_LEN {
		src_len = max(0, ERROR_MESSAGE_BUFFER_LEN - 4)
		builtin.copy(data.message[:src_len], src_message[:src_len])
		builtin.copy(data.message[src_len:], "...")
	} else {
		builtin.copy(data.message[:], src_message)
	}

	data.error = error
	data.timestamp = time.now()

	when LOG_ENABLED {
		print_last_error()
	}

	when PANIC_ON_ERROR {
		panic("nWGPU error occurred!", data.loc)
	}
}

@(disabled = !ENABLE_ERROR_HANDLING)
error_update_data :: proc "contextless" (
	error: Error,
	message: string,
) {
	_error_update_data(error, message)
}

@(disabled = !ENABLE_ERROR_HANDLING)
error_reset_and_update :: proc "contextless" (
	error: Error,
	message: string,
	loc: runtime.Source_Code_Location,
) {
	_error_reset_data(loc)
	_error_update_data(error, message)
}

/* Callback procedure for handling uncaptured errors from the api. */
uncaptured_error_data_callback :: proc "c" (
	type: Error_Type,
	message: cstring,
	user_data: rawptr,
) {
	if type == .No_Error do return

	error := type // Uncaptured error type is the current general error

	if g_error.data.user_cb != nil {
		g_error.data.user_cb(error, message, g_error.data.user_data)
	}

	error_update_data(error, string(message))
}

@(private)
set_uncaptured_error_callback :: proc "contextless" (
	callback: Error_Callback,
	user_data: rawptr,
) {
	sync.guard(&g_error.mutex)

	data := &g_error.data
	data.user_cb = callback
	data.user_data = user_data
}

/*============================================================================
** Public procedures
**============================================================================*/

when ENABLE_ERROR_HANDLING {
/*
Get last error message.

**Notes**
1. Ownership not transferred.
2. String valid until next error.
*/
get_last_error_message :: #force_inline proc "contextless" () -> string #no_bounds_check {
	return string(g_error.data.message[:])
}

/*
Get the last error value.

**Returns**
- The error ocurred in the last procedure/API call. Returns nil if error handling is disabled or
no error has occurred.

**Notes**
1. Error is set to nil in the next procedure/API all.
*/
get_last_error :: #force_inline proc "contextless" () -> Error #no_bounds_check {
	return g_error.data.error
}

/*
Get more information about the last error.

**Returns**

	Error_Data_Info :: struct {
		id        : int,
		type      : Error_Data_Type,
		error     : Error,
		message   : string,
		loc       : runtime.Source_Code_Location,
		timestamp : time.Time,
		thread_id : int,
	}

- The last error data as an `Error_Data_Info`. Returns an empty struct if error handling is
disabled or no error has occurred.

**Notes**
1. Error data is set to `{}` in the next procedure/API all.
*/
get_last_error_data :: #force_inline proc "contextless" () -> Error_Data_Info #no_bounds_check {
	current_err := g_error.data
	return {
		error     = current_err.error,
		message   = current_err.message,
		loc       = current_err.loc,
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
	data := &g_error.data
	runtime.print_string("WGPU error: ")
	runtime.print_string(get_last_error_message())
	runtime.print_byte('\n')
	runtime.print_caller_location(data.loc)
	runtime.print_byte('\n')
}
} else {
get_last_error_message :: #force_inline proc "contextless" () -> string { return "" }
get_last_error :: #force_inline proc "contextless" () -> Error { return nil }
get_last_error_data :: #force_inline proc "contextless" () -> Error_Data_Info { return {} }
print_last_error :: proc "contextless" () {}
}
