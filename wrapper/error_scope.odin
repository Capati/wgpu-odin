package wgpu

// Core
import "core:fmt"
import "core:runtime"

Error_Scope :: struct {
    type: Error_Type,
    info: cstring,
}

error_scope_callback := proc "c" (
    type: Error_Type,
    message: cstring,
    user_data: rawptr,
) {
    if type == .No_Error {
        return
    }
    context = runtime.default_context()
    error := cast(^Error_Scope)user_data
    fmt.eprintf("ERROR - %s [%v]:\n\t%s\n", error.info, type, message)
    error.type = type
}
