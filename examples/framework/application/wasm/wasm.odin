package wasm_application

// Package
import "../core"
import "../events"

// Libs
import wgpu "../../../../wrapper"

Default_Physical_Size :: core.Default_Physical_Size
Physical_Size :: core.Physical_Size
Platform_Info :: core.Platform_Info

Wasm_Application :: struct {
	using properties: Wasm_Properties,
}

Wasm_Properties :: struct {
	selector: cstring,
	title:    cstring,
}

Default_Wasm_Properties :: Wasm_Properties {
	selector = "#canvas",
	title    = "Wasm Game",
}

@(private = "package")
_ctx: Wasm_Application

init :: proc(
	properties: Wasm_Properties = Default_Wasm_Properties,
) -> (
	err: core.Application_Error,
) {
	unimplemented("Wasm init")
}

process_events :: proc() -> events.Event_List {
	unimplemented("Wasm process_events")
}

push_event :: proc(event: events.Event) {
	unimplemented("Wasm push_event")
}

get_size :: proc() -> (size: Physical_Size) {
	unimplemented("Wasm get_size")
}

get_system_info :: proc() -> (info: Platform_Info) {
	unimplemented("Wasm get_system_info")
}

get_wgpu_surface :: proc(instance: ^wgpu.Instance) -> (wgpu.Surface, wgpu.Error_Type) {
	surface_descriptor := wgpu.Surface_Descriptor {
		label = "HTML Canvas",
		target = wgpu.Surface_Descriptor_From_Canvas_Html_Selector{selector = _ctx.selector},
	}
	return wgpu.instance_create_surface(instance, &surface_descriptor)
}

deinit :: proc() {
	unimplemented("Wasm deinit")
}
