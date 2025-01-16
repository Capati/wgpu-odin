package imgui_gen

// Packages
import "core:encoding/json"
import "core:log"
import "core:mem"
import "core:mem/virtual"
import "core:os"

Generator :: struct {
	// Allocator
	allocator:      mem.Allocator,
	tmp_ally_buf:   []byte,
	tmp_arena:      mem.Arena,
	tmp_ally:       mem.Allocator,

	// Containers
	flags:          [dynamic]Enum_Definition,

	// Maps
	type_map:       map[string]string,
	identifier_map: map[string]bool,
}

FLAGS :: "i32"
TAB_SPACE :: "    "
FOREIGN_IMPORT :: `
when ODIN_OS == .Linux || ODIN_OS == .Darwin {
	@(require) foreign import stdcpp "system:c++"
}

when ODIN_OS == .Windows {
	when ODIN_ARCH == .amd64 {
		foreign import lib "imgui_windows_x64.lib"
	} else {
		foreign import lib "imgui_windows_arm64.lib"
	}
} else when ODIN_OS == .Linux {
	when ODIN_ARCH == .amd64 {
		foreign import lib "imgui_linux_x64.a"
	} else {
		foreign import lib "imgui_linux_arm64.a"
	}
} else when ODIN_OS == .Darwin {
	when ODIN_ARCH == .amd64 {
		foreign import lib "imgui_darwin_x64.a"
	} else {
		foreign import lib "imgui_darwin_arm64.a"
	}
}

`


main :: proc() {
	arena: virtual.Arena
	if arena_err := virtual.arena_init_growing(&arena); arena_err != nil {
		panic("Failed to allocate data")
	}
	defer virtual.arena_destroy(&arena)

	allocator := virtual.arena_allocator(&arena)

	gen := new(Generator, allocator)
	assert(gen != nil, "Failed to create new ImGUI 'Generator'")

	gen.allocator = allocator
	gen.flags.allocator = allocator
	gen.type_map.allocator = allocator
	gen.identifier_map.allocator = allocator

	// Core
	gen.type_map["ImGuiID"] = "ID"
	gen.type_map["ImGuiID*"] = "^ID"
	gen.type_map["ImGuiIO"] = "IO"
	gen.type_map["ImGuiIO*"] = "^IO"
	gen.type_map["unsigned_int"] = "u32"
	gen.type_map["unsigned int"] = "u32"
	gen.type_map["unsigned int*"] = "^u32"
	gen.type_map["signed char"] = "i8"
	gen.type_map["const char*"] = "cstring"
	gen.type_map["unsigned_char"] = "u8"
	gen.type_map["unsigned char"] = "u8"
	gen.type_map["unsigned char*"] = "^u8"
	gen.type_map["unsigned char**"] = "^^u8"
	gen.type_map["size_t"] = "uint"
	gen.type_map["sizeT*"] = "^uint"
	gen.type_map["size_t*"] = "^uint"
	gen.type_map["signed short"] = "i16"
	gen.type_map["unsigned_short"] = "u16"
	gen.type_map["unsigned short"] = "u16"
	gen.type_map["signed long long"] = "i64"
	gen.type_map["unsigned long long"] = "u64"
	gen.type_map["signed int"] = "i32"
	gen.type_map["ImWchar32"] = "Wchar32"
	gen.type_map["const void*"] = "rawptr"
	gen.type_map["void*"] = "rawptr"
	gen.type_map["void**"] = "^rawptr"
	gen.type_map["ImU64"] = "u64"
	gen.type_map["ImU64*"] = "u64*"
	gen.type_map["ImS8"] = "i8"
	gen.type_map["ImU8"] = "u8"
	gen.type_map["ImU8*"] = "^u8"
	gen.type_map["ImS16"] = "i16"
	gen.type_map["ImU16"] = "u16"
	gen.type_map["ImS32"] = "i32"
	gen.type_map["ImU32"] = "u32"
	gen.type_map["ImU32*"] = "u32*"
	gen.type_map["ImS64"] = "i64"
	gen.type_map["int"] = "i32"
	gen.type_map["int*"] = "^i32"
	gen.type_map["double"] = "f64"
	gen.type_map["double*"] = "^f64"
	gen.type_map["const double*"] = "^f64"
	gen.type_map["float"] = "f32"
	gen.type_map["float*"] = "^f32"
	gen.type_map["const float*"] = "^f32"
	gen.type_map["short"] = "i16"
	gen.type_map["ichar"] = "i8"
	gen.type_map["char"] = "u8"
	gen.type_map["bool"] = "bool"

	gen.tmp_ally_buf = make([]byte, 1 * mem.Megabyte)
	assert(gen.tmp_ally_buf != nil)
	defer delete(gen.tmp_ally_buf)
	mem.arena_init(&gen.tmp_arena, gen.tmp_ally_buf[:])
	gen.tmp_ally = mem.arena_allocator(&gen.tmp_arena)

	if !write_core(gen) {
		log.fatal("Failed to write 'imgui.odin' file.")
		return
	}
}

write_core :: proc(gen: ^Generator) -> (ok: bool) {
	core_data_file, open_file_ok := os.read_entire_file_from_filename("assets/dcimgui.json")
	if !open_file_ok {
		log.error("Failed to load 'dcimgui.json' file!")
		return
	}
	defer delete(core_data_file)

	json_data, json_err := json.parse(core_data_file)
	if json_err != nil {
		log.error("Failed to parse 'dcimgui.json' file.")
		log.errorf("Error:", json_err)
		return
	}
	defer json.destroy_value(json_data)

	IMGUI_ODIN_FILE :: "./../imgui.odin"

	if os.exists(IMGUI_ODIN_FILE) {
		os.remove(IMGUI_ODIN_FILE)
	}

	core_handle, core_handle_err := os.open(IMGUI_ODIN_FILE, os.O_WRONLY | os.O_CREATE)
	if core_handle_err != nil {
		log.error("Failed to create 'imgui.odin' file.")
		log.errorf("Error:", core_handle_err)
		return
	}
	defer os.close(core_handle)

	write_package_name(gen, core_handle, nl = false)

	os.write_string(core_handle, FOREIGN_IMPORT)

	write_defines(gen, core_handle, &json_data)
	write_enums(gen, core_handle, &json_data)
	write_typedefs(gen, core_handle, &json_data)
	write_structs(gen, core_handle, &json_data)
	write_procedures(gen, core_handle, &json_data)

	return true
}
