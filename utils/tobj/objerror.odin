package tobj

// Packages
import "base:runtime"
import "core:fmt"
import "core:mem"

LINE_BUF_LEN :: 1024
MSG_BUF :: 128

Marker :: struct {
	line_buf:    [LINE_BUF_LEN]byte,
	line:        int,
	column:      int,
	offset:      int,
	line_start:  int,
	line_length: int,
}

update_marker_for_line :: proc(marker: ^Marker, line: string) {
	mem.zero_slice(marker.line_buf[:])
	copy(marker.line_buf[:], transmute([]u8)line)
	marker.line += 1
	marker.column = 1
	marker.line_length = len(line)
	marker.line_start = marker.offset
	marker.offset += marker.line_length + 1 // +1 for newline
}

Error :: struct {
	marker:   Marker,
	line_buf: [LINE_BUF_LEN]byte,
	msg_buf:  [MSG_BUF]u8,
}

make_error :: proc(marker: ^Marker, format: string, args: ..any) -> (err: Error) {
	err.marker = marker^
	copy(err.line_buf[:], marker.line_buf[:])
	fmt.bprintf(err.msg_buf[:], format, ..args)
	return
}

print_error_unwrapped :: proc(error: Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	msg := fmt.tprintf("[line %d]: %s\n%s", error.marker.line, error.msg_buf, error.line_buf)
	fmt.eprintfln(msg)
}

print_error_wrapped :: proc(error: Maybe(Error)) {
	if err, err_exists := error.?; err_exists {
		print_error_unwrapped(err)
	}
}

print_error :: proc {
	print_error_unwrapped,
	print_error_wrapped,
}
