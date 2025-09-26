#+build !js
package webgpu

// Vendor
import "vendor:wgpu"

Version :: struct {
	major: u8,
	minor: u8,
	patch: u8,
	build: u8,
}

BINDINGS_VERSION :: Version {
	wgpu.BINDINGS_VERSION.x,
	wgpu.BINDINGS_VERSION.y,
	wgpu.BINDINGS_VERSION.z,
	wgpu.BINDINGS_VERSION.w,
}
BINDINGS_VERSION_STRING :: wgpu.BINDINGS_VERSION_STRING

// Return a struct with `major`, `minor`, `patch` and `build` version of wgpu.
GetVersion :: proc() -> (version: Version) {
	rawVersion := wgpu.GetVersion()

	version.major = u8((rawVersion >> 24) & 0xFF)
	version.minor = u8((rawVersion >> 16) & 0xFF)
	version.patch = u8((rawVersion >> 8) & 0xFF)
	version.build = u8(rawVersion & 0xFF)

	return
}

GetVersionNumber :: wgpu.GetVersion
