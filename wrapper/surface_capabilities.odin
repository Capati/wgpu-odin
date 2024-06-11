package wgpu

// Defines the capabilities of a given surface and adapter.
Surface_Capabilities :: struct {
	formats:       []Texture_Format,
	present_modes: []Present_Mode,
	alpha_modes:   []Composite_Alpha_Mode,
}

surface_capabilities_free_members :: proc(using self: ^Surface_Capabilities) {
	delete(formats)
	delete(present_modes)
	delete(alpha_modes)
}
