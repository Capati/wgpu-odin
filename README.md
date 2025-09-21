# WGPU Odin Bindings

Bindings to [wgpu-native][] **25.0.2.1** for the [Odin Language][].

The API is similar to the [Rust API](https://docs.rs/wgpu/latest/wgpu/). This allows developers to
easily translate Rust/WebGPU tutorials and examples into Odin code.

Explore the [examples](./examples) to get started, or jump straight into the
[Triangle](./examples/triangle/triangle.odin) example.

## Status

> [!NOTE]
> The wgpu-API still in the "Working Draft" phase. Until the specification is stabilized, break
> changes can happen without notice.

## Table of Contents

- [Linking](#linking)
- [Quick Start Guide](#quick-start-guide)
- [Examples](#examples)
- [Utilities](#utilities)
- [Naming Conventions](#naming-conventions)
- [License](#license)

## Linking

This repository uses the raw bindings from `vendor`, make sure you read the `doc.odin` from
`<odin-folder>/vendor/wgpu/doc.odin` to learn more about how it works.

## Quick Start Guide

1. Create a folder named `libs/wgpu` in the root of your project (where you run `odin build` from).

    Alternatively, you can use the `shared/wgpu` folder in your Odin installation to later
    import the package in your code:

    ```odin
    import "shared:wgpu"
    ```

2. Clone the contents of this repository in the folder created in the previous step, use the
`--recursive` flag to fetch the assets/libs submodules for the examples:

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
import "libs:wgpu"
```

## Examples

Explore [all examples](./examples) to see WGPU in action. Start with the
[Triangle](./examples/triangle/triangle.odin) for a verbose example.

## Utilities

The [utils](./utils/) folder contains utility packages that enhance your WGPU development
experience. Some of these packages are standalone and can be used independently without requiring
any local package.

- **application** (WIP): A lightweight framework for creating WGPU applications with a simple event
    loop, window management, and basic scene setup. Provides common boilerplate code to help you
    get started quickly.

- **glfw/sdl**: Abstractions for surface creation.

- **imgui** (WIP): A WGPU renderer implementation for the ImGui library. Provides bindings with
    backends implementations written in Odin.

- **microui**: A WGPU renderer implementation for the microui library.

- **shaders**: Common WGSL shader library functions.

For detailed information about any specific utility, please refer to the README files in their
respective directories.

## Naming Conventions

Types and values follow the C API as close as possible.

| Element           | Convention           | Example                 |
|-------------------|----------------------|-------------------------|
| Types             | PascalCase           | `TextureFormat`         |
| Enum Values       | PascalCase           | `HighPerformance`       |
| Procedures        | PascalCase           | `RenderPassEnd`         |
| Local Variables   | snake_case           | `buffer_descriptor`     |
| Struct Fields     | camelCase            | `sampleType`            |
| Constants         | SCREAMING_SNAKE_CASE | `COPY_BUFFER_ALIGNMENT` |

## License

MIT License - See [LICENSE](./LICENSE) file for details.

[wgpu-native]: https://github.com/gfx-rs/wgpu-native
[Odin Language]: https://odin-lang.org/
[OLS]: https://github.com/DanielGavin/ols
