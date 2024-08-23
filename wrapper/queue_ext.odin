package wgpu

// STD Library
import "base:runtime"
import "core:fmt"
import "core:image"
import "core:mem"
import "core:slice"
import "core:strings"

// Vendor
import stbi "vendor:stb/image"

Texture_Creation_Options :: struct {
	label            : string,
	srgb             : bool,
	usage            : Texture_Usage_Flags,
	preferred_format : Maybe(Texture_Format),
}

Image_Data_Type :: union {
	[]byte,
	[]u16,
	[]f32,
}

Image_Info :: struct {
	width, height, channels : int,
	is_hdr                  : bool,
	bits_per_channel        : int,
}

Image_Data :: struct {
	using info        : Image_Info,
	total_size        : int,
	bytes_per_channel : int,
	is_float          : bool,
	raw_data          : rawptr,
	data              : Image_Data_Type,
}

queue_copy_image_to_texture_from_image_data :: proc(
	self: Device,
	queue: Queue,
	data: Image_Data,
	options: Texture_Creation_Options = {},
	loc := #caller_location,
) -> (
	texture: Texture,
	ok: bool,
) #optional_ok {
	options := options

	width, height := data.width, data.height

	// Default texture usage if none is given
	if options.usage == {} {
		options.usage = {.Texture_Binding, .Copy_Dst, .Render_Attachment}
	}

	// Determine the texture format based on the image info
	format := options.preferred_format.? or_else image_info_texture_format(data.info)

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	label: cstring = nil
	if options.label != "" {
		label = strings.clone_to_cstring(options.label, context.temp_allocator)
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
	texture = device_create_texture(self, texture_desc) or_return
	defer if !ok do texture_release(texture)

	bytes_per_row := texture_format_bytes_per_row(format, u32(width))

	// Prepare image data for upload
	image_copy_texture := texture_as_image_copy(texture)
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
		image_copy_texture,
		pixels_to_upload,
		texture_data_layout,
		texture_desc.size,
	) or_return

	return texture, true
}

get_image_info_stbi_from_c_string_path :: proc(
	image_path: cstring,
	loc := #caller_location,
) -> (
	info: Image_Info,
	ok: bool,
) #optional_ok {
	w, h, c: i32
	if stbi.info(image_path, &w, &h, &c) == 0 {
		error_reset_and_update(
			.Load_Image_Failed,
			fmt.tprintf(
				"Failed to get image info for '%s': %s",
				image_path,
				stbi.failure_reason(),
			),
			loc,
		)
		return
	}

	info.width, info.height, info.channels = int(w), int(h), int(c)
	info.is_hdr = stbi.is_hdr(image_path) != 0

	// Determine bits per channel
	if info.is_hdr {
		info.bits_per_channel = 32 // Assuming 32-bit float for HDR
	} else {
		info.bits_per_channel = stbi.is_16_bit(image_path) ? 16 : 8
	}

	return info, true
}

get_image_info_stbi_from_string_path :: proc(
	image_path: string,
	loc := #caller_location,
) -> (
	info: Image_Info,
	ok: bool,
) #optional_ok {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	c_image_path := strings.clone_to_cstring(image_path, context.temp_allocator)
	return get_image_info_stbi_from_c_string_path(c_image_path, loc)
}

get_image_info_stbi :: proc {
	get_image_info_stbi_from_c_string_path,
	get_image_info_stbi_from_string_path,
}

Load_Method :: enum {
	Default, // 8-bit channels
	Load_16,
	Load_F32,
}

image_info_determine_load_method :: proc(info: Image_Info) -> Load_Method {
	if info.is_hdr {
		return .Load_F32
	} else if info.bits_per_channel == 16 {
		return .Load_16
	}
	return .Default
}

