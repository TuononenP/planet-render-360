extends RefCounted

## Kamppi Centre (Kampin keskus, 2005), Narinkka. Origin at the centre of the
## OSM outline, front +Z toward Narinkka Square (registry yaw -124.5 turns +Z
## onto the north-east).
##
## Measured: the retail outline (way 122886629 and the building:part ways round
## it, simplified to 1 m, listed in the old frame below and turned by `_t`),
## the 80 x 67 m glass-fronted shopping block on the square, the six stone
## office/hotel blocks of 7 to 9 storeys in two rows west of it with their
## three-storey links, the 7.7 x 6.8 m brick tower at the end of the glass
## front, the highest LoD2 roof 32 m.
## Estimated from visual-plan/refs/landmarks/kamppi_centre/: the storey
## heights, the 4.2 m curtain-wall grid of blue-green glass in dark steel, the
## glazed pitched roof stage, the glass lift tower, the grey stone base with
## dark shopfronts, the stone colour of the office blocks (never seen close up),
## the clock and flues on the brick tower. The bus terminal is underground
## and not modelled. The registry point lay 17 m from the outline's centre.

const D = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_d_kit.gd")
const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const P = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "kamppi_centre", "name": "Kamppi Centre", "lat": 60.169060, "lon": 24.932712,
	"radius_m": 1500.0, "wiki_title": "Kamppi Center", "height_m": 32.0, "clear_m": 40.0,
	"yaw_deg": -124.5, "clear_offsets_m": [[0.0, -62.0], [0.0, 62.0]],
	"kind": "Shopping centre", "aliases": ["kamppi centre", "kamppi center", "kauppakeskus kamppi", "kampin keskus"]}

## Outlines in the old frame (x along the 192 m side, z across); `_t` turns
## them so the glass front is +Z: x' = -z, z' = x.
const SHOP := [30.1, 35.0, 29.0, -44.5, 96.3, -44.5, 95.4, 36.0, 67.1, 34.3]
const TOWER := [64.4, 37.7, 72.1, 37.7, 72.1, 44.5, 64.4, 44.5]
const BASE := [30.1, 35.0, 29.8, -14.5, -91.6, -15.7, -91.6, -2.7, -96.3, -2.6, -96.0, 35.0]
## Stone blocks, old frame x0, x1, z0, z1, storeys.
const BLOCKS := [
	[-55.5, -27.0, -15.4, -9.9, 7], [-55.5, -27.0, -9.9, 4.5, 9], [-55.8, -27.0, 4.5, 30.6, 7],
	[-14.0, 14.7, -14.8, -8.5, 7], [-14.2, 14.6, -8.5, 4.3, 9], [-14.5, 14.7, 4.3, 30.8, 7]]
const STOREY := 3.4
const BASE_H := 11.5
const SHOP_EAVE := 26.0

