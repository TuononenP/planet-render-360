class_name LandmarkBkPrajadhipokMuseum
extends RefCounted

## King Prajadhipok Museum (`พิพิธภัณฑ์พระบาทสมเด็จพระปกเกล้าเจ้าอยู่หัว`) — Phan Fa Bridge, Bangkok BK-5.5
## Site: OSM way 229966092, centroid 13.756076, 100.506471
## (`height_m: 16.0`, `radius_m: 450.0`, `yaw_deg: 22.0` — local Ratchadamnoen/Phan Fa landmark).
## Spec (Former John Sampson & Son / Public Works building, 1906, Commons `front.jpg`):
##   - Symmetrical 3-storey pastel celadon-green stucco Neoclassical corner building (`46 × 22 m`,
##     `11.2 m` eaves) with splayed chamfered side wings, crisp white pilasters & stringcourses,
##     fanlight-arched 2nd-floor windows, dark brown-slate hipped roof, and white rooftop balustrade.
##   - Central octagonal open-arched cupola lantern crowned by a white dome & flagpole reaching `16.0 m` (`front.jpg`).

const K = preload("res://scripts/generation/landmarks/capital_stations/landmark_station_kit.gd")

const HEIGHT_M := 16.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Celadon", LandmarkMaterials.pbr("render", "#B5CEB4", 3.0))
	lm.use("White", LandmarkMaterials.pbr("limestone", "#F7F6F0", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#4A433E", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#24302E"))
	lm.use("Gold", LandmarkMaterials.gold())

	_chamfered_neoclassical_body(lm)
	_central_cupola(lm)
	lm.commit(model)

	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-12.0, 1.8, 18.0), Vector3(0.0, 10.0, 4.0), 50.0, 1.15, 32.0, Color(1.0, 0.93, 0.78)],
		[Vector3(12.0, 1.8, 18.0), Vector3(0.0, 10.0, 4.0), 50.0, 1.15, 32.0, Color(1.0, 0.93, 0.78)],
	])

static func _chamfered_neoclassical_body(lm: LandmarkMesh) -> void:
	# Central 7-bay frontispiece (`22 × 16 m`) + splayed side wings (`±15 m` turned ±28°, `front.jpg`)
	K.block(lm, "Celadon", "White", "Glass", "Roof", 0.0, 1.0, 22.0, 15.6, 0.0, 11.2, "hip", 2.0, 3.2, 3.6, false)
	K.arch_row(lm, "White", "Glass", Vector3(-9.6, 0, 8.85), Vector3(9.6, 0, 8.85),
		Vector3.BACK, 3.9, 7, 1.9, 3.1, 1)
	LandmarkFhUtil.merlons(lm, "White", Vector3(-10.8, 11.2, 8.6), Vector3(10.8, 11.2, 8.6), 0.75, 0.3, 0.75, 0.25)

	# Gilded ceremonial emblem frame on central pilaster bay (no living person depicted)
	lm.box("Gold", Vector3(0, 5.6, 9.05), Vector3(2.2, 3.2, 0.22))
	lm.box("White", Vector3(0, 5.6, 9.18), Vector3(1.4, 2.2, 0.08))

	for s in [-1.0, 1.0]:
		var sx := float(s)
		var wb := Basis(Vector3.UP, -sx * 0.46)
		var wc := Vector3(sx * 15.2, 0.0, -2.2)
		lm.box("Celadon", wc + Vector3(0, 5.5, 0), Vector3(13.6, 11.0, 14.0), wb)
		for y in [0.5, 3.8, 7.5, 10.7]:
			lm.box("White", wc + Vector3(0, y, 0), Vector3(14.0, 0.42, 14.4), wb)
		lm.gable("Roof", wc + Vector3(0, 11.0, 0), 14.2, 14.0, 2.0, wb * Basis(Vector3.UP, PI * 0.5), 0.2, "Celadon")
		for bi in 4:
			var bx := -4.8 + 3.2 * float(bi)
			for wy in [2.1, 5.6, 9.1]:
				lm.box("Glass", wc + wb * Vector3(bx, wy, 7.04), Vector3(1.25, 1.95, 0.10), wb, 0.0)

static func _central_cupola(lm: LandmarkMesh) -> void:
	# Octagonal white cupola lantern (`11.2..14.9 m`) + dome + flagpole reaching `16.0 m` (`front.jpg`)
	var cc := Vector3(0.0, 11.2, 2.2)
	var rot := PI / 8.0
	lm.lathe("Celadon", cc, PackedVector2Array([Vector2(2.3, 0.0), Vector2(2.2, 2.3)]), 8, 1.0, 1.0, rot, false)
	var apothem := 2.22 * cos(rot)
	for i in 8:
		var a := rot + TAU * (float(i) + 0.5) / 8.0
		var n := Vector3(sin(a), 0, cos(a))
		K.arch_window(lm, "White", "Glass", cc + n * apothem + Vector3(0, 0.35, 0), n, 0.85, 1.65, 0)
	lm.lathe("White", cc + Vector3(0, 2.3, 0), LandmarkFhUtil.dome_prof(2.35, 1.45), 14)
	lm.beam("White", cc + Vector3(0, 3.75, 0), Vector3(0, HEIGHT_M, 2.2), 0.08, 0.08)
