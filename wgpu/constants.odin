package wgpu

/* Integral type used for buffer offsets. */
BufferAddress :: u64
/* Integral type used for buffer slice sizes. */
BufferSize :: u64
/* Integral type used for buffer slice sizes. */
ShaderLocation :: u32
/* Integral type used for dynamic bind group offsets. */
DynamicOffset :: u32

/* Buffer-Texture copies must have [`bytes_per_row`] aligned to this number. */
COPY_BYTES_PER_ROW_ALIGNMENT: u32 : 256
/* An offset into the query resolve buffer has to be aligned to self. */
QUERY_RESOLVE_BUFFER_ALIGNMENT: BufferAddress : 256
/*
Buffer to buffer copy as well as buffer clear offsets and sizes must be aligned to
this number.
*/
COPY_BUFFER_ALIGNMENT: BufferAddress : 4
/* Buffer alignment mask to calculate proper size */
COPY_BUFFER_ALIGNMENT_MASK :: COPY_BUFFER_ALIGNMENT - 1
/* Size to align mappings. */
MAP_ALIGNMENT: BufferAddress : 8
/* Vertex buffer strides have to be aligned to this number. */
VERTEX_STRIDE_ALIGNMENT: BufferAddress : 4
/* Alignment all push constants need */
PUSH_CONSTANT_ALIGNMENT: u32 : 4
/* Maximum queries in a query set */
QUERY_SET_MAX_QUERIES: u32 : 8192
/* Size of a single piece of query data. */
QUERY_SIZE: u32 : 8
