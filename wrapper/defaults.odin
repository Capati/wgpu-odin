package wgpu

// Package
import wgpu "../bindings"

// Backends are set to `Primary`, and `FXC` is chosen as the `dx12_shader_compiler`.
Default_Instance_Descriptor :: Instance_Descriptor {
    backends             = wgpu.Instance_Backend_Primary,
    dx12_shader_compiler = .Fxc,
}
Default_Dx12_Compiler :: Dx12_Compiler.Fxc

// High_Performance.
Default_Power_Preference: Power_Preference = .High_Performance

Default_Sampler_Descriptor :: Sampler_Descriptor {
    label          = nil,
    address_mode_u = .Clamp_To_Edge,
    address_mode_v = .Clamp_To_Edge,
    address_mode_w = .Clamp_To_Edge,
    mag_filter     = .Nearest,
    min_filter     = .Nearest,
    mipmap_filter  = .Nearest,
    lod_min_clamp  = 0.0,
    lod_max_clamp  = 32.0,
    compare        = .Undefined,
    max_anisotropy = 1,
}

// Default `count = 1` and mask all pixels `0xFFFFFFFF`.
Default_Multisample_State := Multisample_State {
    next_in_chain             = nil,
    count                     = 1,
    mask                      = ~u32(0), // 0xFFFFFFFF
    alpha_to_coverage_enabled = false,
}
