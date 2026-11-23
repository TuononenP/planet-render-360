class_name LandmarkBkAnantaSamakhom
extends RefCounted

## Ananta Samakhom Throne Hall & Royal Plaza (`พระที่นั่งอนันตสมาคม`) — Bangkok BK-11
## Site: OSM way 31987148 + node 358479765 (King Chulalongkorn equestrian monument),
## centroid 13.771718, 100.513038 (`height_m: 49.5`, `yaw_deg: 17.0` so long `112.5 m` E-W
## facade spans `X` and faces S `+Z` onto the Royal Plaza).
## Spec (Mario Tamagno, Annibale Rigotti & Carlo Allegri 1908–15, Commons `front.jpg`):
##   - Monumental two-storey white Carrara marble Italian Renaissance / Neo-Classic basilica
##     (`112.5 × 49.5 m`) on a rusticated ground arcade with arched Palladian upper windows,
##     coupled Corinthian pilasters, balustraded attic parapet (`21.5 m`), and projecting
##     pedimented end & central pavilions.
##   - High colonnaded circular marble tambour drum (`21.5..35.5 m`) carrying the ribbed
##     patinated verdigris-copper central dome, lantern & finial rising to `49.5 m`, flanked
##     by six subsidiary patinated green-copper domes over the nave, apse, transepts & ends.
##   - South axial Royal Plaza (`Lan Phra Borommarup Song Ma`) with the bronze equestrian
##     statue of King Chulalongkorn (Rama V, 1908) on a tall white marble & bronze pedestal.

const D = preload("res://scripts/generation/landmark_detail.gd")
const Kits = preload("res://scripts/generation/landmark_kits.gd")

const HEIGHT_M := 49.5

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#ECEBE6", 3.5))
	lm.use("MarbleTrim", LandmarkMaterials.pbr("limestone", "#F7F6F2", 2.5))
	lm.use("Copper", LandmarkMaterials.pbr("copper", "#4F8478", 2.6, 0.52, 0.25))
	lm.use("Glass", LandmarkMaterials.glass("#2D3B46"))
	lm.use("Bronze", LandmarkMaterials.paint("#3E3528", 0.40, 0.78))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#8C8B86", 4.0))
	lm.use("Grass", LandmarkMaterials.pbr("grass", "#456C30", 4.0))

	_marble_palace_body(lm)
	_seven_copper_domes(lm)
	_royal_plaza_equestrian(lm)
	lm.commit(model)

	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-34.0, 2.5, 36.0), Vector3(-12.0, 18.0, 0.0), 86.0, 1.35, 48.0, Color(1.0, 0.94, 0.82)],
		[Vector3(34.0, 2.5, 36.0), Vector3(12.0, 18.0, 0.0), 86.0, 1.35, 48.0, Color(1.0, 0.94, 0.82)],
		[Vector3(0.0, 22.0, 22.0), Vector3(0.0, 38.0, 0.0), 58.0, 1.45, 42.0, Color(0.95, 0.98, 0.92)],
		[Vector3(0.0, 2.0, 62.0), Vector3(0.0, 10.0, 48.0), 34.0, 1.15, 32.0, Color(1.0, 0.90, 0.72)],
	])

