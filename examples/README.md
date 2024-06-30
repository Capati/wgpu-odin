# Odin WGPU Examples

**All examples uses the wrapper package**.

Tested in Odin: `dev-2024-06:edcbca51c`.

## Examples

Execute the `odin build` command inside the `examples` folder or use the script.

All examples are compiled in the `build` folder, where some shared assets are need between examples. Shader files are `#load` at compile time and are located within the example.

By default the examples are built in debug mode with the flag `-debug`.

### Windows

You can use the `build_win.bat` with a example name as argument, for example:

```shell
.\build_win.bat cube_textured
```

To run the examples you need `wgpu_native.dll` along side the examples executables, just place this file in the `build` directory. Examples that use the framework need `SDL2.dll` that can be copied from your Odin installation in `\vendor\sdl2\SDL2.dll` to the `build` directory.

To build optimized for release mode, provide a second argument:

```shell
.\build_win.bat cube_textured release
```

If you want to enforce `DirectX 12`, change the script `build_win.bat` to provide the config as `-define:WGPU_BACKEND_TYPE=DX12`:

```bat
set ARGS=%ARGS% -define:WGPU_BACKEND_TYPE=DX12
```

### Unix

You can use the `Makefile`, for example:

```shell
make cube_textured
```

To build optimized for release mode, set the `MODE` option to `release`:

```shell
make cube_textured MODE=release
```

## More Examples

### [Learn WGPU Tutorial](./learn_wgpu)

This is a great Rust tutorial you can read from [Learn Wgpu](https://sotrh.github.io/learn-wgpu/#what-is-wgpu). The challenges are included.
