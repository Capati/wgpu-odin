# Odin ImGui

[Odin Language][] bindings for **[Dear ImGui][imgui] 1.91.7 (docking branch)** with native backends implementations written in Odin.

## Introduction

[Dear ImGui][imgui] is an immediate-mode library for programming and rendering graphical user interfaces.

### Features

- **Automated Bindings**: C API generated using [Dear Bindings][]
- **Native Backend Support**:
  - WGPU, GLFW
  - All backends written purely in Odin for better integration
- **Developer-Friendly**:
  - Documentation and comments are preserved
  - Obsolete names removed
  - Consistent naming following Odin naming convention

**Note** The available platform backends is supported to use with wgpu backend, If you want a general usage with most backends available, I recommend check [this repo](https://gitlab.com/L-4/odin-imgui).

## How To Build

This project requires building from source, as pre-built binaries are not provided. The build process utilizes `CMake` and includes automated steps for generating the ImGui bindings.

### Prerequisites

Before building, ensure you have the following tools installed:

- `cmake` (version 3.11 or higher, tested with 3.29.3)
- `git` (accessible from your system PATH)
- `python3` (version 3.10 or higher, also `python3-venv` for Unix systems)

### Build Instructions

The provided `CMakeLists.txt` handles the entire build process, including fetching dependencies and generating bindings.

1. Navigate to the `generator` directory
2. Run CMake to generate build files and compile ImGui
3. The resulting library file will be automatically copied to the project root

## Naming Convention

Types and values follow the [Odin Naming Convention][]. In general, `Ada_Case` for types and `snake_case` for values.

| Element           | Convention           | Example               |
|-------------------|----------------------|-----------------------|
| Types             | Ada_Case             | `Draw_Data`           |
| Enum Values       | Ada_Case             | `No_Title_Bar`        |
| Procedures        | snake_case           | `new_frame`           |
| Local Variables   | snake_case           | `draw_lists`          |
| Struct Fields     | snake_case           | `tex_desired_width`   |
| Constants         | SCREAMING_SNAKE_CASE | `KEY_NAMED_KEY_COUNT` |

### Prefix Removal

The following prefixes are removed:

- `cImGui_Impl`
- `ImGui_Impl`
- `IMGUI_`
- `ImGui_`
- `ImGui`
- `IM_`
- `Im`

### Enums and Flags

- Flags are represented as `bit_set`.
- Some values became constants, for example, `KEY_NAMED_KEY_COUNT`, `WINDOW_FLAGS_NO_DECORATION`

### Special Cases

Due to prefix removal and naming convention, some ImGui identifiers require additional refactoring:

- Type names with underscores:
  - Underscores at the start, end, or middle of type names are removed.
  - After underscore removal, proper CamelCase is applied.
  - Examples:
    - `ImVector_ImWchar` → `VectorWchar`
    - `ImVector_char` → `VectorChar`
    - `_ImGuiInputTextCallback` → `InputTextCallback`
    - `ImGuiContext_` → `Context`

## Example

```odin
// Initialization

im_ctx := im.create_context()
defer im.destroy_context(im_ctx)

im.style_colors_dark()

ensure(im.glfw_init(window, true))
defer im.glfw_shutdown()

init_info := im.DEFAULT_WGPU_INIT_INFO
init_info.device = ctx.gpu.device
init_info.render_target_format = ctx.gpu.config.format

ensure(im.wgpu_init(init_info))
defer im.wgpu_shutdown()

// Update frame

im.wgpu_new_frame() or_return
im.glfw_new_frame()
im.new_frame()

if im.begin("Window containing a quit button") {
    if im.button("The quit button in question") {
    }
}
im.end()

im.render()

// Render

im.wgpu_render_draw_data(im.get_draw_data(), render_pass) or_return
```

## Acknowledgements

- [Odin Language][] - The Odin programming language
- [Dear Bindings](https://github.com/dearimgui/dear_bindings) - Tool to generate the C API
- [Dear ImGui][imgui] - The original ImGui library
- [Odin Imgui](https://gitlab.com/L-4/odin-imgui) - by L4

[imgui]: https://github.com/ocornut/imgui
[Dear Bindings]: https://github.com/dearimgui/dear_bindings
[Odin Language]: https://odin-lang.org/
[Odin Naming Convention]: https://github.com/odin-lang/Odin/wiki/Naming-Convention
