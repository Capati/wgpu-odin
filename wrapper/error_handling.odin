package wgpu

// Core
import intr "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:strings"
import "core:sync"
import "core:time"

// Configuration values for enabling error handling and logging
WGPU_ENABLE_ERROR_HANDLING :: #config(WGPU_ENABLE_ERROR_HANDLING, true)
WGPU_LOG_ON_ERROR :: #config(WGPU_LOG_ON_ERROR, false)
WGPU_MUTEX_ON_ERROR :: #config(WGPU_MUTEX_ON_ERROR, false)

@(private = "file")
LOG_ENABLED :: WGPU_ENABLE_ERROR_HANDLING && (ODIN_DEBUG || WGPU_LOG_ON_ERROR)

@(private = "file")
MUTEX_ENABLED :: WGPU_ENABLE_ERROR_HANDLING && (ODIN_DEBUG || WGPU_MUTEX_ON_ERROR)

@(private = "file")
// Start with 2 instances, for 1 fallback and 1 device
WGPU_ERROR_STORAGE_CAPACITY: int : #config(WGPU_ERROR_STORAGE_CAPACITY, 2)

Error_Data_Type :: enum {
	Undefined,
	General,
	Assert,
	Create_Instance,
	Create_Surface,
	Request_Adapter,
	Request_Device,
	Surface_Texture,
	Shader,
	File_System,
	Buffer_Map_Async,
	Compilation_Info_Request,
	Create_Pipeline_Async,
	Queue_Work_Done,
	Surface_Get_Current_Texture,
}

System_Error :: enum {
	None,
	Read_Entire_File,
}

// General error type merged with other types
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
	System_Error,
}

Error_Data_Info :: struct {
	id:        int,
	type:      Error_Data_Type,
	error:     Error,
	message:   string,
	file_path: string,
	line:      i32,
	procedure: string,
	timestamp: time.Time,
	thread_id: int,
}

@(private)
Error_Data :: struct {
	using _info: Error_Data_Info,
	user_cb:     Error_Callback,
	user_data:   rawptr,
	is_fallback: bool,
}

@(private = "file")
Error_Data_Storage :: struct {
	id:        int, // current error data instance in use
	allocator: mem.Allocator,
	mutex:     sync.Mutex,
	data:      [dynamic]Error_Data,
}

@(thread_local, private = "file")
_storage: Error_Data_Storage

@(private)
// Fallback errors that are not from wgpu uncaptured_error_callback
FALLBACK_ERROR_DATA :: 0

@(init, private = "file")
_init_error_data :: proc() {
	when !WGPU_ENABLE_ERROR_HANDLING do return

	// Keep the initial allocator
	// TODO(Capati): Refactor to set as a parameter?
	_storage.allocator = context.allocator
	_storage.data.allocator = _storage.allocator

	reserve(&_storage.data, WGPU_ERROR_STORAGE_CAPACITY)

	assign_at(
		&_storage.data,
		FALLBACK_ERROR_DATA,
		Error_Data{type = .Undefined, error = nil, message = "", is_fallback = true},
	)
}

@(fini, private = "file")
_deinit_error_data :: proc() {
	when !WGPU_ENABLE_ERROR_HANDLING do return

	for &value in _storage.data {
		delete(value.message, _storage.allocator)
	}

	delete(_storage.data)
}

@(private)
add_error_data :: proc() -> (err_data: ^Error_Data, err: Error) {
	when MUTEX_ENABLED {
		sync.guard(&_storage.mutex)
	}

	id := len(_storage.data)
	append(&_storage.data, Error_Data{id = id}) or_return

	err_data = &_storage.data[id]

	return
}

@(private)
set_user_data_uncaptured_error_callback :: proc "contextless" (
	err_data: ^Error_Data,
	callback: Error_Callback,
	user_data: rawptr,
) {
	when MUTEX_ENABLED {
		sync.guard(&_storage.mutex)
	}

	current_err := &_storage.data[err_data.id]

	current_err.user_cb = callback
	current_err.user_data = user_data
}

@(private = "file", disabled = !WGPU_ENABLE_ERROR_HANDLING)
_set_and_reset_err_data :: proc "contextless" (
	err_data: ^Error_Data,
	loc: runtime.Source_Code_Location,
) #no_bounds_check {
	when MUTEX_ENABLED {
		sync.guard(&_storage.mutex)
	}

	if err_data != nil {
		_storage.id = err_data.id
	} else {
		_storage.id = FALLBACK_ERROR_DATA // use the fallback error
	}

	current_err := &_storage.data[_storage.id]

	current_err.type = .Undefined
	current_err.error = nil
	current_err.message = "" // Don't delete, just set to empty
	current_err.file_path = loc.file_path
	current_err.line = loc.line
	current_err.procedure = loc.procedure
	current_err.thread_id = sync.current_thread_id()
}

