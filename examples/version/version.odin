package version

// Core
import "core:fmt"

// Package
import wgpu "../../"

start :: proc() {
    wgpu_version := wgpu.get_version()

    fmt.printf(
        "WGPU version: %d.%d.%d.%d\n",
        (wgpu_version >> 24) & 0xFF,
        (wgpu_version >> 16) & 0xFF,
        (wgpu_version >> 8) & 0xFF,
        wgpu_version & 0xFF,
    )
}
