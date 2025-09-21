package webgpu

// Core
import "core:bytes"
import "core:log"
import "core:reflect"
import "core:slice"

FromBytes :: slice.reinterpret

when ODIN_DEBUG {
	@(private = "file")
	_can_be_bytes :: proc(T: typeid) -> bool {
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
				res &&= _can_be_bytes(ti.id)
			}
			return res

		case .Union:
			res := true
			for ti in type_info_of(id).variant.(reflect.Type_Info_Union).variants {
				res &&= _can_be_bytes(ti.id)
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
			return false
		}

		return true
	}

	/* Convert [dynamic] array to bytes. */
	DynamicArrayToBytes :: proc(arr: $T/[dynamic]$E, loc := #caller_location) -> []u8 {
		if _can_be_bytes(E) {
			return DynamicArrayToBytesContextless(arr)
		} else {
			log.panicf("Cannot fully convert [dynamic] to bytes: %v", typeid_of(T), location = loc)
		}
	}

	/* Convert slice to bytes. */
	SliceToBytes :: proc(s: $T/[]$E, loc := #caller_location) -> []u8 {
		if _can_be_bytes(E) {
			return SliceToBytesContextless(s)
		} else {
			log.panicf("Cannot fully convert [slice] to bytes: %v", typeid_of(T), location = loc)
		}
	}

	/* Convert any to bytes. */
	AnyToBytes :: proc(v: any, loc := #caller_location) -> []u8 {
		if _can_be_bytes(v.id) {
			return AnyToBytesContextless(v)
		} else {
			log.panicf("Cannot fully convert [any] to bytes: %v", v.id, location = loc)
		}
	}
} else {
	SliceToBytes :: SliceToBytesContextless
	DynamicArrayToBytes :: DynamicArrayToBytesContextless
	AnyToBytes :: AnyToBytesContextless
}

/* Compile time panic stub. */
MapToBytes :: proc "contextless" (m: $T/map[$K]$V) -> []u8 {
	#panic("Cannot fully convert [map] to bytes")
}

/* Convert buffer stream to bytes. */
BufferStreamToBytes :: #force_inline proc "contextless" (
	b: bytes.Buffer,
	loc := #caller_location,
) -> []u8 #no_bounds_check {
	return b.buf[b.off:]
}

/* Convert [dynamic] array to bytes. */
DynamicArrayToBytesContextless :: #force_inline proc "contextless" (
	arr: $T/[dynamic]$E,
	loc := #caller_location,
) -> []u8 {
	return slice.to_bytes(arr[:])
}

/* Convert slice to bytes. */
SliceToBytesContextless :: #force_inline proc "contextless" (
	s: $T/[]$E,
	loc := #caller_location,
) -> []u8 {
	return slice.to_bytes(s)
}

/* Convert any to bytes. */
AnyToBytesContextless :: #force_inline proc "contextless" (
	v: any,
	loc := #caller_location,
) -> []u8 #no_bounds_check {
	sz: int
	if ti := type_info_of(v.id); ti != nil {
		sz = ti.size
	}
	return ([^]byte)(v.data)[:sz]
}

ToBytes :: proc {
	SliceToBytes,
	BufferStreamToBytes,
	DynamicArrayToBytes,
	MapToBytes,
	AnyToBytes,
}

ToBytesContextless :: proc {
	SliceToBytesContextless,
	BufferStreamToBytes,
	DynamicArrayToBytesContextless,
	MapToBytes,
	AnyToBytesContextless,
}
