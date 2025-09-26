#+build !js
package webgpu

// Vendor
import "vendor:wgpu"

/*
Set push constant data.

Offset is measured in bytes, but must be a multiple of `PUSH_CONSTANT_ALIGNMENT`.

Data size must be a multiple of `4` and must have an alignment of `4`. For
example, with an offset of `4` and an array of `[8]u8`, that will write to the
range of `4..12`.

For each byte in the range of push constant data written, the union of the
stages of all push constant ranges that covers that byte must be exactly
`stages`. There's no good way of explaining this simply, so here are some
examples:

```text
For the given ranges:
- 0..4 Vertex
- 4..8 Fragment
```

You would need to upload this in two `RenderBundleEncoderSetPushConstants`
calls. First for the `Vertex` range, second for the `Fragment` range.

```text
For the given ranges:
- 0..8  Vertex
- 4..12 Fragment
```

You would need to upload this in three
`RenderBundleEncoderSetPushConstants` calls. First for the `Vertex` only
range `0..4`, second for the `{.Vertex, .Fragment}` range `4..8`, third for the
`Fragment` range `8..12`.
*/
RenderBundleEncoderSetPushConstants :: proc "c" (
	self: RenderBundleEncoder,
	stages: ShaderStages,
	offset: u32,
	data: []byte,
) {
	wgpu.RenderBundleEncoderSetPushConstants(self, stages, offset, u32(len(data)), raw_data(data))
}
