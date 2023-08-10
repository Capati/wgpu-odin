package wgpu

// Core
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"
import "core:runtime"

// Package
import wgpu "../bindings"

Shader_Module :: struct {
    ptr:          WGPU_Shader_Module,
    using vtable: ^GPU_Shader_Module_VTable,
}

@(private)
GPU_Shader_Module_VTable :: struct {
    // get_compilation_info: proc(
    //     using self: ^Shader_Module,
    //     callback: wgpu.Compilation_Info_Callback = _compilation_info_callback,
    //     user_data: rawptr = nil,
    // ),
    set_label: proc(self: ^Shader_Module, label: cstring),
    reference: proc(self: ^Shader_Module),
    release:   proc(self: ^Shader_Module),
}

@(private)
default_shader_module_vtable := GPU_Shader_Module_VTable {
    // get_compilation_info = shader_module_get_compilation_info,
    set_label = shader_module_set_label,
    reference = shader_module_reference,
    release   = shader_module_release,
}

@(private)
default_shader_module := Shader_Module {
    vtable = &default_shader_module_vtable,
}

Shader_Load_Error :: enum {
    No_Error,
    Read_File,
    Shader_Compilation_Error,
}

@(private)
Shader_Module_Response :: struct {
    status: Compilation_Info_Request_Status,
}

Shader_Load_Response :: struct {
    type:    Error_Type,
    message: cstring,
}

device_load_wgsl_shader_module :: proc(
    using self: ^Device,
    path: cstring,
    label: cstring = nil,
) -> (
    shader_module: Shader_Module,
    err: Error_Type,
) {
    runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
    data, data_ok := os.read_entire_file(string(path), context.temp_allocator)

    if !data_ok {
        fmt.eprintf("Failed to load WGSL shader file: [%s]\n", path)
        return {}, .Unknown
    }

    // Use the path as label if label is not given
    current_label: cstring = path if label == nil else label

    descriptor := Shader_Module_Descriptor {
        label           = current_label,
        wgsl_descriptor = &{code = strings.clone_to_cstring(string(data), context.temp_allocator)}, // clone to cstring to ensure null termination
    }

    shader_module = self->create_shader_module(&descriptor) or_return

    // res := Shader_Module_Response{}
    // shader_module->get_compilation_info(_compilation_info_callback, &res)

    return shader_module, .No_Error
}

device_load_spirv_shader_module :: proc(
    using self: ^Device,
    path: cstring,
    label: cstring = nil,
) -> (
    shader_module: Shader_Module,
    err: Error_Type,
) {
    runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
    data, data_ok := os.read_entire_file(string(path), context.temp_allocator)

    if !data_ok {
        fmt.eprintf("Failed to load SPIRV shader file: [%s]\n", path)
        return {}, .Unknown
    }

    // Use the path as label if label is not given
    current_label: cstring = path if label == nil else label

    descriptor := Shader_Module_Descriptor {
        label            = current_label,
        spirv_descriptor = &{code = slice.reinterpret([]u32, data)},
    }

    shader_module = self->create_shader_module(&descriptor) or_return

    // res := Shader_Module_Response{}
    // shader_module->get_compilation_info(_compilation_info_callback, &res)

    return shader_module, .No_Error
}

// @(private)
// _shader_module_get_compilation_info :: proc(
//     using self: ^Shader_Module,
//     callback: Compilation_Info_Callback,
//     user_data: rawptr = nil,
// ) {
//     wgpu.shader_module_get_compilation_info(ptr, callback, nil)
// }

@(private)
shader_module_set_label :: proc(using self: ^Shader_Module, label: cstring) {
    wgpu.shader_module_set_label(ptr, label)
}

@(private)
shader_module_reference :: proc(using self: ^Shader_Module) {
    wgpu.shader_module_reference(ptr)
}

@(private)
shader_module_release :: proc(using self: ^Shader_Module) {
    wgpu.shader_module_release(ptr)
}

// @(private)
// _compilation_info_callback :: proc "c" (
//     status: wgpu.Compilation_Info_Request_Status,
//     compilation_info: ^wgpu.Compilation_Info,
//     user_data: rawptr,
// ) {
//     response := cast(^Shader_Module_Response)user_data
//     response.status = status
// }

// @(private)
// _handle_create_shader_module_error :: proc "c" (
//     type: Error_Type,
//     message: cstring,
//     user_data: rawptr,
// ) {
//     if type == .No_Error {
//         return
//     }

//     response := cast(^Shader_Load_Response)user_data
//     response.type = type
//     response.message = message
// }