static func _t(flat: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, flat.size(), 2):
		out.append(Vector2(-float(flat[i + 1]), float(flat[i])))
	return out

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("concrete", "#9C968D", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("concrete", "#B4AEA4", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#6E6E6D", 3.0))
	lm.use("Glass", LandmarkMaterials.paint("#5F94B0", 0.18, 0.55))
	lm.use("Win", LandmarkMaterials.glass("#2B3236"))
	lm.use("Shop", LandmarkMaterials.glass("#2F3C42"))
	lm.use("Frame", LandmarkMaterials.paint("#2F3438", 0.5, 0.5))
	lm.use("Roof", LandmarkMaterials.paint("#5C6468", 0.6, 0.3))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8A4A38", 2.4))
	lm.use("Lamp", LandmarkMaterials.lit("#F0ECDC", 0.35))
	# Three-storey podium under the stone blocks.
	var base := _t(BASE)
	D.block(lm, base, {"wall": "Wall", "eave": BASE_H, "plinth": 1.4, "cornice": 0.6, "bay": 4.2,
		"glass": "Win", "win": Vector2(2.6, 2.4), "sill": 1.0, "y0": 1.6, "storey": 3.6, "rows": 3, "depth": 0.25})
	# Two rows of 7 to 9 storey stone blocks with ribbon windows.
	for b in BLOCKS:
		var q := _t([b[0], b[2], b[1], b[2], b[1], b[3], b[0], b[3]])
		D.block(lm, q, {"wall": "Wall", "eave": BASE_H + STOREY * float(b[4] - 3), "plinth": 0.0, "cornice": 0.5,
			"bay": 3.4, "glass": "Win", "win": Vector2(1.8, 1.9), "sill": 0.9, "y0": BASE_H, "storey": STOREY,
			"rows": int(b[4]) - 3, "depth": 0.25, "min_len": 6.0})
		var h: float = BASE_H + STOREY * float(int(b[4]) - 3)
		var cx: float = (float(b[0]) + float(b[1])) * 0.5
		var cz: float = (float(b[2]) + float(b[3])) * 0.5
		var c := _t([cx, cz])[0]
		U.blk(lm, "Roof", c.x, h, c.y, absf(float(b[3]) - float(b[2])) - 0.8, 0.3, absf(float(b[1]) - float(b[0])) - 0.8)
	# The glass-fronted shopping block: stone base, curtain wall, glazed roof stage.
	var shop := _t(SHOP)
	lm.poly_prism("Glass", shop, 0.0, SHOP_EAVE, false)
	D.slab(lm, "Stone", shop, 0.25, 0.0, 6.2)
	D.slab(lm, "Frame", shop, 0.3, 6.0, 0.4)
	D.slab(lm, "Frame", shop, 0.3, SHOP_EAVE - 0.3, 0.6)
	for run in D.runs(shop):
		var a: Vector3 = run[0]
		var b: Vector3 = run[1]
		var o: Vector3 = run[2]
		var run_len := a.distance_to(b)
		if run_len < 6.0:
			continue
		var n := maxi(int(round(run_len / 4.2)), 1)
		# Dark shopfronts in the stone base, then the steel curtain-wall grid.
		P.pierce(lm, "Stone", "Shop", a, b, o, 0.0, 6.2, n, 1, Vector2(3.4, 4.2), 0.8, 5.0, 0.3)
		P.ribs(lm, "Frame", a, b, o, 6.4, SHOP_EAVE - 0.3, 4.2, 0.3, 0.3)
		for k in range(1, 5):
			P.band(lm, "Frame", a, b, o, 6.4 + 4.6 * float(k), 0.22, 0.22)
	# Glazed pitched stage above the eave, set in from the facade, with steel trusses.
	var sc := P.centre(shop)
	P.slope_roof(lm, "Glass", shop, sc, 0.84, SHOP_EAVE, SHOP_EAVE + 4.6)
	for k in range(-4, 5):
		lm.beam("Frame", Vector3(sc.x + float(k) * 9.0, SHOP_EAVE + 4.6, sc.y - 28.0),
			Vector3(sc.x + float(k) * 9.0, SHOP_EAVE + 4.6, sc.y + 28.0), 0.25)
	# Glass lift tower on the front and the sign.
	U.blk(lm, "Glass", 10.0, SHOP_EAVE - 2.0, 94.0, 5.0, 8.0, 5.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			U.blk(lm, "Frame", 10.0 + sx * 2.5, SHOP_EAVE - 2.0, 94.0 + sz * 2.5, 0.3, 8.2, 0.3)
	lm.box("Lamp", Vector3(-8.0, 6.8, 97.0), Vector3(12.0, 1.0, 0.3), Basis(), 0.0)
	# The red-brick tower at the end of the glass front: clock and flues.
	var tw := _t(TOWER)
	lm.poly_prism("Brick", tw, 0.0, 31.0, true)
	var tc := P.centre(tw)
	lm.disc("Trim", Vector3(tc.x, 26.0, tc.y + 3.5), Vector3.BACK, 1.1, 20)
	for k in 2:
		lm.frustum("Frame", Vector3(tc.x - 1.4 + 2.8 * float(k), 31.0, tc.y), 0.55, 0.5, 2.6, 8)
	lm.commit(model)
