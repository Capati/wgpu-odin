package wgpu

// Core
/* import "core:fmt" */
import "core:runtime"
import "core:strings"

Error_Data :: struct {
    type: Error_Type,
    message: string,
    user_cb: Error_Callback,
    user_data: rawptr,
}

uncaptured_error_callback := proc "c" (
    type: Error_Type,
    message: cstring,
    user_data: rawptr,
) {
    if type == .No_Error {
        return
    }
    context = runtime.default_context()
    error := cast(^Error_Data)user_data
    /* fmt.eprintf("ERROR - %s [%v]:\n\t%s\n", error.info, type, message) */
    if error.user_cb != nil do error.user_cb(type, message, error.user_data)
    error.type = type
    delete(error.message)
    error.message = strings.clone_from_cstring(message)
}
