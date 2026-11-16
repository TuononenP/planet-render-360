class_name LandmarkVcHall
extends RefCounted

## The Paul VI Audience Hall with Casa Santa Marta, and the Palace of the
## Governorate, in true metres.

const HALL_YAW := -11.2
const GOV_LEN := 121.5
const GOV_DEEP := 31.5

# --- Paul VI Audience Hall -----------------------------------------------------

## Origin at the middle of Nervi's hall (1966-71), long axis along X,
## entrance end at -X: a 120 x 62 m concrete shell on a travertine
## podium, its roof an undulating vault rising from the 7 m side
## walls to a 20 m crest, the walls braced by fifteen tapering
## buttress piers a side, the end walls glazed under the vault, and the
## entrance block with its canopy. Casa Santa Marta (2003, six storeys,
## 58 x 39 m) stands west of it, aligned to the compass rather than the hall.
static func audience(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B8B2A5", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D5CAB0", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#3E5560"))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4338", 3.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#D3B98F", 4.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#6F6A63", 3.0))
	lm.use("Lead", LandmarkMaterials.pbr("sheet_metal", "#A7ABAB", 3.0, 0.5, 0.3))
	var hall_l := 120.0
	var wid := 62.0
	var hw := wid * 0.5
	lm.box("Stone", Vector3(0, 0.5, 0), Vector3(hall_l + 6.0, 1.0, wid + 6.0))
	# Side walls and the buttress piers leaning against them.
	for s in [-1.0, 1.0]:
		lm.box("Concrete", Vector3(0, 3.6, s * (hw - 0.8)), Vector3(hall_l, 7.0, 1.6))
		for k in 15:
			var x := -hall_l * 0.5 + 4.0 + (hall_l - 8.0) * float(k) / 14.0
			lm.beam("Concrete", Vector3(x, 1.0, s * (hw + 3.0)), Vector3(x, 8.4, s * (hw - 0.6)),
				2.6, 2.2, Vector3.RIGHT)
	# The vault: a smooth shell over the plan, crest 20 m, scalloped along
	# the length where it rests on the piers.
	var rows: Array = []
	var nz := 14
	var nx := 60
	for j in nz + 1:
		var u := float(j) / float(nz) * 2.0 - 1.0
		var row := PackedVector3Array()
		for i in nx + 1:
			var x := -hall_l * 0.5 + hall_l * float(i) / float(nx)
			var wave := 0.5 + 0.5 * cos(TAU * (x + hall_l * 0.5 - 4.0) / ((hall_l - 8.0) / 14.0))
			var arch := pow(maxf(1.0 - u * u, 0.0), 0.6)
			var y := 7.0 + 13.0 * arch - 0.9 * wave * (1.0 - arch)
			row.append(Vector3(x, y, u * (hw - 0.2)))
		rows.append(row)
	SEuUtil.grid_facing(lm, "Lead", rows, Vector3.UP)
	# End walls under the vault: glazed, with the Stone mullions.
	for s in [-1.0, 1.0]:
		var x: float = float(s) * hall_l * 0.5
		var toward := Vector3(s, 0, 0)
		for j in nz:
			var u0 := float(j) / float(nz) * 2.0 - 1.0
			var u1 := float(j + 1) / float(nz) * 2.0 - 1.0
			var h0 := 7.0 + 13.0 * pow(maxf(1.0 - u0 * u0, 0.0), 0.6)
			var h1 := 7.0 + 13.0 * pow(maxf(1.0 - u1 * u1, 0.0), 0.6)
			LandmarkVcUtil.quad_facing(lm, "Glass", Vector3(x, 1.0, u0 * (hw - 0.2)), Vector3(x, 1.0, u1 * (hw - 0.2)),
				Vector3(x, h1, u1 * (hw - 0.2)), Vector3(x, h0, u0 * (hw - 0.2)), toward)
		for k in 9:
			var u := float(k) / 8.0 * 2.0 - 1.0
			var hh := 7.0 + 13.0 * pow(maxf(1.0 - u * u, 0.0), 0.6)
			lm.box("Concrete", Vector3(x + s * 0.2, 1.0 + (hh - 1.0) * 0.5, u * (hw - 0.4)), Vector3(0.5, hh - 1.0, 0.6))
	# Entrance block, canopy and the broad steps.
	lm.box("Stone", Vector3(-hall_l * 0.5 - 5.5, 3.5, 0), Vector3(8.0, 7.0, 44.0))
	lm.box("Concrete", Vector3(-hall_l * 0.5 - 9.5, 7.6, 0), Vector3(15.0, 1.0, 52.0))
	for k in 7:
		var sz := -22.0 + 44.0 * float(k) / 6.0
		lm.box("Stone", Vector3(-hall_l * 0.5 - 10.4, 3.4, sz), Vector3(0.9, 6.8, 0.9))
	for k in 5:
		var z := -17.0 + 34.0 * float(k) / 4.0
		lm.box("Shadow", Vector3(-hall_l * 0.5 - 1.4, 2.4, z), Vector3(0.2, 4.4, 5.6))
	SEuUtil.steps_up(lm, "Stone", Vector3(-hall_l * 0.5 - 12.0, 0, 0), Vector3(-1, 0, 0), 48.0, 0.35, 0.15, 5)
	# Casa Santa Marta, aligned to the compass.
	var sm := LandmarkVcUtil.rbox(lm, "Plaster", -108.8, 5.4, HALL_YAW, 0.0, 58.4, 19.0, 39.1, 0.0)
	var sb := Basis(Vector3.UP, deg_to_rad(HALL_YAW))
	lm.box("Roof", sm + Vector3(0, 9.9, 0), Vector3(59.0, 0.8, 39.7), sb)
	for f in 5:
		for z in [19.6, -19.6]:
			lm.box("Glass", sm + sb * Vector3(0, -9.5 + 2.7 + float(f) * 3.4, z), Vector3(54.0, 1.2, 0.12), sb)
	lm.commit(model)

# --- Palace of the Governorate -----------------------------------------------

## Origin at the middle of the ground plan, front toward +Z (east once
## the registry yaw is applied): Venturi and Momo's 1931 palace, a
## 121.5 x 31.5 m block of cream stone and plaster, six storeys to 27 m
## with a rusticated ground floor and a flat roof, a taller central
## bay 30 m wide with the arched entrance and the arms in its attic,
## and the wings' paired window bands.
static func governorate(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#D8C8A2", 4.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E6DCC3", 3.0))
	lm.use("Rust", LandmarkMaterials.pbr("limestone", "#C9B78F", 2.5))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4338", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#76716A", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	var h := 27.0
	var l := GOV_LEN
	var d := GOV_DEEP
	LandmarkRmLUtil.block(lm, "Wall", Vector3.ZERO, l, h, d, Vector3(0, 0, 1), 6, 29, 1.6, 2.5)
	LandmarkVcUtil.face_windows(lm, "Wall", Vector3.ZERO, Vector3(0, 0, -1), l, h, d, 6, 29, Vector2(1.6, 2.5))
	LandmarkVcUtil.face_windows(lm, "Wall", Vector3.ZERO, Vector3(1, 0, 0), d, h, l, 6, 7, Vector2(1.6, 2.5))
	LandmarkVcUtil.face_windows(lm, "Wall", Vector3.ZERO, Vector3(-1, 0, 0), d, h, l, 6, 7, Vector2(1.6, 2.5))
	# Rusticated ground floor: horizontal joints across the front and back.
	for z in [d * 0.5 + 0.1, -d * 0.5 - 0.1]:
		for j in 7:
			lm.box("Rust", Vector3(0, 0.6 + 0.62 * float(j), z), Vector3(l + 0.4, 0.14, 0.22))
		lm.box("Rust", Vector3(0, 2.4, z), Vector3(l + 0.4, 4.8, 0.1))
	# Flat roof slab and the roof parapet.
	lm.box("Roof", Vector3(0, h + 0.15, 0), Vector3(l - 0.6, 0.3, d - 0.6))
	lm.box("Trim", Vector3(0, h + 0.7, d * 0.5 - 0.3), Vector3(l, 1.0, 0.5))
	lm.box("Trim", Vector3(0, h + 0.7, -d * 0.5 + 0.3), Vector3(l, 1.0, 0.5))
	# Central bay: projecting, taller, with the arched entrance and attic.
	var cb := 30.0
	lm.box("Wall", Vector3(0, 15.0, d * 0.5 + 1.5), Vector3(cb, 30.0, 3.0))
	lm.box("Trim", Vector3(0, 29.6, d * 0.5 + 1.6), Vector3(cb + 1.0, 1.0, 3.6))
	lm.box("Trim", Vector3(0, 0.5, d * 0.5 + 1.6), Vector3(cb + 0.8, 1.0, 3.4))
	for z in [d * 0.5 + 3.05]:
		for s in [-1.0, 1.0]:
			lm.box("Trim", Vector3(s * 11.2, 14.0, z), Vector3(1.4, 25.0, 0.2))
		# Triple entrance arches framed by piers, then three window storeys.
		SEuParts.niche(lm, "Trim", "Shadow", Vector3(-7.0, 0.8, z), Vector3(0, 0, 1), 5.0, 8.2, SEuParts.ROUND, 0.5)
		SEuParts.niche(lm, "Trim", "Shadow", Vector3(0.0, 0.8, z), Vector3(0, 0, 1), 5.0, 9.0, SEuParts.ROUND, 0.5)
		SEuParts.niche(lm, "Trim", "Shadow", Vector3(7.0, 0.8, z), Vector3(0, 0, 1), 5.0, 8.2, SEuParts.ROUND, 0.5)
		for f in 3:
			for k in 5:
				var wx := -8.0 + 4.0 * float(k)
				LandmarkRmLKit.frame_opening(lm, "Trim", Vector3(wx, 11.0 + 5.8 * float(f), z), Vector3(1, 0, 0),
					Vector3(0, 0, 1), 1.8, 3.2, 0)
	lm.disc("Gold", Vector3(0, 27.6, d * 0.5 + 3.12), Vector3(0, 0, 1), 1.3, 18)
	lm.box("Roof", Vector3(0, 30.3, d * 0.5 + 1.5), Vector3(cb - 1.0, 0.6, 3.0))
	lm.commit(model)
