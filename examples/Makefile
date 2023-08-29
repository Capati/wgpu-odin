ARGS = -define:WGPU_USE_SYSTEM_LIBRARIES=true
OUT = -out:./build

.PHONY: all

all: info triangle_example triangle_msaa_example cube_example simple_compute capture_example learn_wgpu_examples

info:
	odin build ./info $(ARGS) $(OUT)/info

triangle_example:
	odin build ./triangle $(ARGS) $(OUT)/triangle

triangle_msaa_example:
	odin build ./triangle_msaa $(ARGS) $(OUT)/triangle_msaa

cube_example:
	odin build ./cube $(ARGS) $(OUT)/cube

simple_compute:
	odin build ./simple_compute $(ARGS) $(OUT)/simple_compute

capture_example:
	odin build ./capture $(ARGS) $(OUT)/capture

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
