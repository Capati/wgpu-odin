package webgpu

// Core
import sa "core:container/small_array"

// Vendor
import "vendor:wgpu"

/*
Encodes a series of GPU operations.

A command encoder can record `RenderPass`es, `ComputePass`es, and transfer
operations between driver-managed resources like `Buffer`s and `Texture`s.

When finished recording, call `CommandEncoderFinish` to obtain a `CommandBuffer`
which may be submitted for execution.

Corresponds to [WebGPU
`GPUCommandEncoder`](https://gpuweb.github.io/gpuweb/#command-encoder).
*/
CommandEncoder :: wgpu.CommandEncoder

/*
Describes a `CommandBuffer`.

Corresponds to [WebGPU `GPUCommandBufferDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpucommandbufferdescriptor).
*/
CommandBufferDescriptor :: wgpu.CommandBufferDescriptor

/* Finishes recording and returns a `CommandBuffer` that can be submitted for execution. */
@(require_results)
CommandEncoderFinish :: proc "c" (
	self: CommandEncoder,
	descriptor: ^CommandBufferDescriptor = nil,
) -> (
	commandBuffer: CommandBuffer,
) {
	if descriptor != nil {
		commandBuffer = wgpu.CommandEncoderFinish(self, descriptor)
	} else {
		commandBuffer = wgpu.CommandEncoderFinish(self, nil)
	}
	return
}

/*
Maximum number of color attachments that can be bound to a render pass.

This constant defines the maximum number of color attachments that can be used
simultaneously in a render pass. The value is configurable through the
`WGPU_MAX_COLOR_ATTACHMENTS` configuration option, defaulting to `8` if not
specified otherwise.

This limit is hardware dependent and follows WebGPU specifications for maximum
color attachments in a render pass.
*/
MAX_COLOR_ATTACHMENTS :: #config(WGPU_MAX_COLOR_ATTACHMENTS, 8)

@(private)
RawRenderPassColorAttachment :: sa.Small_Array(
	MAX_COLOR_ATTACHMENTS,
	wgpu.RenderPassColorAttachment,
)

/*
Describes a color attachment to a `RenderPass`.

For use with `Render_Pass_Descriptor`.

Corresponds to [WebGPU `GPURenderPassColorAttachment`](
https://gpuweb.github.io/gpuweb/#color-attachments).
*/
RenderPassColorAttachment :: struct {
	view:          TextureView,
	resolveTarget: TextureView,
	ops:           Operations(Color),
}

RenderPassDepthOperations :: struct {
	using depthOps: Operations(f32),
	readOnly:       bool,
}

RenderPassStencilOperations :: struct {
	using stencilOps: Operations(u32),
	readOnly:         bool,
}

/*
Describes a depth/stencil attachment to a `RenderPass`.

For use with `RenderPassDescriptor`.

Corresponds to [WebGPU `GPURenderPassDepthStencilAttachment`](
https://gpuweb.github.io/gpuweb/#depth-stencil-attachments).
*/
RenderPassDepthStencilAttachment :: struct {
	view:       TextureView,
	depthOps:   Maybe(RenderPassDepthOperations),
	stencilOps: Maybe(RenderPassStencilOperations),
}

/*
Describes the timestamp writes of a render pass.

For use with `RenderPassDescriptor`.
At least one of `beginningOfPassWriteIndex` and `endOfPassWriteIndex` must be valid.

Corresponds to [WebGPU `GPURenderPassTimestampWrite`](
https://gpuweb.github.io/gpuweb/#dictdef-gpurenderpasstimestampwrites).
*/
RenderPassTimestampWrites :: wgpu.RenderPassTimestampWrites

/*
Describes the attachments of a render pass.

For use with `CommandEncoderBeginRenderPass`.

Corresponds to [WebGPU `GPURenderPassDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpurenderpassdescriptor).
*/
RenderPassDescriptor :: struct {
	label:                  string,
	colorAttachments:       []RenderPassColorAttachment,
	depthStencilAttachment: Maybe(RenderPassDepthStencilAttachment),
	timestampWrites:        Maybe(RenderPassTimestampWrites),
	occlusionQuerySet:      Maybe(QuerySet),
	/* Extras */
	maxDrawCount:           u64,
}

