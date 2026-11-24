extends RefCounted

## Havis Amanda (Ville Vallgren, 1908), the Art Nouveau mermaid fountain at the
## head of Helsinki Market Square. Model origin on OSM artwork node 1376320186.
##
## Authentic Vehmaa red-granite circular basin on two grey-granite steps with
## four projecting rim pedestals carrying lifelike bronze sea lions spouting
## parabolic jets inward, a slender sculpted red-granite & bronze column wrapped
## with four spouting sea-fish and kelp, and Vallgren's contrapposto bronze
## mermaid rising from the waves to 5.0 m total height.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const ENTRY := {"type": "havis_amanda", "name": "Havis Amanda", "lat": 60.1675863, "lon": 24.9513987,
	"radius_m": 1500.0, "wiki_title": "Havis Amanda", "height_m": 5.0, "clear_m": 7.0,
	"base_at_m": [0.0, 9.0], "base_drop_m": 0.35,
	"kind": "Fountain", "aliases": ["havis amanda", "havis amanda fountain", "manta helsinki"]}

const RIM := 0.88

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#A66A60", 1.2, 0.38))
	lm.use("Step", LandmarkMaterials.pbr("stone", "#8C8884", 2.0))
	lm.use("Bronze", LandmarkMaterials.paint("#3B5949", 0.38, 0.68))
	lm.use("Water", LandmarkMaterials.pool_water("#46847E", 0.06))

	# Two stepped grey-granite paving rings & moulded polished Vehmaa red-granite basin.
	lm.lathe("Step", Vector3.ZERO, PackedVector2Array([
		Vector2(6.65, 0.0), Vector2(6.65, 0.14),
		Vector2(6.15, 0.15), Vector2(6.15, 0.29), Vector2(5.75, 0.30),
	]), 64)
	lm.lathe("Granite", Vector3(0.0, 0.29, 0.0), PackedVector2Array([
		Vector2(5.65, 0.0), Vector2(5.62, 0.18), Vector2(5.48, 0.42),
		Vector2(5.58, 0.52), Vector2(5.42, RIM - 0.29),
		Vector2(5.16, RIM - 0.33), Vector2(5.08, 0.25), Vector2(5.02, 0.08),
	]), 64)
	lm.disc("Water", Vector3(0.0, RIM - 0.14, 0.0), Vector3.UP, 5.08, 64)

	# Slender Art Nouveau red-granite central pedestal shaft (NOT a wide saucer!)
	lm.lathe("Granite", Vector3(0.0, 0.30, 0.0), PackedVector2Array([
		Vector2(1.18, 0.0), Vector2(1.06, 0.28), Vector2(0.76, 0.58),
		Vector2(0.58, 1.05), Vector2(0.46, 1.75), Vector2(0.44, 2.25),
		Vector2(0.58, 2.52), Vector2(0.64, 2.66), Vector2(0.50, 2.70),
	]), 36)
	# Scalloped bronze Art Nouveau shell & seaweed capital crowning the granite shaft (y = 2.95 m)
	var cap_centers := PackedVector3Array()
	var cap_rows: Array = []
	for j in 6:
		var t := float(j) / 5.0
		var y := 2.76 + t * 0.24
		var base_r := 0.01 if j == 5 else lerpf(0.45, 0.62, sin(t * PI * 0.72))
		cap_centers.append(Vector3(0.0, y, 0.0))
		var row := PackedVector3Array()
		for i in 29:
			var a := TAU * float(i) / 28.0 if i < 28 else 0.0
			var scallop := (1.0 + 0.07 * sin(a * 8.0) * sin(t * PI)) if j < 5 else 1.0
			row.append(Vector3(cos(a) * base_r * scallop, y, sin(a) * base_r * scallop))
		cap_rows.append(row)
	SculptureKit.emit_rings(lm, "Bronze", cap_centers, cap_rows)
	# Sculpted bronze wave & seaweed relief collar around the lower flare of the granite shaft
	var col_centers := PackedVector3Array()
	var col_rows: Array = []
	for j in 5:
		var t := float(j) / 4.0
		var y := 0.68 + t * 0.56
		var r_col := lerpf(0.96, 0.64, t)
		col_centers.append(Vector3(0.0, y, 0.0))
		var row := PackedVector3Array()
		for i in 29:
			var a := TAU * float(i) / 28.0 if i < 28 else 0.0
			var wave_mod := 1.0 + 0.06 * sin(a * 8.0 + t * 2.4)
			row.append(Vector3(cos(a) * r_col * wave_mod, y, sin(a) * r_col * wave_mod))
		col_rows.append(row)
	SculptureKit.emit_rings(lm, "Bronze", col_centers, col_rows)

	var fk := FountainKit.new()
	_sea_lions_and_fish(lm, fk)
	# Ville Vallgren's bronze mermaid (2.02 m figure standing at y = 2.98 -> exact 5.00 m crest)
	SculptureKit.contrapposto_nude(lm, "Bronze", Vector3(0.0, 2.98, 0.0), 2.02, 0.25)

	lm.commit(model)
	fk.commit(model)
	var warm := Color(1.0, 0.88, 0.66)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(4.2, RIM + 0.1, 4.2), Vector3(0.0, 3.8, 0.0), 50.0, 0.9, 14.0, warm],
		[Vector3(-4.2, RIM + 0.1, 4.2), Vector3(0.0, 3.8, 0.0), 50.0, 0.9, 14.0, warm],
		[Vector3(-4.2, RIM + 0.1, -4.2), Vector3(0.0, 3.8, 0.0), 50.0, 0.9, 14.0, warm],
		[Vector3(4.2, RIM + 0.1, -4.2), Vector3(0.0, 3.8, 0.0), 50.0, 0.9, 14.0, warm],
	])

