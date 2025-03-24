# Odin WGPU Examples

> [!NOTE]
> Tested in Odin: `dev-2025-03:97d410c2a`.

## Table of Contents

+ [Assets](#assets)
+ [How to Build](#how-to-build)
  + [Build Script](#build-script)
    + [Windows](#windows)
    + [Unix](#unix)
+ [Examples](#examples)
  + [Triangle](#triangle)
  + [Misc](#misc)
    + [Info](#info)
  + [Basic Graphics](#basic-graphics)
    + [Clear Screen](#clear-screen)
    + [Triangle MSAA](#triangle-msaa)
    + [Square](#square)
    + [Stencil Triangles](#stencil-triangles)
    + [Two Cubes](#two-cubes)
    + [Cubemap](#cubemap)
    + [Coordinate System](#coordinate-system)
    + [Cube](#cube)
    + [Rotating Cube](#rotating-cube)
    + [Textured Cube](#textured-cube)
    + [Cube Textured](#cube-textured)
    + [Instanced Cube](#instanced-cube)
  + [Compute](#compute)
    + [Simple Compute](#simple-compute)
  + [Graphics Techniques](#graphics-techniques)
    + [Cameras](#cameras)
    + [Image Blur](#image-blur)
    + [Texture Arrays](#texture-arrays)
    + [Capture](#capture)
  + [UI and Integration](#ui-and-integration)
    + [ImGui](#imgui)
    + [MicroUI](#microui)
  + [Tutorials](#tutorials)
    + [Learn WGPU](#learn-wgpu)

## Assets

The repository includes the directory `examples/build/assets` as a Git submodule
containing shared resources used across multiple examples:

+ Textures: Image files for various texture mapping examples
+ Models: 3D model files used in rendering examples
+ Shaders: Common shader files that may be shared between examples

To properly clone the repository with assets, use:

```shell
git clone --recursive https://github.com/Capati/wgpu-odin.git
```

Or if you've already cloned the repository:

```shell
git submodule update --init --recursive
```

Note: Most shader files are `#load` at compile time and are located within the example.

## How to Build

Execute the `odin build` command inside the `examples` folder or use the script.

### Build Script

By default when using the script, the examples are built in debug mode with the flag `-debug`.

#### Windows

You can use the `build.bat` with a example name as argument, for example:

```shell
.\build.bat cube_textured run
```

To run the examples you need `wgpu_native.dll` along side the examples executables, just place
this file in the `build` directory.

To build optimized for release mode, provide the option `release`:

```shell
.\build.bat cube_textured release
```

If you want to enforce `DirectX 12`, just provide the config `-define:WGPU_BACKEND_TYPE=DX12`:

```bat
.\build.bat cube_textured run -define:WGPU_BACKEND_TYPE=DX12
```

#### Unix

You can use the `build.sh`, for example:

```shell
./build.sh cube_textured run
```

To build optimized for release mode, provide the option `release`:

```shell
./build.sh cube_textured release
```

#### Options

Available script commands:

+ `run`: Run the example after a sussefull build
+ `release`: Build optimized for release mode
+ `clean`: Removes artifacts (.exe, .pdb, .a, etc) before build

Any other argument is passed to the `odin` command, on Windows, wrap any additional arguments
in double quotes:

```shell
build.bat imgui run "-define:APP_ENABLE_IMGUI=true" "-use-separate-modules"
```

## Examples

### [Triangle](./triangle/triangle.odin)

Verbose example for getting a colored triangle rendered to the screen. This is meant as a
starting point for learning WGPU from the ground up.

### Misc

#### [Info](./info/info.odin)

Print current WGPU version and selected adapter information.

### Basic Graphics

#### [Clear Screen](./clear_screen/clear_screen.odin)

This example shows how to set up a render pass for clearing the screen. The screen clearing
animation shows a fade-in and fade-out effect from blue to black.

#### [Triangle MSAA](./triangle_msaa/triangle_msaa.odin)

Shows multisampled rendering the previous triangle example.

#### [Square](./square/square.odin)

This example shows how to render a static colored square with only using vertex buffers.

#### Stencil Triangles

This example renders two different sized triangles to display three same sized triangles, by
demonstrating the use of stencil buffers.

#### [Two Cubes](./two_cubes/two_cubes.odin)

This example shows some of the alignment requirements involved when updating and binding
multiple slices of a uniform buffer. It renders two rotating cubes which have transform
matrices at different offsets in a uniform buffer.

#### [Cubemap](./cubemap/cubemap.odin)

This example shows how to render and sample from a cubemap texture.

#### [Coordinate System](./coordinate_system/coordinate_system.odin)

Demonstrates the coordinate system in WGPU by rendering a series of axes and grids to help
visualize 3D space orientation.

#### [Cube](./cube/cube.odin)

Basic example showing how to render a 3D cube with solid colors and depth testing.

#### [Rotating Cube](./rotating_cube/rotating_cube.odin)

This example shows how to upload uniform data every frame to render a rotating object.

#### [Textured Cube](./textured_cube/textured_cube.odin)

This example shows how to bind and sample textures.

#### [Cube Textured](./cube_textured/cube_textured.odin)

An alternative implementation of texture mapping on a cube, demonstrating different UV mapping
techniques.

#### [Instanced Cube](./instanced_cube/instanced_cube.odin)

Demonstrates instance rendering by drawing multiple cubes efficiently using instancing
techniques.

### Compute

#### [Simple Compute](./compute/compute.odin)

Shows how to use compute shaders and storage buffers in WGPU.

### Graphics Techniques

#### [Cameras](./cameras/cameeras.odin)

This example provides example camera implementations.

#### [Image Blur](./image_blur/image_blur.odin)

Shows how to implement a Gaussian blur effect using compute shaders for image processing.

#### [Texture Arrays](./texture_arrays/texture_arrays.odin)

Shows how to use texture arrays in WGPU, allowing multiple textures to be stored and accessed
as a single array texture.

#### [Capture](./capture/capture.odin)

Demonstrates how to capture and save the contents of a render target to an image file.

### UI and Integration

#### [ImGui](./imgui/imgui_example.odin)

Shows integration with the ImGui for creating user interfaces in WGPU.

#### [MicroUI](./microui/microui.odin)

Shows integration with the MicroUI for creating user interfaces in WGPU.

### Tutorials

#### [Learn WGPU](./learn_wgpu)

This is a great Rust tutorial you can read from <https://sotrh.github.io/learn-wgpu>.
The challenges are included.
