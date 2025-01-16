package wgpu

// Packages
import "core:mem"
import "core:strings"

String_View :: struct {
	data:   cstring,
	length: uint,
}

STRLEN :: max(uint)

STRING_VIEW_BUFFER_SIZE :: #config(WGPU_STRING_VIEW_BUFFER_SIZE, 256)

String_View_Buffer :: struct {
	data:   [STRING_VIEW_BUFFER_SIZE]u8,
	length: uint,
	str:    String_View,
}

init_string_buffer :: proc "contextless" (buffer: ^String_View_Buffer, str: string) -> String_View {
	buffer.length = 0
	buffer.str = String_View {
		data   = nil,
		length = 0,
	}
	string_buffer_append(buffer, str)
	return string_buffer_get(buffer)
}

init_string_buffer_owned :: proc(str: string, allocator := context.allocator) -> String_View {
	return {data = strings.clone_to_cstring(str, allocator), length = STRLEN}
}

string_buffer_append :: proc "contextless" (self: ^String_View_Buffer, str: string) {
	// Check if we have enough space (leaving room for null terminator)
	if self.length + len(str) >= STRING_VIEW_BUFFER_SIZE - 1 {
		// Truncate if necessary
		remaining := STRING_VIEW_BUFFER_SIZE - self.length - 1
		copy(self.data[self.length:], (transmute([]u8)str)[:remaining])
		self.length += remaining
	} else {
		// Copy entire string
		copy(self.data[self.length:], (transmute([]u8)str)[:])
		self.length += len(str)
	}
	self.data[self.length] = 0 // Ensure null termination
	string_buffer_update(self) // Update the String_View
}

string_buffer_update :: proc "contextless" (self: ^String_View_Buffer) {
	if (self.length == 0) {
		self.str.data = nil
		self.str.length = 0
	} else {
		// Normal case - can use STRLEN since we ensure null termination
		self.str.data = cstring(raw_data(self.data[:]))
		self.str.length = STRLEN
	}
}

string_buffer_clear :: proc "contextless" (self: ^String_View_Buffer) {
	mem.zero_slice(self.data[:])
	self.length = 0
	self.str = String_View {
		data   = nil,
		length = 0,
	}
}

string_buffer_get :: proc "contextless" (self: ^String_View_Buffer) -> String_View {
	return self.str
}

string_view_get_string :: proc "contextless" (self: String_View) -> string {
	if self.length > 0 {
		return string(self.data)[:self.length]
	}
	return ""
}

string_view_clone_string :: proc(
	self: String_View,
	allocator := context.allocator,
) -> (
	res: string,
	err: mem.Allocator_Error,
) #optional_allocator_error {
	return strings.clone(string_view_get_string(self), allocator)
}
