# Odin WGPU Examples

All examples uses the wrapper package.

## Examples

Execute the `odin build` command inside the `examples` folder.

### [Info](./info/info.odin)

Print current WGPU version and selected adapter information.

```shell
odin build . -define:INFO_EXAMPLE=true -out:./build/<executable-name>
```

Output example:

```shell
WGPU version: 0.17.0.2

Selected device:

AMD Radeon (TM) RX 6650 XT
        Driver: 23.7.2
        Type: Discrete GPU with separate CPU/GPU memory
        Backend: Vulkan API
```

### [Simple Compute](./simple_compute/simple_compute.odin)

```shell
odin build . -define:SIMPLE_COMPUTE=true -out:./build/<executable-name>
```

### [Triangle](./triangle/triangle.odin)

This example uses `SDL2` from the `vendor:sdl2` package on all platforms.

```shell
odin build . -define:TRIANGLE_EXAMPLE=true -out:./build/<executable-name>
```

#### Triangle MSAA

This uses the same triangle example but with 4x MSAA.

```shell
odin build . -define:TRIANGLE_MSAA_EXAMPLE=true -out:./build/<executable-name>
```

![Triangle 4x MSAA](./triangle/triangle_msaa.png)
