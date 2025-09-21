# CHANGELOG

## [25.0.2.1] - 09-21-2025

feat: upgrade to WGPU 25.0.2.1.

### Added

- `SDL3` utils for surface creation.

### Fixed

- fix(adapter): initialization of `nativeLimits` in `AdapterRequestDevice`.

- fix #19 (examples): mixed up path for tobj.

### Changed

- Use the raw bindings from `vendor`.
  - Change package name to `webgpu` to avoid conflict

- Change naming convention to `PascalCase` and `camelCase` to conform with `vendor` and upstream.
  - All other names are changed too, not just part of wgpu.

- `InstanceRequestAdapter` and `AdapterRequestDevice` now returns a result struct.

  ```odin
  RequestAdapterResult :: struct {
    status:  RequestAdapterStatus,
    message: string,
    adapter: Adapter,
  }
  
  RequestDeviceResult :: struct {
    status:  RequestDeviceStatus,
    message: string,
    device:  Device,
  }
  ```

- Improve leak report.

- Refactor `LimitsCheck`

- Replace `StringViewBuffer` with `StringView` (aka `string`).
  -  Some wrapping around `StringView` are not need anymore
  - `AdapterGetInfo` does not need an allocator

- All procedures uses the `"c"` calling convention by default when possible

- `QueueSubmit` second parameters is now a slice of `CommandBuffer`'s

- Refactor all examples with the latest changes.

### Removed

- Remove the global error handling.
  - Procedures no longer returns an optional ok
  - Errors are now handled by the user
  - The wgpu-native treats errors as fatal by default

- Remove `StringViewBuffer`.
  - The `StringView` are just Odin `string`s, hence no need for the wrapper

- Remove `exports.odin`
  - Move the contents of `wgpu` folder to the root directory

## 2025-23-03

feat: upgrade to 24.0.3.1.

### Changed

**General**:

- Refactor rendering loop to improve input latency, specially on Fifo present mode

## [24.0.0.2] - 2025-28-02

feat: upgrade to 24.0.0.2.

[Compare changes](https://github.com/gfx-rs/wgpu-native/compare/v24.0.0.1...v24.0.0.2).

### Fixed

- Return status from `adapter_info` and `surface_get_capabilities`.

## [24.0.0.1] - 2025-22-02

feat: upgrade to 24.0.0.1 and refactor core components

> [!WARNING]
> There may be more changes than those listed here. Please refer to the examples, as
> they are always updated.

[Compare changes](https://github.com/gfx-rs/wgpu-native/compare/v22.1.0.5...v24.0.0.1).

You can see a [list of changes](https://github.com/gfx-rs/wgpu-native/pull/427) in wgpu-native
since latest update.

### Added

**General**:

- Implement `Buffer_Slice` and `Buffer_View`
- `export.odin` in the root directory to allow use the package directly, useful to avoid
repeating the package name, specially for submodules
- Utility procedure for WGPU Memory Leak Report

**Utils**:

- Create new `application` utils to replace `renderlink` framework
  - Now is using `GLFW` instead of `SDL2`
- Tiny OBJ Loader
  - This is currently used for the examples, but it will eventually be migrated to a submodule.
- WGPU backend for ImGui written in Odin

**Examples**:

- Coordinate System
- Instanced Cube
- Two Cubes
- Square
- learn_wgpu/beginner/tutorial7_instancing
- learn_wgpu/beginner/tutorial7_instancing_challenge
- learn_wgpu/beginner/tutorial8_depth
- learn_wgpu/beginner/tutorial9_model_loading

### Changed

**General**:

- Merge wrapper with raw bindings
  - This means there is no separation of two bindings, only the wrapper now
  - If you need raw version, I recommend the official bindings
- Disallow `do`
- Change the config `WGPU_CHECK_TO_BYTES` in favor of `ODIN_DEBUG`

**Examples**:

- Refactor the build script to build examples automatically by using the target name
  - Also added `run` command for the build script
- Remove Makefile in favor of build.sh

### Fixed

**General**:

- Fixed instances range for **draw** procedures

### Removed

**General**:

- Move queue extension procedures to `application` utils