/*
Begins recording of a render pass.

This procedure returns a `RenderPass` object which records a single render pass.

As long as the returned  `RenderPass` has not ended, any mutating operation on
this command encoder causes an error and invalidates it.
*/
@(require_results)
CommandEncoderBeginRenderPass :: proc "c" (
	self: CommandEncoder,
	descriptor: RenderPassDescriptor,
) -> (
	renderPass: RenderPass,
) {
	desc: wgpu.RenderPassDescriptor
	desc.label = descriptor.label

	// Color attachments
	colorAttachments: RawRenderPassColorAttachment
	if len(descriptor.colorAttachments) > 0 {
		// Validate color attachment count doesn't exceed maximum
		assert_contextless(len(descriptor.colorAttachments) <= MAX_COLOR_ATTACHMENTS,
			   "Too many color attachments")

		for &attachment in descriptor.colorAttachments {
			attachment_raw := wgpu.RenderPassColorAttachment {
				view          = attachment.view,
				resolveTarget = attachment.resolveTarget,
				depthSlice    = DEPTH_SLICE_UNDEFINED,
				loadOp        = attachment.ops.load,
				storeOp       = attachment.ops.store,
				clearValue    = wgpu.Color {
					attachment.ops.clearValue.r,
					attachment.ops.clearValue.g,
					attachment.ops.clearValue.b,
					attachment.ops.clearValue.a,
				},
			}
			sa.push_back(&colorAttachments, attachment_raw)
		}

		desc.colorAttachmentCount = uint(sa.len(colorAttachments))
		desc.colorAttachments = raw_data(sa.slice(&colorAttachments))
	}

	// Depth/Stencil attachment
	depthStencil: wgpu.RenderPassDepthStencilAttachment
	if dsa, dsa_ok := descriptor.depthStencilAttachment.?; dsa_ok {
		depthStencil.view = dsa.view

		// Handle depth operations
		if depthOps, depthOpsOk := dsa.depthOps.?; depthOpsOk {
			depthStencil.depthLoadOp     = depthOps.load
			depthStencil.depthStoreOp    = depthOps.store
			depthStencil.depthClearValue = depthOps.clearValue
			depthStencil.depthReadOnly   = b32(depthOps.readOnly)
		}

		// Handle stencil operations
		if stencilOps, stencilOpsOk := dsa.stencilOps.?; stencilOpsOk {
			depthStencil.stencilLoadOp     = stencilOps.load
			depthStencil.stencilStoreOp    = stencilOps.store
			depthStencil.stencilClearValue = stencilOps.clearValue
			depthStencil.stencilReadOnly   = b32(stencilOps.readOnly)
		}

		desc.depthStencilAttachment = &depthStencil
	}

	if timestampWrites, ok := descriptor.timestampWrites.?; ok {
		desc.timestampWrites = &timestampWrites
	}

	if querySet, ok := descriptor.occlusionQuerySet.?; ok {
		desc.occlusionQuerySet = querySet
	}

	// Extra extensions
	when ODIN_OS != .JS {
		maxDrawCount: wgpu.RenderPassMaxDrawCount
		if descriptor.maxDrawCount > 0 {
			maxDrawCount = {
				chain = { sType = .RenderPassMaxDrawCount },
				maxDrawCount = descriptor.maxDrawCount,
			}
			desc.nextInChain = &maxDrawCount.chain
		}
	}

	renderPass = wgpu.CommandEncoderBeginRenderPass(self, &desc)

	return
}

/*
Describes the timestamp writes of a compute pass.

For use with `ComputePassDescriptor`.
At least one of `BeginningOfPassWriteIndex` and `EndOfPassWriteIndex` must be valid.

Corresponds to [WebGPU `GPUComputePassTimestampWrites`](
https://gpuweb.github.io/gpuweb/#dictdef-gpucomputepasstimestampwrites).
*/
ComputePassTimestampWrites :: wgpu.ComputePassTimestampWrites

/*
Describes a `Command_Encoder`.

For use with `DeviceCreateCommandEncoder`.

Corresponds to [WebGPU `GPUCommandEncoderDescriptor`](
https://gpuweb.github.io/gpuweb/#dictdef-gpucommandencoderdescriptor).
*/
ComputePassDescriptor :: wgpu.ComputePassDescriptor

/*
Begins recording of a compute pass.

This procedure returns a `ComputePass` object which records a single compute pass.

As long as the returned  `ComputePass` has not ended,
any mutating operation on this command encoder causes an error and invalidates it.
*/
@(require_results)
CommandEncoderBeginComputePass :: proc "c" (
	self: CommandEncoder,
	descriptor: Maybe(ComputePassDescriptor) = nil,
) -> (
	computePass: ComputePass,
) {
	if desc, desc_ok := descriptor.?; desc_ok {
		computePass = wgpu.CommandEncoderBeginComputePass(self, &desc)
	} else {
		computePass = wgpu.CommandEncoderBeginComputePass(self, nil)
	}
	return
}

/*
Copy data from one buffer to another.

**Panics**

- Buffer offsets or copy size not a multiple of `COPY_BUFFER_ALIGNMENT`.
- Copy would overrun buffer.
- Copy within the same buffer.
*/
CommandEncoderCopyBufferToBuffer :: wgpu.CommandEncoderCopyBufferToBuffer

