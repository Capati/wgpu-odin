package capture

// STD Library
import "base:runtime"
import "core:fmt"

// Vendor
import "vendor:stb/image"

// Local packages
import wgpu "../../wrapper"

_log_callback :: proc "c" (level: wgpu.Log_Level, message: cstring, user_data: rawptr) {
	context = runtime.default_context()
	fmt.eprintf("[wgpu] [%v] %s\n\n", level, message)
}

Buffer_Dimensions :: struct {
	width                  : uint,
	height                 : uint,
	unpadded_bytes_per_row : uint,
	padded_bytes_per_row   : uint,
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

IMAGE_WIDTH  : uint : 100
IMAGE_HEIGHT : uint : 200

run :: proc() -> (ok: bool) {
	wgpu.set_log_callback(_log_callback, nil)
	wgpu.set_log_level(.Warn)

	instance_descriptor := wgpu.Instance_Descriptor {
		backends = wgpu.Instance_Backend_Primary,
	}

	instance := wgpu.create_instance(instance_descriptor) or_return
	defer wgpu.instance_release(instance)

	adapter := wgpu.instance_request_adapter(
		instance,
		{compatible_surface = nil, power_preference = .High_Performance},
	) or_return
	defer wgpu.adapter_release(adapter)

	adapter_info := wgpu.adapter_get_info(adapter) or_return

	device_descriptor := wgpu.Device_Descriptor {
		label = adapter_info.name,
	}

	device := wgpu.adapter_request_device(adapter, device_descriptor) or_return
	defer wgpu.device_release(device)

	queue := wgpu.device_get_queue(device)
	defer wgpu.queue_release(queue)

	buffer_dimensions := Buffer_Dimensions{}
	buffer_dimensions_init(&buffer_dimensions, IMAGE_WIDTH, IMAGE_HEIGHT)

	fmt.printf("%#v\n", buffer_dimensions)

	buffer_size := buffer_dimensions.padded_bytes_per_row * buffer_dimensions.height

	output_buffer := wgpu.device_create_buffer(
		device,
		wgpu.Buffer_Descriptor {
			label              = "Buffer output",
			size               = cast(u64)buffer_size,
			usage              = {.Map_Read, .Copy_Dst},
			mapped_at_creation = false,
		},
	) or_return

	texture_extent := wgpu.Extent_3D {
		width                 = cast(u32)buffer_dimensions.width,
		height                = cast(u32)buffer_dimensions.height,
		depth_or_array_layers = 1,
	}

	texture := wgpu.device_create_texture(
		device,
		wgpu.Texture_Descriptor {
			label           = "Texture",
			size            = texture_extent,
			mip_level_count = 1,
			sample_count    = 1,
			dimension       = .D2,
			format          = .Rgba8_Unorm_Srgb,
			usage           = {.Render_Attachment, .Copy_Src},
		},
	) or_return
	defer wgpu.texture_release(texture)

	texture_view := wgpu.texture_create_view(texture) or_return
	defer wgpu.texture_view_release(texture_view)

	command_encoder := wgpu.device_create_command_encoder(
		device,
		wgpu.Command_Encoder_Descriptor{label = "command_encoder"},
	) or_return
	defer wgpu.command_encoder_release(command_encoder)

	colors: []wgpu.Render_Pass_Color_Attachment = {
		{
			view        = texture_view,
			load_op     = .Clear,
			store_op    = .Store,
			clear_value = {1.0, 0.0, 0.0, 1.0},
		},
	}

	render_pass := wgpu.command_encoder_begin_render_pass(
		command_encoder,
		{label = "render_pass", color_attachments = colors},
	)
	wgpu.render_pass_end(render_pass) or_return
	wgpu.render_pass_release(render_pass)

	wgpu.command_encoder_copy_texture_to_buffer(
		command_encoder,
		{texture = texture, mip_level = 0, origin = {}, aspect = .All},
		{
			buffer = output_buffer,
			layout = {
				offset = 0,
				bytes_per_row = cast(u32)buffer_dimensions.padded_bytes_per_row,
				rows_per_image = wgpu.COPY_STRIDE_UNDEFINED,
			},
		},
		texture_extent,
	) or_return

	command_buffer := wgpu.command_encoder_finish(command_encoder) or_return
	defer wgpu.command_buffer_release(command_buffer)

	wgpu.queue_submit(queue, command_buffer)

	Buffer_Map_Context :: struct {
		buffer     : wgpu.Buffer,
		dimensions : Buffer_Dimensions,
	}

	handle_buffer_map := proc "c" (status: wgpu.Buffer_Map_Async_Status, user_data: rawptr) {
		context = runtime.default_context()

		fmt.printfln("Buffer map status: %v", status)
		if status != .Success do return

		buffer_map := cast(^Buffer_Map_Context)user_data
		defer wgpu.buffer_release(buffer_map.buffer)

		data, data_ok := wgpu.buffer_get_const_mapped_range(buffer_map.buffer)
		if !data_ok {
			fmt.eprintln("ERROR: Failed to get data from buffer")
			return
		}

		result := image.write_png(
			"red.png",
			cast(i32)buffer_map.dimensions.width,
			cast(i32)buffer_map.dimensions.height,
			4,
			raw_data(data),
			cast(i32)buffer_map.dimensions.padded_bytes_per_row,
		)

		if result == 0 {
			fmt.eprintfln("ERROR: Image writing failed: %s", image.failure_reason())
		}
	}

	buffer_map := Buffer_Map_Context{output_buffer, buffer_dimensions}
	wgpu.buffer_map_async(
		output_buffer,
		{.Read},
		handle_buffer_map,
		&buffer_map,
		{offset = 0, size = u64(buffer_size)},
	) or_return

	wgpu.device_poll(device)

	return true
}

main :: proc() {
	run()
}
