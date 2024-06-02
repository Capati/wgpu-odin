package wgpu

// Package
import wgpu "../bindings"

Version :: struct {
	major: u8,
	minor: u8,
	patch: u8,
	build: u8,
}

// Return a struct with `major`, `minor`, `patch` and `build` version of wgpu.
get_version :: proc() -> Version {
	version := wgpu.get_version()

	return ({
				major = cast(u8)((version >> 24) & 0xFF),
				minor = cast(u8)((version >> 16) & 0xFF),
				patch = cast(u8)((version >> 8) & 0xFF),
				build = cast(u8)(version & 0xFF),
			})
}

get_raw_version :: proc() -> u32 {
	return wgpu.get_version()
}
