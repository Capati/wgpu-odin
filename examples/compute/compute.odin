package compute

// Packages
import "base:runtime"
import "core:fmt"

// Local packages
import "root:wgpu"

_log_callback :: proc "c" (level: wgpu.LogLevel, message: wgpu.StringView, user_data: rawptr) {
	if message.length > 0 {
		context = runtime.default_context()
		temp := string(message.data)[:message.length]
		fmt.eprintf("[wgpu] [%v] %s\n\n", level, temp)
	}
}

run :: proc() -> (ok: bool) {
	wgpu.set_log_callback(_log_callback, nil)
	wgpu.set_log_level(.Error)

	numbers: []u32 = {1, 2, 3, 4}
	numbers_size: u32 = size_of(numbers)
	numbers_length: u32 = numbers_size / size_of(u32)

	// Instantiates instance of WebGPU
	instance := wgpu.create_instance(
		wgpu.InstanceDescriptor{backends = wgpu.BACKENDS_PRIMARY},
	) or_return
	defer wgpu.instance_release(instance)

	// Instantiates the general connection to the GPU
	adapter := wgpu.instance_request_adapter(
		instance,
		wgpu.RequestAdapterOptions{power_preference = .HighPerformance},
	) or_return
	defer wgpu.adapter_release(adapter)

	adapter_info := wgpu.adapter_get_info(adapter) or_return
	defer wgpu.adapter_info_free_members(adapter_info)

	// Instantiates the feature specific connection to the GPU, defining some parameters,
	// `features` being the available features.
	device := wgpu.adapter_request_device(
		adapter,
		wgpu.DeviceDescriptor{label = adapter_info.description},
	) or_return
	defer wgpu.device_release(device)

	queue := wgpu.device_get_queue(device)
	defer wgpu.queue_release(queue)

	// Shader module
	shader_source := #load("./compute.wgsl")
	shader_module := wgpu.device_create_shader_module(
		device,
		{label = "Compute module", source = string(shader_source)},
	) or_return
	defer wgpu.shader_module_release(shader_module)

	// Instantiates buffer without data.
	// `usage` of buffer specifies how it can be used:
	//   `Map_Read` allows it to be read (outside the shader).
	//   `CopyDst` allows it to be the destination of the copy.
	staging_buffer := wgpu.device_create_buffer(
		device,
		{label = "staging_buffer", size = cast(u64)numbers_size, usage = {.MapRead, .CopyDst}},
	) or_return
	defer wgpu.buffer_release(staging_buffer)

	// Instantiates buffer with data (`numbers`).
	// Usage allowing the buffer to be:
	//   A storage buffer (can be bound within a bind group and thus available to a
	// shader).
	//   The destination of a copy.
	//   The source of a copy.
	storage_buffer := wgpu.device_create_buffer_with_data(
		device,
		{
			label = "storage_buffer",
			contents = wgpu.to_bytes(numbers),
			usage = {.Storage, .CopySrc, .CopyDst},
		},
	) or_return
	defer wgpu.buffer_release(storage_buffer)

	// A bind group defines how buffers are accessed by shaders.
	// It is to WebGPU what a descriptor set is to Vulkan.
	// `binding` here refers to the `binding` of a buffer in the shader (`layout(set = 0,
	// binding = 0) buffer`).

	// A pipeline specifies the operation of a shader

	// Instantiates the pipeline.
	compute_pipeline := wgpu.device_create_compute_pipeline(
		device,
		wgpu.ComputePipelineDescriptor {
			label = "compute_pipeline",
			module = shader_module,
			entry_point = "main",
		},
	) or_return
	defer wgpu.compute_pipeline_release(compute_pipeline)

	// Instantiates the bind group, once again specifying the binding of buffers.
	bind_group_layout := wgpu.compute_pipeline_get_bind_group_layout(compute_pipeline, 0) or_return
	defer wgpu.bind_group_layout_release(bind_group_layout)

	// Setup a bindGroup to tell the shader which
	// buffer to use for the computation
	bind_group := wgpu.device_create_bind_group(
		device,
		{
			layout = bind_group_layout,
			entries = {{binding = 0, resource = wgpu.buffer_as_entire_binding(storage_buffer)}},
			label = "bind_group_layout",
		},
	) or_return
	defer wgpu.bind_group_release(bind_group)

	// A command encoder executes one or many pipelines.
	// It is to WebGPU what a command buffer is to Vulkan.
	encoder := wgpu.device_create_command_encoder(
		device,
		wgpu.CommandEncoderDescriptor{label = "command_encoder"},
	) or_return
	defer wgpu.command_encoder_release(encoder)

	compute_pass := wgpu.command_encoder_begin_compute_pass(
		encoder,
		wgpu.ComputePassDescriptor{label = "compute_pass"},
	) or_return

	wgpu.compute_pass_set_pipeline(compute_pass, compute_pipeline)
	wgpu.compute_pass_set_bind_group(compute_pass, 0, bind_group)
	wgpu.compute_pass_dispatch_workgroups(compute_pass, numbers_length)
	wgpu.compute_pass_end(compute_pass) or_return

	// Release the compute_pass before we submit or we get the error:
	// CommandBuffer cannot be destroyed because is still in use
	wgpu.compute_pass_release(compute_pass)

	// Sets adds copy operation to command encoder.
	// Will copy data from storage buffer on GPU to staging buffer on CPU.
	wgpu.command_encoder_copy_buffer_to_buffer(
		encoder,
		storage_buffer,
		0,
		staging_buffer,
		0,
		u64(numbers_size),
	) or_return

	// Submits command encoder for processing
	command_buffer := wgpu.command_encoder_finish(encoder) or_return
	defer wgpu.command_buffer_release(command_buffer)

	wgpu.queue_submit(queue, command_buffer)

	result: wgpu.MapAsyncStatus

	handle_buffer_map := proc "c" (
		status: wgpu.MapAsyncStatus,
		message: wgpu.StringView,
		userdata1: rawptr,
		userdata2: rawptr,
	) {
		result := cast(^wgpu.MapAsyncStatus)userdata1
		result^ = status
	}
	wgpu.buffer_map_async(
		staging_buffer,
		{.Read},
		{start = 0, end = wgpu.buffer_size(staging_buffer)},
		{callback = handle_buffer_map, userdata1 = &result},
	)

	wgpu.device_poll(device) or_return

	if result == .Success {
		data_view := wgpu.buffer_get_mapped_range(staging_buffer, type_of(numbers)) or_return
		data := data_view.data
		fmt.printf("Steps: [%d, %d, %d, %d]\n", data[0], data[1], data[2], data[3])
	} else {
		fmt.eprintf("ERROR: Failed to map async result buffer: %v\n", result)
	}

	return true
}

main :: proc() {
	run()
}
