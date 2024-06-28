package events

// Core
import "core:container/queue"
import "core:mem"

// Default events queue capacity
DEFAULT_EVENTS_CAPACITY :: #config(DEFAULT_EVENTS_CAPACITY, 64)

Event :: union #no_nil {
	Text_Input_Event,
	Key_Press_Event,
	Key_Release_Event,
	Mouse_Motion_Event,
	Mouse_Press_Event,
	Mouse_Release_Event,
	Mouse_Scroll_Event,
	Framebuffer_Resize_Event,
	Focus_Gained_Event,
	Focus_Lost_Event,
	Quit_Event,
}

// FIFO Queue
Event_List :: distinct queue.Queue(Event)

init_events :: proc(
	capacity := DEFAULT_EVENTS_CAPACITY,
	allocator := context.allocator,
) -> (
	out: Event_List,
	err: mem.Allocator_Error,
) {
	if err = queue.init(&out, capacity, allocator); err != .None {
		return {}, err
	}
	return
}

push :: proc(self: ^Event_List, event: Event) {
	queue.push_front(self, event)
}

pop :: proc(self: ^Event_List) -> Event {
	return queue.pop_back(self)
}

has_next :: proc(self: ^Event_List) -> bool {
	return self.len > 0
}

is_empty :: proc(self: ^Event_List) -> bool {
	return self.len == 0
}
