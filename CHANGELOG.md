# CHANGELOG

## [24.0.0.1] - 2025-22-02

feat: upgrade to 24.0.0.1 and refactor core components

> [!WARNING]
> There may be more changes than those listed here. Please refer to the examples, as
> they are always updated.

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
