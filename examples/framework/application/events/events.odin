package events

// Core
import "base:runtime"
import "core:container/queue"

// Default events queue capacity
DEFAULT_EVENTS_CAPACITY :: #config(DEFAULT_EVENTS_CAPACITY, 2048)

Event :: union #no_nil {
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
Event_Queue :: distinct queue.Queue(Event)

init_events :: proc(
	capacity := DEFAULT_EVENTS_CAPACITY,
	allocator := context.allocator,
) -> (
	out: Event_Queue,
	err: runtime.Allocator_Error,
) {
	if err = queue.init(&out, capacity, allocator); err != .None {
		return {}, err
	}
	return
}

push_event :: proc(self: ^Event_Queue, event: Event) {
	queue.push_back(self, event)
}
