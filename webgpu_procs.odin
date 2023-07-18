package wgpu_bindings

// import "core:c"

Buffer_Map_Callback :: #type proc "c" (
    status: Buffer_Map_Async_Status,
    user_data: rawptr,
)

Compilation_Info_Callback :: #type proc "c" (
    status: Compilation_Info_Request_Status,
    compilation_info: ^Compilation_Info,
    user_data: rawptr,
)

Create_Compute_Pipeline_Async_Callback :: #type proc "c" (
    status: Create_Pipeline_Async_Status,
    pipeline: Compute_Pipeline,
    message: cstring,
    user_data: rawptr,
)

Create_Render_Pipeline_Async_Callback :: #type proc "c" (
    status: Create_Pipeline_Async_Status,
    pipeline: Render_Pipeline,
    message: cstring,
    user_data: rawptr,
)

Device_Lost_Callback :: #type proc "c" (
    reason: Device_Lost_Reason,
    message: cstring,
    user_data: rawptr,
)

Error_Callback :: #type proc "c" (type: Error_Type, message: cstring, user_data: rawptr)

Proc :: #type proc(self: rawptr)

Queue_Work_Done_Callback :: #type proc "c" (
    status: Queue_Work_Done_Status,
    user_data: rawptr,
)

Request_Adapter_Callback :: #type proc "c" (
    status: Request_Adapter_Status,
    adapter: Adapter,
    message: cstring,
    user_data: rawptr,
)

Request_Device_Callback :: #type proc "c" (
    status: Request_Device_Status,
    device: Device,
    message: cstring,
    user_data: rawptr,
)
