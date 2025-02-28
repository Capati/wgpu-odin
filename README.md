# WGPU Odin Bindings

Bindings to [wgpu-native][] **24.0.0.2** for the [Odin Language][].

This repository provides handcrafted Odin bindings for [wgpu-native][], offering an API similar to
the [Rust API](https://docs.rs/wgpu/latest/wgpu/). This allows developers to easily translate
Rust/WebGPU tutorials and examples into Odin code.

Explore the [examples](./examples) to get started, or jump straight into the
[Triangle](./examples/triangle/triangle.odin) example.

## Status

> [!NOTE]
> The wgpu-API still in the "Working Draft" phase. Until the specification is stabilized, break
> changes can happen without notice.

## Table of Contents

- [Linking](#linking)
  - [Windows](#windows)
  - [Unix](#unix)
    - [Link against system](#link-against-system)
- [Quick Start Guide](#quick-start-guide)
- [Examples](#examples)
- [Utilities](#utilities)
- [TODO (Roadmap)](#todo-roadmap)
- [Naming Conventions](#naming-conventions)
- [License](#license)

## Linking

To keep this repository lightweight and maintainable, prebuilt binaries are not included (they can
exceed 130MB). You can build the library yourself or download the necessary files from the
[wgpu-native][] releases page:

<https://github.com/gfx-rs/wgpu-native/releases/tag/v24.0.0.2>

**Ensure the version matches the upstream release**. Place the downloaded files in the `wgpu/lib/`
directory according to the following structure:

```text
📦lib
 ┣ 📂linux
 ┃ ┣ 📂arch64
 ┃ ┃ ┗ 📜libwgpu_native.a
 ┃ ┗ 📂x86_64
 ┃ ┃ ┗ 📜libwgpu_native.a
 ┣ 📂mac_os
 ┃ ┣ 📂arch64
 ┃ ┃ ┗ 📜libwgpu_native.a
 ┃ ┗ 📂x86_64
 ┃ ┃ ┗ 📜libwgpu_native.a
 ┣ 📂windows
 ┃ ┣ 📂i686
 ┃ ┃ ┃ 📜wgpu_native.dll.lib
 ┃ ┃ ┗ 📜wgpu_native.lib
 ┃ ┗ 📂x86_64
 ┃ ┃ ┃ 📜wgpu_native.dll.lib
 ┃ ┃ ┗ 📜wgpu_native.lib
```

For more details, refer to the foreign imports in [wgpu_lib.odin](./wgpu/wgpu_lib.odin). For
example, on Windows, download `wgpu-windows-x86_64-release.zip` and place `lib/wgpu_native.dll.lib`
in `lib/windows/x86_64/`.

### Windows

By default, Windows uses dynamic linking, requiring `wgpu_native.dll` alongside your executable. To
enable static linking, set the Odin config `WGPU_SHARED` to `false`.

### Unix

Linux and Mac default to static linking for ease of use. However, you can link against system
libraries if desired.

#### Link against system

On Linux or Mac, you can tell the library to link against system `libwgpu_native` instead of one
provided in the directory by defining the Odin config value `WGPU_USE_SYSTEM_LIBRARIES` as `true`.

## Quick Start Guide

1. Create a folder named `libs/wgpu` in the root of your project (where you run `odin build` from).

    Alternatively, you can use the `shared/wgpu` folder in your Odin installation to later
    import the package in your code:

    ```odin
    import "shared:wgpu/wgpu"
    ```

2. Clone the contents of this repository in the folder created in the previous step, use the
`--recursive` flag to fetch the assets submodule for the examples:

    ```shell
    git clone --recursive https://github.com/Capati/wgpu-odin.git .
    ```

3. Ensure you follow the [Linking](#linking) steps outlined above to include the appropriate
binaries for your target platform.

If you are not using the `shared` folder, to easily import the package into your project, set up a
`collection` by adding this to your build command:

```shell
odin build ./src -collection:libs=./libs
```

You can now import the package in your code:

```odin
import "libs:wgpu/wgpu"
```

> [!NOTE]
> While you can import directly from the root folder since all names are exported from the
> `wgpu/wgpu` folder to [export.odin](./export.odin), using explicit imports provides better editor
> support. When importing from the root, [OLS][] (Odin Language Server) won't be able to show inline
> documentation, and you'll need to jump twice to definitions.

## Examples

Explore [all examples](./examples) to see WGPU in action. Start with the
[Triangle](./examples/triangle/triangle.odin) for a verbose example.

## Utilities

The [utils](./utils/) folder contains utility packages that enhance your WGPU development
experience. Some of these packages are standalone and can be used independently without requiring
any local package.

- **application** (WIP): A lightweight framework for creating WGPU applications with a simple event
  loop, window management, and basic scene setup. Provides common boilerplate code to help you get
  started quickly.

- **glfw/sdl**: Abstractions for surface creation.

- **imgui** (WIP): A WGPU renderer implementation for the ImGui library. Provides bindings with
  backends implementations written in Odin.

- **microui**: A WGPU renderer implementation for the microui library.

- **shaders**: Common WGSL shader library functions.

- **tobj**: Wavefront .obj file loader and parser. Enables easy loading of 3D models and their
  materials into your graphics applications.

For detailed information about any specific utility, please refer to the README files in their
respective directories.

## TODO (Roadmap)

- [x] Export names in the root folder (useful for submodules and to avoid importing the wgpu package
  directly)
- [ ] KTX2 parser
- [ ] Option to choose DAWN or WGPU implementation
- [ ] Wasm support

## Naming Conventions

Types and values follow the [Odin Naming Convention][]. In general, `Ada_Case` for types and
`snake_case` for values:

| Element           | Convention           | Example                 |
|-------------------|----------------------|-------------------------|
| Types             | Ada_Case             | `Texture_Format`        |
| Enum Values       | Ada_Case             | `High_Performance`      |
| Procedures        | snake_case           | `render_pass_end`       |
| Local Variables   | snake_case           | `buffer_descriptor`     |
| Struct Fields     | snake_case           | `sample_type`           |
| Constants         | SCREAMING_SNAKE_CASE | `COPY_BUFFER_ALIGNMENT` |

You can find the complete list of names in the [export.odin](./export.odin) file.

## License

MIT License - See [LICENSE](./LICENSE) file for details.

[wgpu-native]: https://github.com/gfx-rs/wgpu-native
[Odin Language]: https://odin-lang.org/
[Odin Naming Convention]: https://github.com/odin-lang/Odin/wiki/Naming-Convention
[OLS]: https://github.com/DanielGavin/ols
