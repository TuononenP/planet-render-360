extends RefCounted

## ateneum. Registry entry and model in one file.

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "ateneum", "name": "Ateneum Art Museum", "lat": 60.17002, "lon": 24.94407,
	"radius_m": 5000.0, "wiki_title": "Ateneum", "height_m": 28.6, "clear_m": 58.0,
	"yaw_deg": 178.0, "kind": "Museum", "aliases": ["ateneum", "ateneum art museum", "ateneumin taidemuseo",
		"ateneum museum"]}

## From the Commons photos (visual-plan/refs/landmarks/ateneum/): warm
## sandy-ochre rendered walls with pale trim, all three storeys arched, the
## dark grey metal roof, and a flagpole above the pediment. Measured: the
## 77 x 49 m plan (OSM way 8033120), 28.6 m top (LoD2, which reads the
## flagpole). Estimated: the eave (17.2 m), the colours.
## Yaw 178: the front faces north across Kaivokatu to the station.
##
## Höijer's Ateneum (1887), origin at the OSM footprint centre, front +Z
## (the registry yaw turns it north onto the station square): the 77 x
## 49 m neo-Renaissance block of three storeys over a granite plinth, the
## rusticated ground floor with round-arched windows, pedimented windows
## on the first floor with Vallgren's 16 medallion reliefs between them,
## the shallow side risalits and the central risalit: three arched portals
## up a flight of steps, the busts of Bramante, Raphael and Phidias above
## them, four caryatids carrying the pediment and Sjöström's sculpture
## group on its crown. Low metal hips with the glazed roof of the halls.
static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#AE9C74", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#C4B58F", 2.5))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#8A8780", 4.0))
	lm.use("Copper", LandmarkMaterials.pbr("sheet_metal", "#5A626C", 2.0))
	lm.use("Gilt", LandmarkMaterials.pbr("sheet_metal", "#B08A3A", 2.0, 0.4, 0.6))
	lm.use("Glass", LandmarkMaterials.paint("#46555F", 0.3, 0.4))
	var x0 := -38.5
	var x1 := 38.5
	var zb := -24.5
	var zf := 24.9
	var cz := (zb + zf) * 0.5
	var w := x1 - x0
	var d := zf - zb
	var eave := 17.2
	FhU.blk(lm, "Plinth", 0.0, 0.0, cz, w + 0.6, 1.3, d + 0.6)
	FhU.blk(lm, "Wall", 0.0, 1.3, cz, w, eave - 1.3, d)
	# Rusticated ground floor: horizontal joints as thin bands, then the
	# first-floor band and the main cornice round the block.
	for k in 5:
		FhP.box_band(lm, "Wall", 0.0, cz, w, d, 1.3 + 1.0 * float(k) + 0.9, 0.12, 0.08)
	FhP.box_band(lm, "Trim", 0.0, cz, w, d, 6.1, 0.5, 0.25)
	FhP.box_band(lm, "Trim", 0.0, cz, w, d, 11.9, 0.35, 0.15)
	for face in FhP.faces(0.0, cz, w, d):
		LandmarkDetail.cornice(lm, "Trim", (face[0] as Vector3) + Vector3(0, eave - 0.9, 0),
			(face[1] as Vector3) + Vector3(0, eave - 0.9, 0), face[2], 0.95, true)
	# Low hips and the glazed hall roof.
	FhU.hip(lm, "Copper", Vector3(0, eave, cz), w + 0.6, d + 0.6, 2.4, 0.62)
	FhU.ridge_x(lm, "Glass", "Glass", Vector3(0, eave + 2.4, cz), 44.0, 28.0, 2.2, 0.0)
	for k in 9:
		var x := -21.0 + 5.25 * float(k)
		lm.beam("Trim", Vector3(x, eave + 2.45, cz - 14.0), Vector3(x, eave + 4.6, cz), 0.15, 0.2)
		lm.beam("Trim", Vector3(x, eave + 2.45, cz + 14.0), Vector3(x, eave + 4.6, cz), 0.15, 0.2)
	# Front wings either side of the central risalit, with their side risalits.
	var fo := Vector3(0, 0, 1)
	for s in [-1.0, 1.0]:
		var wa := Vector3(s * 10.2, 0, zf)
		var wb := Vector3(s * 38.3, 0, zf)
		var l := wa if s < 0.0 else wb
		var r := wb if s < 0.0 else wa
		l = Vector3(minf(wa.x, wb.x), 0, zf)
		r = Vector3(maxf(wa.x, wb.x), 0, zf)
		FhP.win_row(lm, "Trim", "Glass", l, r, fo, 2.0, 7, 1.7, 3.2, true, 0.25)
		FhP.win_row(lm, "Trim", "Glass", l, r, fo, 7.4, 7, 1.8, 3.4, true, 0.25)
		FhP.win_row(lm, "Trim", "Glass", l, r, fo, 12.9, 7, 1.5, 2.6, true, 0.2)
		# Medallion reliefs between the first-floor windows.
		for k in 6:
			var p := l.lerp(r, (float(k) + 1.0) / 7.0)
			FhP.ring(lm, "Trim", p + Vector3(0, 9.4, 0.02), fo, 0.55, 0.75, 0.15, 14)
			lm.disc("Trim", p + Vector3(0, 9.4, 0.12), fo, 0.56, 12)
		# Side risalit: a shallow projecting bay with quoins and a raised attic.
		var rx: float = s * 33.0
		FhU.blk(lm, "Wall", rx, 1.3, zf + 0.5, 5.6, eave - 1.3, 1.0)
		FhP.strips(lm, "Trim", Vector3(rx - 2.8, 0, zf + 1.0), Vector3(rx + 2.8, 0, zf + 1.0), fo, 6.6, 10.2, 2,
			0.7, 0.15)
		FhU.blk(lm, "Wall", rx, eave, zf + 0.3, 6.2, 1.6, 1.6)
		LandmarkDetail.balustrade(lm, "Trim", Vector3(rx - 2.9, eave + 1.6, zf + 0.9), Vector3(rx + 2.9, eave + 1.6,
			zf + 0.9), 0.9, 2.9)
	# Central risalit: portals, busts, caryatids and the pediment.
	var rz := zf + 1.7
	FhU.blk(lm, "Wall", 0.35, 1.3, zf + 0.85, 20.3, eave - 1.3, 1.7)
	FhU.blk(lm, "Plinth", 0.35, 0.0, zf + 1.0, 21.0, 1.3, 2.4)
	FhU.steps(lm, "Plinth", Vector3(0.35, 0.0, rz + 0.3), fo, 14.0, 0.4, 0.26, 5)
	for k in 3:
		var px := 0.35 + (float(k) - 1.0) * 5.4
		var pc := Vector3(px, 1.3, rz)
		lm.quad("Glass", pc + Vector3(-1.3, 0, 0.02), pc + Vector3(1.3, 0, 0.02), pc + Vector3(1.3, 3.8, 0.02),
			pc + Vector3(-1.3, 3.8, 0.02), fo)
		LandmarkDetail.arch(lm, "Trim", pc + Vector3(0, 3.8, 0), fo, 2.6, 0.45, 0.35)
		for sx in [-1.0, 1.0]:
			lm.box("Trim", pc + Vector3(sx * 1.55, 1.9, 0.15), Vector3(0.5, 3.8, 0.3))
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(px, 9.0, rz + 0.02), fo, 1.9, 3.6, true, 0.3)
		# A bust on its console over each portal.
		_bust(lm, "Trim", Vector3(px + (2.6 if k < 2 else -2.6), 7.6, rz + 0.4), 1.1)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(px, 14.3, rz + 0.02), fo, 1.6, 2.6, false, 0.25)
	for k in 4:
		var px := 0.35 + (float(k) - 1.5) * 5.4
		lm.box("Trim", Vector3(px, 12.4, rz + 0.45), Vector3(1.0, 0.5, 0.9))
		LandmarkKits.statue_figure(lm, "Trim", Vector3(px, 12.65, rz + 0.5), 3.6, false)
		lm.box("Trim", Vector3(px, 16.4, rz + 0.45), Vector3(1.1, 0.4, 0.9))
	FhU.blk(lm, "Trim", 0.35, eave - 0.6, rz - 0.6, 21.2, 0.9, 1.8)
	FhU.blk(lm, "Wall", 0.35, eave + 0.3, rz - 0.75, 20.3, 1.2, 1.5)
	lm.gable("Copper", Vector3(0.35, eave + 1.5, rz - 7.0), 20.6, 14.0, 3.6, Basis(), 0.3, "Trim")
	# Raking cornices and the sculpture group on the pediment.
	for sx in [-1.0, 1.0]:
		lm.beam("Trim", Vector3(0.35 + sx * 10.6, eave + 1.5, rz + 0.1), Vector3(0.35, eave + 5.1, rz + 0.1), 0.45,
			0.6, Vector3.RIGHT)
		LandmarkKits.statue_figure(lm, "Trim", Vector3(0.35 + sx * 3.2, eave + 1.6, rz - 0.2), 2.2, false)
		lm.box("Trim", Vector3(0.35 + sx * 10.4, eave + 1.9, rz - 0.2), Vector3(0.8, 0.8, 0.8))
	lm.box("Trim", Vector3(0.35, eave + 1.7, rz - 0.2), Vector3(2.0, 0.4, 1.0))
	# The flagpole over the pediment, up to the LoD2 top (28.6 m).
	lm.frustum("Trim", Vector3(0.35, eave + 5.4, rz - 1.6), 0.1, 0.04, 28.6 - eave - 5.4 - 0.2, 6)
	lm.lathe("Gilt", Vector3(0.35, 28.4, rz - 1.6), FhU.ball(0.1), 8)
	LandmarkKits.statue_figure(lm, "Trim", Vector3(0.35, eave + 1.9, rz - 0.2), 3.0, true)
	# Sides and back: recessed windows in three storeys.
	for s in [-1.0, 1.0]:
		var x: float = x1 if s > 0.0 else x0
		FhP.pierce(lm, "Wall", "Glass", Vector3(x, 0, zf), Vector3(x, 0, zb), Vector3(s, 0, 0), 1.3, 15.6, 9, 3,
			Vector2(1.7, 3.0), 1.2, 5.4, 0.25)
	FhP.pierce(lm, "Wall", "Glass", Vector3(x1, 0, zb), Vector3(x0, 0, zb), Vector3(0, 0, -1), 1.3, 15.6, 15, 3,
		Vector2(1.7, 3.0), 1.2, 5.4, 0.25)
	lm.commit(model)
	# Night: the front is washed with warm light from across Kaivokatu.
	var warm := Color(1.0, 0.88, 0.7)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-14.0, 3.0, zf + 22.0), Vector3(-6.0, 10.0, zf), 40.0, 0.9, 50.0, warm],
		[Vector3(14.0, 3.0, zf + 22.0), Vector3(6.0, 10.0, zf), 40.0, 0.9, 50.0, warm],
	])

## A portrait bust of height h on a console: shoulders, neck and head.
static func _bust(lm: LandmarkMesh, key: String, base: Vector3, h: float) -> void:
	lm.box(key, base + Vector3(0, h * 0.12, 0), Vector3(h * 0.5, h * 0.24, h * 0.4))
	lm.lathe(key, base + Vector3(0, h * 0.24, 0), PackedVector2Array([Vector2(h * 0.18, 0), Vector2(h * 0.3, h * 0.1),
		Vector2(h * 0.28, h * 0.32), Vector2(h * 0.08, h * 0.42), Vector2(h * 0.07, h * 0.5)]), 12, 1.0, 0.6)
	lm.lathe(key, base + Vector3(0, h * 0.72, 0), PackedVector2Array([Vector2(0.0, 0), Vector2(h * 0.09, h * 0.04),
		Vector2(h * 0.12, h * 0.13), Vector2(h * 0.1, h * 0.22), Vector2(0.0, h * 0.28)]), 12, 0.9, 1.0)

