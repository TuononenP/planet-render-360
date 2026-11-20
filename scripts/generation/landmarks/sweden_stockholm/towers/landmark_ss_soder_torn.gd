extends RefCounted

## Söder Torn (Söderhallarna, 1997-99, Ralph Erskine's tower for Medborgarplatsen),
## origin at the centre of the mapped octagon, 86 m tall. The registry yaw
## (-13.3) turns the model's facets (normals at 0, 45, 90 degrees) onto the
## mapped octagon, whose edges run about 32 degrees mod 45.
##
## The shaft is a regular octagon, 23.3 m across the flats (OSM way 37299689:
## 23.1-23.4 m), clad in tan granite panels. Each facet carries six narrow
## tall windows per storey on a 2.9 m storey rhythm (24 storeys in all);
## the last two storeys have small square windows in a plain band, under a
## thin projecting stone cornice at 69.4-70 m.
##
## The crown, measured off the side photo against the 23.3 m shaft:
## - a round drum clad in silver panels (radius 7.4 m) with a balcony and
##   railing round it on the octagon roof,
## - a glazed restaurant cylinder (radius 5.7 m, 3.4 m tall) with slim
##   mullions, lit warm at night,
## - the flared bronze saucer roof (radius 8.3 m) over it,
## - above it an openwork cage: ten slender steel columns on a 4.4 m
##   radius carrying a thin ring at the 86 m top.
##
## Sources: sv/en Wikipedia (86 m, 24 storeys), OSM way 37299689, and the
## Commons photos in visual-plan/refs/landmarks/soder_torn/.

const FLATS := 11.65
const SHAFT_TOP := 69.4
const CORNICE_TOP := 70.0
const DRUM_TOP := 72.6
const GLASS_TOP := 76.0
const TOP := 86.0
const STOREY := 2.9
const SKIN := 0.3

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("stone", "#B39C84", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3A44"))
	lm.use("Steel", LandmarkMaterials.pbr("concrete", "#B9BDC0", 2.0, 0.4, 0.65))
	lm.use("Saucer", LandmarkMaterials.pbr("concrete", "#A98F6E", 2.0, 0.3, 0.8))
	lm.use("CrownLamp", _crown_glass())
	_shaft(lm)
	_windows(lm)
	_crown(lm)
	lm.commit(model)

## Restaurant glazing: glass by day, warm-lit at night (LandmarkLights).
static func _crown_glass() -> StandardMaterial3D:
	var m := LandmarkMaterials.glass("#3E4F5A").duplicate() as StandardMaterial3D
	m.emission_enabled = true
	m.emission = Color("#FFD9A0")
	m.emission_energy_multiplier = 0.0
	m.set_meta(LandmarkLights.NIGHT_GLOW_META, 0.6)
	return m

## Octagon outline (circumradius from the flats), vertices on the diagonals.
static func _octagon(flats: float) -> PackedVector2Array:
	var poly := PackedVector2Array()
	var r := flats / cos(PI / 8.0)
	for k in 8:
		var a := TAU * (float(k) + 0.5) / 8.0
		poly.append(Vector2(cos(a), sin(a)) * r)
	return poly

static func _shaft(lm: LandmarkMesh) -> void:
	lm.poly_prism("Wall", _octagon(FLATS - SKIN + 0.02), 0.0, SHAFT_TOP, true)
	# Projecting cornice under the crown.
	lm.poly_prism("Wall", _octagon(FLATS + 0.35), SHAFT_TOP, CORNICE_TOP, true)

## Window skins on the eight facets: tall narrow windows up the storeys,
## small square ones in the top band.
static func _windows(lm: LandmarkMesh) -> void:
	var width := 2.0 * FLATS * tan(PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var n := Vector3(cos(a), 0, sin(a))
		var right := Vector3.UP.cross(n)
		var origin := n * (FLATS - SKIN) - right * width * 0.5
		LandmarkDetail.pierced_face(lm, "Wall", "Glass", origin, right, n, width, 64.0, 6, 22,
			Vector2(0.85, 1.75), 0.95, STOREY, SKIN)
		LandmarkDetail.pierced_face(lm, "Wall", "Glass", origin + Vector3.UP * 64.0, right, n,
			width, SHAFT_TOP - 64.0, 6, 3, Vector2(0.8, 0.8), 1.0, 2.2, SKIN)

static func _crown(lm: LandmarkMesh) -> void:
	# Silver drum and the balcony round it on the octagon roof.
	lm.frustum("Steel", Vector3(0, CORNICE_TOP, 0), 7.4, 7.4, DRUM_TOP - CORNICE_TOP, 24)
	_balcony(lm, 7.75, CORNICE_TOP)
	# Glazed restaurant cylinder with its mullions.
	lm.frustum("CrownLamp", Vector3(0, DRUM_TOP, 0), 5.7, 5.7, GLASS_TOP - DRUM_TOP, 32)
	for i in 24:
		var a := TAU * float(i) / 24.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Steel", d * 5.78 + Vector3.UP * DRUM_TOP, d * 5.78 + Vector3.UP * GLASS_TOP, 0.14, 0.14)
	# The flared saucer roof: underside dishing out to a rim, flat top.
	lm.lathe("Saucer", Vector3(0, GLASS_TOP, 0), PackedVector2Array([Vector2(5.7, -0.1),
		Vector2(6.6, 0.05), Vector2(7.6, 0.4), Vector2(8.2, 0.8), Vector2(8.3, 1.05),
		Vector2(8.1, 1.3), Vector2(6.0, 1.4), Vector2(4.2, 1.4)]), 36)
	# Openwork cage: slender columns and the ring they carry.
	var base_y := GLASS_TOP + 1.4
	for i in 10:
		var a := TAU * float(i) / 10.0
		lm.frustum("Steel", Vector3(cos(a) * 4.4, base_y, sin(a) * 4.4), 0.24, 0.24, TOP - 0.5 - base_y, 8)
	_ring(lm, "Steel", 4.4, TOP - 0.5, 0.5, 0.5, 20)

## A railing round a circle: posts and a handrail of straight segments.
static func _balcony(lm: LandmarkMesh, r: float, y0: float) -> void:
	var seg := 24
	for i in seg:
		var a0 := TAU * float(i) / float(seg)
		var a1 := TAU * float(i + 1) / float(seg)
		var p0 := Vector3(cos(a0) * r, 0, sin(a0) * r)
		var p1 := Vector3(cos(a1) * r, 0, sin(a1) * r)
		lm.beam("Steel", p0 + Vector3.UP * y0, p0 + Vector3.UP * (y0 + 1.1), 0.07, 0.07)
		lm.beam("Steel", p0 + Vector3.UP * (y0 + 1.1), p1 + Vector3.UP * (y0 + 1.1), 0.08, 0.08)
		lm.beam("Steel", p0 + Vector3.UP * (y0 + 0.5), p1 + Vector3.UP * (y0 + 0.5), 0.05, 0.05)

## A flat ring of `count` straight members at radius r, y0..y0+h.
static func _ring(lm: LandmarkMesh, key: String, r: float, y0: float, h: float, w: float, count: int) -> void:
	for i in count:
		var a0 := TAU * float(i) / float(count)
		var a1 := TAU * float(i + 1) / float(count)
		var p0 := Vector3(cos(a0) * r, y0 + h * 0.5, sin(a0) * r)
		var p1 := Vector3(cos(a1) * r, y0 + h * 0.5, sin(a1) * r)
		lm.beam(key, p0, p1, h, w, Vector3.UP)
