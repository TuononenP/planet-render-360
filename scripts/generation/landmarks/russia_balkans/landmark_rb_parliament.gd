class_name LandmarkRbParliament
extends RefCounted

## The Palace of the Parliament, Bucharest (Anca Petrescu, 1984-1997),
## in true metres: the colossal marble-clad block, 270 x 240 m on plan,
## rising in setback tiers to the square central tower, 84 m. Its
## "neo-neoclassical" fronts carry rows of windows between pilasters,
## balustrades on every setback, the arcaded base and the colonnaded
## balcony loggia of the main (east) front, and the four corner
## pavilions.

const PARL_TOP := 84.0
## Tiers: width (X), depth (Z), top y.
const TIERS := [[216.0, 168.0, 38.0], [172.0, 128.0, 52.0], [100.0, 84.0, 66.0]]
const ZC := 2.0

## Origin at the footprint centre, the balcony front facing +Z (the real
## front looks east down Bulevardul Unirii).
static func parliament(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DAD3C2", 5.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E9E4D6", 4.0))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#8E8A80", 4.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#56626A", 4.0, 0.55, 0.25))
	lm.use("Dome", LandmarkMaterials.pbr("slate", "#7A8A94", 4.0, 0.3, 0.5))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	# Setback tiers: the mass, its moulded cornice, the flat roof, the
	# balustrade round the edge and the window skins on every front.
	var low := 0.0
	for ti in TIERS.size():
		var t: Array = TIERS[ti]
		var w: float = t[0]
		var d: float = t[1]
		var top: float = t[2]
		var h := top - low
		lm.box("Stone", Vector3(0, low + h * 0.5, ZC), Vector3(w - 0.8, h, d - 0.8))
		lm.box("Trim", Vector3(0, top - 0.6, ZC), Vector3(w + 0.6, 1.2, d + 0.6))
		lm.box("Roof", Vector3(0, top + 0.05, ZC), Vector3(w - 1.0, 0.1, d - 1.0), Basis(), 0.0)
		var corners := [Vector3(-w * 0.5, top, ZC - d * 0.5), Vector3(w * 0.5, top, ZC - d * 0.5),
			Vector3(w * 0.5, top, ZC + d * 0.5), Vector3(-w * 0.5, top, ZC + d * 0.5)]
		for k in 4:
			var a: Vector3 = corners[k]
			var b: Vector3 = corners[(k + 1) % 4]
			LandmarkRbParts.balustrade(lm, "Trim", a, b, 1.2, 0.9, 6.0)
		var storeys := 6 if ti == 0 else 2
		var y0 := low + (1.5 if ti == 0 else 1.0)
		var wall_h := top - 1.2 - y0
		_front(lm, Vector3(0, y0, ZC - d * 0.5 + 0.4), Vector3(0, 0, -1), w - 0.8, wall_h, storeys, ti == 0)
		_front(lm, Vector3(w * 0.5 - 0.4, y0, ZC), Vector3(1, 0, 0), d - 0.8, wall_h, storeys, ti == 0)
		_front(lm, Vector3(-w * 0.5 + 0.4, y0, ZC), Vector3(-1, 0, 0), d - 0.8, wall_h, storeys, ti == 0)
		if ti == 0:
			# The main front is split by the central block.
			for sx in [-1.0, 1.0]:
				_front(lm, Vector3(sx * 77.0, y0, ZC + d * 0.5 - 0.4), Vector3(0, 0, 1), 61.0, wall_h, storeys, true)
		else:
			_front(lm, Vector3(0, y0, ZC + d * 0.5 - 0.4), Vector3(0, 0, 1), w - 0.8, wall_h, storeys, false)
		low = top
	lm.box("Plinth", Vector3(0, 0.75, ZC), Vector3(217.0, 1.5, 169.0))
	_pavilions(lm)
	_front_block(lm)
	_tower(lm)
	lm.commit(model)

