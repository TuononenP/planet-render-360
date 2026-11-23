extends RefCounted

## Kallio Library (Kallion kirjasto, Karl Hård af Segerstad, 1912), Viides
## linja 11. Origin at the registry point; the footprint is the OSM outline
## (LandmarkFhInnerFootprints "kallio_library", 0.5-1 m simplified), yaw 0.
##
## From the photographs (visual-plan/refs/landmarks/kallio_library/): a
## dark maroon brick block of three storeys on a rough granite base, light
## sandstone quoins and window surrounds, tall paired windows, an arched
## entrance under a curved gable with an oval window, and a steep roof of
## orange-red tile with red-painted ridges and a red chimney.
##
## Measured: outline, orientation (OSM); the 19 m registry height. Estimated:
## 12 m eaves, mansard heights, window positions. This version darkens the
## brick and brightens the tile to the photographed colours.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")
const I = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_inner_footprints.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const LIBRARY_M := 19.0

const ENTRY := {"type": "kallio_library", "name": "Kallio Library", "lat": 60.183619, "lon": 24.953646,
	"radius_m": 2000.0, "wiki_title": "Kallio Library", "height_m": 19.0, "clear_m": 17.0,
	"kind": "Library", "aliases": ["kallio library", "kallion kirjasto", "berghälls bibliotek"]}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#7A382D", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DCCFB4", 2.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#706B64", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#CC6A35", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#2E383C"))
	var poly := I.outline("kallio_library")
	var eave := 12.0
	lm.poly_prism("Granite", F.offset(poly, 0.15), 0.0, 1.3)
	lm.poly_prism("Brick", poly, 1.3, eave)
	lm.poly_prism("Stone", F.offset(poly, 0.1), 5.5, 5.8, false)
	lm.poly_prism("Stone", F.offset(poly, 0.25), eave - 0.4, eave, false)
	W.edge_windows(lm, "Glass", poly, 1.8, 3, 3.6, 2.6, 1.3, 2.2, "Stone")
	_quoins(lm, poly, 1.3, eave - 0.4)
	# Red tiled mansard: a steep lower skirt, a low upper hip, chimneys.
	var cen := FhP.centre(poly)
	var skirt := F.offset(poly, 0.3)
	FhP.slope_roof(lm, "Tile", skirt, cen, 0.8, eave, eave + 3.4)
	var upper := PackedVector2Array()
	for p in skirt:
		upper.append(cen + (p - cen) * 0.8)
	FhP.slope_roof(lm, "Tile", upper, cen, 0.6, eave + 3.4, eave + 5.0)
	for s: float in [-1.0, 1.0]:
		U.blk(lm, "Brick", cen.x + 4.5 * s, eave + 2.5, cen.y, 1.2, LIBRARY_M - eave - 2.5, 1.2)
	_entrance_gable(lm, eave)
	_dormers(lm, eave)
	lm.commit(model, "Kallio_library_")
	var warm := Color(1.0, 0.86, 0.64)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-21.0, 1.5, 26.0), Vector3(-8.7, 9.5, 11.5), 46.0, 1.0, 45.0, warm],
		[Vector3(19.0, 1.5, -18.0), Vector3(9.0, 8.5, -10.0), 46.0, 0.85, 45.0, warm],
		[Vector3(-22.0, 1.5, -16.0), Vector3(-9.0, 9.0, -5.0), 48.0, 0.8, 45.0, warm],
		[Vector3(20.0, 1.5, 20.0), Vector3(8.0, 9.0, 8.0), 48.0, 0.8, 45.0, warm],
	])