load_image_data_stbi :: proc(
	image_path: string,
	loc := #caller_location,
) -> (
	image_data: Image_Data,
	ok: bool,
) #optional_ok {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	c_image_path := strings.clone_to_cstring(image_path, context.temp_allocator)

	image_data.info = get_image_info_stbi(c_image_path, loc) or_return

	method := image_info_determine_load_method(image_data.info)

	width, height, channels: i32

	switch method {
	case .Default:
		image_data.raw_data = stbi.load(c_image_path, &width, &height, &channels, 0)
		image_data.bytes_per_channel = 1
	case .Load_16:
		image_data.raw_data = stbi.load_16(c_image_path, &width, &height, &channels, 0)
		image_data.bytes_per_channel = 2
	case .Load_F32:
		image_data.raw_data = stbi.loadf(c_image_path, &width, &height, &channels, 0)
		image_data.bytes_per_channel = 4
		image_data.is_float = true
	}

	if image_data.raw_data == nil {
		error_reset_and_update(
			.Load_Image_Failed,
			fmt.tprintf("Failed to load image '%s': %s", image_path, stbi.failure_reason()),
			loc,
		)
		return
	}

	image_data.total_size = int(width * height * channels)

	switch method {
	case .Default:
		image_data.data = mem.slice_ptr(cast([^]byte)image_data.raw_data, image_data.total_size)
	case .Load_16:
		image_data.data = mem.slice_ptr(cast([^]u16)image_data.raw_data, image_data.total_size)
	case .Load_F32:
		image_data.data = mem.slice_ptr(cast([^]f32)image_data.raw_data, image_data.total_size)
	}

	return image_data, true
}

queue_copy_image_to_texture_from_path :: proc(
	self: Device,
	queue: Queue,
	image_path: string,
	options: Texture_Creation_Options = {},
	loc := #caller_location,
) -> (
	texture: Texture,
	ok: bool,
) #optional_ok {
	image_data := load_image_data_stbi(image_path, loc) or_return
	defer stbi.image_free(image_data.raw_data)

	texture = queue_copy_image_to_texture_from_image_data(
		self,
		queue,
		image_data,
		options,
		loc,
	) or_return

	return texture, true
}

queue_copy_image_to_texture_image_paths :: proc(
	self: Device,
	queue: Queue,
	image_paths: []string,
	options: Texture_Creation_Options = {},
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	textures: []Texture,
	ok: bool,
) #optional_ok {
	textures = make([]Texture, len(image_paths), allocator)
	defer if !ok {
		for &t in textures {
			texture_destroy(t)
			texture_release(t)
		}
	}

	for path, i in image_paths {
		image_data := load_image_data_stbi(path, loc) or_return
		defer stbi.image_free(image_data.raw_data)

		textures[i] = queue_copy_image_to_texture_from_image_data(
			self,
			queue,
			image_data,
			options,
			loc,
		) or_return
	}

	return textures, true
}

queue_copy_image_to_texture_image :: proc(
	self: Device,
	queue: Queue,
	image: ^image.Image,
	options: Texture_Creation_Options = {},
	loc := #caller_location,
) -> (
	texture: Texture,
	ok: bool,
) #optional_ok {
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

	texture = queue_copy_image_to_texture_from_image_data(
		self,
		queue,
		image_data,
		options,
		loc,
	) or_return

	return texture, true
}

queue_copy_image_to_texture :: proc {
	queue_copy_image_to_texture_from_path,
	queue_copy_image_to_texture_image_paths,
	queue_copy_image_to_texture_image,
}

image_info_texture_format :: proc(info: Image_Info) -> Texture_Format {
	if info.is_hdr {
		switch info.channels {
		case 1:
			return .R32_Float
		case 2:
			return .Rg32_Float
		case 3, 4:
			return .Rgba32_Float
		}
	} else if info.bits_per_channel == 16 {
		switch info.channels {
		case 1:
			return .R16_Uint
		case 2:
			return .Rg16_Uint
		case 3, 4:
			return .Rgba16_Uint
		}
	} else {
		switch info.channels {
		case 1:
			return .R8_Unorm
		case 2:
			return .Rg8_Unorm
		case 3, 4:
			return .Rgba8_Unorm
		}
	}

	return .Rgba8_Unorm // Default to RGBA8 if channels are unexpected
}

