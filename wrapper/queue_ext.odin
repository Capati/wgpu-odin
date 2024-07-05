package wgpu

// Base
import "base:runtime"

// Core
import "core:fmt"
import "core:image"
import "core:mem"
import "core:slice"
import "core:strings"

// Vendor
import stbi "vendor:stb/image"

Load_Method :: enum {
	Default, // 8-bit channels
	Load_16,
	Load_F32,
}

Texture_Creation_Options :: struct {
	label:            string,
	srgb:             bool,
	usage:            Texture_Usage_Flags,
	preferred_format: Maybe(Texture_Format),
	load_method:      Load_Method,
}

Image_Data_Type :: union {
	[]byte,
	[]u16,
	[]f32,
}

Image_Data :: struct {
	width:             int,
	height:            int,
	channels:          int,
	bytes_per_channel: int,
	is_float:          bool,
	data:              Image_Data_Type,
}

queue_copy_image_to_texture_image_data :: proc(
	self: ^Device,
	queue: ^Queue,
	data: ^Image_Data,
	options: Texture_Creation_Options = {},
	loc := #caller_location,
) -> (
	texture: Texture,
	err: Error,
) {
	options := options

	width, height := data.width, data.height

	// Default texture usage if none is given
	if options.usage == {} {
		options.usage = {.Texture_Binding, .Copy_Dst, .Render_Attachment}
	}

	// Determine the texture format based on the image data
	format := _determine_texture_format(data, options)

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	label: cstring = nil
	if options.label != "" {
		label = strings.clone_to_cstring(options.label, context.temp_allocator) or_return
	}

	// Create the texture
	texture_desc := Texture_Descriptor {
		label = label,
		size = {width = u32(width), height = u32(height), depth_or_array_layers = 1},
		mip_level_count = 1,
		sample_count = 1,
		dimension = .D2,
		format = format,
		usage = options.usage,
	}
	texture = device_create_texture(self, &texture_desc) or_return
	defer if err != nil do texture_release(&texture)

	// Get block size for the determined format
	block_size := texture_format_block_size(format)

	// Calculate bytes per row, ensuring it meets the WGPU alignment requirements
	bytes_per_row :=
		((u32(width) * block_size + COPY_BYTES_PER_ROW_ALIGNMENT - 1) &
			~(COPY_BYTES_PER_ROW_ALIGNMENT - 1))

	// Prepare image data for upload
	image_copy_texture := texture_as_image_copy(&texture)
	texture_data_layout := Texture_Data_Layout {
		offset         = 0,
		bytes_per_row  = bytes_per_row,
		rows_per_image = u32(height),
	}

	// Convert image data if necessary
	pixels_to_upload := _convert_image_data(
		data,
		format,
		bytes_per_row,
		context.temp_allocator,
	) or_return

	// Copy image data to texture
	queue_write_texture(
		queue,
		&image_copy_texture,
		pixels_to_upload,
		&texture_data_layout,
		&texture_desc.size,
	) or_return

	return
}

queue_copy_image_to_texture_image_path :: proc(
	self: ^Device,
	queue: ^Queue,
	image_path: string,
	options: Texture_Creation_Options = {},
	loc := #caller_location,
) -> (
	texture: Texture,
	err: Error,
) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	// Load the image
	width, height, channels: i32
	data: rawptr
	c_image_path := strings.clone_to_cstring(image_path, context.temp_allocator) or_return

	bytes_per_channel: int
	is_float: bool

	switch options.load_method {
	case .Default:
		data = stbi.load(c_image_path, &width, &height, &channels, 0)
		bytes_per_channel = 1
	case .Load_16:
		data = stbi.load_16(c_image_path, &width, &height, &channels, 0)
		bytes_per_channel = 2
	case .Load_F32:
		data = stbi.loadf(c_image_path, &width, &height, &channels, 0)
		bytes_per_channel = 4
		is_float = true
	}

	if data == nil {
		err = .Load_Image_Failed
		set_and_update_err_data(
			self._err_data,
			.File_System,
			err,
			fmt.tprintf("Failed to load image '%s': %s", image_path, stbi.failure_reason()),
			loc,
		)
		return
	}
	defer stbi.image_free(data)

	total_size := int(width * height * channels)

	typed_data: Image_Data_Type

	switch options.load_method {
	case .Default:
		typed_data = mem.slice_ptr(cast([^]byte)data, total_size)
	case .Load_16:
		typed_data = mem.slice_ptr(cast([^]u16)data, total_size)
	case .Load_F32:
		typed_data = mem.slice_ptr(cast([^]f32)data, total_size)
	}

	image_data := Image_Data {
		width             = int(width),
		height            = int(height),
		channels          = int(channels),
		bytes_per_channel = bytes_per_channel,
		is_float          = is_float,
		data              = typed_data,
	}

	texture = queue_copy_image_to_texture_image_data(
		self,
		queue,
		&image_data,
		options,
		loc,
	) or_return

	return
}

