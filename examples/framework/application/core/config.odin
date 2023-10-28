package application_core

STR_UNDEFINED_CONFIG :: "Undefined"
STR_WASM_PLATFORM :: "Wasm"
STR_NATIVE_PLATFORM :: "Native"
STR_WGPU_BACKEND :: "WebGL"
STR_WEBGL_BACKEND :: "WGPU"

@(private = "file")
_PLATFORM_TYPE :: #config(_PLATFORM_TYPE, STR_UNDEFINED_CONFIG)

@(private = "file")
_BACKEND_TYPE :: #config(_BACKEND_TYPE, STR_UNDEFINED_CONFIG)

Application_Type :: enum {
    Native,
    Wasm,
}

Backend_Type :: enum {
    WebGL,
    WGPU,
}

when _PLATFORM_TYPE == STR_UNDEFINED_CONFIG {
    when ODIN_OS == .JS || ODIN_OS == .WASI {
        APPLICATION_TYPE :: Application_Type.Wasm
    } else {
        APPLICATION_TYPE :: Application_Type.Native
    }
} else {
    when _PLATFORM_TYPE == STR_WASM_PLATFORM {
        APPLICATION_TYPE :: Application_Type.Wasm
    } else when _PLATFORM_TYPE == STR_NATIVE_PLATFORM {
        APPLICATION_TYPE :: Application_Type.Native
    } else {
        #panic("APPLICATION_TYPE not available.")
    }
}