static func _marble_palace_body(lm: LandmarkMesh) -> void:
	# Raised marble stylobate (`114 × 50 m`) + E-W main nave (`110 × 26 m`) + N-S transept (`32 × 48 m`)
	lm.box("MarbleTrim", Vector3(0, 0.75, 0), Vector3(114.0, 1.5, 50.0))
	var y0 := 1.5
	var wall_h := 18.2
	lm.box("Marble", Vector3(0, y0 + wall_h * 0.5, 0), Vector3(108.0, wall_h, 25.0))
	lm.box("Marble", Vector3(0, y0 + (wall_h + 1.4) * 0.5, 0), Vector3(28.0, wall_h + 1.4, 46.0))
	# End pavilions (`±46 m` along X, `18 × 32 m`, slightly proud like `front.jpg`)
	for sx in [-1.0, 1.0]:
		var px := float(sx) * 46.0
		lm.box("Marble", Vector3(px, y0 + wall_h * 0.5, 0), Vector3(18.0, wall_h + 0.6, 31.0))
		lm.box("MarbleTrim", Vector3(px, y0 + wall_h + 0.8, 0), Vector3(19.0, 0.9, 32.0))

	# Pierced Renaissance window bays on long S & N faces + Corinthian pilaster rhythm + entablature
	for sz in [-1.0, 1.0]:
		var z_wing := float(sz) * 12.52
		var nrm := Vector3(0, 0, float(sz))
		var right := Vector3(float(sz), 0, 0)
		for sx in [-1.0, 1.0]:
			var wx := float(sx) * 25.5
			D.pierced_face(lm, "Marble", "Glass", Vector3(wx, y0 + 0.8, z_wing), right, nrm,
				22.0, 16.0, 5, 2, Vector2(2.4, 4.8), 1.4, 7.6, 0.42)
			for k in 6:
				var cx := wx - 10.5 + float(k) * 4.2
				lm.box("MarbleTrim", Vector3(cx, y0 + 9.0, z_wing + float(sz) * 0.22), Vector3(0.75, 16.8, 0.45))
		# Central transept arch frontispiece (`front.jpg` semicircular coffered entry arch + pediment)
		var z_trans := float(sz) * 23.05
		D.pierced_face(lm, "Marble", "Glass", Vector3(0.0, y0 + 0.8, z_trans), right, nrm,
			24.0, 16.6, 5, 2, Vector2(2.6, 5.2), 1.4, 7.8, 0.48)
		lm.gable("MarbleTrim", Vector3(0.0, y0 + wall_h + 1.4, float(sz) * 21.8), 26.0, 4.2, 3.6, Basis(), 0.4, "Marble")
		for k in [-10.5, -5.2, 5.2, 10.5]:
			lm.frustum("MarbleTrim", Vector3(float(k), y0, z_trans + float(sz) * 0.45), 0.58, 0.50, 17.4, 12)

	# Continuous Renaissance cornice & rooftop marble balustrade (`y = 19.7..21.4 m`)
	lm.box("MarbleTrim", Vector3(0, y0 + wall_h + 0.48, 0), Vector3(109.2, 0.95, 26.2))
	D.balustrade(lm, "MarbleTrim", Vector3(-54.0, y0 + wall_h + 0.95, 12.8),
		Vector3(54.0, y0 + wall_h + 0.95, 12.8), 1.25, 2.2)
	D.balustrade(lm, "MarbleTrim", Vector3(-54.0, y0 + wall_h + 0.95, -12.8),
		Vector3(54.0, y0 + wall_h + 0.95, -12.8), 1.25, 2.2)

