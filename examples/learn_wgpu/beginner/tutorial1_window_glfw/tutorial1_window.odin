package tutorial1_window_glfw

// Packages
import "core:fmt"

// Vendor
import "vendor:glfw"

main :: proc() {
	if !glfw.Init() {
		panic("[glfw] init failure")
	}

	glfw.WindowHint(glfw.CLIENT_API, glfw.NO_API)
	window := glfw.CreateWindow(960, 540, "Tutorial 1 - Window", nil, nil)

	for !glfw.WindowShouldClose(window) {
		glfw.PollEvents()

		// We will render here...
	}

	glfw.DestroyWindow(window)
	glfw.Terminate()

	fmt.println("Exiting...")
}
