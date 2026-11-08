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

const SPREAD := 0.14
const WARMTH := 0.04
## Shade at the foot of a wall and the height (m) it fades out over.
const FOOT_SHADE := 0.82
const FADE_M := 14.0

static func mark(m: BaseMaterial3D) -> void:
	m.set_meta("wall", true)
	m.vertex_color_use_as_albedo = true

static func is_wall(m: Material) -> bool:
	return m != null and m.has_meta("wall")

## Paint families a building's own colour is drawn from (per-channel
## multipliers over the look's wall tint). None exceeds 1: vertex colours
## are 8-bit, so a brighter multiplier would clamp anyway. Cream, ochre,
## blush, sage and mist are the render and plaster colours real streets
## mix; "clean" leaves the look's own tint.
const FAMILIES: Array[Color] = [
	Color(1.00, 1.00, 1.00), Color(1.00, 0.95, 0.80), Color(1.00, 0.84, 0.58),
	Color(1.00, 0.84, 0.80), Color(0.84, 0.95, 0.80), Color(0.82, 0.90, 1.00)]

## Tint for the building at x/z; stable per building, mean ≈ 1. `chroma`
## (0..1, ArchitectureStyle.chroma_of the wall set) adds that building's
## paint family on top, `tone` (0..1, ArchitectureStyle.tone_for the place)
## rotates which families the place favours, so a city leans cream and sage
## where its neighbour leans ochre and blush. chroma 0 is the plain tint
## (the far city's native kernel reproduces exactly that).
static func tint_for(x: float, z: float, chroma: float = 0.0, tone: float = 0.0) -> Color:
	var l := 1.0 + (TerrainBuilder._hash(x * 0.53 + 17.0, z * 0.29) * 2.0 - 1.0) * SPREAD
	var w := (TerrainBuilder._hash(z * 0.61 + 3.0, x * 1.13) * 2.0 - 1.0) * WARMTH
	var base := Color(l * (1.0 + w), l, l * (1.0 - w))
	if chroma <= 0.0:
		return base
	var fam := Color.WHITE.lerp(FAMILIES[_family(x, z, tone)], minf(chroma, 1.0))
	return Color(minf(base.r * fam.r, 1.0), minf(base.g * fam.g, 1.0), minf(base.b * fam.b, 1.0))

## The paint family at x/z: a seeded pick weighted by how close each family
## sits to the place's `tone` on a circle (every family stays possible).
static func _family(x: float, z: float, tone: float) -> int:
	var n := FAMILIES.size()
	var weights := PackedFloat32Array()
	var total := 0.0
	for i in n:
		var k := maxf(0.25, 1.0 + 1.1 * cos(TAU * (float(i) / float(n) - tone)))
		weights.append(k)
		total += k
	var t := TerrainBuilder._hash(x * 0.83 + 29.0, z * 0.47 + 7.0) * total
	for i in n:
		t -= weights[i]
		if t < 0.0:
			return i
	return 0

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