@(private = "file")
_update_err_data :: proc(
	err_data: ^Error_Data,
	type: Error_Data_Type,
	error: Error,
	message: string,
) {
	when MUTEX_ENABLED {
		sync.guard(&_storage.mutex)
	}

	// TODO(Capati): Test to replicate how this problem occur
	if err_data != nil && _storage.id != err_data.id {
		fmt.printf(
			"Error data mismatch [%d:%d], this might be a bug or concurrency problem. Threads: [%d:%d]\n",
			_storage.id,
			err_data.id,
			_storage.data[_storage.id].thread_id,
			err_data.thread_id,
		)
		_storage.id = err_data.id
	}

	current_err := &_storage.data[_storage.id]

	delete(current_err.message, _storage.allocator)
	current_err.message = strings.clone(message, _storage.allocator)

	current_err.type = type
	current_err.error = error
	current_err.timestamp = time.now()

	when LOG_ENABLED {
		print_last_error()
	}
}

@(private, disabled = !WGPU_ENABLE_ERROR_HANDLING)
set_and_reset_err_data :: proc "contextless" (
	err_data: ^Error_Data,
	loc: runtime.Source_Code_Location,
) {
	_set_and_reset_err_data(err_data, loc)
}

@(private, disabled = !WGPU_ENABLE_ERROR_HANDLING)
update_error_data :: proc(
	err_data: ^Error_Data,
	type: Error_Data_Type,
	error: Error,
	message: string,
) {
	_update_err_data(err_data, type, error, message)
}

@(private, disabled = !WGPU_ENABLE_ERROR_HANDLING)
set_and_update_err_data :: proc(
	err_data: ^Error_Data,
	type: Error_Data_Type,
	error: Error,
	message: string,
	loc: runtime.Source_Code_Location,
) {
	_set_and_reset_err_data(err_data, loc)
	_update_err_data(err_data, type, error, message)
}

// Callback procedure for handling uncaptured errors from C code.
uncaptured_error_data_callback :: proc "c" (
	type: Error_Type,
	message: cstring,
	user_data: rawptr,
) {
	if type == .No_Error do return

	error := type // Uncaptured error type is the current general error

	context = runtime.default_context()

	err_data := cast(^Error_Data)user_data

	if err_data.user_cb != nil {
		err_data.user_cb(error, message, err_data.user_data)
	}

	update_error_data(err_data, .General, error, string(message))
}

/*============================================================================
** Public procedures
**============================================================================*/

when WGPU_ENABLE_ERROR_HANDLING {
	// Get last error message. Ownership not transferred. String valid until next error
	get_last_error_message :: #force_inline proc "contextless" () -> string #no_bounds_check {
		return _storage.data[_storage.id].message
	}
} else {
	get_last_error_message :: #force_inline proc "contextless" () -> string {
		return ""
	}
}

when WGPU_ENABLE_ERROR_HANDLING {
	// Get the last error value.
	// Returns nil if error handling is disabled or no error has occurred.
	//
	// Error is set to nil in the next API all.
	get_last_error :: #force_inline proc "contextless" () -> Error #no_bounds_check {
		return _storage.data[_storage.id].error
	}
} else {
	get_last_error :: #force_inline proc "contextless" () -> Error {
		return nil
	}
}

when WGPU_ENABLE_ERROR_HANDLING {
	// Get the last error data as an `Error_Data_Info`.
	// Returns an empty struct if error handling is disabled or no error has occurred.
	//
	// Error message is set to empty in the next API all.
	get_last_error_data :: #force_inline proc "contextless" (
	) -> Error_Data_Info #no_bounds_check {
		current_err := _storage.data[_storage.id]

		return {
			type = current_err.type,
			error = current_err.error,
			message = current_err.message,
			file_path = current_err.file_path,
			line = current_err.line,
			procedure = current_err.procedure,
			timestamp = current_err.timestamp,
			thread_id = current_err.thread_id,
		}
	}
} else {
	get_last_error_data :: #force_inline proc "contextless" () -> Error_Data_Info {
		return {}
	}
}

when WGPU_ENABLE_ERROR_HANDLING {
	// Print the last error message.
	// Disabled if error handling or logging is disabled.
	print_last_error :: proc() #no_bounds_check {
		current_err := &_storage.data[_storage.id]

		fmt.printfln(
			"WGPU error: %s\nError Type: %v | %v\nFile Path: %s:%d\nProcedure: %s\nTimestamp: %v\nThread ID: %d\n",
			current_err.message,
			current_err.type,
			current_err.error,
			current_err.file_path,
			current_err.line,
			current_err.procedure,
			current_err.timestamp,
			current_err.thread_id,
		)
	}
} else {
	print_last_error :: proc "contextless" () #no_bounds_check {
	}
}
