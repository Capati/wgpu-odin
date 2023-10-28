package application

// Package
import app_core "core"
import "events"

Platform_Info :: app_core.Platform_Info
Physical_Size :: app_core.Physical_Size
Application_Error :: app_core.Application_Error

when app_core.APPLICATION_TYPE == .Wasm {
    app :: wasm_application
} else {
    app :: native_application
}

@(private = "file")
_initialized := false

init :: proc(properties: Properties = Default_Properties) -> Application_Error {
    if err := app.init(properties); err != .No_Error {
        return err
    }
    _initialized = true
    return .No_Error
}

is_initialized :: proc() -> bool {
    return _initialized
}

process_events :: proc() -> events.Event_List {
    return app.process_events()
}

push_event :: proc(event: events.Event) {
    app.push_event(event)
}

get_size :: proc() -> Physical_Size {
    return app.get_size()
}

get_system_info :: proc() -> Platform_Info {
    return app.get_system_info()
}

when app_core.APPLICATION_TYPE == .Wasm {
    get_wgpu_surface :: wasm_application.get_wgpu_surface
}

when app_core.APPLICATION_TYPE == .Native {
    get_wgpu_surface :: native_application.get_wgpu_surface
}

deinit :: proc() {
    app.deinit()
}
