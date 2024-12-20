package application

// Packages
import "core:math"
import la "core:math/linalg"

// Local packages
import "./../../wgpu"

Color :: wgpu.Color


/*
Returns a gray color.

**Parameters**:
- `brightness`: The brightness of the color. `0.0` is black, `1.0` is white.
*/
color_gray :: proc "contextless" (brightness: f64) -> Color {
	b := brightness if brightness <= 1.0 else 1.0
	return {b, b, b, 1.0}
}

/*
Returns a semi-transparent white color.

**Parameters**:
- `transparency`: The transparency of the color. `0.0` is transparent, `1.0` is opaque.
*/
color_alpha :: proc "contextless" (transparency: f64) -> Color {
	t := transparency if transparency <= 1.0 else 1.0
	return {1.0, 1.0, 1.0, t}
}

/* Converts an sRGB color component to its linear (physical) representation. */
color_srgb_component_to_linear :: proc "contextless" (color: f64) -> f64 {
	c := clamp(color, 0.0, 1.0)
	if c <= 0.04045 {
		return c / 12.92
	} else {
		return math.pow((c + 0.055) / 1.055, 2.4)
	}
}

/* Converts a linear (physical) color component to its sRGB representation. */
color_linear_component_to_srgb :: proc "contextless" (color: f64) -> f64 {
	if color <= 0.0031308 {
		return clamp(color * 12.92, 0.0, 1.0)
	} else {
		return clamp(math.pow(color, 1.0 / 2.4) * 1.055 - 0.055, 0.0, 1.0)
	}
}

/* Converts a Color from sRGB space to linear (physical) space. */
color_srgb_color_to_linear :: proc "contextless" (color: Color) -> Color {
	color := color
	color_set_srgb_color_to_linear(&color)
	return color
}

/* Converts a Color from sRGB space to linear (physical) space. */
color_set_srgb_color_to_linear :: proc "contextless" (color: ^Color) {
	color.r = color_srgb_component_to_linear(color.r)
	color.g = color_srgb_component_to_linear(color.g)
	color.b = color_srgb_component_to_linear(color.b)
}

/* Converts a Color from linear (physical) space to sRGB space. */
color_linear_color_to_srgb :: proc "contextless" (color: Color) -> Color {
	color := color
	color_set_linear_color_to_srgb(&color)
	return color
}

/* Converts a Color from linear (physical) space to sRGB space. */
color_set_linear_color_to_srgb :: proc "contextless" (color: ^Color) {
	color.r = color_linear_component_to_srgb(color.r)
	color.g = color_linear_component_to_srgb(color.g)
	color.b = color_linear_component_to_srgb(color.b)
}

color_srgb_to_linear :: proc {
	color_srgb_component_to_linear,
	color_srgb_color_to_linear,
}

color_linear_to_srgb :: proc {
	color_linear_component_to_srgb,
	color_linear_color_to_srgb,
}

/* Helper function to convert HSV to RGB. */
color_hsv_to_rgb :: proc "contextless" (h, s, v: f64) -> la.Vector3f64 {
	c := v * s
	x := c * (1.0 - math.abs(math.mod(h * 6.0, 2.0) - 1.0))
	m := v - c

	rgb: la.Vector3f64
	switch int(h * 6.0) {
	case 0:
		rgb = {c, x, 0}
	case 1:
		rgb = {x, c, 0}
	case 2:
		rgb = {0, c, x}
	case 3:
		rgb = {0, x, c}
	case 4:
		rgb = {x, 0, c}
	case 5:
		rgb = {c, 0, x}
	}

	return la.Vector3f64{rgb.x + m, rgb.y + m, rgb.z + m}
}

/* Helper function to convert HSV to Color. */
color_hsv_to_color :: proc "contextless" (h, s, v: f64) -> (color: Color) {
	rgb := color_hsv_to_rgb(h, s, v)
	color.r = rgb.r
	color.g = rgb.g
	color.b = rgb.b
	color.a = 1.0
	return
}

color_lerp :: proc(a, b: Color, t: f64) -> (c: Color) {
	c.r = (1 - t) * a.r + t * b.r
	c.g = (1 - t) * a.g + t * b.g
	c.b = (1 - t) * a.b + t * b.b
	return
}

