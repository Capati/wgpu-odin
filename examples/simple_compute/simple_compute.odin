package simple_compute

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
    // Instance
    instance_descriptor := wgpu.Instance_Descriptor {
        backends = wgpu.Instance_Backend_Primary,
    }

    instance := wgpu.create_instance(&instance_descriptor)
    defer instance->release()

    // Adapter
    adapter, adapter_err := instance->request_adapter(
        &{compatible_surface = nil, power_preference = .High_Performance},
    )
    if adapter_err != .No_Error {
        fmt.eprintln("ERROR Couldn't Request Adapter:", wgpu.get_error_message())
        return
    }
    defer adapter->release()

    // Device
    device_options := wgpu.Device_Options {
        label = adapter.info.name,
    }

    device, device_err := adapter->request_device(&device_options)
    if device_err != .No_Error {
        fmt.eprintln("ERROR Couldn't Request Adapter:", wgpu.get_error_message())
        return
    }
    defer device->release()

    device->set_uncaptured_error_callback(proc "c" (type: wgpu.Error_Type, message: cstring, user_data: rawptr) {
        context = runtime.default_context()
        fmt.eprintln("ERROR:", message)
    }, nil)

    // Shader module
    module, module_err := device->load_wgsl_shader_module(
        "assets/simple_compute.wgsl",
        "Simple compute module",
    )
    if module_err != .No_Error do return
    defer module->release()

    pipeline, pipeline_err := device->create_compute_pipeline(
        &wgpu.Compute_Pipeline_Descriptor{
            label = "Simple compute pipeline",
            layout = nil,
            compute = {module = &module, entry_point = "computeSomething"},
        },
    )
    if pipeline_err != .No_Error do return
    defer pipeline->release()

    input_data := []f32{1.0, 3.0, 5.0}
    input_size := cast(u64)len(input_data)

    work_buffer, work_buffer_err := device->create_buffer(
        &{
            label = "Work buffer",
            size = cast(u64)(input_size * size_of(f32)),
            usage = {.Storage, .Copy_Src, .Copy_Dst},
        },
    )
    if work_buffer_err != .No_Error do return
    defer work_buffer->release()

    result_buffer, result_buffer_err := device->create_buffer(
        &{
            label = "Result Buffer",
            size = work_buffer.size,
            usage = {.Map_Read, .Copy_Dst},
        },
    )
    if result_buffer_err != .No_Error do return
    defer result_buffer->release()

    bind_group_layout := pipeline->get_bind_group_layout(0)
    defer bind_group_layout->release()

    // Setup a bindGroup to tell the shader which
    // buffer to use for the computation
    bind_group, bind_group_err := device->create_bind_group(
        &{
            layout = &bind_group_layout,
            entries = {
                {
                    binding = 0,
                    buffer = work_buffer.ptr,
                    offset = 0,
                    size = work_buffer.size,
                },
            },
            label = "bindGroup for work buffer",
        },
    )
    if bind_group_err != .No_Error do return
    defer bind_group->release()

    encoder, encoder_err := device->create_command_encoder(
        &wgpu.Command_Encoder_Descriptor{label = "Command Encoder"},
    )
    if encoder_err != .No_Error do return
    defer encoder->release()

    compute_pass := encoder->begin_compute_pass(&{label = "doubling compute pass"})
    defer compute_pass->release()

    compute_pass->set_pipeline(&pipeline)
    compute_pass->set_bind_group(0, &bind_group)
    compute_pass->dispatch_workgroups(cast(u32)input_size)
    compute_pass->end()

    // Encode a command to copy the results to a mappable buffer.
    encoder->copy_buffer_to_buffer(work_buffer, 0, result_buffer, 0, result_buffer.size)

    command_buffer, command_buffer_err := encoder->finish()
    if command_buffer_err != .No_Error {
        fmt.panicf("%v", command_buffer_err)
    }
    defer command_buffer->release()

    device.queue->write_buffer(&work_buffer, 0, wgpu.to_bytes(input_data))
    device.queue->submit(command_buffer)

    data, status := result_buffer->map_read()

    if status == .Success {
        result_data := wgpu.from_bytes([]f32, data)

        for v, i in input_data {
            fmt.printf("input %.1f became %.1f\n", v, result_data[i])
        }
    } else {
        fmt.eprintf("ERROR: Failed to map async result buffer: %v\n", status)
    }
}
