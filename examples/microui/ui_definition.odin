package microui_example

// Core
import "core:fmt"

// Vendor
import mu "vendor:microui"

// Package
import wmu "./../../utils/microui"

SLIDER_FMT :: "%.0f"

test_window :: proc(using state: ^State) {
	if mu.begin_window(mu_ctx, "Demo Window", {40, 40, 300, 450}) {
		win := mu.get_current_container(mu_ctx)
		win.rect.w = max(win.rect.w, 240)
		win.rect.h = max(win.rect.h, 300)

		// Window information
		if .ACTIVE in mu.header(mu_ctx, "Window Info", {}) {
			win = mu.get_current_container(mu_ctx)
			mu.layout_row(mu_ctx, {54, -1}, 0)
			buf: [64]u8
			mu.label(mu_ctx, "Position:")
			mu.label(mu_ctx, fmt.bprintf(buf[:], "%d, %d", win.rect.x, win.rect.y))
			mu.label(mu_ctx, "Size:")
			mu.label(mu_ctx, fmt.bprintf(buf[:], "%d, %d", win.rect.w, win.rect.h))
		}

		// Test labels and buttons
		if .ACTIVE in mu.header(mu_ctx, "Test Buttons", {.EXPANDED}) {
			mu.layout_row(mu_ctx, {86, -110, -1}, 0)
			mu.label(mu_ctx, "Test buttons 1:")
			if .SUBMIT in mu.button(mu_ctx, "Button 1") {write_log(state, "Pressed button 1")}
			if .SUBMIT in mu.button(mu_ctx, "Button 2") {write_log(state, "Pressed button 2")}
			mu.label(mu_ctx, "Test buttons 2:")
			if .SUBMIT in mu.button(mu_ctx, "Button 3") {write_log(state, "Pressed button 3")}
			if .SUBMIT in mu.button(mu_ctx, "Popup") {
				mu.open_popup(mu_ctx, "Test Popup")
			}
			if (mu.begin_popup(mu_ctx, "Test Popup")) {
				if .SUBMIT in mu.button(mu_ctx, "Hello") {write_log(state, "Hello")}
				if .SUBMIT in mu.button(mu_ctx, "World") {write_log(state, "World")}
				mu.end_popup(mu_ctx)
			}
		}

		if .ACTIVE in mu.header(mu_ctx, "Tree and Text", {.EXPANDED}) {
			mu.layout_row(mu_ctx, {140, -1})
			mu.layout_begin_column(mu_ctx)
			if .ACTIVE in mu.treenode(mu_ctx, "Test 1") {
				if .ACTIVE in mu.treenode(mu_ctx, "Test 1a") {
					mu.label(mu_ctx, "Hello")
					mu.label(mu_ctx, "world")
				}
				if .ACTIVE in mu.treenode(mu_ctx, "Test 1b") {
					if .SUBMIT in
					   mu.button(mu_ctx, "Button 1") {write_log(state, "Pressed button 1")}
					if .SUBMIT in
					   mu.button(mu_ctx, "Button 2") {write_log(state, "Pressed button 2")}
				}
			}
			if .ACTIVE in mu.treenode(mu_ctx, "Test 2") {
				mu.layout_row(mu_ctx, {53, 53})
				if .SUBMIT in mu.button(mu_ctx, "Button 4") {write_log(state, "Pressed button 4")}
				if .SUBMIT in mu.button(mu_ctx, "Button 5") {write_log(state, "Pressed button 5")}
				if .SUBMIT in mu.button(mu_ctx, "Button 6") {write_log(state, "Pressed button 6")}
				if .SUBMIT in mu.button(mu_ctx, "Button 7") {write_log(state, "Pressed button 7")}
			}
			if .ACTIVE in mu.treenode(mu_ctx, "Test 3") {
				@(static)
				checks := [3]bool{true, false, true}
				mu.checkbox(mu_ctx, "Checkbox 1", &checks[0])
				mu.checkbox(mu_ctx, "Checkbox 2", &checks[1])
				mu.checkbox(mu_ctx, "Checkbox 3", &checks[2])

			}
			mu.layout_end_column(mu_ctx)

			mu.layout_begin_column(mu_ctx)
			mu.layout_row(mu_ctx, {-1})
			mu.text(
				mu_ctx,
				"Lorem ipsum dolor sit amet, consectetur adipiscing " +
				"elit. Maecenas lacinia, sem eu lacinia molestie, mi risus faucibus " +
				"ipsum, eu varius magna felis a nulla.",
			)
			mu.layout_end_column(mu_ctx)
		}

		if .ACTIVE in mu.header(mu_ctx, "Background Color", {.EXPANDED}) {
			mu.layout_row(mu_ctx, {-78, -1}, 68)
			// Sliders
			mu.layout_begin_column(mu_ctx)
			{
				mu.layout_row(mu_ctx, {46, -1}, 0)
				mu.label(mu_ctx, "Red:");wmu.slider(mu_ctx, &bg.r, 0, 255, 0, SLIDER_FMT)
				mu.label(mu_ctx, "Green:");wmu.slider(mu_ctx, &bg.g, 0, 255, 0, SLIDER_FMT)
				mu.label(mu_ctx, "Blue:");wmu.slider(mu_ctx, &bg.b, 0, 255, 0, SLIDER_FMT)
			}
			mu.layout_end_column(mu_ctx)

			// Preview
			rect := mu.layout_next(mu_ctx)
			mu.draw_rect(mu_ctx, rect, {u8(bg.r), u8(bg.g), u8(bg.b), 255})
			mu.draw_box(mu_ctx, mu.expand_rect(rect, 1), mu_ctx.style.colors[.BORDER])
			mu.draw_control_text(
				mu_ctx,
				fmt.tprintf("#%02x%02x%02x", state.bg.r, state.bg.g, state.bg.b),
				rect,
				.TEXT,
				{.ALIGN_CENTER},
			)
		}

		mu.end_window(mu_ctx)
	}
}

