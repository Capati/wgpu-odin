package compute

// Core
import "base:runtime"
import "core:fmt"

// Package
import wgpu "../../wrapper"

_log_callback :: proc "c" (level: wgpu.Log_Level, message: cstring, user_data: rawptr) {
	context = runtime.default_context()
	fmt.eprintf("[wgpu] [%v] %s\n\n", level, message)
}

@(init)
init :: proc() {
	wgpu.set_log_callback(_log_callback, nil)
	wgpu.set_log_level(.Warn)
}

main :: proc() {
	numbers: []u32 = {1, 2, 3, 4}
	numbers_size: u32 = size_of(numbers)
	numbers_length: u32 = numbers_size / size_of(u32)

	// Instantiates instance of WebGPU
	instance, instance_err := wgpu.create_instance({backends = wgpu.Instance_Backend_Primary})
	if instance_err != nil do return
	defer wgpu.instance_release(instance)

	// Instantiates the general connection to the GPU
	adapter, adapter_err := wgpu.instance_request_adapter(
		instance,
		{compatible_surface = nil, power_preference = .High_Performance},
	)
	if adapter_err != nil do return
	defer wgpu.adapter_release(adapter)

	// Instantiates the feature specific connection to the GPU, defining some parameters,
	// `features` being the available features.
	device, queue, device_err := wgpu.adapter_request_device(adapter, {label = adapter.info.name})
	if device_err != nil do return
	defer {
		wgpu.device_release(device)
		wgpu.queue_release(queue)
	}

	// Shader module
	shader_source := #load("./compute.wgsl")
	shader_module, shader_module_err := wgpu.device_create_shader_module(
		device,
		{label = "Compute module", source = cstring(raw_data(shader_source))},
	)
	if shader_module_err != nil do return
	defer wgpu.shader_module_release(shader_module)

	// Instantiates buffer without data.
	// `usage` of buffer specifies how it can be used:
	//   `Map_Read` allows it to be read (outside the shader).
	//   `Copy_Dst` allows it to be the destination of the copy.
	staging_buffer, staging_buffer_err := wgpu.device_create_buffer(
		device,
		{label = "staging_buffer", size = cast(u64)numbers_size, usage = {.Map_Read, .Copy_Dst}},
	)
	if staging_buffer_err != nil do return
	defer wgpu.buffer_release(staging_buffer)

	// Instantiates buffer with data (`numbers`).
	// Usage allowing the buffer to be:
	//   A storage buffer (can be bound within a bind group and thus available to a
	// shader).
	//   The destination of a copy.
	//   The source of a copy.
	storage_buffer, storage_buffer_err := wgpu.device_create_buffer(
		device,
		{
			label = "storage_buffer",
			size = cast(u64)numbers_size,
			usage = {.Storage, .Copy_Src, .Copy_Dst},
		},
	)
	if storage_buffer_err != nil do return
	defer wgpu.buffer_release(storage_buffer)

	// A bind group defines how buffers are accessed by shaders.
	// It is to WebGPU what a descriptor set is to Vulkan.
	// `binding` here refers to the `binding` of a buffer in the shader (`layout(set = 0,
	// binding = 0) buffer`).

	// A pipeline specifies the operation of a shader

	// Instantiates the pipeline.
	compute_pipeline, compute_pipeline_err := wgpu.device_create_compute_pipeline(
		device,
		wgpu.Compute_Pipeline_Descriptor {
			label = "compute_pipeline",
			layout = nil,
			compute = {module = shader_module.ptr, entry_point = "main"},
		},
	)
	if compute_pipeline_err != nil do return
	defer wgpu.compute_pipeline_release(compute_pipeline)

	// Instantiates the bind group, once again specifying the binding of buffers.
	bind_group_layout, bind_group_layout_err := wgpu.compute_pipeline_get_bind_group_layout(
		compute_pipeline,
		0,
	)
	if bind_group_layout_err != nil do return
	defer wgpu.bind_group_layout_release(bind_group_layout)

	// Setup a bindGroup to tell the shader which
	// buffer to use for the computation
	bind_group, bind_group_err := wgpu.device_create_bind_group(
		device,
		{
			layout = bind_group_layout.ptr,
			entries = {
				{
					binding = 0,
					resource = wgpu.Buffer_Binding {
						buffer = storage_buffer.ptr,
						offset = 0,
						size = storage_buffer.size,
					},
				},
			},
			label = "bind_group_layout",
		},
	)
	if bind_group_err != nil do return
	defer wgpu.bind_group_release(bind_group)

	// A command encoder executes one or many pipelines.
	// It is to WebGPU what a command buffer is to Vulkan.
	encoder, encoder_err := wgpu.device_create_command_encoder(
		device,
		wgpu.Command_Encoder_Descriptor{label = "command_encoder"},
	)
	if encoder_err != nil do return
	defer wgpu.command_encoder_release(encoder)

	compute_pass, compute_pass_encoder_err := wgpu.command_encoder_begin_compute_pass(
		encoder,
		{label = "compute_pass"},
	)
	if compute_pass_encoder_err != nil do return
	defer wgpu.compute_pass_encoder_release(compute_pass)

	wgpu.compute_pass_encoder_set_pipeline(compute_pass, compute_pipeline.ptr)
	wgpu.compute_pass_encoder_set_bind_group(compute_pass, 0, bind_group.ptr)
	wgpu.compute_pass_encoder_dispatch_workgroups(compute_pass, numbers_length)
	wgpu.compute_pass_encoder_end(compute_pass)

	// Sets adds copy operation to command encoder.
	// Will copy data from storage buffer on GPU to staging buffer on CPU.
	wgpu.command_encoder_copy_buffer_to_buffer(
		encoder,
		storage_buffer.ptr,
		0,
		staging_buffer.ptr,
		0,
		staging_buffer.size,
	)

	// Submits command encoder for processing
	command_buffer, command_buffer_err := wgpu.command_encoder_finish(encoder)
	if command_buffer_err != nil do return
	defer wgpu.command_buffer_release(command_buffer)

	wgpu.queue_write_buffer(queue, storage_buffer.ptr, 0, wgpu.to_bytes(numbers))
	wgpu.queue_submit(queue, command_buffer.ptr)

	result: wgpu.Buffer_Map_Async_Status

	handle_buffer_map := proc "c" (status: wgpu.Buffer_Map_Async_Status, user_data: rawptr) {
		result := cast(^wgpu.Buffer_Map_Async_Status)user_data
		result^ = status
	}
	wgpu.buffer_map_async(
		staging_buffer,
		{.Read},
		handle_buffer_map,
		&result,
		{offset = 0, size = staging_buffer.size},
	)

	_, res_err := wgpu.device_poll(device)
	if res_err != nil do return

	if result == .Success {
		data, data_err := wgpu.buffer_get_mapped_range(staging_buffer, type_of(numbers))
		if data_err != nil do return
		fmt.printf("Steps: [%d, %d, %d, %d]\n", data[0], data[1], data[2], data[3])
	} else {
		fmt.eprintf("ERROR: Failed to map async result buffer: %v\n", result)
	}
}
