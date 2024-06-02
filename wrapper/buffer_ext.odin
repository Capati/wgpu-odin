package wgpu

import "core:bytes"
import "core:fmt"
import "core:reflect"
import "core:slice"

from_bytes :: slice.reinterpret

CHECK_TO_BYTES :: #config(WGPU_CHECK_TO_BYTES, true)

@(private = "file")
can_be_bytes :: proc(T: typeid) -> bool {
	id := reflect.typeid_core(T)
	kind := reflect.type_kind(id)
	for kind == .Array || kind == .Enumerated_Array {
		id = reflect.typeid_elem(id)
		id = reflect.typeid_core(id)
		kind = reflect.type_kind(id)
	}
	#partial switch kind {
	case .Struct:
		res := true
		for ti in reflect.struct_field_types(id) {
			res &&= can_be_bytes(ti.id)
		}
		return res
	case .Union:
		res := true
		for ti in type_info_of(id).variant.(reflect.Type_Info_Union).variants {
			res &&= can_be_bytes(ti.id)
		}
		return res
	case .Slice,
	     .Dynamic_Array,
	     .Map,
	     .Pointer,
	     .Multi_Pointer,
	     .String,
	     .Procedure,
	     .Type_Id,
	     .Any,
	     .Soa_Pointer,
	     .Simd_Vector,
	     .Relative_Pointer,
	     .Relative_Multi_Pointer:
		return false
	}

	return true
}

dynamic_array_to_bytes :: proc(arr: $T/[dynamic]$E) -> []u8 {
	when CHECK_TO_BYTES {
		if can_be_bytes(E) {
			return slice.to_bytes(arr[:])
		} else do fmt.panicf("Cannot fully convert to bytes: %v", typeid_of(T))
	} else {
		return slice.to_bytes(arr[:])
	}
}

slice_to_bytes :: proc(s: $T/[]$E) -> []u8 {
	when CHECK_TO_BYTES {
		if can_be_bytes(E) {
			return slice.to_bytes(s)
		} else do fmt.panicf("Cannot fully convert to bytes: %v", typeid_of(T))
	} else {
		return slice.to_bytes(s)
	}
}

buffer_stream_to_bytes :: proc(b: ^bytes.Buffer) -> []u8 {
	return bytes.buffer_to_bytes(b)
}

// Compile time panic stub
@(private = "file")
map_to_bytes :: proc(m: $T/map[$K]$V) -> []u8 {
	#panic("Cannot fully convert map to bytes")
}

any_to_bytes :: proc(v: any) -> []u8 {
	when CHECK_TO_BYTES {
		if can_be_bytes(v.id) {
			return reflect.as_bytes(v)
		} else do fmt.panicf("Cannot fully convert to bytes: %v", v.id)
	} else {
		return reflect.as_bytes(v)
	}
}

to_bytes :: proc {
	slice_to_bytes,
	buffer_stream_to_bytes,
	dynamic_array_to_bytes,
	map_to_bytes,
	any_to_bytes,
}
