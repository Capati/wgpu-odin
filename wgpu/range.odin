package wgpu

// Packages
import intr "base:intrinsics"

Range :: struct($T: typeid) where intr.type_is_ordered(T) {
	start, end: T,
}

range_init :: proc "contextless" (
	$T: typeid,
	start, end: T,
) -> Range(T) where intr.type_is_ordered(T) {
	return Range(T){start, end}
}

/* Get the length of the Range */
range_len :: proc "contextless" (r: Range($T)) -> T {
	if range_is_empty(r) {
		return 0
	}
	return (r.end - r.start) + 1
}

/* Check if the range is empty */
range_is_empty :: proc "contextless" (r: Range($T)) -> bool {
	return r.end < r.start
}

/* Check if a value is within the Range */
range_contains :: proc "contextless" (r: Range($T), value: T) -> bool {
	return value >= r.start && value < r.end
}

/* Iterator for the Range */
Range_Iterator :: struct($T: typeid) {
	current, end: T,
}

/* Create an iterator for the Range */
range_iterator :: proc "contextless" (r: Range($T)) -> Range_Iterator(T) {
	return Range_Iterator(T){r.start, r.end}
}

/* Get the next value from the iterator */
range_next :: proc "contextless" (it: ^Range_Iterator($T), value: ^T) -> bool {
	if it.current < it.end {
		value^ = it.current
		it.current += 1
		return true
	}
	return false
}
