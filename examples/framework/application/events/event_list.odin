package events

// Core
import "core:container/queue"

Event_List :: struct {
    queue:         ^Event_Queue,
    using _vtable: ^Event_List_VTable,
}

@(private)
Event_List_VTable :: struct {
    next:     proc(self: ^Event_List) -> Event,
    has_next: proc(self: ^Event_List) -> bool,
}

@(private)
default_event_list_vtable := Event_List_VTable {
    next     = event_list_next,
    has_next = event_list_has_next,
}

default_event_list := Event_List {
    _vtable = &default_event_list_vtable,
}

create_event_list :: proc(queue: ^Event_Queue) -> Event_List {
    return {queue, &default_event_list_vtable}
}

event_list_next :: proc(self: ^Event_List) -> Event {
    return queue.pop_front(self.queue)
}

event_list_has_next :: proc(self: ^Event_List) -> bool {
    return self.queue.len > 0
}
