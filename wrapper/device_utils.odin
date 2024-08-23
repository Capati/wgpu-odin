package wgpu

/* Describes `Buffer` when allocating. */
Buffer_Data_Descriptor :: struct {
	/* Debug label of a buffer. This will show up in graphics debuggers for easy
	identification. */
	label:    cstring,
	/* Contents size of a buffer on creation. */
	contents: []byte,
	/* Usages of a buffer. If the buffer is used in any way that isn't specified here,
	the operation will panic. */
	usage:    Buffer_Usage_Flags,
}

/* Creates a `Buffer` with data to initialize it. */
@(require_results)
device_create_buffer_with_data :: proc(
	self: Device,
	descriptor: Buffer_Data_Descriptor,
	loc := #caller_location,
) -> (
	buffer: Buffer,
	ok: bool,
) #optional_ok {
	// Skip mapping if the buffer is zero sized
	if descriptor.contents == nil || len(descriptor.contents) == 0 {
		buffer_descriptor: Buffer_Descriptor = {
			label              = descriptor.label,
			size               = 0,
			usage              = descriptor.usage,
			mapped_at_creation = false,
		}

		return device_create_buffer(self, buffer_descriptor, loc)
	}

	unpadded_size := cast(Buffer_Address)len(descriptor.contents)

	// Valid vulkan usage is
	// 1. buffer size must be a multiple of COPY_BUFFER_ALIGNMENT.
	// 2. buffer size must be greater than 0.
	// Therefore we round the value up to the nearest multiple, and ensure it's at least
	// COPY_BUFFER_ALIGNMENT.

	align_mask := COPY_BUFFER_ALIGNMENT_MASK
	padded_size := max(((unpadded_size + align_mask) & ~align_mask), COPY_BUFFER_ALIGNMENT)

	buffer_descriptor: Buffer_Descriptor = {
		label              = descriptor.label,
		size               = padded_size,
		usage              = descriptor.usage,
		mapped_at_creation = true,
	}

	buffer = device_create_buffer(self, buffer_descriptor, loc) or_return

	// Synchronously and immediately map a buffer for reading. If the buffer is not
	// immediately mappable through `mapped_at_creation` or
	// `buffer_map_async`, will panic.
	mapped_buffer_slice := buffer_get_mapped_range_bytes(
		buffer,
		{size = padded_size},
		loc,
	) or_return
	copy(mapped_buffer_slice, descriptor.contents)
	buffer_unmap(buffer, loc) or_return

	return buffer, true
}

/* Order in which texture data is laid out in memory. */
Texture_Data_Order :: enum {
	Layer_Major, /* default */
	Mip_Major,
}

/*  Upload an entire texture and its mipmaps from a source buffer. */
@(require_results)
device_create_texture_with_data :: proc(
	self: Device,
	queue: Queue,
	desc: Texture_Descriptor,
	order: Texture_Data_Order,
	data: []byte,
	loc := #caller_location,
) -> (
	texture: Texture,
	ok: bool,
) #optional_ok {
	desc := desc

	// Implicitly add the .Copy_Dst usage
	if .Copy_Dst not_in desc.usage {
		desc.usage += {.Copy_Dst}
	}

	texture = device_create_texture(self, desc, loc) or_return
	defer if !ok do texture_release(texture)

	// Will return 0 only if it's a combined depth-stencil format
	// If so, default to 4, validation will fail later anyway since the depth or stencil
	// aspect needs to be written to individually
	block_size := texture_format_block_size(desc.format)
	if block_size == 0 do block_size = 4
	block_width, block_height := texture_format_block_dimensions(desc.format)
	layer_iterations := texture_descriptor_array_layer_count(desc)

	outer_iteration, inner_iteration: u32

	switch order {
	case .Layer_Major:
		outer_iteration = layer_iterations
		inner_iteration = desc.mip_level_count
	case .Mip_Major:
		outer_iteration = desc.mip_level_count
		inner_iteration = layer_iterations
	}

	binary_offset: u32 = 0
	for outer in 0 ..< outer_iteration {
		for inner in 0 ..< inner_iteration {
			layer, mip: u32
			switch order {
			case .Layer_Major:
				layer = outer
				mip = inner
			case .Mip_Major:
				layer = inner
				mip = outer
			}

			mip_size, mip_size_ok := texture_descriptor_mip_level_size(desc, mip)
			assert(mip_size_ok, "Invalid mip level")
			// if !mip_size_ok {
			// 	err = Error_Type.Validation
			// 	set_and_update_err_data(self._err_data, .Assert, err, "Invalid mip level", loc)
			// 	return
			// }

			// copying layers separately
			if desc.dimension != .D3 {
				mip_size.depth_or_array_layers = 1
			}

			// When uploading mips of compressed textures and the mip is supposed to be
			// a size that isn't a multiple of the block size, the mip needs to be uploaded
			// as its "physical size" which is the size rounded up to the nearest block size.
			mip_physical := extent_3d_physical_size(mip_size, desc.format)

			// All these calculations are performed on the physical size as that's the
			// data that exists in the buffer.
			width_blocks := mip_physical.width / block_width
			height_blocks := mip_physical.height / block_height

			bytes_per_row := width_blocks * block_size
			data_size := bytes_per_row * height_blocks * mip_size.depth_or_array_layers

			end_offset := binary_offset + data_size
			assert(end_offset <= u32(len(data)), "Buffer too small")
			// if end_offset > u32(len(data)) {
			// 	err = Error_Type.Validation
			// 	set_and_update_err_data(self._err_data, .Assert, err, "Buffer too small", loc)
			// 	return
			// }

			queue_write_texture(
				queue,
				{texture = texture, mip_level = mip, origin = {0, 0, layer}, aspect = .All},
				data[binary_offset:end_offset],
				{offset = 0, bytes_per_row = bytes_per_row, rows_per_image = height_blocks},
				mip_physical,
				loc,
			) or_return

			binary_offset = end_offset
		}
	}

	return texture, true
}
