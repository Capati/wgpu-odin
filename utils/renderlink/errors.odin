package application

// Core
import "core:mem"

// Vendor Package
import wgpu "./../../wrapper"

Platform_Error :: enum {
	None,
	System_Error,
}

Error :: union #shared_nil {
	Event_Error,
	Window_Error,
	Mouse_Error,
	Joystick_Error,
	Renderer_Error,
	Platform_Error,
	mem.Allocator_Error,
	wgpu.Error,
	wgpu.Error_Type,
	wgpu.Surface_Get_Current_Texture_Status,
}