## Karl Hård af Segerstad's signature curved Jugend entrance gable with oval window
## and arched granite portal on the south-west Viides linja risalit.
static func _entrance_gable(lm: LandmarkMesh, eave: float) -> void:
	var a := Vector2(-4.9, 14.4)
	var b := Vector2(-12.5, 8.6)
	var mid := (a + b) * 0.5
	var along2 := (b - a).normalized()
	var out2 := Vector2(-0.6066, 0.795)
	var out := Vector3(out2.x, 0.0, out2.y)
	var right := Vector3(along2.x, 0.0, along2.y)
	var basis := Basis(right, Vector3.UP, out)
	var cen3 := Vector3(mid.x, 0.0, mid.y)
	# Granite entrance steps, flanking piers, semicircular arch and doorway.
	U.steps(lm, "Granite", cen3 + out * 0.2, out, 4.4, 0.36, 0.16, 4)
	for s in [-1.0, 1.0]:
		lm.box("Granite", cen3 + right * s * 1.65 + Vector3(0, 1.6, 0) + out * 0.25,
			Vector3(0.95, 3.2, 0.7), basis)
	var arch_c := cen3 + Vector3(0, 2.8, 0) + out * 0.25
	var r_arch := 1.45
	var prev := arch_c + right * r_arch
	for k in range(1, 9):
		var ang := PI * float(k) / 8.0
		var p := arch_c + right * (r_arch * cos(ang)) + Vector3(0, r_arch * sin(ang), 0)
		lm.beam("Granite", prev, p, 0.55, 0.65, out)
		prev = p
	lm.quad("Glass", cen3 - right * 1.15 + Vector3(0, 0.65, 0) + out * 0.18,
		cen3 + right * 1.15 + Vector3(0, 0.65, 0) + out * 0.18,
		cen3 + right * 1.15 + Vector3(0, 3.0, 0) + out * 0.18,
		cen3 - right * 1.15 + Vector3(0, 3.0, 0) + out * 0.18, out)
	# Curved bell-shaped Jugend gable above the eave with sandstone coping.
	var gable_h := 5.4
	var rows := 8
	var widths := [7.4, 6.8, 5.9, 5.1, 4.5, 3.8, 2.8, 1.5]
	var prev_w := 7.6
	for k in rows:
		var y := eave + (float(k) + 0.5) * gable_h / float(rows)
		var w := float(widths[k])
		lm.box("Brick", cen3 - out * 0.45 + Vector3(0, y, 0), Vector3(w, gable_h / float(rows) + 0.05, 1.4), basis, 0.0)
		for s: float in [-1.0, 1.0]:
			var p0 := cen3 - out * 0.45 + right * (s * prev_w * 0.5) + Vector3(0, eave + float(k) * gable_h / float(rows), 0)
			var p1 := cen3 - out * 0.45 + right * (s * w * 0.5) + Vector3(0, eave + float(k + 1) * gable_h / float(rows), 0)
			lm.beam("Stone", p0, p1, 0.36, 1.6, out)
		prev_w = w
	lm.box("Stone", cen3 - out * 0.45 + Vector3(0, eave + gable_h + 0.15, 0), Vector3(1.6, 0.32, 1.6), basis)
	# Oval Jugend window in the gable tympanum.
	var oc := cen3 + out * 0.28 + Vector3(0, eave + 2.35, 0)
	var oseg := 14
	for k in oseg:
		var a0 := TAU * float(k) / float(oseg)
		var a1 := TAU * float(k + 1) / float(oseg)
		var q0 := oc + right * (0.72 * cos(a0)) + Vector3(0, 1.05 * sin(a0), 0)
		var q1 := oc + right * (0.72 * cos(a1)) + Vector3(0, 1.05 * sin(a1), 0)
		lm.tri("Glass", oc, q0, q1, out, out, out, Vector2(0.5, 0.5), Vector2(0, 0), Vector2(1, 0))
		lm.beam("Stone", q0 + out * 0.06, q1 + out * 0.06, 0.2, 0.2, out)

## Youthful mansard roof dormers along both 22.3 m library flanks.
static func _dormers(lm: LandmarkMesh, eave: float) -> void:
	for flank: Array in [[Vector2(-16.5, 3.2), Vector2(-3.0, -14.6)], [Vector2(14.9, -1.2), Vector2(1.4, 16.6)]]:
		var a: Vector2 = flank[0]
		var b: Vector2 = flank[1]
		var along2 := (b - a).normalized()
		var out2 := W.outward(I.outline("kallio_library"), a, b)
		var out := Vector3(out2.x, 0.0, out2.y)
		var right := Vector3(along2.x, 0.0, along2.y)
		var basis := Basis(right, Vector3.UP, out)
		for t in [0.25, 0.5, 0.75]:
			var p2 := a.lerp(b, t) - out2 * 1.15
			var dc := Vector3(p2.x, eave + 0.55, p2.y)
			lm.box("Brick", dc + Vector3(0, 0.75, 0), Vector3(1.6, 1.5, 1.5), basis, 0.0)
			lm.gable("Tile", dc + Vector3(0, 1.5, 0), 1.6, 1.6, 0.75, basis, 0.15, "Brick")
			lm.quad("Glass", dc + out * 0.77 - right * 0.45 + Vector3(0, 0.25, 0),
				dc + out * 0.77 + right * 0.45 + Vector3(0, 0.25, 0),
				dc + out * 0.77 + right * 0.45 + Vector3(0, 1.25, 0),
				dc + out * 0.77 - right * 0.45 + Vector3(0, 1.25, 0), out)

## Light stone quoins at every corner between two edges at least 3 m long.
static func _quoins(lm: LandmarkMesh, poly: PackedVector2Array, y0: float, y1: float) -> void:
	var n := poly.size()
	for i in n:
		var p := poly[i]
		var prev := poly[(i + n - 1) % n]
		var next := poly[(i + 1) % n]
		if p.distance_to(prev) < 3.0 or p.distance_to(next) < 3.0:
			continue
		var along := (next - p).normalized()
		lm.box("Stone", Vector3(p.x, (y0 + y1) * 0.5, p.y), Vector3(0.9, y1 - y0, 0.9),
			Basis(Vector3.UP, atan2(-along.y, along.x)), 0.0)