log_window :: proc(using state: ^State) {
	if mu.begin_window(mu_ctx, "Log Window", {350, 40, 300, 200}) {
		// output text panel
		mu.layout_row(mu_ctx, {-1}, -28)
		mu.begin_panel(mu_ctx, "Log Output")
		mu.layout_row(mu_ctx, {-1}, -1)
		mu.text(mu_ctx, read_log(state))

		if log_buf_updated {
			panel := mu.get_current_container(mu_ctx)
			panel.scroll.y = panel.content_size.y
			log_buf_updated = false
		}
		mu.end_panel(mu_ctx)

		// input textbox + submit button
		@(static)
		buf: [128]byte
		@(static)
		buf_len: int

		submitted := false
		mu.layout_row(mu_ctx, {-70, -1})

		if .SUBMIT in mu.textbox(mu_ctx, buf[:], &buf_len) {
			mu.set_focus(mu_ctx, mu_ctx.last_id)
			submitted = true
		}

		if .SUBMIT in mu.button(mu_ctx, "Submit") {
			submitted = true
		}

		if submitted {
			write_log(state, string(buf[:buf_len]))
			buf_len = 0
		}

		mu.end_window(mu_ctx)
	}
}

write_log :: proc(using state: ^State, text: string) {
	log_buf_len += copy(log_buf[log_buf_len:], text)
	log_buf_len += copy(log_buf[log_buf_len:], "\n")
	log_buf_updated = true
}

read_log :: proc(using state: ^State) -> string {
	return string(log_buf[:log_buf_len])
}

reset_log :: proc(using state: ^State) {
	log_buf_updated = true
	log_buf_len = 0
}

style_window :: proc(using state: ^State) {
	if mu.window(mu_ctx, "Style Window", {350, 250, 300, 240}) {
		@(static)
		colors := [mu.Color_Type]string {
			.TEXT         = "text",
			.SELECTION_BG = "selection bg",
			.BORDER       = "border",
			.WINDOW_BG    = "window bg",
			.TITLE_BG     = "title bg",
			.TITLE_TEXT   = "title text",
			.PANEL_BG     = "panel bg",
			.BUTTON       = "button",
			.BUTTON_HOVER = "button hover",
			.BUTTON_FOCUS = "button focus",
			.BASE         = "base",
			.BASE_HOVER   = "base hover",
			.BASE_FOCUS   = "base focus",
			.SCROLL_BASE  = "scroll base",
			.SCROLL_THUMB = "scroll thumb",
		}

		sw := i32(f32(mu.get_current_container(mu_ctx).body.w) * 0.14)
		mu.layout_row(mu_ctx, {80, sw, sw, sw, sw, -1})
		for label, col in colors {
			mu.label(mu_ctx, label)
			wmu.slider(mu_ctx, &mu_ctx.style.colors[col].r, 0, 255, 0, SLIDER_FMT)
			wmu.slider(mu_ctx, &mu_ctx.style.colors[col].g, 0, 255, 0, SLIDER_FMT)
			wmu.slider(mu_ctx, &mu_ctx.style.colors[col].b, 0, 255, 0, SLIDER_FMT)
			wmu.slider(mu_ctx, &mu_ctx.style.colors[col].a, 0, 255, 0, SLIDER_FMT)
			mu.draw_rect(mu_ctx, mu.layout_next(mu_ctx), mu_ctx.style.colors[col])
		}
	}
}
