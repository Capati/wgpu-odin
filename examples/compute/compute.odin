package compute

// Core
import "base:runtime"
import "core:fmt"

// Local packages
import wgpu "../../"

_log_callback :: proc "c" (level: wgpu.LogLevel, message: string, user_data: rawptr) {
	context = runtime.default_context()
	fmt.eprintf("[wgpu] [%v] %s\n\n", level, message)
}

main :: proc() {
	wgpu.SetLogCallback(_log_callback, nil)
	wgpu.SetLogLevel(.Error)

	numbers: []u32 = {1, 2, 3, 4}
	numbers_size: u32 = size_of(numbers)
	numbers_length: u32 = numbers_size / size_of(u32)

	// Instantiates instance of WebGPU
	instance := wgpu.CreateInstance(
		wgpu.InstanceDescriptor{backends = wgpu.BACKENDS_PRIMARY},
	)
	defer wgpu.InstanceRelease(instance)

	// Instantiates the general connection to the GPU
	adapter_res := wgpu.InstanceRequestAdapter(
		instance,
		wgpu.RequestAdapterOptions{powerPreference = .HighPerformance},
	)
	if (adapter_res.status != .Success) {
		fmt.panicf(
			"Failed to request the selected adapter [%v]: %s",
			adapter_res.status,
			adapter_res.message,
		)
	}
	adapter := adapter_res.adapter
	defer wgpu.AdapterRelease(adapter)

	adapter_info, info_status := wgpu.AdapterGetInfo(adapter)
	if info_status != .Success {
		fmt.panicf("Failed to get adapter info for the selected adapter: %v", info_status)
	}
	defer wgpu.AdapterInfoFreeMembers(adapter_info)

	// Instantiates the feature specific connection to the GPU, defining some parameters,
	// `features` being the available features.
	device_res := wgpu.AdapterRequestDevice(
		adapter,
		wgpu.DeviceDescriptor{label = adapter_info.description},
	)
	if (device_res.status != .Success) {
		fmt.panicf(
			"Failed to request the device [%v]: %s",
			device_res.status,
			device_res.message,
		)
	}
	device := device_res.device
	defer wgpu.DeviceRelease(device)

	queue := wgpu.DeviceGetQueue(device)
	defer wgpu.QueueRelease(queue)

	// Shader module
	shader_source := #load("./compute.wgsl")
	shader_module := wgpu.DeviceCreateShaderModule(
		device,
		{label = "Compute module", source = string(shader_source)},
	)
	defer wgpu.ShaderModuleRelease(shader_module)

	// Instantiates buffer without data.
	// `usage` of buffer specifies how it can be used:
	//   `Map_Read` allows it to be read (outside the shader).
	//   `Copy_Dst` allows it to be the destination of the copy.
	staging_buffer := wgpu.DeviceCreateBuffer(
		device,
		{label = "staging_buffer", size = cast(u64)numbers_size, usage = {.MapRead, .CopyDst}},
	)
	defer wgpu.BufferRelease(staging_buffer)

	// Instantiates buffer with data (`numbers`).
	// Usage allowing the buffer to be:
	//   A storage buffer (can be bound within a bind group and thus available to a shader).
	//   The destination of a copy.
	//   The source of a copy.
	storage_buffer := wgpu.DeviceCreateBufferWithData(
		device,
		{
			label = "storage_buffer",
			contents = wgpu.ToBytes(numbers),
			usage = {.Storage, .CopySrc, .CopyDst},
		},
	)
	defer wgpu.BufferRelease(storage_buffer)

	// A bind group defines how buffers are accessed by shaders.
	// It is to WebGPU what a descriptor set is to Vulkan.
	// `binding` here refers to the `binding` of a buffer in the shader (`layout(set = 0,
	// binding = 0) buffer`).

	// A pipeline specifies the operation of a shader

	// Instantiates the pipeline.
	compute_pipeline := wgpu.DeviceCreateComputePipeline(
		device,
		wgpu.ComputePipelineDescriptor {
			label = "compute_pipeline",
			module = shader_module,
			entryPoint = "main",
		},
	)
	defer wgpu.ComputePipelineRelease(compute_pipeline)

	// Instantiates the bind group, once again specifying the binding of buffers.
	bind_group_layout := wgpu.ComputePipelineGetBindGroupLayout(compute_pipeline, 0)
	defer wgpu.BindGroupLayoutRelease(bind_group_layout)

	// Setup a bindGroup to tell the shader which
	// buffer to use for the computation
	bind_group := wgpu.DeviceCreateBindGroup(
		device,
		{
			layout = bind_group_layout,
			entries = {{binding = 0, resource = wgpu.BufferAsEntireBinding(storage_buffer)}},
			label = "bind_group_layout",
		},
	)
	defer wgpu.BindGroupRelease(bind_group)

	// A command encoder executes one or many pipelines.
	// It is to WebGPU what a command buffer is to Vulkan.
	encoder := wgpu.DeviceCreateCommandEncoder(
		device,
		wgpu.CommandEncoderDescriptor{label = "command_encoder"},
	)
	defer wgpu.CommandEncoderRelease(encoder)

	compute_pass := wgpu.CommandEncoderBeginComputePass(
		encoder,
		wgpu.ComputePassDescriptor{label = "compute_pass"},
	)

	wgpu.ComputePassSetPipeline(compute_pass, compute_pipeline)
	wgpu.ComputePassSetBindGroup(compute_pass, 0, bind_group)
	wgpu.ComputePassDispatchWorkgroups(compute_pass, numbers_length, 1, 1)
	wgpu.ComputePassEnd(compute_pass)

	// Release the compute_pass before we submit or we get the error:
	// Command_Buffer cannot be destroyed because is still in use
	wgpu.ComputePassRelease(compute_pass)

	// Sets adds copy operation to command encoder.
	// Will copy data from storage buffer on GPU to staging buffer on CPU.
	wgpu.CommandEncoderCopyBufferToBuffer(
		encoder,
		storage_buffer,
		0,
		staging_buffer,
		0,
		u64(numbers_size),
	)

	// Submits command encoder for processing
	command_buffer := wgpu.CommandEncoderFinish(encoder)
	defer wgpu.CommandBufferRelease(command_buffer)

	wgpu.QueueSubmit(queue, { command_buffer })

	result: wgpu.MapAsyncStatus

	handle_buffer_map := proc "c" (
		status: wgpu.MapAsyncStatus,
		message: string,
		userdata1: rawptr,
		userdata2: rawptr,
	) {
		result := cast(^wgpu.MapAsyncStatus)userdata1
		result^ = status
	}

	wgpu.BufferMapAsync(
		staging_buffer,
		{.Read},
		{start = 0, end = wgpu.BufferGetSize(staging_buffer)},
		{callback = handle_buffer_map, userdata1 = &result},
	)

	wgpu.DevicePoll(device)

	if result == .Success {
		data_view := wgpu.BufferGetMappedRange(staging_buffer, type_of(numbers))
		data := data_view.data
		fmt.printf("Steps: [%d, %d, %d, %d]\n", data[0], data[1], data[2], data[3])
	} else {
		fmt.eprintf("ERROR: Failed to map async result buffer: %v\n", result)
	}
}