queue_create_cubemap_texture :: proc(
	self: Device,
	queue: Queue,
	image_paths: [6]string,
	options: Texture_Creation_Options = {},
	loc := #caller_location,
) -> (
	out: Texture_Resource,
	ok: bool,
) #optional_ok {
	options := options

	// Get info of the first image
	first_info := get_image_info_stbi(image_paths[0], loc) or_return

	// Default texture usage if none is given
	if options.usage == {} {
		options.usage = {.Texture_Binding, .Copy_Dst, .Render_Attachment}
	}

	// Determine the texture format based on the image info or use the preferred format
	format := options.preferred_format.? or_else image_info_texture_format(first_info)

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	c_label: cstring = nil
	if options.label != "" {
		c_label = strings.clone_to_cstring(options.label, context.temp_allocator)
	}

	// Create the cubemap texture
	texture_desc := Texture_Descriptor {
		label = c_label,
		size = {
			width = u32(first_info.width),
			height = u32(first_info.height),
			depth_or_array_layers = 6,
		},
		mip_level_count = 1,
		sample_count = 1,
		dimension = .D2,
		format = format,
		usage = options.usage,
	}
	out.texture = device_create_texture(self, texture_desc) or_return
	defer if !ok do texture_release(out.texture)

	// Calculate bytes per row, ensuring it meets the WGPU alignment requirements
	bytes_per_row := texture_format_bytes_per_row(format, u32(first_info.width))

	// Load and copy each face of the cubemap
	for i in 0 ..< 6 {
		// Check info of each face
		face_info := get_image_info_stbi(image_paths[i], loc) or_return

		if face_info != first_info {
			error_reset_and_update(
				.Validation,
				fmt.tprintf("Cubemap face '%s' has different properties", image_paths[i]),
				loc,
			)
			return
		}

		// Load the face image
		face_image_data := load_image_data_stbi(image_paths[i], loc) or_return
		defer stbi.image_free(face_image_data.raw_data)

		// Copy the face image to the appropriate layer of the cubemap texture
		origin := Origin_3D{0, 0, u32(i)}

		// Prepare image data for upload
		image_copy_texture := texture_as_image_copy(out.texture, origin)
		texture_data_layout := Texture_Data_Layout {
			offset         = 0,
			bytes_per_row  = bytes_per_row,
			rows_per_image = u32(face_image_data.height),
		}

		// Convert image data if necessary
		pixels_to_upload := _convert_image_data(
			face_image_data,
			format,
			bytes_per_row,
			context.temp_allocator,
		) or_return

		queue_write_texture(
			queue,
			image_copy_texture,
			pixels_to_upload,
			texture_data_layout,
			{u32(face_image_data.width), u32(face_image_data.height), 1},
		) or_return
	}

	cube_view_descriptor := Texture_View_Descriptor {
		label             = "Cube Texture View",
		format            = texture_format(out.texture), // Use the same format as the texture
		dimension         = .Cube,
		base_mip_level    = 0,
		mip_level_count   = 1, // Assume no mipmaps
		base_array_layer  = 0,
		array_layer_count = 6, // 6 faces of the cube
		aspect            = .All,
	}
	out.view = texture_create_view(out.texture, cube_view_descriptor) or_return
	defer if !ok do texture_view_release(out.view)

	// Create a sampler with linear filtering for smooth interpolation.
	sampler_descriptor := Sampler_Descriptor {
		address_mode_u = .Repeat,
		address_mode_v = .Repeat,
		address_mode_w = .Repeat,
		mag_filter     = .Linear,
		min_filter     = .Linear,
		mipmap_filter  = .Linear,
		lod_min_clamp  = 0.0,
		lod_max_clamp  = 1.0,
		compare        = .Undefined,
		max_anisotropy = 1,
	}

	out.sampler = device_create_sampler(self, sampler_descriptor) or_return
	// defer if !ok do sampler_release(out.sampler)

	return out, true
}

texture_resource_release :: proc(res: Texture_Resource) {
	sampler_release(res.sampler)
	texture_view_release(res.view)
	texture_destroy(res.texture)
	texture_release(res.texture)
}

@(private = "file")
_convert_image_data :: proc(
	image_data: Image_Data,
	format: Texture_Format,
	aligned_bytes_per_row: u32,
	allocator := context.allocator,
) -> (
	data: []byte,
	ok: bool,
) {
	bytes_per_pixel := image_data.channels * image_data.bytes_per_channel

	if image_data.channels == 3 {
		// Convert RGB to RGBA
		new_bytes_per_pixel := 4 * image_data.bytes_per_channel
		data = make([]byte, int(aligned_bytes_per_row) * image_data.height, allocator)

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
			return data, true
		}

		// If not converting, create a byte slice of the data with proper alignment
		total_size := int(aligned_bytes_per_row) * image_data.height
		data = make([]byte, total_size, allocator)

		copy_image_data :: proc(
			$T: typeid,
			src: ^[]T,
			dst: ^[]byte,
			image_data: Image_Data,
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

	return data, true
}
