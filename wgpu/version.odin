package wgpu

// Packages
import "base:runtime"
import "core:fmt"
import "core:strings"

Version :: struct {
	major: u8,
	minor: u8,
	patch: u8,
	build: u8,
}

BINDINGS_VERSION :: Version{24, 0, 0, 1}
BINDINGS_VERSION_STRING :: "24.0.0.1"

@(private = "file", init)
_version_check :: proc() {
	version := get_version()

	if version != {} && version != BINDINGS_VERSION {
		fmt.panicf(
			"Version mismatch: WGPU bindings expect version %s, but linked library is version %d.%d.%d.%d",
			BINDINGS_VERSION_STRING,
			version.major,
			version.minor,
			version.patch,
			version.build,
		)
	}
}

// Return a struct with `major`, `minor`, `patch` and `build` version of wgpu.
get_version :: proc() -> (version: Version) {
	raw_version := get_raw_version()

	version.major = u8((raw_version >> 24) & 0xFF)
	version.minor = u8((raw_version >> 16) & 0xFF)
	version.patch = u8((raw_version >> 8) & 0xFF)
	version.build = u8(raw_version & 0xFF)

	return
}

get_version_string_from_bindings :: proc() -> string {
	return BINDINGS_VERSION_STRING
}

get_version_string_from_version :: proc(
	version: Version,
	allocator := context.allocator,
) -> string {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == context.temp_allocator)
	sb := strings.builder_make(context.temp_allocator)
	defer strings.builder_destroy(&sb)

	strings.write_int(&sb, int(version.major))
	strings.write_byte(&sb, '.')
	strings.write_int(&sb, int(version.minor))
	strings.write_byte(&sb, '.')
	strings.write_int(&sb, int(version.patch))
	strings.write_byte(&sb, '.')
	strings.write_int(&sb, int(version.build))

	return strings.clone(strings.to_string(sb), allocator)
}

get_version_string :: proc {
	get_version_string_from_bindings,
	get_version_string_from_version,
}

get_raw_version :: proc() -> u32 {
	return wgpuGetVersion()
}
