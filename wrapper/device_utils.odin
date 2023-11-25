package wgpu

// Describes `Buffer` when allocating.
Buffer_Data_Descriptor :: struct {
    // Debug label of a buffer. This will show up in graphics debuggers for easy
    // identification.
    label:    cstring,
    // Contents size of a buffer on creation.
    contents: []byte,
    // Usages of a buffer. If the buffer is used in any way that isn't specified here,
    // the operation will panic.
    usage:    Buffer_Usage_Flags,
}

// Creates a `Buffer` with data to initialize it.
device_create_buffer_with_data :: proc(
    using self: ^Device,
    descriptor: ^Buffer_Data_Descriptor,
) -> (
    buffer: Buffer,
    err: Error_Type,
) {
    // Skip mapping if the buffer is zero sized
    if descriptor == nil || descriptor.contents == nil || len(descriptor.contents) == 0 {
        buffer_descriptor: Buffer_Descriptor = {
            label              = descriptor.label,
            size               = 0,
            usage              = descriptor.usage,
            mapped_at_creation = false,
        }

        return self->create_buffer(&buffer_descriptor)
    }

    unpadded_size := cast(Buffer_Address)len(descriptor.contents)

    // Valid vulkan usage is
    // 1. buffer size must be a multiple of Copy_Buffer_Alignment.
    // 2. buffer size must be greater than 0.
    // Therefore we round the value up to the nearest multiple, and ensure it's at least
    // Copy_Buffer_Alignment.

    align_mask := Copy_Buffer_Alignment - 1
    padded_size := max(((unpadded_size + align_mask) & ~align_mask), Copy_Buffer_Alignment)

    buffer_descriptor: Buffer_Descriptor = {
        label              = descriptor.label,
        size               = padded_size,
        usage              = descriptor.usage,
        mapped_at_creation = true,
    }

    buffer = self->create_buffer(&buffer_descriptor) or_return

    // Synchronously and immediately map a buffer for reading. If the buffer is not
    // immediately mappable through `mapped_at_creation` or
    // `buffer->map_async`, will panic.
    mapped_array_buffer := buffer->get_mapped_range(0, cast(uint)padded_size)
    copy(mapped_array_buffer, descriptor.contents)
    buffer->unmap() or_return

    return
}

// TODO: Upload an entire texture and its mipmaps from a source buffer.
device_create_texture_with_data :: proc(
    self: ^Device,
    queue: ^Queue,
    descriptor: ^Texture_Descriptor,
    data: []byte,
) {
}
