extends RefCounted

## Helsinki Swimming Stadium (Uimastadion, Jorma Järvi, 1952), Eläintarha.
## Origin at the centroid of the OSM stand way 4252923 (60.188842 N
## 24.930414 E), yaw -10.7 so the pools and stands run along the model axes:
## the long axis is Z (the 50 m pool runs from z = -8 to 42.4) and the pools
## lie east (+X) of the west stand.
##
## From the photographs (visual-plan/refs/landmarks/swimming_stadium_helsinki/):
## - Two long open terraces of timber benches, no roof: the west stand
##   rises westward from the pool deck, the east stand eastward, each with a
##   steel handrail on the bottom row and flagpoles along the top.
## - A flagstone deck round three pools: the 50 x 20 m main pool (bright
##   turquoise), the square diving pool and the children's pool north of it.
## - The white concrete diving tower between the diving and children's
##   pools: a stepped stack of platforms at 3, 5, 7.5 and 10 m with
##   railings and a clock on the shaft.
##
## Measured: the pool and stand outlines (OSM ways 4252918-4252923 and the
## east terrace way 842434372, simplified; the east stand is a rectangle
## fitted to the terrace). Estimated: the stand heights (7.7 m west, 8.5 m
## east), row counts, the tower's platform heights and the light poles.
## The registry's earlier point lay 150 m west of the pools.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const ENTRY := {"type": "swimming_stadium_helsinki", "name": "Helsinki Swimming Stadium", "lat": 60.188842, "lon": 24.930414,
	"radius_m": 1500.0, "wiki_title": "Helsinki Swimming Stadium", "height_m": 14.0, "clear_m": 30.0,
	"yaw_deg": -10.7, "kind": "Swimming stadium", "aliases": ["helsinki swimming stadium", "uimastadion", "simstadion helsingfors"]}

const POOLS := {
	"iso": [Vector2(19.1, -8.0), Vector2(39.2, 42.4)],
	"dive": [Vector2(19.8, -31.8), Vector2(39.5, -11.8)],
}
const KIDS := [Vector2(19.9, -37.9), Vector2(39.7, -37.7), Vector2(39.8, -51.0), Vector2(36.6, -51.4),
	Vector2(29.8, -56.6), Vector2(26.6, -56.9), Vector2(21.8, -54.6), Vector2(20.1, -50.6)]

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Deck", LandmarkMaterials.pbr("stone", "#B4AFA2", 2.5))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#8A6A48", 2.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#E6E3DA", 3.0))
	lm.use("Water", LandmarkMaterials.pool_water("#2FB0CF"))
	lm.use("Steel", LandmarkMaterials.paint("#C9CED0", 0.4, 0.6))
	lm.use("Lamp", LandmarkMaterials.lit("#FFF1CC", 1.4))
	# Flagstone deck round the pools.
	var deck := PackedVector2Array([Vector2(12.0, -60.0), Vector2(44.5, -60.0), Vector2(44.5, 47.0), Vector2(12.0, 47.0)])
	lm.poly_prism("Deck", deck, 0.0, 0.3)
	for key in POOLS:
		_pool(lm, POOLS[key][0], POOLS[key][1])
	var kids := PackedVector2Array(KIDS)
	lm.poly_prism("Concrete", kids, 0.3, 0.42)
	lm.poly_prism("Water", _inset(kids, 0.4), 0.42, 0.5)
	# Stands: west rises toward -X, east toward +X.
	_stand(lm, 12.0, -6.3, -37.0, 41.0, 14, 0.55)
	_stand(lm, 45.0, 68.3, -54.0, 44.0, 17, 0.5)
	_tower(lm, Vector3(25.6, 0.3, -36.9))
	# Flagpoles along the top of both stands and light poles round the deck.
	for z in 7:
		var zz := -36.0 + 12.0 * float(z)
		lm.beam("Steel", Vector3(-6.0, 8.2, zz), Vector3(-6.0, 14.0, zz), 0.1)
		lm.beam("Steel", Vector3(67.5, 8.8, zz - 2.0), Vector3(67.5, 14.0, zz - 2.0), 0.1)
	for p in [Vector2(14.0, -50.0), Vector2(14.0, -10.0), Vector2(14.0, 30.0), Vector2(43.0, -50.0), Vector2(43.0, -10.0),
			Vector2(43.0, 30.0)]:
		lm.beam("Steel", Vector3(p.x, 0.3, p.y), Vector3(p.x, 8.0, p.y), 0.14)
		lm.box("Lamp", Vector3(p.x, 8.1, p.y), Vector3(0.9, 0.25, 0.9))
	lm.commit(model)

