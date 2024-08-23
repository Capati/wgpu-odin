//+private
//+build linux, darwin, windows
package renderlink

// Vendor
import sdl "vendor:sdl2"

Cursor_Impl :: struct {
	using _cursor: Cursor,
	cursor:        ^sdl.Cursor,
	type:          Cursor_Type,
	system_type:   System_Cursor,
}

@(private = "file")
CURSOR_NATIVE_TO_SDL := [System_Cursor]sdl.SystemCursor {
	.Arrow      = .ARROW,
	.I_Beam     = .IBEAM,
	.Wait       = .WAIT,
	.Crosshair  = .CROSSHAIR,
	.Wait_Arrow = .WAITARROW,
	.Size_NW_SE = .SIZENWSE,
	.Size_NE_SW = .SIZENESW,
	.Size_WE    = .SIZEWE,
	.Size_NS    = .SIZENS,
	.Size_All   = .SIZEALL,
	.No         = .NO,
	.Hand       = .HAND,
}

_cursor_native_to_sdl :: proc "contextless" (
	cursor: System_Cursor,
) -> sdl.SystemCursor #no_bounds_check {
	if int(cursor) >= 0 && int(cursor) < len(CURSOR_NATIVE_TO_SDL) {
		return CURSOR_NATIVE_TO_SDL[cursor]
	}
	return .ARROW
}
