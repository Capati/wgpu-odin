package application

STR_UNDEFINED_CONFIG :: "Undefined"
STR_WASM_PLATFORM :: "Wasm"
STR_NATIVE_PLATFORM :: "Native"

@(private = "file")
_PLATFORM_TYPE :: #config(_PLATFORM_TYPE, STR_UNDEFINED_CONFIG)

Platform_Type :: enum {
	Undefined,
	Native,
	Wasm,
}

when _PLATFORM_TYPE == STR_UNDEFINED_CONFIG {
	when ODIN_OS == .JS || ODIN_OS == .WASI {
		PLATFORM_TYPE :: Platform_Type.Wasm
	} else {
		PLATFORM_TYPE :: Platform_Type.Native
	}
} else {
	when _PLATFORM_TYPE == STR_WASM_PLATFORM {
		PLATFORM_TYPE :: Platform_Type.Wasm
	} else when _PLATFORM_TYPE == STR_NATIVE_PLATFORM {
		PLATFORM_TYPE :: Platform_Type.Native
	} else {
		#panic("PLATFORM_TYPE not available.")
	}
}

// Platform_Interface :: struct {
// 	init: proc(props: Platform_Properties) -> (err: Error),
// }
