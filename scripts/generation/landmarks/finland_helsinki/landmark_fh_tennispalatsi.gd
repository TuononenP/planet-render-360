extends RefCounted

## Tennispalatsi (Helsingin Tennispalatsi, Helge Lindberg and Gunnar Taucher,
## 1937), Salomonkatu / Fredrikinkatu, now the Art Museum and Finnkino. Origin
## at the OSM outline's bounding-box centre, front +Z toward the long glass-
## arched side (registry yaw 55.4 turns +Z onto the south-west street).
##
## Measured: the outline (way 123978648, 58 x 111 m with the 41 x 12 m
## projection at the -X end, simplified to 1 m, rotated to the street grid)
## and the overall 34 m (OSM `height`, which includes the roof pylons).
## Estimated from visual-plan/refs/landmarks/tennispalatsi/: the three
## storeys (12.5 m), ribbon windows, the deep canopy on round columns, the
## two barrel vaults (crest 24 m; their count, length and position are read
## from the aerial photo and are approximate), the glazed arch end with its
## white frame and mullions, the four white roof pylons carrying the museum
## lettering. The earlier registry point lay 70 m from the building.

const D = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_d_kit.gd")
const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const ENTRY := {"type": "tennispalatsi", "name": "Tennispalatsi", "lat": 60.169638, "lon": 24.930410,
	"radius_m": 1500.0, "wiki_title": "Tennispalatsi", "height_m": 34.0, "clear_m": 40.0,
	"yaw_deg": 55.4, "kind": "Cinema", "aliases": ["tennispalatsi", "tennis palace helsinki", "tennispalatset"]}

const OUTLINE := [-44.1, 29.0, -44.1, 20.4, -55.7, 20.5, -55.5, -20.4, -43.9, -20.3, -43.9, -29.0, 55.7, -29.0, 55.5, 29.0]
const EAVE := 12.5
const CREST := 24.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#ECEBE4", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F4F3EC", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#6C6E70", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#4A5E66"))
	lm.use("Shop", LandmarkMaterials.glass("#2F3C42"))
	lm.use("Vault", LandmarkMaterials.pbr("sheet_metal", "#7E868C", 3.0, 0.45, 0.45))
	lm.use("Canopy", LandmarkMaterials.paint("#2E3032", 0.6, 0.2))
	lm.use("Lamp", LandmarkMaterials.lit("#F4F0E0", 0.35))
	var p := D.poly(OUTLINE)
	D.block(lm, p, {"eave": EAVE, "plinth": 1.0, "cornice": 0.5, "cornice_out": 0.3, "bay": 3.6,
		"win": Vector2(2.5, 1.5), "sill": 1.1, "y0": 4.6, "storey": 3.9, "rows": 2, "depth": 0.25})
	# Roof deck skin and the shop storey glazing under the canopy (front +Z).
	U.blk(lm, "Canopy", 0.0, EAVE, 0.0, 111.0, 0.15, 57.4)
	U.window_grid(lm, "Shop", Vector3(-52.0, 0, 29.0), Vector3(52.0, 0, 29.0), Vector3(0, 0, 1), 0.6, 1, 4.0, 22, 3.4, 3.5, 0.05)
	# Canopy over the street front: a deep slab on slender round columns.
	U.blk(lm, "Wall", 6.0, 4.6, 33.0, 100.0, 0.5, 8.4)
	for i in 11:
		var x := -39.0 + 9.4 * float(i)
		lm.frustum("Trim", Vector3(x, 0.0, 36.0), 0.32, 0.28, 4.6, 12)
	# Two barrel vaults: the big one at the left of the front, running the
	# depth of the block, and a shorter one beside it.
	_vault(lm, -30.0, -29.0, 29.5, 21.0, 11.6)
	_vault(lm, 17.0, -29.0, 8.0, 17.0, 9.0)
	# Four white pylons on the roof with the museum lettering.
	for x in [-38.0, -22.0, -4.0, 14.0]:
		U.blk(lm, "Trim", float(x), EAVE, 6.0, 2.4, 34.0 - EAVE, 1.7)
		lm.box("Lamp", Vector3(float(x), 28.0, 6.9), Vector3(1.5, 12.0, 0.12), Basis(), 0.0)
	lm.commit(model)

## A barrel vault along Z over x = cx +- hw from z0 to z1, springing at EAVE:
## standing-seam zinc, a glazed arch end at z1 with a white frame, mullions and
## a ring of panes.
static func _vault(lm: LandmarkMesh, cx: float, z0: float, z1: float, hw: float, rise: float) -> void:
	var seg := 14
	var prev := Vector2(cx + hw, EAVE)
	for i in range(1, seg + 1):
		var a := PI * float(i) / float(seg)
		var q := Vector2(cx + hw * cos(a), EAVE + rise * sin(a))
		var mid := (prev + q) * 0.5
		var n := Vector3(mid.x - cx, (mid.y - EAVE) * hw / rise, 0.0).normalized()
		lm.quad("Vault", Vector3(prev.x, prev.y, z0), Vector3(q.x, q.y, z0), Vector3(q.x, q.y, z1),
			Vector3(prev.x, prev.y, z1), n)
		prev = q
	var o := Vector3(0, 0, 1)
	var base := Vector3(cx, EAVE, z1)
	# Glazed end: panes up to the arch, white frame, vertical mullions.
	for i in range(0, seg):
		var a0 := PI * float(i) / float(seg)
		var a1 := PI * float(i + 1) / float(seg)
		var p0 := base + Vector3(hw * cos(a0), rise * sin(a0), 0.0) * 0.96
		var p1 := base + Vector3(hw * cos(a1), rise * sin(a1), 0.0) * 0.96
		lm.tri("Glass", base, p0 + o * 0.05, p1 + o * 0.05, o, o, o, Vector2.ZERO, Vector2(1, 0), Vector2(0, 1))
		lm.beam("Trim", p0 + o * 0.15, p1 + o * 0.15, 0.7, 0.5, o)
	for k in range(-5, 6):
		var x := cx + hw * 0.96 * float(k) / 5.5
		var h := rise * 0.96 * sqrt(maxf(1.0 - pow((x - cx) / (hw * 0.96), 2.0), 0.0))
		lm.box("Trim", Vector3(x, EAVE + h * 0.5, z1 + 0.15), Vector3(0.35, h, 0.3), Basis(), 0.0)
	for r in [0.35, 0.7]:
		lm.box("Trim", Vector3(cx, EAVE + rise * r * 0.5, z1 + 0.15), Vector3(hw * 1.9, 0.3, 0.3), Basis(), 0.0)