/*
Layout of a texture in a buffer's memory.

Corresponds to [WebGPU `GPUTexelCopyBufferLayout`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuimagedatalayout).
*/
TexelCopyBufferLayout :: wgpu.TexelCopyBufferLayout

/*
View of a buffer which can be used to copy to/from a texture.

Corresponds to [WebGPU `GPUImageCopyBuffer`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuimagecopybuffer).
*/
TexelCopyBufferInfo :: wgpu.TexelCopyBufferInfo

/*
View of a texture which can be used to copy to/from a buffer/texture.

Corresponds to [WebGPU `GPUImageCopyTexture`](
https://gpuweb.github.io/gpuweb/#dictdef-gpuimagecopytexture).
*/
TexelCopyTextureInfo :: wgpu.TexelCopyTextureInfo

/* Copy data from a buffer to a texture. */
CommandEncoderCopyBufferToTexture :: proc "c" (
	commandEncoder: CommandEncoder,
	source: TexelCopyBufferInfo,
	destination: TexelCopyTextureInfo,
	copySize: Extent3D,
) {
	source := source
	destination := destination
	copySize := copySize
	wgpu.CommandEncoderCopyBufferToTexture(commandEncoder, &source, &destination, &copySize)
}

/* Copy data from a texture to a buffer. */
CommandEncoderCopyTextureToBuffer :: proc "c" (
	commandEncoder: CommandEncoder,
	source: TexelCopyTextureInfo,
	destination: TexelCopyBufferInfo,
	copySize: Extent3D,
) {
	source := source
	destination := destination
	copySize := copySize
	wgpu.CommandEncoderCopyTextureToBuffer(commandEncoder, &source, &destination, &copySize)
}

/*
Copy data from one texture to another.

**Panics**

- Textures are not the same type
- If a depth texture, or a multisampled texture, the entire texture must be copied
- Copy would overrun either texture
*/
CommandEncoderCopyTextureToTexture :: proc "c" (
	commandEncoder: CommandEncoder,
	source: TexelCopyTextureInfo,
	destination: TexelCopyTextureInfo,
	copySize: Extent3D,
) {
	source := source
	destination := destination
	copySize := copySize
	wgpu.CommandEncoderCopyTextureToTexture(commandEncoder, &source, &destination, &copySize)
}

/*
Clears buffer to zero.

**Panics**

- Buffer does not have `COPY_DST` usage.
- Range is out of bounds
*/
CommandEncoderClearBuffer :: wgpu.CommandEncoderClearBuffer

/* Inserts debug marker. */
CommandEncoderInsertDebugMarker :: wgpu.CommandEncoderInsertDebugMarker

/* Start record commands and group it into debug marker group. */
CommandEncoderPushDebugGroup :: wgpu.CommandEncoderPushDebugGroup

/* Stops command recording and creates debug group. */
CommandEncoderPopDebugGroup :: wgpu.CommandEncoderPopDebugGroup

/*
Resolve a query set, writing the results into the supplied destination buffer.

Queries may be between 8 and 40 bytes each. See `Pipeline_Statistics_Types` for more information.
*/
CommandEncoderResolveQuerySet :: proc "c" (
	self: CommandEncoder,
	querySet: QuerySet,
	queryRange: Range(u32),
	destination: Buffer,
	destinationOffset: BufferAddress,
) {
	wgpu.CommandEncoderResolveQuerySet(
		self,
		querySet,
		queryRange.start,
		queryRange.end,
		destination,
		destinationOffset,
	)
}

/*
Issue a timestamp command at this point in the queue.
The timestamp will be written to the specified query set, at the specified index.

Attention: Since commands within a command recorder may be reordered,
there is no strict guarantee that timestamps are taken after all commands
recorded so far and all before all commands recorded after.
This may depend both on the backend and the driver.
*/
CommandEncoderWriteTimestamp :: wgpu.CommandEncoderWriteTimestamp

/* Sets a debug label for the given `CommandEncoder`. */
CommandEncoderSetLabel :: wgpu.CommandEncoderSetLabel

/* Increase the `CommandEncoder` reference count. */
CommandEncoderAddRef :: wgpu.CommandEncoderAddRef

/* Release the `CommandEncoder` resources, use to decrease the reference count. */
CommandEncoderRelease :: wgpu.CommandEncoderRelease

/*
Safely releases the `CommandEncoder` resources and invalidates the handle.
The procedure checks both the pointer and handle before releasing.

Note: After calling this, the handle will be set to `nil` and should not be used.
*/
CommandEncoderReleaseSafe :: proc "c" (self: ^CommandEncoder) {
	if self != nil && self^ != nil {
		wgpu.CommandEncoderRelease(self^)
		self^ = nil
	}
}