queue_copy_image_to_texture_image :: proc(
	self: ^Device,
	queue: ^Queue,
	image: ^image.Image,
	options: Texture_Creation_Options = {},
	loc := #caller_location,
) -> (
	texture: Texture,
	err: Error,
) {
	bytes_per_channel := 1
	if image.depth > 8 {
		bytes_per_channel = 2
	}

	total_size := image.width * image.height * image.channels

	typed_data: Image_Data_Type
	if bytes_per_channel == 1 {
		typed_data = mem.slice_ptr(raw_data(image.pixels.buf[:]), total_size)
	} else {
		typed_data = mem.slice_ptr(cast([^]u16)raw_data(image.pixels.buf[:]), total_size)
	}

	image_data := Image_Data {
		width             = image.width,
		height            = image.height,
		channels          = image.channels,
		bytes_per_channel = bytes_per_channel,
		data              = typed_data,
	}

	texture = queue_copy_image_to_texture_image_data(
		self,
		queue,
		&image_data,
		options,
		loc,
	) or_return

	return
}

queue_copy_image_to_texture :: proc {
	queue_copy_image_to_texture_image_path,
	queue_copy_image_to_texture_image,
}

@(private = "file")
_determine_texture_format :: proc(
	data: ^Image_Data,
	options: Texture_Creation_Options,
) -> Texture_Format {
	if f, ok := options.preferred_format.?; ok {
		return f
	}

	format: Texture_Format

	// NOTE: 3 channels will be converted to rgba later

	if data.is_float {
		switch data.channels {
		case 1:
			format = .R32_Float
		case 2:
			format = .Rg32_Float
		case 3, 4:
			format = .Rgba32_Float
		}
	} else {
		switch data.channels {
		case 1:
			format = .R8_Unorm if data.bytes_per_channel == 1 else .R16_Uint
		case 2:
			format = .Rg8_Unorm if data.bytes_per_channel == 1 else .Rg16_Uint
		case 3, 4:
			format = .Rgba8_Unorm if data.bytes_per_channel == 1 else .Rgba16_Uint
		}
	}

	return format
}

@(private = "file")
_convert_image_data :: proc(
	image_data: ^Image_Data,
	format: Texture_Format,
	aligned_bytes_per_row: u32,
	allocator := context.allocator,
) -> (
	data: []byte,
	err: Error,
) {
	bytes_per_pixel := image_data.channels * image_data.bytes_per_channel

	if image_data.channels == 3 {
		// Convert RGB to RGBA
		new_bytes_per_pixel := 4 * image_data.bytes_per_channel
		data = make([]byte, int(aligned_bytes_per_row) * image_data.height, allocator) or_return

		switch src in image_data.data {
		case []byte:
			for y in 0 ..< image_data.height {
				for x in 0 ..< image_data.width {
					src_idx := (y * image_data.width + x) * bytes_per_pixel
					dst_idx := y * int(aligned_bytes_per_row) + x * new_bytes_per_pixel
					copy(data[dst_idx:], src[src_idx:src_idx + bytes_per_pixel])
					data[dst_idx + 3] = 255 // Full alpha for 8-bit
				}
			}
		case []u16:
			for y in 0 ..< image_data.height {
				for x in 0 ..< image_data.width {
					src_idx := (y * image_data.width + x) * image_data.channels
					dst_idx := y * int(aligned_bytes_per_row) + x * 4 * 2
					for j in 0 ..< 3 {
						(^u16)(&data[dst_idx + j * 2])^ = src[src_idx + j]
					}
					(^u16)(&data[dst_idx + 6])^ = 65535 // Full alpha for 16-bit
				}
			}
		case []f32:
			for y in 0 ..< image_data.height {
				for x in 0 ..< image_data.width {
					src_idx := (y * image_data.width + x) * image_data.channels
					dst_idx := y * int(aligned_bytes_per_row) + x * 4 * 4
					for j in 0 ..< 3 {
						(^f32)(&data[dst_idx + j * 4])^ = src[src_idx + j]
					}
					(^f32)(&data[dst_idx + 12])^ = 1.0 // Full alpha for float
				}
			}
		}
	} else {
		// Check if the source data is already properly aligned
		src_bytes_per_row := u32(image_data.width * bytes_per_pixel)
		if src_bytes_per_row == aligned_bytes_per_row {
			// If already aligned, we can simply reinterpret the data
			switch src in image_data.data {
			case []byte:
				data = src
			case []u16:
				data = slice.reinterpret([]byte, src)
			case []f32:
				data = slice.reinterpret([]byte, src)
			}
			return
		}

		// If not converting, create a byte slice of the data with proper alignment
		total_size := int(aligned_bytes_per_row) * image_data.height
		data = make([]byte, total_size, allocator) or_return

		copy_image_data :: proc(
			$T: typeid,
			src: ^[]T,
			dst: ^[]byte,
			image_data: ^Image_Data,
			aligned_bytes_per_row: int,
		) {
			bytes_per_pixel := size_of(T) * image_data.channels

			for y in 0 ..< image_data.height {
				src_row := src[y * image_data.width * image_data.channels:]
				dst_row := dst[y * aligned_bytes_per_row:]

				when T == byte {
					copy(dst_row[:image_data.width * bytes_per_pixel], src_row)
				} else {
					copy_slice(
						dst_row[:image_data.width * bytes_per_pixel],
						slice.reinterpret(
							[]byte,
							src_row[:image_data.width * image_data.channels],
						),
					)
				}
			}
		}

		switch &src in image_data.data {
		case []byte:
			copy_image_data(byte, &src, &data, image_data, int(aligned_bytes_per_row))
		case []u16:
			copy_image_data(u16, &src, &data, image_data, int(aligned_bytes_per_row))
		case []f32:
			copy_image_data(f32, &src, &data, image_data, int(aligned_bytes_per_row))
		}
	}

	return
}