## A pool of the rectangle `lo`..`hi`: white coping and the water surface.
static func _pool(lm: LandmarkMesh, lo: Vector2, hi: Vector2) -> void:
	var cx := (lo.x + hi.x) * 0.5
	var cz := (lo.y + hi.y) * 0.5
	lm.box("Concrete", Vector3(cx, 0.36, cz), Vector3(hi.x - lo.x + 0.8, 0.12, hi.y - lo.y + 0.8), Basis(), 0.0)
	lm.box("Water", Vector3(cx, 0.43, cz), Vector3(hi.x - lo.x - 0.4, 0.08, hi.y - lo.y - 0.4), Basis(), 0.0)

## Terraced benches between x = `x_low` (the row at the deck) and `x_high`,
## `rows` rows rising `rise` each from z0 to z1.
static func _stand(lm: LandmarkMesh, x_low: float, x_high: float, z0: float, z1: float, rows: int, rise: float) -> void:
	var dx := (x_high - x_low) / float(rows)
	for k in rows:
		var xc := x_low + dx * (float(k) + 0.5)
		var h := rise * float(k + 1) + 0.3
		lm.box("Wood", Vector3(xc, h * 0.5, (z0 + z1) * 0.5), Vector3(absf(dx), h, z1 - z0), Basis(), 0.0)
	# Handrail along the front row.
	var xf := x_low - signf(dx) * 0.2
	lm.beam("Steel", Vector3(xf, 1.2, z0), Vector3(xf, 1.2, z1), 0.06)
	for z in range(int(z0), int(z1), 6):
		lm.beam("Steel", Vector3(xf, 0.3, float(z)), Vector3(xf, 1.2, float(z)), 0.05)

static func _inset(poly: PackedVector2Array, d: float) -> PackedVector2Array:
	var c := Vector2.ZERO
	for p in poly:
		c += p
	c /= float(poly.size())
	var out := PackedVector2Array()
	for p in poly:
		out.append(p - (p - c).normalized() * d)
	return out

## The concrete diving tower: shaft with a clock, four platforms stepping
## out over the diving pool (+Z) with railings and a stair beam.
static func _tower(lm: LandmarkMesh, b: Vector3) -> void:
	lm.box("Concrete", b + Vector3(0, 5.2, 0), Vector3(2.4, 10.4, 2.4))
	lm.box("Concrete", b + Vector3(0, 0.4, 0), Vector3(3.6, 0.8, 3.6))
	var levels := [[3.0, 1.0], [5.0, 1.5], [7.5, 2.0], [10.0, 2.6]]
	for lv in levels:
		var y: float = lv[0]
		var proj: float = lv[1]
		lm.box("Concrete", b + Vector3(0, y, 1.2 + proj * 0.5), Vector3(2.8, 0.25, 2.4 + proj))
		lm.beam("Steel", b + Vector3(-1.4, y + 0.1, 1.2 - 1.2), b + Vector3(-1.4, y + 0.1, 2.4 + proj), 0.05)
		lm.beam("Steel", b + Vector3(-1.4, y + 1.1, 0.0), b + Vector3(-1.4, y + 1.1, 2.4 + proj), 0.05)
		lm.beam("Steel", b + Vector3(1.4, y + 1.1, 0.0), b + Vector3(1.4, y + 1.1, 2.4 + proj), 0.05)
	lm.beam("Steel", b + Vector3(-1.4, 0.8, -1.2), b + Vector3(-1.4, 10.6, -1.2), 0.05)
	lm.disc("Lamp", b + Vector3(0, 8.2, 1.22), Vector3(0, 0, 1), 0.45, 16)
