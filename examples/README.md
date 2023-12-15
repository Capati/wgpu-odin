# Odin WGPU Examples

All examples uses the wrapper package.

Tested in Odin: `dev-2023-11:e8e35014`.

## Examples

Execute the `odin build` command inside the `examples` folder or use the script.

All examples are compiled in the `build` folder, where some shared assets are need between examples. Shader files are `#load` at compile time and are located within the example.

### Windows

You can use the `build_win.bat` with a example name as argument, for example:

```shell
./build_win.bat cube_textured
```

Examples that use the framework, the `Direct3D-12` is enforced, if you want to use `Vulkan`, provide the config as `-define:WGPU_BACKEND_TYPE=Vulkan`:

```bat
set ARGS=-o:speed ^
	-disable-assert ^
	-no-bounds-check ^
	-define:WGPU_BACKEND_TYPE=Vulkan ^
	-define:CHECK_TO_BYTES=false
set OUT=-out:.\build
```

### Unix

You can use the `Makefile`, for example:

```shell
make cube_textured_example
```

The suffix `_example` is to avoid a problem with same target and directory name.

## More Examples

### [Learn WGPU Tutorial](./learn_wgpu)

This is a great Rust tutorial you can read from [Learn Wgpu](https://sotrh.github.io/learn-wgpu/#what-is-wgpu). The challenges are included.
