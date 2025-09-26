# Odin WGPU Examples

A comprehensive collection of WebGPU examples and tutorials, demonstrating graphics programming
concepts from basic rendering to advanced techniques.

## 🚀 Quick Start

### Prerequisites

- [Odin compiler](https://odin-lang.org/) (tested in `dev-2025-09:e9d20a9b4`)
- Git
- Python 3 (to serve web examples)

### Installation

The repository includes the directory `examples/build/assets` and `libs` as a Git submodule
containing shared resources used across multiple examples.

To properly clone the repository with assets, use:

```bash
git clone --recursive https://github.com/Capati/wgpu-odin.git
cd wgpu-odin/examples
```

If you've already cloned without submodules:

```bash
git submodule update --init --recursive
```

### 📁 Project Structure

```
examples/
├── build/
│   ├── assets/        # Shared resources (textures, models, shaders)
│   └── web/           # Web build output
├── [example-name]/    # Individual example directories
├── build.bat          # Windows build script
├── build.sh           # Unix build script
└── README.md
```

### Build and Run

Execute the `odin build` command inside the `examples` folder or use the script.

> [!NOTE]
> Make sure you read the `doc.odin` from `<odin-folder>/vendor/wgpu/doc.odin` to learn more about
> how it works.

#### Build Script Options

The build scripts support several commands and options:

| Command | Description |
|---------|-------------|
| `run` | Build and immediately run the example |
| `release` | Build with optimizations enabled |
| `clean` | Remove build artifacts before building |
| `web` | Build for WebAssembly/WebGPU |

By default when using the script, the examples are built in debug mode with the flag `-debug`.

#### Windows

```batch
.\build.bat triangle run
```

By default, the wgpu bindings use the static release version. To speed up compilation during
development, the script sets the flag `-define:WGPU_SHARED=true`. This requires `wgpu_native.dll`
to be placed alongside the example executables in the build directory. The script will also copy
this file for you automatically.

If you want to enforce `DirectX 12`, just provide the config `-define:WGPU_BACKEND_TYPE=DX12`:

```bat
.\build.bat triangle run "-define:WGPU_BACKEND_TYPE=DX12"
```

#### Unix/Linux/macOS

```bash
./build.sh triangle run
```

####  Web

Most examples support WebGPU and can run in modern browsers. Examples marked with ❌ are native-only
due to:

- File system access requirements
- Unimplemented web texture loading
- Platform-specific APIs

**Running Web Examples**:

1. Build for web: `./build.bat|sh [example] web`. The files are stored in `build/web/`.
2. Serve locally: `python -m http.server 8080`
3. Open `http://localhost:8080` in a WebGPU-compatible browser

## Examples Overview

### Misc

| Example | Description | WebGPU Support |
|---------|-------------|----------------|
| [**Info**](./info/info.odin) | Display WGPU version and adapter information | ❌ |

###  Getting Started

| Example | Description | WebGPU Support |
|---------|-------------|----------------|
| [**Triangle**](./triangle/triangle.odin) | Verbose example for getting a colored triangle rendered to the screen. This is meant as a starting point for learning WGPU from the ground up. | ✅ |
| [**Clear Screen**](./clear_screen/clear_screen.odin) | How to set up a render pass for clearing the screen. The screen clearing animation shows a fade-in and fade-out effect from red and green. | ✅ |
| [**Square**](./square/square.odin) | How to render a static colored square with only using vertex buffers. | ✅ |

### Basic 3D Graphics

| Example | Description | WebGPU Support |
|---------|-------------|----------------|
| [**Cube**](./cube/cube.odin) | Basic example showing how to render a 3D cube with solid colors and depth testing. | ✅ |
| [**Rotating Cube**](./rotating_cube/rotating_cube.odin) | This example shows how to upload uniform data every frame to render a rotating object. | ✅ |
| [**Textured Cube**](./textured_cube/textured_cube.odin) | This example shows how to bind and sample textures. | ✅ |
| [**Cube Textured**](./cube_textured/cube_textured.odin) | An alternative implementation of texture mapping on a cube, by loading an image from file. | ✅ |
| [**Two Cubes**](./two_cubes/two_cubes.odin) | This example shows some of the alignment requirements involved when updating and binding multiple slices of a uniform buffer. It renders two rotating cubes which have transform matrices at different offsets in a uniform buffer. | ✅ |
| [**Instanced Cube**](./instanced_cube/instanced_cube.odin) | Demonstrates instance rendering by drawing multiple cubes efficiently using instancing techniques. | ✅ |

### 🔬 Advanced Techniques

| Example | Description | WebGPU Support |
|---------|-------------|----------------|
| [**Triangle MSAA**](./triangle_msaa/triangle_msaa.odin) | Multisampling anti-aliasing demonstration | ✅ |
| [**Stencil Triangles**](./stencil_triangles/stencil_triangles.odin) | This example renders two different sized triangles to display three same sized triangles, by demonstrating the use of stencil buffers. | ✅ |
| [**Fractal Cube**](./fractal_cube/fractal_cube.odin) | This example uses the previous frame's rendering result as the source texture for the next frame. | ✅ |
| [**Coordinate System**](./coordinate_system/coordinate_system.odin) | Demonstrates the coordinate system in WGPU by rendering a series of axes and grids to help visualize 3D space orientation. | ❌ |
| [**Cubemap**](./cubemap/cubemap.odin) | This example shows how to render and sample from a cubemap texture. | ❌ |

### Compute Shaders

| Example | Description | WebGPU Support |
|---------|-------------|----------------|
| [**Simple Compute**](./compute/compute.odin) | Shows how to use compute shaders and storage buffers in WGPU. | ✅ |
| [**Image Blur**](./image_blur/image_blur.odin) | Shows how to implement a Gaussian blur effect using compute shaders for image processing. | ❌ |

### Graphics Techniques

| Example | Description | WebGPU Support |
|---------|-------------|----------------|
| [**Cameras**](./cameras/cameras.odin) | This example provides example camera implementations. | ✅ |
| [**Texture Arrays**](./texture_arrays/texture_arrays.odin) | Shows how to use texture arrays in WGPU, allowing multiple textures to be stored and accessed as a single array texture. | ✅ |
| [**Capture**](./capture/capture.odin) | Demonstrates how to capture and save the contents of a render target to an image file. | ❌ |

### UI Integration

| Example | Description | WebGPU Support |
|---------|-------------|----------------|
| [**ImGui**](./imgui/imgui_example.odin) | Dear ImGui integration | ❌ |
| [**MicroUI**](./microui/microui.odin) | MicroUI integration | ✅ |

### Learning Resources

| Example | Description | WebGPU Support |
|---------|-------------|----------------|
| [**Learn WGPU**](./learn_wgpu/) | Port of the Rust WebGPU tutorial | ❌ |
