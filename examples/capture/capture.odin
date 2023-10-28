package capture

// Core
import "core:fmt"
import "core:runtime"

// Vendor
import "vendor:stb/image"

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

Buffer_Dimensions :: struct {
    width:                  uint,
    height:                 uint,
    unpadded_bytes_per_row: uint,
    padded_bytes_per_row:   uint,
}

buffer_dimensions_init :: proc(r: ^Buffer_Dimensions, width, height: uint) {
    bytes_per_pixel := size_of(u32(0))
    unpadded_bytes_per_row := width * cast(uint)bytes_per_pixel
    align := cast(uint)wgpu.Copy_Bytes_Per_Row_Alignment
    padded_bytes_per_row_padding := (align - (unpadded_bytes_per_row % align)) % align
    padded_bytes_per_row := unpadded_bytes_per_row + padded_bytes_per_row_padding

    r.width = width
    r.height = height
    r.unpadded_bytes_per_row = unpadded_bytes_per_row
    r.padded_bytes_per_row = padded_bytes_per_row
}

Width: uint : 100
Height: uint : 200

main :: proc() {
    instance_descriptor := wgpu.Instance_Descriptor {
        backends = wgpu.Instance_Backend_Primary,
    }

    instance, instance_err := wgpu.create_instance(&instance_descriptor)
    if instance_err != .No_Error {
        fmt.eprintln("ERROR Creating Instance:", wgpu.get_error_message())
        return
    }
    defer instance->release()

    adapter, adapter_err := instance->request_adapter(
        &{compatible_surface = nil, power_preference = .High_Performance},
    )
    if adapter_err != .No_Error {
        fmt.eprintln("ERROR Couldn't Request Adapter:", wgpu.get_error_message())
        return
    }
    defer adapter->release()

    device_descriptor := wgpu.Device_Descriptor {
        label = adapter.info.name,
    }

    device, device_err := adapter->request_device(&device_descriptor)
    if device_err != .No_Error {
        fmt.eprintln("ERROR Couldn't Request Adapter:", wgpu.get_error_message())
        return
    }
    defer device->release()

    device->set_uncaptured_error_callback(
        proc "c" (type: wgpu.Error_Type, message: cstring, user_data: rawptr) {
            context = runtime.default_context()
            fmt.eprintln("ERROR: ", message)
        },
        nil,
    )

    buffer_dimensions := Buffer_Dimensions{}
    buffer_dimensions_init(&buffer_dimensions, Width, Height)

    fmt.printf("%#v\n\n", buffer_dimensions)

    buffer_size := buffer_dimensions.padded_bytes_per_row * buffer_dimensions.height

    output_buffer, output_buffer_err := device->create_buffer(
        &wgpu.Buffer_Descriptor{
            label = "Buffer output",
            size = cast(u64)buffer_size,
            usage = {.Map_Read, .Copy_Dst},
            mapped_at_creation = false,
        },
    )
    if output_buffer_err != .No_Error do return
    defer output_buffer->release()

    texture_extent := wgpu.Extent_3D {
        width                 = cast(u32)buffer_dimensions.width,
        height                = cast(u32)buffer_dimensions.height,
        depth_or_array_layers = 1,
    }

    texture, texture_err := device->create_texture(
        &wgpu.Texture_Descriptor{
            label = "Texture",
            size = texture_extent,
            mip_level_count = 1,
            sample_count = 1,
            dimension = .D2,
            format = .Rgba8_Unorm_Srgb,
            usage = {.Render_Attachment, .Copy_Src},
        },
    )
    if texture_err != .No_Error do return
    defer texture->release()

    texture_view, texture_view_err := texture->create_view(nil)
    if texture_view_err != .No_Error do return
    defer texture_view->release()

    command_encoder, command_encoder_err := device->create_command_encoder(
        &{label = "command_encoder"},
    )
    if command_encoder_err != .No_Error do return
    defer command_encoder->release()

    colors: []wgpu.Render_Pass_Color_Attachment = {
        {
            view = &texture_view,
            load_op = .Clear,
            store_op = .Store,
            clear_value = {1.0, 0.0, 0.0, 1.0},
        },
    }

    render_pass_encoder := command_encoder->begin_render_pass(
        &{label = "render_pass_encoder", color_attachments = colors},
    )
    if render_pass_encoder->end() != .No_Error do return
    render_pass_encoder->release()

    command_encoder->copy_texture_to_buffer(
        &{texture = &texture, mip_level = 0, origin = {}, aspect = .All},
        &{
            buffer = &output_buffer,
            layout = {
                offset = 0,
                bytes_per_row = cast(u32)buffer_dimensions.padded_bytes_per_row,
                rows_per_image = cast(u32)wgpu.Copy_Stride_Undefined,
            },
        },
        &texture_extent,
    )

    command_buffer, command_buffer_err := command_encoder->finish()
    if command_buffer_err != .No_Error do return
    defer command_buffer->release()

    device.queue->submit(command_buffer)

    data, data_err := output_buffer->map_read()
    if data_err != .Success do return

    /* Async version:
    handle_buffer_map := proc "c" (
        status: wgpu.Buffer_Map_Async_Status,
        user_data: rawptr,
    ) {
        context = runtime.default_context()
        fmt.printf("Buffer map status: %v\n", status)
    }
    output_buffer->map_async({.Read}, handle_buffer_map, nil, 0, buffer_size)
    device->poll(true, nil)

    data := output_buffer->get_const_mapped_range(0, buffer_size)
    */

    result := image.write_png(
        "red.png",
        cast(i32)buffer_dimensions.width,
        cast(i32)buffer_dimensions.height,
        4,
        raw_data(data),
        cast(i32)buffer_dimensions.padded_bytes_per_row,
    )

    if result == 0 {
        fmt.eprintln("ERROR: Image writing failed!")
    }
}
