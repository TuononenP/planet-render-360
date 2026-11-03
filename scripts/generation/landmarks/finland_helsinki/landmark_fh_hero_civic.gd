class_name LandmarkFhHeroCivic
extends RefCounted

## Helsinki additions, true metres. Building envelopes are approximations
## around mapped locations; architectural cues follow owner photographs.
## Kamppi: https://kampinkappeli.fi/en/index/architectureanddesign.html
## Amos Rex: https://jkmm.fi/work/amos-rex-museum/
## Empire pair: https://historia.hel.fi/en/alueet/southern/the-senate-square
## University: https://www.helsinki.fi/en/about-us/university-helsinki/history

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

static func _materials(wall: String = "#D9C690") -> LandmarkMesh:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", wall, 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#92908A", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E8E3D4", 2.0))
	lm.use("Roof", LandmarkMaterials.paint("#536D60", 0.58))
	lm.use("Glass", LandmarkMaterials.glass())
	return lm

## Windowless timber vessel with the flaring upper lip and low entrance.
static func kamppi(model: Node3D) -> void:
	var lm := _materials()
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#BC853E", 2.0))
	lm.use("Seam", LandmarkMaterials.pbr("wood", "#9D7039", 2.0))
	var profile := PackedVector2Array([Vector2(0.82, 0), Vector2(0.83, 1), Vector2(0.87, 3),
		Vector2(0.93, 6), Vector2(0.985, 9), Vector2(1.0, 11.5)])
	lm.lathe("Wood", Vector3.ZERO, profile, 64, 8.4, 6.2)
	# Fine horizontal plank seams follow the same curved vessel profile.
	for i in 57:
		var y := 0.15 + float(i) * 0.20
		var r := profile[0].x
		for j in profile.size() - 1:
			if y >= profile[j].y and y <= profile[j + 1].y:
				r = lerpf(profile[j].x, profile[j + 1].x,
					(y - profile[j].y) / (profile[j + 1].y - profile[j].y))
				break
		lm.lathe("Seam", Vector3(0, y, 0), PackedVector2Array([Vector2(r + 0.002, 0),
			Vector2(r + 0.002, 0.016)]), 64, 8.4, 6.2, 0.0, false, false)
	# Elliptical flat roof closes the vessel, hidden behind the wood rim.
	var roof := PackedVector2Array([Vector2(1.0, 0), Vector2(0.0, 0)])
	lm.lathe("Roof", Vector3(0, 11.44, 0), roof, 64, 8.35, 6.15, 0.0, false)
	U.blk(lm, "Stone", 8.4, 0, -1.8, 8.0, 3.0, 8.0)
	LandmarkDetail.window(lm, "Trim", "Glass", Vector3(8.4, 1.3, 2.24), Vector3.BACK, 3.2, 2.5, false, 0.08)
	lm.commit(model)

## Five low concrete light scoops; each has an offset circular skylight.
static func amos(model: Node3D) -> void:
	var lm := _materials("#B9B7AA")
	U.blk(lm, "Stone", 0, 0, 0, 67.0, 0.15, 53.0)
	for dome in [[-18.0, -11.0, 10.0, 5.0], [5.0, -13.0, 9.0, 4.2],
			[20.0, 5.0, 7.0, 3.0], [-1.0, 11.0, 11.0, 6.0], [-23.0, 13.0, 6.0, 2.7]]:
		var base := Vector3(float(dome[0]), 0.15, float(dome[1]))
		var r := float(dome[2])
		var h := float(dome[3])
		var rings: Array = []
		for j in 13:
			var t := float(j) / 12.0
			var ring := PackedVector3Array()
			var rad := lerpf(r, 1.7, t)
			for k in 49:
				var a := TAU * float(k) / 48.0
				ring.append(base + Vector3(cos(a) * rad + t * 2.2,
					h * sin(t * PI * 0.5), sin(a) * rad))
			rings.append(ring)
		lm.grid("Wall", rings, base + Vector3(0, -2, 0), true)
		var top := base + Vector3(2.2, h, 0)
		lm.frustum("Trim", top, 1.85, 1.85, 0.20, 48)
		lm.disc("Glass", top + Vector3.UP * 0.21, Vector3.UP, 1.62, 48)
	lm.commit(model)

