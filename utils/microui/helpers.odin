package wgpu_microui

// Base
import intr "base:intrinsics"

// Vendor
import mu "vendor:microui"

update_window_rect :: proc(ctx: ^mu.Context, window_name: string, rect: mu.Rect) {
	if c := mu.get_container(ctx, window_name); c != nil {
		c.rect = rect
	}
}

slider :: proc(
	ctx: ^mu.Context,
	val: ^$T,
	lo, hi: T,
	step: mu.Real = 0.0,
	fmt_string: string = mu.SLIDER_FMT,
	options: mu.Options = {.ALIGN_CENTER},
) -> (
	res: mu.Result_Set,
) where intr.type_is_numeric(T) {
	mu.push_id(ctx, uintptr(val))

	@(static)
	tmp: mu.Real

	tmp = mu.Real(val^)
	res = mu.slider(ctx, &tmp, mu.Real(lo), mu.Real(hi), step, fmt_string, options)
	val^ = T(tmp)
	mu.pop_id(ctx)

	return
}
