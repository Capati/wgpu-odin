#+build windows
package wgpu

// STD Library
import "core:mem"
import "core:path/filepath"
import "core:strings"
import win "core:sys/windows"

@(private)
_set_dx12_compiler :: proc(
	extras: ^Instance_Extras,
	compiler: Dx12_Compiler,
	allocator: mem.Allocator,
) -> bool {
	if compiler == .Dxc {
		buffer: [win.MAX_PATH]u16
		size := win.GetModuleFileNameW(nil, &buffer[0], win.MAX_PATH)
		if size == 0 do return false

		filename, _ := win.wstring_to_utf8(raw_data(buffer[:size]), int(size), allocator)
		if filename == "" do return false

		exe_path := filepath.dir(filename, allocator)
		if exe_path == "" do return false

		relative_path := filepath.abs(exe_path, allocator) or_return

		c_relative_path := strings.clone_to_cstring(relative_path, allocator)
		if c_relative_path == nil do return false

		extras.dx12_shader_compiler = .Dxc
		extras.dxc_path = c_relative_path
		extras.dxil_path = c_relative_path
	} else {
		extras.dx12_shader_compiler = .Fxc
	}

	return true
}
