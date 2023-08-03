package main

// Core
import "core:fmt"
import "core:log"
import "core:mem"

when #config(INFO_EXAMPLE, false) {
    import sample "./info"
} else when #config(TRIANGLE_EXAMPLE, false) || #config(TRIANGLE_MSAA_EXAMPLE, false) {
    import sample "./triangle"
} else when #config(SIMPLE_COMPUTE, false) {
    import sample "./simple_compute"
} else when #config(TUTORIAL1_WINDOW, false) {
    import sample "./learn_wgpu/beginner/tutorial1_window"
} else when #config(TUTORIAL2_SURFACE, false) {
    import sample "./learn_wgpu/beginner/tutorial2_surface"
} else when #config(TUTORIAL2_SURFACE_CHALLENGE, false) {
    import sample "./learn_wgpu/beginner/tutorial2_surface_challenge"
} else when #config(TUTORIAL3_PIPELINE, false) {
    import sample "./learn_wgpu/beginner/tutorial3_pipeline"
} else when #config(TUTORIAL3_PIPELINE_CHALLENGE, false) {
    import sample "./learn_wgpu/beginner/tutorial3_pipeline_challenge"
} else {
    import sample "./triangle"
}

main :: proc() {
    context.logger = log.create_console_logger(.Debug)
    defer log.destroy_console_logger(context.logger)

    ta: mem.Tracking_Allocator
    mem.tracking_allocator_init(&ta, context.allocator)
    defer mem.tracking_allocator_destroy(&ta)
    context.allocator = mem.tracking_allocator(&ta)

    defer if len(ta.allocation_map) > 0 {
        fmt.eprintln()
        for _, v in ta.allocation_map {
            fmt.eprintf("%v - leaked %v bytes\n", v.location, v.size)
        }
    }

    sample.start()
}
