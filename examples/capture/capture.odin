package capture

// Core
import "base:runtime"
import "core:fmt"

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
	align := cast(uint)wgpu.COPY_BYTES_PER_ROW_ALIGNMENT
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
	if instance_err != nil do return
	defer wgpu.instance_release(&instance)

	adapter, adapter_err := wgpu.instance_request_adapter(
		&instance,
		&{compatible_surface = nil, power_preference = .High_Performance},
	)
	if adapter_err != nil do return
	defer wgpu.adapter_release(&adapter)

	device_descriptor := wgpu.Device_Descriptor {
		label = adapter.info.name,
	}

	device, queue, device_err := wgpu.adapter_request_device(&adapter, &device_descriptor)
	if device_err != nil do return
	defer {
		wgpu.queue_release(&queue)
		wgpu.device_release(&device)
	}

	buffer_dimensions := Buffer_Dimensions{}
	buffer_dimensions_init(&buffer_dimensions, Width, Height)

	fmt.printf("%#v\n", buffer_dimensions)

	buffer_size := buffer_dimensions.padded_bytes_per_row * buffer_dimensions.height

	output_buffer, output_buffer_err := wgpu.device_create_buffer(
		&device,
		&wgpu.Buffer_Descriptor {
			label = "Buffer output",
			size = cast(u64)buffer_size,
			usage = {.Map_Read, .Copy_Dst},
			mapped_at_creation = false,
		},
	)
	if output_buffer_err != nil do return
	defer wgpu.buffer_release(&output_buffer)

	texture_extent := wgpu.Extent_3D {
		width                 = cast(u32)buffer_dimensions.width,
		height                = cast(u32)buffer_dimensions.height,
		depth_or_array_layers = 1,
	}

	texture, texture_err := wgpu.device_create_texture(
		&device,
		&wgpu.Texture_Descriptor {
			label = "Texture",
			size = texture_extent,
			mip_level_count = 1,
			sample_count = 1,
			dimension = .D2,
			format = .Rgba8_Unorm_Srgb,
			usage = {.Render_Attachment, .Copy_Src},
		},
	)
	if texture_err != nil do return
	defer wgpu.texture_release(&texture)

	texture_view, texture_view_err := wgpu.texture_create_view(&texture, nil)
	if texture_view_err != nil do return
	defer wgpu.texture_view_release(&texture_view)

	command_encoder, command_encoder_err := wgpu.device_create_command_encoder(
		&device,
		&{label = "command_encoder"},
	)
	if command_encoder_err != nil do return
	defer wgpu.command_encoder_release(&command_encoder)

	colors: []wgpu.Render_Pass_Color_Attachment = {
		{
			view = texture_view.ptr,
			load_op = .Clear,
			store_op = .Store,
			clear_value = {1.0, 0.0, 0.0, 1.0},
		},
	}

	render_pass := wgpu.command_encoder_begin_render_pass(
		&command_encoder,
		&{label = "render_pass", color_attachments = colors},
	)
	if wgpu.render_pass_encoder_end(&render_pass) != nil do return
	wgpu.render_pass_encoder_release(&render_pass)

	wgpu.command_encoder_copy_texture_to_buffer(
		&command_encoder,
		&{texture = texture.ptr, mip_level = 0, origin = {}, aspect = .All},
		&{
			buffer = output_buffer.ptr,
			layout = {
				offset = 0,
				bytes_per_row = cast(u32)buffer_dimensions.padded_bytes_per_row,
				rows_per_image = wgpu.COPY_STRIDE_UNDEFINED,
			},
		},
		&texture_extent,
	)

	command_buffer, command_buffer_err := wgpu.command_encoder_finish(&command_encoder)
	if command_buffer_err != nil do return
	defer wgpu.command_buffer_release(&command_buffer)

	wgpu.queue_submit(&queue, command_buffer.ptr)

	handle_buffer_map := proc "c" (status: wgpu.Buffer_Map_Async_Status, user_data: rawptr) {
		context = runtime.default_context()
		fmt.printf("Buffer map status: %v\n", status)
	}
	wgpu.buffer_map_async(&output_buffer, {.Read}, handle_buffer_map, nil, 0, buffer_size)

	_, res_err := wgpu.device_poll(&device)
	if res_err != nil do return

	data, data_err := wgpu.buffer_get_const_mapped_range(&output_buffer, byte, 0, buffer_size)
	if data_err != nil do return

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