## The matched Senate Square facades use distinct classical orders.
static func empire(model: Node3D, government: bool) -> void:
	var lm := _materials("#DCC280" if government else "#E4D9B5")
	var w := 88.0 if government else 85.0
	var d := 18.0
	var h := 18.0
	U.blk(lm, "Stone", 0, 0, 0, w, 1.2, d)
	U.blk(lm, "Wall", 0, 1.2, 0, w, h - 1.2, d)
	# Side and rear wings enclose the real city-block courtyard.
	for s in [-1.0, 1.0]:
		U.blk(lm, "Wall", s * (w * 0.5 - 7.0), 0, -27.0, 14.0, 15.0, 40.0)
		U.hip(lm, "Roof", Vector3(s * (w * 0.5 - 7.0), 15.0, -27.0), 14.8, 40.8, 4.0, 0.12)
	U.blk(lm, "Wall", 0, 0, -49.0, w, 15.0, 14.0)
	U.hip(lm, "Roof", Vector3(0, 15, -49), w + 0.8, 14.8, 4.0, 0.1)
	U.hip(lm, "Roof", Vector3(0, h, 0), w + 0.8, d + 0.8, 4.0, 0.16)
	for row in 3:
		var y := 2.0 + float(row) * 5.0
		for i in 21:
			var x := (float(i) - 10.0) * 3.9
			if absf(x) < 12.0 and row > 0:
				continue
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, y + 1.55, 9.1), Vector3.BACK,
				1.55, 3.1, row == 0, 0.18)
		LandmarkDetail.cornice(lm, "Trim", Vector3(-w * 0.5, y - 0.4, 9.05),
			Vector3(w * 0.5, y - 0.4, 9.05), Vector3.BACK, 0.25, false)
	U.blk(lm, "Wall", 0, 0, 10.0, 24.0, 18.0, 3.0)
	U.window_grid(lm, "Glass", Vector3(-11.0, 0, 11.6), Vector3(11.0, 0, 11.6), Vector3.BACK,
		7.1, 2, 5.0, 7, 1.5, 3.0)
	for i in 6:
		LandmarkDetail.column(lm, "Trim", Vector3((float(i) - 2.5) * 3.6, 5.3, 12.3), 0.56,
			10.8, "corinthian" if government else "ionic", 20, 12)
	U.blk(lm, "Trim", 0, 16.1, 11.5, 23.0, 1.5, 4.0)
	lm.gable("Trim", Vector3(0, 17.6, 11.6), 23.0, 3.8, 3.0)
	if government:
		lm.frustum("Trim", Vector3(0, 20, -2), 5.0, 5.0, 2.0, 32)
		lm.lathe("Roof", Vector3(0, 22, -2), U.dome_prof(5.0, 4.0), 40)
	LandmarkDetail.cornice(lm, "Trim", Vector3(-w * 0.5, h - 0.5, 9),
		Vector3(w * 0.5, h - 0.5, 9), Vector3.BACK, 0.65)
	U.steps(lm, "Stone", Vector3(0, 0, 12), Vector3.BACK, 19.0, 0.35, 0.2, 6)
	lm.commit(model)

## Saarinen's red-brick market hall: granite base, white window heads,
## paired gables and a long grey sheet-metal ridge.
static func hakaniemi(model: Node3D) -> void:
	var lm := _materials("#A6523E")
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A6523E", 2.0))
	lm.use("Roof", LandmarkMaterials.paint("#575C5B"))
	U.blk(lm, "Stone", 0, 0, 0, 59.0, 1.0, 25.0)
	U.blk(lm, "Brick", 0, 1, 0, 59.0, 11.0, 25.0)
	U.ridge_x(lm, "Roof", "Brick", Vector3(0, 12, 0), 60.0, 26.0, 5.0)
	for s in [-1.0, 1.0]:
		for i in 14:
			var x := (float(i) - 6.5) * 3.9
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, 4.2, s * 12.6), Vector3(0, 0, s), 2.1, 4.8, true, 0.22)
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, 9.4, s * 12.6), Vector3(0, 0, s), 2.1, 2.8, false, 0.16)
		for x in [-22.0, 22.0]:
			U.blk(lm, "Brick", x, 0, s * 12.8, 8.0, 13.0, 2.0)
			lm.gable("Roof", Vector3(x, 13.0, s * 12.8), 8.8, 2.6, 4.0, Basis(), 0.0, "Brick")
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, 3, s * 13.9), Vector3(0, 0, s), 3.0, 5.0, true, 0.25)
	lm.commit(model)

## Nordiska Kompaniet style department store, its striped stone piers,
## bronze shop fronts and copper screen crown facing the Three Smiths.
static func stockmann(model: Node3D) -> void:
	var lm := _materials("#967F6A")
	U.blk(lm, "Stone", 0, 0, 0, 83.0, 30.0, 65.0)
	U.blk(lm, "Roof", 0, 30, 0, 82.0, 5.0, 64.0)
	for s in [-1.0, 1.0]:
		for i in 20:
			var x := (float(i) - 9.5) * 3.9
			for row in 6:
				var y := 2.6 + float(row) * 4.2
				LandmarkDetail.window(lm, "Wall", "Glass", Vector3(x, y, s * 32.55), Vector3(0, 0, s), 2.45, 3.3, false, 0.16)
			U.blk(lm, "Roof", x, 30, s * 32.55, 0.25, 5.0, 0.35)
		for j in 15:
			var z := (float(j) - 7.0) * 4.1
			for row in 6:
				LandmarkDetail.window(lm, "Wall", "Glass", Vector3(s * 41.55, 2.6 + float(row) * 4.2, z),
					Vector3(s, 0, 0), 2.5, 3.3, false, 0.16)
	# The clock is part of the familiar main-entrance meeting place.
	lm.disc("Trim", Vector3(0, 6.8, 32.9), Vector3.BACK, 0.95, 32)
	lm.beam("Roof", Vector3(0, 6.8, 32.95), Vector3(0, 7.5, 32.95), 0.07)
	lm.beam("Roof", Vector3(0, 6.8, 32.95), Vector3(0.5, 6.55, 32.95), 0.07)
	lm.commit(model)
