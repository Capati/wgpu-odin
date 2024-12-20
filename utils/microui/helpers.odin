package wgpu_microui

// Packages
import mu "vendor:microui"

update_window_rect :: proc(ctx: ^mu.Context, window_name: string, rect: mu.Rect) {
	if c := mu.get_container(ctx, window_name); c != nil {
		c.rect = rect
	}
}
