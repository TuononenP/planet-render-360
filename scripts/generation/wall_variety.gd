class_name WallVariety
extends RefCounted

## Per-building wall variety, the facade twin of RoofVariety. Facades
## share a few materials per look, so a street of one style read as one
## freshly cleaned block. Each real building's wall surfaces carry a
## vertex colour that wall materials multiply into the (tinted) wall
## photo — never into painted frames or glass (FacadePaint's detail
## layer is mixed in after the vertex colour):
## - a seeded tint: some fronts cleaner and paler, some sooty, some
##   warmer or cooler stone/paint;
## - sky occlusion: the lowest storeys see less sky between neighbours
##   and darken toward the street, the top keeps its full tint.
## Impostors and far masses carry no colour (white), as for roofs.

const SPREAD := 0.09
const WARMTH := 0.04
## Shade at the foot of a wall and the height (m) it fades out over.
const FOOT_SHADE := 0.82
const FADE_M := 14.0

static func mark(m: BaseMaterial3D) -> void:
	m.set_meta("wall", true)
	m.vertex_color_use_as_albedo = true

static func is_wall(m: Material) -> bool:
	return m != null and m.has_meta("wall")

## Tint for the building at x/z; stable per building, mean ≈ 1.
static func tint_for(x: float, z: float) -> Color:
	var l := 1.0 + (TerrainBuilder._hash(x * 0.53 + 17.0, z * 0.29) * 2.0 - 1.0) * SPREAD
	var w := (TerrainBuilder._hash(z * 0.61 + 3.0, x * 1.13) * 2.0 - 1.0) * WARMTH
	return Color(l * (1.0 + w), l, l * (1.0 - w))

## Per-vertex colours of one wall surface: `c` shaded by height above the
## surface's lowest vertex.
static func colours(verts: PackedVector3Array, c: Color) -> PackedColorArray:
	var y0 := INF
	for v in verts:
		y0 = minf(y0, v.y)
	var fade := FADE_M * WorldScale.metres_to_units()
	var cols := PackedColorArray()
	cols.resize(verts.size())
	for i in verts.size():
		var k := lerpf(FOOT_SHADE, 1.0, clampf((verts[i].y - y0) / fade, 0.0, 1.0))
		cols[i] = Color(c.r * k, c.g * k, c.b * k)
	return cols
