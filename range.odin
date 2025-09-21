package webgpu

// Core
import intr "base:intrinsics"

Range :: struct($T: typeid) where intr.type_is_ordered(T) {
	start, end: T,
}

RangeInit :: proc "contextless" (
	$T: typeid,
	start, end: T,
) -> Range(T) where intr.type_is_ordered(T) {
	return Range(T){start, end}
}

/* Get the length of the Range */
RangeLen :: proc "contextless" (r: Range($T)) -> T {
	if range_is_empty(r) {
		return 0
	}
	return (r.end - r.start) + 1
}

/* Check if the range is empty */
RangeIsEmpty :: proc "contextless" (r: Range($T)) -> bool {
	return r.end < r.start
}

/* Check if a value is within the Range */
RangeContains :: proc "contextless" (r: Range($T), value: T) -> bool {
	return value >= r.start && value < r.end
}

/* Iterator for the Range */
RangeIterator :: struct($T: typeid) {
	current, end: T,
}

/* Create an iterator for the Range */
RangeCreateIterator :: proc "contextless" (r: Range($T)) -> RangeIterator(T) {
	return RangeIterator(T){r.start, r.end}
}

/* Get the next value from the iterator */
RangeIteratorNext :: proc "contextless" (it: ^RangeIterator($T), value: ^T) -> bool {
	if it.current < it.end {
		value^ = it.current
		it.current += 1
		return true
	}
	return false
}
