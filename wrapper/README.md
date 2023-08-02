# WGPU Bindings and Wrapper

Odin bindings for [Native WebGPU](https://github.com/gfx-rs/wgpu-native) implementation based on [wgpu-core](https://github.com/gfx-rs/wgpu).

## Naming Convention

Both bindings and wrapper follow the [Odin Naming Convention](https://github.com/odin-lang/Odin/wiki/Naming-Convention). In general, `Ada_Case` for types and `snake_case` for values

|                    | Case                                |
| ------------------ | ----------------------------------- |
| Import Name        | snake_case (but prefer single word) |
| Types              | Ada_Case                            |
| Enum Values        | Ada_Case                            |
| Procedures         | snake_case                          |
| Local Variables    | snake_case                          |
| Constant Variables | SCREAMING_SNAKE_CASE                |

## Bindings only

If you want to use only the bindings, you can import the package from the bindings folder:

```odin
import wgpu "wgpu/bindings"
```

## Wrapper

The root folder of the package is the wrapper version.

The wrapper design is to abstract some boilerplate and group types and their procedures together. This is done using `vtable`, so you can use the [-> operator](https://odin-lang.org/docs/overview/#--operator-selector-call-expressions) to emulate type hierarchies, for example:

```odin
buffer := device->create_buffer(&descriptor)
```

Is equivalent to and can be used in the same way:

```odin
buffer := wgpu.device_create_buffer(&device, &descriptor)
```
