# Set the default mode to debug
MODE ?= debug

# Arguments for debug mode
ARGS = -debug -vet -strict-style

# Output directory
OUT = -out:./build

# Check if we're in release mode
ifeq ($(MODE),release)
	ARGS = -o:speed \
		-disable-assert \
		-no-bounds-check \
		-define:WGPU_CHECK_TO_BYTES=false \
		-define:WGPU_ENABLE_ERROR_HANDLING=false
endif

# Set the default linking
USE_SYSTEM_LIBRARIES ?= false
ARGS += -define:WGPU_USE_SYSTEM_LIBRARIES=$(USE_SYSTEM_LIBRARIES)

# Add macOS-specific linker flags
ifeq ($(shell uname -s),Darwin)
	ARGS += -extra-linker-flags:"-L/opt/homebrew/lib"
endif

# Set default build target
BUILD_TARGET ?= all

# Define all target names
TARGETS := capture compute cube cube_textured image_blur info microui rotating_cube \
	rotating_cube_textured texture_arrays triangle triangle_msaa learn_wgpu

.PHONY: all $(TARGETS)

all: $(TARGETS)

capture:
	@echo Building 'capture' in $(MODE) mode...
	@odin build ./capture $(ARGS) $(OUT)/capture

compute:
	@echo Building 'compute' in $(MODE) mode...
	@odin build ./compute $(ARGS) $(OUT)/compute

cube:
	@echo Building 'cube' in $(MODE) mode...
	@odin build ./cube $(ARGS) $(OUT)/cube

cube_textured:
	@echo Building 'cube_textured' in $(MODE) mode...
	@odin build ./cube_textured $(ARGS) $(OUT)/cube_textured

image_blur:
	@echo Building 'image_blur' in $(MODE) mode...
	@odin build ./image_blur $(ARGS) $(OUT)/image_blur

info:
	@echo Building 'info' in $(MODE) mode...
	@odin build ./info $(ARGS) $(OUT)/info

microui:
	@echo Building 'microui' in $(MODE) mode...
	@odin build ./microui $(ARGS) $(OUT)/microui

rotating_cube:
	@echo Building 'rotating_cube' in $(MODE) mode...
	@odin build ./rotating_cube $(ARGS) $(OUT)/rotating_cube

rotating_cube_textured:
	@echo Building 'rotating_cube_textured' in $(MODE) mode...
	@odin build ./rotating_cube_textured $(ARGS) $(OUT)/rotating_cube_textured

texture_arrays:
	@echo Building 'texture_arrays' in $(MODE) mode...
	@odin build ./texture_arrays $(ARGS) $(OUT)/texture_arrays

triangle:
	@echo Building 'triangle' in $(MODE) mode...
	@odin build ./triangle $(ARGS) $(OUT)/triangle

triangle_msaa:
	@echo Building 'triangle_msaa' in $(MODE) mode...
	@odin build ./triangle_msaa $(ARGS) $(OUT)/triangle_msaa

learn_wgpu:
	@echo Building 'learn_wgpu' examples in $(MODE) mode...
	@odin build ./learn_wgpu/beginner/tutorial1_window_glfw $(ARGS) $(OUT)/tutorial1_window_glfw
	@odin build ./learn_wgpu/beginner/tutorial1_window_sdl $(ARGS) $(OUT)/tutorial1_window_sdl
	@odin build ./learn_wgpu/beginner/tutorial2_surface_glfw $(ARGS) $(OUT)/tutorial2_surface_glfw
	@odin build ./learn_wgpu/beginner/tutorial2_surface_sdl $(ARGS) $(OUT)/tutorial2_surface_sdl
	@odin build ./learn_wgpu/beginner/tutorial2_surface_challenge $(ARGS) $(OUT)/tutorial2_surface_challenge
	@odin build ./learn_wgpu/beginner/tutorial3_pipeline $(ARGS) $(OUT)/tutorial3_pipeline
	@odin build ./learn_wgpu/beginner/tutorial3_pipeline_challenge $(ARGS) $(OUT)/tutorial3_pipeline_challenge
	@odin build ./learn_wgpu/beginner/tutorial4_buffer $(ARGS) $(OUT)/tutorial4_buffer
	@odin build ./learn_wgpu/beginner/tutorial4_buffer_challenge $(ARGS) $(OUT)/tutorial4_buffer_challenge
	@odin build ./learn_wgpu/beginner/tutorial5_textures $(ARGS) $(OUT)/tutorial5_textures
	@odin build ./learn_wgpu/beginner/tutorial5_textures_challenge $(ARGS) $(OUT)/tutorial5_textures_challenge
	@odin build ./learn_wgpu/beginner/tutorial6_uniforms $(ARGS) $(OUT)/tutorial6_uniforms
