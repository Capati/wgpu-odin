package wgpu

// Packages
import "core:bytes"
import "core:fmt"
import "core:reflect"
import "core:slice"

from_bytes :: slice.reinterpret

when #config(WGPU_CHECK_TO_BYTES, true) {
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
		     .Simd_Vector:
			//  .Relative_Pointer,
			//  .Relative_Multi_Pointer:
			return false
		}

		return true
	}

	dynamic_array_to_bytes :: proc(arr: $T/[dynamic]$E) -> []u8 {
		if can_be_bytes(E) {
			return slice.to_bytes(arr[:])
		} else {
			fmt.panicf("Cannot fully convert to bytes: %v", typeid_of(T))
		}
	}

	slice_to_bytes :: proc(s: $T/[]$E) -> []u8 {
		if can_be_bytes(E) {
			return slice.to_bytes(s)
		} else {
			fmt.panicf("Cannot fully convert to bytes: %v", typeid_of(T))
		}
	}

	any_to_bytes :: proc(v: any) -> []u8 {
		if can_be_bytes(v.id) {
			return reflect.as_bytes(v)
		} else {
			fmt.panicf("Cannot fully convert to bytes: %v", v.id)
		}
	}
} else {
	dynamic_array_to_bytes :: dynamic_array_to_bytes_contextless

	slice_to_bytes :: slice_to_bytes_contextless

	any_to_bytes :: proc(v: any) -> []u8 {
		return reflect.as_bytes(v)
	}
}

buffer_stream_to_bytes :: proc "contextless" (b: bytes.Buffer) -> []u8 {
	return b.buf[b.off:]
}

// Compile time panic stub
@(private = "file")
map_to_bytes :: proc(m: $T/map[$K]$V) -> []u8 {
	#panic("Cannot fully convert map to bytes")
}

to_bytes :: proc {
	slice_to_bytes,
	buffer_stream_to_bytes,
	dynamic_array_to_bytes,
	map_to_bytes,
	any_to_bytes,
}

dynamic_array_to_bytes_contextless :: proc "contextless" (arr: $T/[dynamic]$E) -> []u8 {
	return slice.to_bytes(arr[:])
}

slice_to_bytes_contextless :: proc "contextless" (s: $T/[]$E) -> []u8 {
	return slice.to_bytes(s)
}