static func _seven_copper_domes(lm: LandmarkMesh) -> void:
	# 1. Central crossing tambour drum (`r = 9.4 m`, `20.8..32.2 m`) with 16 coupled columns + ribbed copper dome (`49.5 m`)
	var dy := 20.8
	lm.frustum("Marble", Vector3(0, dy, 0), 10.2, 9.8, 2.4, 20)
	lm.frustum("Marble", Vector3(0, dy + 2.4, 0), 8.9, 8.7, 9.2, 20)
	for i in 16:
		var a := TAU * float(i) / 16.0
		lm.frustum("MarbleTrim", Vector3(cos(a) * 9.35, dy + 2.4, sin(a) * 9.35), 0.42, 0.36, 8.8, 8)
		lm.box("Glass", Vector3(cos(a + PI / 16.0) * 8.65, dy + 6.8, sin(a + PI / 16.0) * 8.65),
			Vector3(1.1, 4.2, 1.1), Basis(Vector3.UP, -a))
	lm.frustum("MarbleTrim", Vector3(0, dy + 11.6, 0), 9.6, 9.2, 1.1, 20)
	# Ribbed patinated copper dome (`33.5..43.2 m`) + marble/copper lantern (`43.2..47.0 m`) + finial (`49.5 m`)
	var dome_prof := PackedVector2Array([
		Vector2(9.1, 0.0), Vector2(8.9, 2.4), Vector2(8.0, 5.2),
		Vector2(6.1, 7.6), Vector2(3.4, 9.2), Vector2(1.8, 9.8),
	])
	lm.lathe("Copper", Vector3(0, 33.5, 0), dome_prof, 20)
	for i in 12:
		var a := TAU * float(i) / 12.0
		lm.beam("MarbleTrim", Vector3(cos(a) * 9.05, 33.6, sin(a) * 9.05),
			Vector3(cos(a) * 2.1, 43.1, sin(a) * 2.1), 0.22, 0.22)
	lm.frustum("Copper", Vector3(0, 43.3, 0), 1.95, 1.75, 2.6, 12)
	lm.lathe("Copper", Vector3(0, 45.9, 0), PackedVector2Array([
		Vector2(1.85, 0.0), Vector2(1.1, 1.0), Vector2(0.18, 1.7)]), 12)
	lm.beam("Gold", Vector3(0, 47.5, 0), Vector3(0, HEIGHT_M, 0), 0.14, 0.14)

	# 2. Six subsidiary copper domes: two over end pavilions (`±46, 0`), two intermediate (`±22, 0`), two N/S arms (`0, ±17`)
	for sub in [Vector3(-46.0, 20.4, 0.0), Vector3(46.0, 20.4, 0.0),
			Vector3(-22.0, 19.8, 0.0), Vector3(22.0, 19.8, 0.0),
			Vector3(0.0, 21.2, -16.5), Vector3(0.0, 21.2, 16.5)]:
		var p := sub as Vector3
		var r := 5.0 if absf(p.x) > 35.0 else 3.8
		lm.frustum("MarbleTrim", p, r * 1.08, r * 1.02, 2.2, 14)
		lm.lathe("Copper", p + Vector3(0, 2.2, 0), PackedVector2Array([
			Vector2(r, 0.0), Vector2(r * 0.88, r * 0.48), Vector2(r * 0.52, r * 0.86),
			Vector2(0.45, r * 1.05), Vector2(0.0, r * 1.45)]), 14)

static func _royal_plaza_equestrian(lm: LandmarkMesh) -> void:
	# Paved Royal Plaza (`+Z = 25..62 m`) + King Chulalongkorn equestrian monument (`front.jpg`)
	lm.box("Paving", Vector3(0, 0.08, 44.0), Vector3(54.0, 0.16, 38.0))
	for sx in [-18.0, 18.0]:
		lm.box("Grass", Vector3(float(sx), 0.14, 48.0), Vector3(10.0, 0.22, 12.0))
	var ped := Vector3(0, 0.16, 48.0)
	lm.box("MarbleTrim", ped + Vector3(0, 0.45, 0), Vector3(7.6, 0.90, 9.8))
	lm.box("MarbleTrim", ped + Vector3(0, 3.10, 0), Vector3(2.9, 4.40, 4.6))
	lm.box("Gold", ped + Vector3(0, 3.00, 2.34), Vector3(1.8, 2.4, 0.10))
	lm.box("MarbleTrim", ped + Vector3(0, 5.55, 0), Vector3(3.4, 0.50, 5.1))
	# Bronze horse + rider facing S (`+Z`) onto Ratchadamnoen Nok Avenue
	var horse := ped + Vector3(0, 5.80, 0)
	lm.box("Bronze", horse + Vector3(0, 1.55, 0.0), Vector3(0.95, 1.15, 2.75))
	lm.beam("Bronze", horse + Vector3(0, 1.85, 1.05), horse + Vector3(0, 2.95, 1.55), 0.52, 0.62)
	lm.box("Bronze", horse + Vector3(0, 3.05, 1.75), Vector3(0.42, 0.46, 0.78))
	for lx in [-0.34, 0.34]:
		for lz in [-0.95, 0.95]:
			lm.beam("Bronze", horse + Vector3(float(lx), 0.0, float(lz)),
				horse + Vector3(float(lx), 1.35, float(lz)), 0.22, 0.22)
	Kits.statue_figure(lm, "Bronze", horse + Vector3(0, 1.95, -0.05), 2.35)
