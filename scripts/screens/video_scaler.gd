class_name VideoScaler
extends SubViewport

## The view's picture at the video's size, drawn on the GPU for
## VideoRecorder: reading back the full window (a Retina or 5K view is
## 15-60 MB a frame) and scaling it on one CPU thread could not keep up,
## so only this small RGBA8 target is read back. Each video pixel averages
## a TAPS x TAPS grid of linear samples across its footprint in the view
## (a box filter, like the encoder's CPU scaler), so fine detail doesn't
## shimmer as the view is scaled down.

const MAX_TAPS := 4
const SHADER := """
shader_type canvas_item;
// One video pixel in the source's UV space, and samples per axis.
uniform vec2 footprint;
uniform int taps = 1;

void fragment() {
	vec4 sum = vec4(0.0);
	for (int y = 0; y < taps; y++) {
		for (int x = 0; x < taps; x++) {
			vec2 o = (vec2(float(x), float(y)) + 0.5) / float(taps) - 0.5;
			sum += texture(TEXTURE, UV + o * footprint);
		}
	}
	COLOR = vec4(sum.rgb / float(taps * taps), 1.0);
}
"""

static var _shader: Shader

## Bilinear taps per axis to cover a `ratio`-to-one reduction: each tap
## already averages two source pixels a side.
static func taps_for(ratio: float) -> int:
	return clampi(ceili(ratio / 2.0), 1, MAX_TAPS)

func _init(source: Texture2D, src_size: Vector2i, out_size: Vector2i) -> void:
	size = out_size
	disable_3d = true
	transparent_bg = false
	use_hdr_2d = false
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("footprint", Vector2(1.0 / out_size.x, 1.0 / out_size.y))
	var ratio := maxf(float(src_size.x) / out_size.x, float(src_size.y) / out_size.y)
	mat.set_shader_parameter("taps", taps_for(ratio))
	var pic := TextureRect.new()
	pic.texture = source
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_SCALE
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	pic.size = Vector2(out_size)
	pic.material = mat
	add_child(pic)
