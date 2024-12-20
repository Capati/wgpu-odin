# `tobj` - Tiny OBJ Loader

A lightweight and efficient OBJ file loader written in Odin, drawing inspiration from [tobj](https://github.com/Twinklebear/tobj) and [`tinyobjloader`](https://github.com/syoyo/tinyobjloader). Designed to be simple and straightforward, providing clean access to 3D model data through basic slices.

## Features

### Mesh Loading

- Returns simple slices containing loaded models and materials
- No complex abstractions or unnecessary overhead
- Supports both triangulated and non-triangulated meshes

### Triangulation

Meshes can be triangulated during loading or preserved in their original form. Only supports polygons that can be trivially converted to triangle fans. For best results, convert your meshes to triangles in your modeling software before export.

### Optional Attributes

While vertex positions are required, the loader handles optional attributes flexibly:

- Normals
- Texture coordinates
- Vertex colors

If these attributes aren't present in the file, their corresponding slices will be empty.

### Data Structure

The loader provides a simple Mesh structure that contains all geometry data.

- Each array stores its data in a simple, contiguous format
- Uses dynamic arrays to handle models of any size
- Compatible with common graphics APIs and 3D applications
- Separates geometry data from indices for efficient reuse

### Index Handling

- Supports indexed geometry to optimize memory usage
- Preserves mesh topology when using separate index buffers

### Material Support

- Loads standard MTL files
- Supports common material attributes
- Stores unknown parameters in a hash map for custom extensions

### TODO

- [ ] Multi index support
- [ ] Vertex merging

## Usage

```odin
import "core:fmt"
import "shared:tobj"

main :: proc() {
    // Load an OBJ file
    models, materials, err := tobj.load_obj("model.obj")
    if err != nil {
        tobj.print_error(err)
        return
    }

    // Access the data
    for &m in models {
        fmt.printf("Model has %d vertices\n", len(m.mesh.vertices))
        fmt.printf("Model has %d faces\n", len(m.mesh.indices))
    }
}
```

## License

MIT License - See LICENSE file for details
