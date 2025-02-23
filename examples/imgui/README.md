# ImGui Example

This example demonstrates how to use Dear ImGui with WGPU backend in Odin to create graphical
user interfaces.

## Compile ImGui

First, ensure you cloned this repository with submodules, then follow the build instructions
provided in the link below. You just need the `glfw` backend, while the `wgpu` backend can be
skipped as it's implemented in Odin.

<https://github.com/Capati/odin-imgui/tree/main?tab=readme-ov-file#building>

## Build

```shell
build.bat imgui run
```

```shell
odin build ./imgui -out:./build/<executable-name>
```