## A window skin over the front centred at `c` (foot of the skin) facing
## `out`, `w` long and `h` tall: `storeys` rows of real openings in 4.2 m
## bays, pilaster strips every third bay and a string course per storey.
static func _front(lm: LandmarkMesh, c: Vector3, out: Vector3, w: float, h: float, storeys: int, tall: bool) -> void:
	var b := LandmarkRbParts.facing(out)
	var right := b.x
	var cols := maxi(roundi(w / 4.2), 1)
	var storey := h / float(storeys)
	var win := Vector2(2.4, storey * (0.55 if tall else 0.6))
	LandmarkDetail.pierced_face(lm, "Stone", "Windows", c - right * (w * 0.5), right, out, w, h, cols, storeys,
		win, storey * 0.22, storey, 0.4)
	var face := c + out * 0.4
	var pitch := w / float(cols)
	for i in range(0, cols + 1, 3):
		var x := -w * 0.5 + pitch * float(i)
		lm.box("Trim", face + right * x + out * 0.2 + Vector3(0, h * 0.5, 0), Vector3(1.2, h, 0.4), b, 0.0)
	for j in storeys:
		lm.box("Trim", face + out * 0.15 + Vector3(0, storey * float(j) + storey * 0.16, 0), Vector3(w, 0.35, 0.3), b, 0.0)
	# Pediment heads on the main floors of the lowest tier.
	if tall:
		for i in cols:
			var x := -w * 0.5 + pitch * (float(i) + 0.5)
			for j in [1, 2]:
				var top_y := storey * float(j) + storey * 0.22 + win.y
				lm.box("Trim", face + right * x + out * 0.2 + Vector3(0, top_y + 0.2, 0), Vector3(win.x + 0.8, 0.3, 0.4), b, 0.0)

## Four corner pavilions with hipped roofs and their links to the block.
static func _pavilions(lm: LandmarkMesh) -> void:
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var c := Vector3(sx * 123.0, 0, sz * 100.0)
			lm.box("Stone", c + Vector3(0, 25.0, 0), Vector3(29.0, 50.0, 29.0))
			lm.box("Trim", c + Vector3(0, 50.4, 0), Vector3(31.0, 1.2, 31.0))
			LandmarkCeParts.hip(lm, "Roof", c + Vector3(0, 51.0, 0), 29.0, 29.0, 9.0)
			lm.box("Stone", Vector3(sx * 111.0, 18.9, sz * 93.0), Vector3(20.0, 37.8, 20.0))
			for k in 4:
				var out := Vector3(cos(PI * 0.5 * k), 0, sin(PI * 0.5 * k))
				var right := Vector3.UP.cross(out)
				for y in [4.0, 17.0, 30.0]:
					LandmarkDetail.window(lm, "Trim", "Windows", c + out * 14.52 + Vector3(0, y + 4.5, 0), out, 3.0, 9.0,
						true, 0.35)
					for s in [-1.0, 1.0]:
						LandmarkDetail.window(lm, "Trim", "Windows", c + out * 14.52 + right * (s * 8.5) + Vector3(0, y + 4.0, 0),
							out, 2.0, 6.5, false, 0.3)
				for s in [-1.0, 1.0]:
					lm.box("Trim", c + out * 14.7 + right * (s * 13.6) + Vector3(0, 24.0, 0), Vector3(1.6, 46.0, 0.5),
						LandmarkRbParts.facing(out))