static func _sea_lions_and_fish(lm: LandmarkMesh, fk: FountainKit) -> void:
	var wat_y := RIM - 0.14
	for i in 4:
		var a := TAU * float(i) / 4.0 + PI * 0.25
		var d := Vector3(cos(a), 0.0, sin(a))
		var yaw_inward := atan2(-d.x, -d.z)
		# Projecting red-granite rim plinth under each bronze sea lion
		var plinth_c := d * 5.25 + Vector3(0.0, 0.62, 0.0)
		lm.box("Granite", plinth_c, Vector3(1.15, 0.68, 1.55), Basis(Vector3.UP, yaw_inward))
		lm.box("Granite", plinth_c + Vector3(0.0, 0.36, 0.0), Vector3(1.26, 0.10, 1.66), Basis(Vector3.UP, yaw_inward))
		var lion_base := d * 5.20 + Vector3(0.0, 0.98, 0.0)
		var mouth := SculptureKit.sea_lion(lm, "Bronze", lion_base, 1.48, yaw_inward)
		var land := d * 1.75 + Vector3(0.0, wat_y, 0.0)
		fk.arc_stream(mouth, land, 0.68, 0.065, 0.17)
		fk.splash_ring(land, 0.85, 0.82)

		# Compact Art Nouveau bronze grotesque sea-fish / dolphins emerging from the lower wave collar
		var fa := a + PI * 0.25
		var fd := Vector3(cos(fa), 0.0, sin(fa))
		var f_side := Vector3(-fd.z, 0.0, fd.x)
		var fish_spine := PackedVector3Array([
			fd * 0.64 + f_side * 0.12 + Vector3(0.0, 1.30, 0.0), # curled tail root on lower shaft
			fd * 0.76 + f_side * 0.06 + Vector3(0.0, 1.15, 0.0), # arched scaly body
			fd * 0.92 + Vector3(0.0, 1.03, 0.0),                 # broad gill / brow head
			fd * 1.06 + Vector3(0.0, 0.97, 0.0),                 # upper snout lip
		])
		SculptureKit.loft_tube(lm, "Bronze", fish_spine, PackedVector2Array([
			Vector2(0.045, 0.065), Vector2(0.085, 0.095),
			Vector2(0.115, 0.110), Vector2(0.060, 0.052),
		]), 14)
		# Parted lower jaw + fanned bilobed tail fin + delicate S-curved relief kelp hugging lower shaft
		SculptureKit.loft_tube(lm, "Bronze", PackedVector3Array([
			fd * 0.90 + Vector3(0.0, 0.96, 0.0), fd * 1.03 + Vector3(0.0, 0.90, 0.0),
		]), PackedVector2Array([Vector2(0.065, 0.040), Vector2(0.038, 0.022)]), 10)
		for lobe in [-1.0, 1.0]:
			var lf := float(lobe)
			SculptureKit.loft_tube(lm, "Bronze", PackedVector3Array([
				fd * 0.64 + f_side * 0.12 + Vector3(0.0, 1.30, 0.0),
				fd * 0.58 + f_side * (0.12 + lf * 0.11) + Vector3(0.0, 1.44, 0.0),
			]), PackedVector2Array([Vector2(0.038, 0.018), Vector2(0.052, 0.012)]), 8)
		var fish_mouth := fd * 1.05 + Vector3(0.0, 0.94, 0.0)
		var fish_land := fd * 2.85 + Vector3(0.0, wat_y, 0.0)
		fk.arc_stream(fish_mouth, fish_land, 0.48, 0.052, 0.14)
		fk.splash_ring(fish_land, 0.70, 0.76)
	# Subtle splash ripple around the foot of the red-granite shaft (keep shaft & bronze fish clearly visible!)
	fk.splash_ring(Vector3(0.0, wat_y, 0.0), 1.55, 0.55)
	fk.mist_emitter(Vector3(0.0, wat_y + 0.25, 0.0), 1.1, 0.75, 3)
