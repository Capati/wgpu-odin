// Converts a linear (physical) color to sRGB space
fn linear_to_srgb(linear: vec3<f32>) -> vec3<f32> {
    let cutoff = vec3<f32>(0.0031308);
    let srgb_low = linear * 12.92;
    let srgb_high = pow(linear, vec3<f32>(1.0 / 2.4)) * 1.055 - 0.055;
    return select(srgb_high, srgb_low, linear <= cutoff);
}