## Central front block: the arcade of eleven arches, the balcony loggia
## of twelve columns under its entablature and balustrade, and the
## stairs.
static func _front_block(lm: LandmarkMesh) -> void:
	lm.box("Stone", Vector3(0, 13.0, 93.0), Vector3(92.0, 26.0, 14.0))
	lm.box("Trim", Vector3(0, 26.4, 93.0), Vector3(94.0, 1.0, 16.0))
	var out := Vector3(0, 0, 1)
	for i in 11:
		var x := (float(i) - 5.0) * 7.6
		SEuUtil.opening(lm, "Windows", Vector3(x, 1.0, 100.05), Vector3.RIGHT, Vector3.UP, 4.6, 16.0)
		LandmarkDetail.arch(lm, "Trim", Vector3(x, 14.7, 100.0), out, 4.6, 0.9, 0.5)
		LandmarkDetail.window(lm, "Trim", "Windows", Vector3(x, 21.0, 100.02), out, 2.4, 4.0, false, 0.3)
	for i in 12:
		lm.box("Trim", Vector3((float(i) - 5.5) * 7.6, 13.0, 100.3), Vector3(3.0, 25.0, 0.6), Basis(), 0.0)
	# Balcony loggia: twelve Corinthian columns, balustrade, entablature.
	LandmarkRbParts.balustrade(lm, "Trim", Vector3(-46.0, 26.9, 100.4), Vector3(46.0, 26.9, 100.4), 1.2, 0.6, 7.6)
	lm.box("Stone", Vector3(0, 34.0, 92.0), Vector3(90.0, 14.0, 10.0))
	LandmarkDetail.pierced_face(lm, "Stone", "Windows", Vector3(-45.0, 26.9, 97.0), Vector3.RIGHT, out, 90.0, 13.0, 12, 1,
		Vector2(4.4, 9.0), 1.0, 13.0, 0.4)
	for i in 12:
		LandmarkRbParts.order_column(lm, "Trim", Vector3((float(i) - 5.5) * 7.6, 26.9, 98.8), 0.9, 12.6, "corinthian", out, 12)
	lm.box("Trim", Vector3(0, 40.8, 96.0), Vector3(94.0, 2.2, 8.4))
	LandmarkDetail.cornice(lm, "Trim", Vector3(-47.0, 41.9, 100.2), Vector3(47.0, 41.9, 100.2), out, 1.0, true)
	LandmarkRbParts.balustrade(lm, "Trim", Vector3(-46.0, 42.9, 99.6), Vector3(46.0, 42.9, 99.6), 1.2, 0.6, 7.6)
	LandmarkRbParts.steps(lm, "Plinth", Vector3(0, 0, 101.0), out, 104.0, 1.2, 0.3, 6)

## The square central tower over the hall: a colonnaded storey of
## paired columns on each face, entablature and balustrade, the
## stepped attic and the low glazed lantern (84 m).
static func _tower(lm: LandmarkMesh) -> void:
	var y0 := 66.0
	var c := Vector3(0, y0, ZC)
	lm.box("Stone", c + Vector3(0, 5.5, 0), Vector3(38.0, 11.0, 38.0))
	for k in 4:
		var out := Vector3(cos(PI * 0.5 * k), 0, sin(PI * 0.5 * k))
		var right := Vector3.UP.cross(out)
		LandmarkDetail.pierced_face(lm, "Stone", "Windows", c + out * 19.0 - right * 19.0 + Vector3(0, 0.5, 0), right, out,
			38.0, 10.2, 6, 1, Vector2(2.8, 6.6), 1.2, 10.0, 0.3)
		for i in 7:
			var x := (float(i) - 3.0) * (38.0 / 6.0)
			for s in [-0.7, 0.7]:
				LandmarkRbParts.order_column(lm, "Trim", c + out * 20.6 + right * (x + float(s)), 0.5, 10.9, "corinthian", out, 8)
		LandmarkRbParts.balustrade(lm, "Trim", c + out * 21.0 - right * 21.0 + Vector3(0, 12.3, 0),
			c + out * 21.0 + right * 21.0 + Vector3(0, 12.3, 0), 1.2, 0.8, 6.3)
	lm.box("Trim", c + Vector3(0, 11.6, 0), Vector3(43.0, 1.4, 43.0))
	lm.box("Stone", c + Vector3(0, 13.8, 0), Vector3(30.0, 3.0, 30.0))
	lm.box("Trim", c + Vector3(0, 15.5, 0), Vector3(31.0, 0.4, 31.0))
	lm.lathe("Dome", c + Vector3(0, 15.7, 0), LandmarkRbParts.dome_profile(8.0, PARL_TOP - y0 - 15.7, 6), 24)