ColorTransparent :: Color{0.0, 0.0, 0.0, 0.0}
ColorAliceBlue :: Color{0.941176, 0.972549, 1.0, 1.0}
ColorAntiqueWhite :: Color{0.980392, 0.921569, 0.843137, 1.0}
ColorAqua :: Color{0.0, 1.0, 1.0, 1.0}
ColorAquamarine :: Color{0.498039, 1.0, 0.831373, 1.0}
ColorAzure :: Color{0.941176, 1.0, 1.0, 1.0}
ColorBeige :: Color{0.960784, 0.960784, 0.862745, 1.0}
ColorBisque :: Color{1.0, 0.894118, 0.768627, 1.0}
ColorBlack :: Color{0.0, 0.0, 0.0, 1.0}
ColorBlanchedAlmond :: Color{1.0, 0.921569, 0.803922, 1.0}
ColorBlue :: Color{0.0, 0.0, 1.0, 1.0}
ColorBlueViolet :: Color{0.541176, 0.168627, 0.886275, 1.0}
ColorBrown :: Color{0.647059, 0.164706, 0.164706, 1.0}
ColorBurlyWood :: Color{0.870588, 0.721569, 0.529412, 1.0}
ColorCadetBlue :: Color{0.372549, 0.619608, 0.627451, 1.0}
ColorChartreuse :: Color{0.498039, 1.0, 0.0, 1.0}
ColorChocolate :: Color{0.823529, 0.411765, 0.117647, 1.0}
ColorCoral :: Color{1.0, 0.498039, 0.313725, 1.0}
ColorCornflowerBlue :: Color{0.392157, 0.584314, 0.929412, 1.0}
ColorCornsilk :: Color{1.0, 0.972549, 0.862745, 1.0}
ColorCrimson :: Color{0.862745, 0.0784314, 0.235294, 1.0}
ColorCyan :: Color{0.0, 1.0, 1.0, 1.0}
ColorDarkBlue :: Color{0.0, 0.0, 0.545098, 1.0}
ColorDarkCyan :: Color{0.0, 0.545098, 0.545098, 1.0}
ColorDarkGoldenrod :: Color{0.721569, 0.529412, 0.0431373, 1.0}
ColorDarkGray :: Color{0.662745, 0.662745, 0.662745, 1.0}
ColorDarkGreen :: Color{0.0, 0.392157, 0.0, 1.0}
ColorDarkKhaki :: Color{0.741176, 0.717647, 0.419608, 1.0}
ColorDarkMagenta :: Color{0.545098, 0.0, 0.545098, 1.0}
ColorDarkOliveGreen :: Color{0.333333, 0.419608, 0.184314, 1.0}
ColorDarkOrange :: Color{1.0, 0.54902, 0.0, 1.0}
ColorDarkOrchid :: Color{0.6, 0.196078, 0.8, 1.0}
ColorDarkRed :: Color{0.545098, 0.0, 0.0, 1.0}
ColorDarkSalmon :: Color{0.913725, 0.372549, 0.478431, 1.0}
ColorDarkSeaGreen :: Color{0.560784, 0.737255, 0.560784, 1.0}
ColorDarkSlateBlue :: Color{0.282353, 0.239216, 0.545098, 1.0}
ColorDarkSlateGray :: Color{0.184314, 0.309804, 0.309804, 1.0}
ColorDarkTurquoise :: Color{0.0, 0.807843, 0.819608, 1.0}
ColorDarkViolet :: Color{0.580392, 0.0, 0.827451, 1.0}
ColorDeepPink :: Color{1.0, 0.0784314, 0.576471, 1.0}
ColorDeepSkyBlue :: Color{0.0, 0.74902, 1.0, 1.0}
ColorDimGray :: Color{0.411765, 0.411765, 0.411765, 1.0}
ColorDodgerBlue :: Color{0.117647, 0.564706, 1.0, 1.0}
ColorFirebrick :: Color{0.698039, 0.133333, 0.133333, 1.0}
ColorFloralWhite :: Color{1.0, 0.980392, 0.941176, 1.0}
ColorForestGreen :: Color{0.133333, 0.545098, 0.133333, 1.0}
ColorFuchsia :: Color{1.0, 0.0, 1.0, 1.0}
ColorGainsboro :: Color{0.862745, 0.862745, 0.862745, 1.0}
ColorGhostWhite :: Color{0.972549, 0.972549, 1.0, 1.0}
ColorGold :: Color{1.0, 0.843137, 0.0, 1.0}
ColorGoldenrod :: Color{0.854902, 0.647059, 0.12549, 1.0}
ColorGray :: Color{0.501961, 0.501961, 0.501961, 1.0}
ColorGreen :: Color{0.0, 0.501961, 0.0, 1.0}
ColorGreenYellow :: Color{0.678431, 1.0, 0.184314, 1.0}
ColorHoneydew :: Color{0.941176, 1.0, 0.941176, 1.0}
ColorHotPink :: Color{1.0, 0.411765, 0.705882, 1.0}
ColorIndianRed :: Color{0.803922, 0.360784, 0.360784, 1.0}
ColorIndigo :: Color{0.294118, 0.0, 0.509804, 1.0}
ColorIvory :: Color{1.0, 1.0, 0.941176, 1.0}
ColorKhaki :: Color{0.941176, 0.901961, 0.54902, 1.0}
ColorLavender :: Color{0.901961, 0.901961, 0.941176, 1.0}
ColorLavenderBlush :: Color{1.0, 0.941176, 0.960784, 1.0}
ColorLawnGreen :: Color{0.486275, 0.988235, 0.0, 1.0}
ColorLemonChiffon :: Color{1.0, 0.980392, 0.803922, 1.0}
ColorLightBlue :: Color{0.678431, 0.847059, 0.901961, 1.0}
ColorLightCoral :: Color{0.941176, 0.501961, 0.501961, 1.0}
ColorLightCyan :: Color{0.878431, 1.0, 1.0, 1.0}
ColorLightGoldenrodYellow :: Color{0.980392, 0.980392, 0.823529, 1.0}
ColorLightGray :: Color{0.827451, 0.827451, 0.827451, 1.0}
ColorLightGreen :: Color{0.564706, 0.933333, 0.564706, 1.0}
ColorLightPink :: Color{1.0, 0.713726, 0.756863, 1.0}
ColorLightSalmon :: Color{1.0, 0.627451, 0.478431, 1.0}
ColorLightSeaGreen :: Color{0.12549, 0.698039, 0.666667, 1.0}
ColorLightSkyBlue :: Color{0.529412, 0.807843, 0.937255, 1.0}
ColorLightSlateGray :: Color{0.466667, 0.533333, 0.6, 1.0}
ColorLightSteelBlue :: Color{0.690196, 0.768627, 0.870588, 1.0}
ColorLightYellow :: Color{1.0, 1.0, 0.878431, 1.0}
ColorLime :: Color{0.0, 1.0, 0.0, 1.0}
ColorLimeGreen :: Color{0.196078, 0.803922, 0.196078, 1.0}
ColorLinen :: Color{0.980392, 0.941176, 0.901961, 1.0}
ColorMagenta :: Color{1.0, 0.0, 1.0, 1.0}
ColorMaroon :: Color{0.501961, 0.0, 0.0, 1.0}
ColorMediumAquamarine :: Color{0.4, 0.803922, 0.666667, 1.0}
ColorMediumBlue :: Color{0.0, 0.0, 0.803922, 1.0}
ColorMediumOrchid :: Color{0.729412, 0.333333, 0.827451, 1.0}
ColorMediumPurple :: Color{0.576471, 0.439216, 0.858824, 1.0}
ColorMediumSeaGreen :: Color{0.235294, 0.701961, 0.443137, 1.0}
ColorMediumSlateBlue :: Color{0.482353, 0.407843, 0.933333, 1.0}
ColorMediumSpringGreen :: Color{0.0, 0.980392, 0.603922, 1.0}
ColorMediumTurquoise :: Color{0.282353, 0.819608, 0.8, 1.0}
ColorMediumVioletRed :: Color{0.780392, 0.0823529, 0.780392, 1.0}
ColorMidnightBlue :: Color{0.0980392, 0.0980392, 0.439216, 1.0}
ColorMintCream :: Color{0.960784, 0.980392, 0.968627, 1.0}
ColorMistyRose :: Color{1.0, 0.894118, 0.882353, 1.0}
ColorMoccasin :: Color{1.0, 0.894118, 0.709804, 1.0}
ColorMonoGameOrange :: Color{0.0, 0.235294, 0.905882, 1.0}
ColorNavajoWhite :: Color{1.0, 0.870588, 0.678431, 1.0}
ColorNavy :: Color{0.0, 0.0, 0.501961, 1.0}
ColorOldLace :: Color{0.992157, 0.960784, 0.901961, 1.0}
ColorOlive :: Color{0.501961, 0.501961, 0.0, 1.0}
ColorOliveDrab :: Color{0.419608, 0.556863, 0.137255, 1.0}
ColorOrange :: Color{1.0, 0.647059, 0.0, 1.0}
ColorOrangeRed :: Color{1.0, 0.270588, 0.0, 1.0}
ColorOrchid :: Color{0.854902, 0.439216, 0.839216, 1.0}
ColorPaleGoldenrod :: Color{0.933333, 0.913725, 0.666667, 1.0}
ColorPaleGreen :: Color{0.596078, 0.984314, 0.596078, 1.0}
ColorPaleTurquoise :: Color{0.686275, 0.933333, 0.933333, 1.0}
ColorPaleVioletRed :: Color{0.858824, 0.439216, 0.576471, 1.0}
ColorPapayaWhip :: Color{1.0, 0.937255, 0.835294, 1.0}
ColorPeachPuff :: Color{1.0, 0.854902, 0.72549, 1.0}
ColorPeru :: Color{0.803922, 0.521569, 0.247059, 1.0}
ColorPink :: Color{1.0, 0.752941, 0.796078, 1.0}
ColorPlum :: Color{0.866667, 0.627451, 0.866667, 1.0}
ColorPowderBlue :: Color{0.690196, 0.878431, 0.901961, 1.0}
ColorPurple :: Color{0.501961, 0.0, 0.501961, 1.0}
ColorRed :: Color{1.0, 0.0, 0.0, 1.0}
ColorRosyBrown :: Color{0.737255, 0.560784, 0.560784, 1.0}
ColorRoyalBlue :: Color{0.411765, 0.34902, 0.803922, 1.0}
ColorSaddleBrown :: Color{0.0745098, 0.27451, 0.545098, 1.0}
ColorSalmon :: Color{0.980392, 0.501961, 0.447059, 1.0}
ColorSandyBrown :: Color{0.956863, 0.643137, 0.376471, 1.0}
ColorSeaGreen :: Color{0.180392, 0.545098, 0.341176, 1.0}
ColorSeaShell :: Color{1.0, 0.960784, 0.933333, 1.0}
ColorSienna :: Color{0.627451, 0.321569, 0.176471, 1.0}
ColorSilver :: Color{0.752941, 0.752941, 0.752941, 1.0}
ColorSkyBlue :: Color{0.529412, 0.807843, 0.921569, 1.0}
ColorSlateBlue :: Color{0.415686, 0.352941, 0.803922, 1.0}
ColorSlateGray :: Color{0.439216, 0.501961, 0.564706, 1.0}
ColorSnow :: Color{1.0, 0.980392, 0.980392, 1.0}
ColorSpringGreen :: Color{0.0, 1.0, 0.498039, 1.0}
ColorSteelBlue :: Color{0.27451, 0.509804, 0.705882, 1.0}
ColorTan :: Color{0.823529, 0.705882, 0.54902, 1.0}
ColorTeal :: Color{0.0, 0.501961, 0.501961, 1.0}
ColorThistle :: Color{0.847059, 0.74902, 0.847059, 1.0}
ColorTomato :: Color{1.0, 0.388235, 0.278431, 1.0}
ColorTurquoise :: Color{0.25098, 0.878431, 0.819608, 1.0}
ColorViolet :: Color{0.933333, 0.509804, 0.933333, 1.0}
ColorWheat :: Color{0.960784, 0.870588, 0.701961, 1.0}
ColorWhite :: Color{1.0, 1.0, 1.0, 1.0}
ColorWhiteSmoke :: Color{0.960784, 0.960784, 0.960784, 1.0}
ColorYellow :: Color{1.0, 1.0, 0.0, 1.0}
ColorYellowGreen :: Color{0.603922, 0.803922, 0.196078, 1.0}
