package renderlink

MAX_INT8 :: 0x7F
MAX_UINT8 :: 0xFF
MAX_INT16 :: 0x7FFF
MAX_UINT16 :: 0xFFFF
MAX_INT32 :: 0x7FFFFFFF
MAX_UINT32 :: 0xFFFFFFFF
MAX_INT64 :: 0x7FFFFFFFFFFFFFFF
MAX_UINT64 :: 0xFFFFFFFFFFFFFFFF

Position :: struct {
	x, y: f32,
}

Physical_Size :: struct {
	width:  u32,
	height: u32,
}

GUID :: distinct [16]byte
