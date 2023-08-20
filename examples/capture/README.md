# Capture

This example shows how to capture an image by rendering it to a texture, copying the texture to a buffer, and retrieving it from the buffer.

This create ./red.png with all pixels red and size 100x200.

## Build

```shell
odin build ./capture -out:./build/<executable-name>
```

**Note**: If you get `write_png` reference errors, try to run the Makefile on `/vendor/stb/src`.

## Screenshots

![Capture](./red.png)
