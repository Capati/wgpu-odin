package compute

// Core
import "core:fmt"
import "core:runtime"

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
    instance, instance_err := wgpu.create_instance(
        &{backends = wgpu.Instance_Backend_Primary},
    )
    if instance_err != .No_Error {
        fmt.eprintln("ERROR Creating Instance:", wgpu.get_error_message())
        return
    }
    defer instance->release()

    // Instantiates the general connection to the GPU
    adapter, adapter_err := instance->request_adapter(
        &{compatible_surface = nil, power_preference = .High_Performance},
    )
    if adapter_err != .No_Error {
        fmt.eprintln("ERROR Couldn't Request Adapter:", wgpu.get_error_message())
        return
    }
    defer adapter->release()

    // Instantiates the feature specific connection to the GPU, defining some parameters,
    // `features` being the available features.
    device, device_err := adapter->request_device(&{label = adapter.info.name})
    if device_err != .No_Error {
        fmt.eprintln("ERROR Couldn't Request Adapter:", wgpu.get_error_message())
        return
    }
    defer device->release()

    device->set_uncaptured_error_callback(
        proc "c" (type: wgpu.Error_Type, message: cstring, user_data: rawptr) {
            context = runtime.default_context()
            fmt.eprintln("ERROR:", message)
        },
        nil,
    )

    // Shader module
    shader_module, shader_module_err := device->load_wgsl_shader_module(
        "assets/compute.wgsl",
        "Compute module",
    )
    if shader_module_err != .No_Error do return
    defer shader_module->release()

    // Instantiates buffer without data.
    // `usage` of buffer specifies how it can be used:
    //   `Map_Read` allows it to be read (outside the shader).
    //   `Copy_Dst` allows it to be the destination of the copy.
    staging_buffer, staging_buffer_err := device->create_buffer(
        &{
            label = "staging_buffer",
            size = cast(u64)numbers_size,
            usage = {.Map_Read, .Copy_Dst},
        },
    )
    if staging_buffer_err != .No_Error do return
    defer staging_buffer->release()

    // Instantiates buffer with data (`numbers`).
    // Usage allowing the buffer to be:
    //   A storage buffer (can be bound within a bind group and thus available to a
    // shader).
    //   The destination of a copy.
    //   The source of a copy.
    storage_buffer, storage_buffer_err := device->create_buffer(
        &{
            label = "storage_buffer",
            size = cast(u64)numbers_size,
            usage = {.Storage, .Copy_Src, .Copy_Dst},
        },
    )
    if storage_buffer_err != .No_Error do return
    defer storage_buffer->release()

    // A bind group defines how buffers are accessed by shaders.
    // It is to WebGPU what a descriptor set is to Vulkan.
    // `binding` here refers to the `binding` of a buffer in the shader (`layout(set = 0,
    // binding = 0) buffer`).

    // A pipeline specifies the operation of a shader

    // Instantiates the pipeline.
    compute_pipeline, compute_pipeline_err := device->create_compute_pipeline(
        &wgpu.Compute_Pipeline_Descriptor{
            label = "compute_pipeline",
            layout = nil,
            compute = {module = &shader_module, entry_point = "main"},
        },
    )
    if compute_pipeline_err != .No_Error do return
    defer compute_pipeline->release()

    // Instantiates the bind group, once again specifying the binding of buffers.
    bind_group_layout, bind_group_layout_err := compute_pipeline->get_bind_group_layout(
        0,
    )
    if bind_group_layout_err != .No_Error {
        fmt.eprintln("ERROR Couldn't Get Bind Group Layout: ", wgpu.get_error_message())
        return
    }
    defer bind_group_layout->release()

    // Setup a bindGroup to tell the shader which
    // buffer to use for the computation
    bind_group, bind_group_err := device->create_bind_group(
        &{
            layout = &bind_group_layout,
            entries = {
                {
                    binding = 0,
                    resource = wgpu.Buffer_Binding {
                    buffer = &storage_buffer,
                    offset = 0,
                    size = storage_buffer.size,
                    },
                },
            },
            label = "bind_group_layout",
        },
    )
    if bind_group_err != .No_Error do return
    defer bind_group->release()

    // A command encoder executes one or many pipelines.
    // It is to WebGPU what a command buffer is to Vulkan.
    encoder, encoder_err := device->create_command_encoder(
        &wgpu.Command_Encoder_Descriptor{label = "command_encoder"},
    )
    if encoder_err != .No_Error do return
    defer encoder->release()

    compute_pass, compute_pass_err := encoder->begin_compute_pass(
        &{label = "compute_pass"},
    )
    if compute_pass_err != .No_Error {
        fmt.eprintln("ERROR Couldn't Begin Compute Pass: ", wgpu.get_error_message())
        return
    }
    defer compute_pass->release()

    compute_pass->set_pipeline(&compute_pipeline)
    compute_pass->set_bind_group(0, &bind_group)
    compute_pass->dispatch_workgroups(numbers_length)
    compute_pass->end()

    // Sets adds copy operation to command encoder.
    // Will copy data from storage buffer on GPU to staging buffer on CPU.
    encoder->copy_buffer_to_buffer(
        storage_buffer,
        0,
        staging_buffer,
        0,
        staging_buffer.size,
    )

    // Submits command encoder for processing
    command_buffer, command_buffer_err := encoder->finish()
    if command_buffer_err != .No_Error {
        fmt.panicf("%v", command_buffer_err)
    }
    defer command_buffer->release()

    device.queue->write_buffer(&storage_buffer, 0, wgpu.to_bytes(numbers))
    device.queue->submit(command_buffer)

    data, status := staging_buffer->map_read()

    if status == .Success {
        buf := wgpu.from_bytes([]u32, data)
        fmt.printf("Steps: [%d, %d, %d, %d]\n", buf[0], buf[1], buf[2], buf[3])
    } else {
        fmt.eprintf("ERROR: Failed to map async result buffer: %v\n", status)
    }
}
