#+build !js
package capture

// Core
import "base:runtime"
import "core:fmt"

// Vendor
import "vendor:stb/image"

// Local packages
import wgpu "../.."

_log_callback :: proc "c" (level: wgpu.LogLevel, message: string, user_data: rawptr) {
	context = runtime.default_context()
	fmt.eprintf("[wgpu] [%v] %s\n\n", level, message)
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

IMAGE_WIDTH :: 100
IMAGE_HEIGHT :: 200

main :: proc() {
	wgpu.SetLogCallback(_log_callback, nil)
	wgpu.SetLogLevel(.Warn)

	instance_descriptor := wgpu.InstanceDescriptor {
		backends = wgpu.BACKENDS_PRIMARY,
	}

	instance := wgpu.CreateInstance(instance_descriptor)
	defer wgpu.InstanceRelease(instance)

	adapter_res := wgpu.InstanceRequestAdapterSync(
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

	device_descriptor := wgpu.DeviceDescriptor {
		label = adapter_info.description,
	}

	device_res := wgpu.AdapterRequestDeviceSync(adapter, device_descriptor)
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

	buffer_dimensions: Buffer_Dimensions
	buffer_dimensions_init(&buffer_dimensions, IMAGE_WIDTH, IMAGE_HEIGHT)

	fmt.printf("%#v\n", buffer_dimensions)

	buffer_size := buffer_dimensions.padded_bytes_per_row * buffer_dimensions.height

	output_buffer := wgpu.DeviceCreateBuffer(
		device,
		wgpu.BufferDescriptor {
			label            = "Buffer output",
			size             = cast(u64)buffer_size,
			usage            = {.MapRead, .CopyDst},
			mappedAtCreation = false,
		},
	)

	texture_extent := wgpu.Extent3D {
		width              = cast(u32)buffer_dimensions.width,
		height             = cast(u32)buffer_dimensions.height,
		depthOrArrayLayers = 1,
	}

	texture := wgpu.DeviceCreateTexture(
		device,
		wgpu.TextureDescriptor {
			label         = "Texture",
			size          = texture_extent,
			mipLevelCount = 1,
			sampleCount   = 1,
			dimension     = ._2D,
			format        = .RGBA8UnormSrgb,
			usage         = {.RenderAttachment, .CopySrc},
		},
	)
	defer wgpu.TextureRelease(texture)

	texture_view := wgpu.TextureCreateView(texture)
	defer wgpu.TextureViewRelease(texture_view)

	command_encoder := wgpu.DeviceCreateCommandEncoder(
		device,
		wgpu.CommandEncoderDescriptor{label = "command_encoder"},
	)
	defer wgpu.CommandEncoderRelease(command_encoder)

	colors: []wgpu.RenderPassColorAttachment = {
		{view = texture_view, ops = {.Clear, .Store, {1.0, 0.0, 0.0, 1.0}}},
	}

	render_pass := wgpu.CommandEncoderBeginRenderPass(
		command_encoder,
		{label = "render_pass", colorAttachments = colors},
	)
	wgpu.RenderPassEnd(render_pass)
	wgpu.RenderPassRelease(render_pass)

	wgpu.CommandEncoderCopyTextureToBuffer(
		command_encoder,
		{texture = texture, mipLevel = 0, origin = {}, aspect = .All},
		{
			buffer = output_buffer,
			layout = {
				offset = 0,
				bytesPerRow = cast(u32)buffer_dimensions.padded_bytes_per_row,
				rowsPerImage = wgpu.COPY_STRIDE_UNDEFINED,
			},
		},
		texture_extent,
	)

	command_buffer := wgpu.CommandEncoderFinish(command_encoder)
	defer wgpu.CommandBufferRelease(command_buffer)

	wgpu.QueueSubmit(queue, { command_buffer })

	Buffer_Map_Context :: struct {
		buffer:     wgpu.Buffer,
		dimensions: Buffer_Dimensions,
	}

	handle_buffer_map := proc "c" (
		status: wgpu.MapAsyncStatus,
		message: string,
		userdata1: rawptr,
		userdata2: rawptr,
	) {
		context = runtime.default_context()

		fmt.printfln("Buffer map status: %v", status)
		if status != .Success {
			return
		}

		buffer_map := cast(^Buffer_Map_Context)userdata1
		defer wgpu.BufferRelease(buffer_map.buffer)

		data_view := wgpu.BufferGetMappedRangeSlice(buffer_map.buffer, []byte)

		result := image.write_png(
			"red.png",
			i32(buffer_map.dimensions.width),
			i32(buffer_map.dimensions.height),
			4,
			raw_data(data_view.data),
			i32(buffer_map.dimensions.padded_bytes_per_row),
		)

		if result == 0 {
			fmt.eprintfln("ERROR: Image writing failed: %s", image.failure_reason())
		}
	}

	buffer_map := Buffer_Map_Context{output_buffer, buffer_dimensions}
	wgpu.BufferMapAsync(
		output_buffer,
		{.Read},
		{start = 0, end = u64(buffer_size)},
		{callback = handle_buffer_map, userdata1 = &buffer_map},
	)

	wgpu.DevicePoll(device)
}
