package wgpu

// Packages
import "core:mem"

/* The capabilities of a given surface and adapter. */
SurfaceCapabilities :: struct {
	allocator:     mem.Allocator,
	usages:        TextureUsage,
	formats:       []TextureFormat,
	present_modes: []PresentMode,
	alpha_modes:   []CompositeAlphaMode,
}

surface_capabilities_free_members :: proc(self: SurfaceCapabilities) {
	context.allocator = self.allocator
	delete(self.formats)
	delete(self.present_modes)
	delete(self.alpha_modes)
}
