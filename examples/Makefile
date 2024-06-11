# Set the default mode to debug
MODE ?= debug

# Arguments for debug mode
ifeq ($(MODE),debug)
ARGS = -debug
else
# Arguments optimized for release
ARGS = -o:speed \
    -disable-assert \
    -no-bounds-check \
    -define:CHECK_TO_BYTES=false \
    -define:WGPU_ENABLE_ERROR_HANDLING=false
endif

# Set the default linking
USE_SYSTEM_LIBRARIES ?= true
ARGS := $(ARGS) -define:WGPU_USE_SYSTEM_LIBRARIES=$(USE_SYSTEM_LIBRARIES)

ifeq ($(shell uname -s),Darwin)
	ARGS := $(ARGS) -extra-linker-flags:"-L/opt/homebrew/lib"
endif

OUT = -out:./build

.PHONY: all

all: info_example triangle_example triangle_msaa_example cube_example cube_textured_example compute_example capture_example texture_arrays_example learn_wgpu_examples

info_example:
	odin build ./info $(ARGS) $(OUT)/info

triangle_example:
	odin build ./triangle $(ARGS) $(OUT)/triangle

triangle_msaa_example:
	odin build ./triangle_msaa $(ARGS) $(OUT)/triangle_msaa

cube_example:
	odin build ./cube $(ARGS) $(OUT)/cube

cube_textured_example:
	odin build ./cube_textured $(ARGS) $(OUT)/cube_textured

compute_example:
	odin build ./compute $(ARGS) $(OUT)/compute

capture_example:
	odin build ./capture $(ARGS) $(OUT)/capture

texture_arrays_example:
	odin build ./texture_arrays $(ARGS) $(OUT)/texture_arrays

learn_wgpu_examples:
	odin build ./learn_wgpu/beginner/tutorial1_window $(ARGS) $(OUT)/tutorial1_window
	odin build ./learn_wgpu/beginner/tutorial2_surface $(ARGS) $(OUT)/tutorial2_surface
	odin build ./learn_wgpu/beginner/tutorial2_surface_challenge $(ARGS) $(OUT)/tutorial2_surface_challenge
	odin build ./learn_wgpu/beginner/tutorial3_pipeline $(ARGS) $(OUT)/tutorial3_pipeline
	odin build ./learn_wgpu/beginner/tutorial3_pipeline_challenge $(ARGS) $(OUT)/tutorial3_pipeline_challenge
	odin build ./learn_wgpu/beginner/tutorial4_buffer $(ARGS) $(OUT)/tutorial4_buffer
	odin build ./learn_wgpu/beginner/tutorial4_buffer_challenge $(ARGS) $(OUT)/tutorial4_buffer_challenge
	odin build ./learn_wgpu/beginner/tutorial5_textures $(ARGS) $(OUT)/tutorial5_textures
	odin build ./learn_wgpu/beginner/tutorial5_textures_challenge $(ARGS) $(OUT)/tutorial5_textures_challenge
	odin build ./learn_wgpu/beginner/tutorial6_uniforms $(ARGS) $(OUT)/tutorial6_uniforms
