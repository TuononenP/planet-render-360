class_name LandmarkCsMajorAsia
extends RefCounted

## Capital stations of Asia's large cities without a terminus in
## LandmarkCsAsia, in the station frame (+X along the main facade, +Z the
## forecourt): Jakarta Kota, Dhaka's Kamalapur, Hanoi, Pyongyang,
## Tashkent, Baku and Baghdad Central.

const K = preload("res://scripts/generation/landmarks/capital_stations/landmark_station_kit.gd")

## Jakarta Kota (Frans Ghijsels, 1929): the white Art Deco front with its
## great round-arched glazed hall gable between two flat-topped pavilions
## banded in grey, low two-storey wings, a deep canopy over the doors and
## the steel platform hall behind.
static func jakarta_kota(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#EDEBE4", "#E4E1D8", "sheet_metal", "#8A9096")
	# The main hall: a barrel vault along Z ending in the glazed lunette.
	lm.box("Walls", Vector3(0, 7.0, 24.0), Vector3(28.0, 14.0, 34.0))
	LandmarkFhHelsinkiCity._barrel(lm, "Roof", Vector3(0, 14.0, 41.2), Vector3(0, 14.0, 7.0), 14.6, 9.0)
	K.lunette(lm, "Trim", "Glass", Vector3(0, 14.0, 41.25), Vector3.BACK, 26.0, 8.6, 12, 9)
	lm.box("Glass", Vector3(0, 10.0, 41.15), Vector3(24.0, 8.0, 0.2))
	LandmarkFhParts.strips(lm, "Trim", Vector3(-12.0, 0, 41.1), Vector3(12.0, 0, 41.1), Vector3.BACK, 6.0, 8.0, 9,
		0.35, 0.3)
	# The arch's thick frame band round the lunette.
	var prev := Vector3.ZERO
	for k in 13:
		var t := PI * float(k) / 12.0
		var p := Vector3(cos(t) * 14.3, 14.0 + sin(t) * 9.0, 41.6)
		if k > 0:
			lm.beam("Trim", prev, p, 1.4, 1.0)
		prev = p
	for s in [-1.0, 1.0]:
		lm.box("Trim", Vector3(s * 14.3, 7.0, 41.6), Vector3(1.4, 14.0, 1.0))
		# The flanking pavilions, banded in grey under the parapet.
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 21.5, 35.0, 13.0, 14.0, 0.0, 17.0, "flat", 0.0, 3.2, 4.2)
		lm.box("Steel", Vector3(s * 21.5, 14.8, 35.0), Vector3(13.6, 1.0, 14.6))
		# The wings.
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 64.0, 30.0, 72.0, 18.0, 0.0, 10.0, "flat", 0.0, 4.0, 4.5)
	K.canopy(lm, "Steel", "Steel", Vector3(-28.0, 0, 42.0), Vector3(28.0, 0, 42.0), Vector3.BACK, 5.0, 5.0, 2)
	# The platform hall behind, its steel arch across the tracks.
	K.shed(lm, "Roof", "Steel", "Glass", Vector3(0, 0, 6.0), Vector3.FORWARD, 96.0, 58.0, 7.0, 11.0, 8.0, 0.3, 0)
	lm.commit(model)

## Kamalapur (Robert Boughey and Daniel Dunham, 1968): a field of white
## concrete umbrella shells, each a shallow inverted vault on its own
## column, scalloped at the edges, roofing an open glazed concourse.
static func kamalapur(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "concrete", "#E9E6DE", "#EDEBE5", "concrete", "#EDEBE5")
	lm.use("Curtain", LandmarkMaterials.pbr("render", "#8FA3AE", 6.0, 0.2, 0.3))
	# The OSM outline maps the hall with its long platform roofs; the hall
	# stands at its west end, so the model's origin is the outline's centre.
	var o := Vector3(-162.0, 0, -18.0)
	lm.box("Curtain", o + Vector3(0, 3.5, 0), Vector3(84.0, 7.0, 72.0))
	lm.box("Trim", o + Vector3(0, 0.4, 0), Vector3(84.6, 0.8, 72.6))
	lm.box("Trim", o + Vector3(0, 7.2, 0), Vector3(84.6, 0.4, 72.6))
	var size := 16.0
	for i in 6:
		for j in 6:
			var c := o + Vector3(-48.0 + size * (float(i) + 0.5), 0, -48.0 + size * (float(j) + 0.5))
			_umbrella(lm, c, size, 17.0)
	lm.commit(model)

## One umbrella shell `size` square on its stem at ground point `c`: four
## warped quarters rising from the stem head to scalloped edges whose
## midpoints stand at `tip` and corners dip 2.5 m (the arched rim).
static func _umbrella(lm: LandmarkMesh, c: Vector3, size: float, tip: float) -> void:
	var low := tip - 4.0
	var head := c + Vector3.UP * low
	var corners := [Vector3(-1, 0, -1), Vector3(1, 0, -1), Vector3(1, 0, 1), Vector3(-1, 0, 1)]
	for k in 4:
		var a: Vector3 = corners[k] * size * 0.5 + Vector3.UP * (tip - 2.5)
		var b: Vector3 = corners[(k + 1) % 4] * size * 0.5 + Vector3.UP * (tip - 2.5)
		var m := (a + b) * 0.5
		m.y = tip
		for q in [[a, m], [m, b]]:
			var p0: Vector3 = c + q[0]
			var p1: Vector3 = c + q[1]
			lm.tri("Roof", head, p0, p1, Vector3.UP, Vector3.UP, Vector3.UP, Vector2.ZERO, Vector2(1, 0), Vector2(0, 1))
			lm.tri("Roof", head, p1, p0, Vector3.DOWN, Vector3.DOWN, Vector3.DOWN, Vector2.ZERO, Vector2(1, 0),
				Vector2(0, 1))
	lm.frustum("Trim", c, 0.6, 1.3, low, 10)

## Hanoi station: the rebuilt 1976 central hall, a white block with a
## fine square grid of windows under a thick overhanging slab roof,
## between the surviving yellow French colonial wings of 1902 with their
## white trim, arched ground floor and parapets.
static func hanoi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#E8C46A", "#F2EEE4", "concrete", "#B8B2A6")
	lm.use("White", LandmarkMaterials.pbr("render", "#F1F0EC", 3.0))
	lm.box("White", Vector3(0, 11.0, 0), Vector3(44.0, 22.0, 24.0))
	lm.box("White", Vector3(0, 23.0, 1.0), Vector3(50.0, 2.0, 30.0))
	LandmarkFhUtil.window_grid(lm, "Glass", Vector3(-19.0, 0, 12.0), Vector3(19.0, 0, 12.0), Vector3.BACK, 7.0, 7,
		2.0, 16, 1.4, 1.4, 0.1)
	lm.box("Glass", Vector3(0, 2.8, 12.1), Vector3(30.0, 5.6, 0.2))
	K.canopy(lm, "White", "Steel", Vector3(-22.0, 0, 12.0), Vector3(22.0, 0, 12.0), Vector3.BACK, 4.0, 5.8, 4)
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 81.0, -1.0, 118.0, 22.0, 0.0, 11.0, "flat", 0.0, 4.0, 4.6, true)
		LandmarkFhParts.box_band(lm, "Trim", s * 81.0, -1.0, 118.0, 22.0, 5.4, 0.5, 0.2)
		# The pavilions at the wing ends, a storey higher.
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 128.0, 0.0, 20.0, 25.0, 0.0, 15.0, "hip", 2.5, 4.0, 4.6, true)
	lm.commit(model)

## Pyongyang station (1957): the cream classical front with giant
## colonnades along both wings, the arched central entrance block and the
## clock tower over it, a square base with clocks, an octagonal drum, a
## small dome and spire with its star.
static func pyongyang(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "stone", "#DCCFAE", "#EAE2CC", "concrete", "#B9B1A0")
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 36.0, -2.0, 46.0, 28.0, 0.0, 16.0, "flat", 0.0, 4.0, 5.0)
		var a := Vector3(s * 14.0, 0, 15.0)
		var b := Vector3(s * 58.0, 0, 15.0)
		LandmarkFhUtil.columns(lm, "Trim", a, b, 11, 13.5, 0.75)
		lm.box("Trim", Vector3(s * 36.0, 14.3, 13.5), Vector3(46.0, 1.6, 4.0))
		lm.box("Roof", Vector3(s * 36.0, 15.2, 13.5), Vector3(46.0, 0.2, 4.0))
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 1.0, 26.0, 30.0, 0.0, 18.0, "flat", 0.0, 4.0, 5.0)
	K.arch_window(lm, "Trim", "Glass", Vector3(0, 0.2, 16.05), Vector3.BACK, 9.0, 13.0, 5)
	# The tower: square base with clocks, octagonal drum, dome, spire, star.
	var t := Vector3(0, 18.0, 1.0)
	lm.box("Walls", t + Vector3.UP * 4.5, Vector3(12.0, 9.0, 12.0))
	lm.box("Trim", t + Vector3.UP * 8.8, Vector3(12.8, 0.8, 12.8))
	for i in 4:
		var n := Vector3(sin(PI * 0.5 * float(i)), 0, cos(PI * 0.5 * float(i)))
		K.clock(lm, "Dial", "Trim", t + n * 6.05 + Vector3.UP * 5.0, n, 2.2)
	lm.lathe("Walls", t + Vector3.UP * 9.2, PackedVector2Array([Vector2(4.6, 0.0), Vector2(4.6, 7.0)]), 8, 1.0, 1.0,
		PI / 8.0, false)
	lm.lathe("Trim", t + Vector3.UP * 16.2, PackedVector2Array([Vector2(5.2, 0.0), Vector2(5.2, 0.8)]), 8, 1.0, 1.0,
		PI / 8.0, false)
	lm.lathe("Roof", t + Vector3.UP * 17.0, LandmarkFhUtil.dome_prof(4.0, 4.0), 16)
	lm.frustum("Gilt", t + Vector3.UP * 20.8, 0.5, 0.1, 6.0, 8)
	lm.box("Gilt", t + Vector3.UP * 27.4, Vector3(1.6, 1.6, 0.3))
	lm.commit(model)

## Tashkent station (rebuilt 2011): the long white front of cream
## pilasters framing tall deep-blue arched glazing, and the taller central
## portal block whose great arch frames the blue-glazed entrance.
static func tashkent(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "limestone", "#EEEBE2", "#E3DCC8", "concrete", "#7A8794")
	lm.use("Blue", LandmarkMaterials.glass("#2C4E9C"))
	for s in [-1.0, 1.0]:
		var x0: float = s * 30.0
		var x1: float = s * 160.0
		lm.box("Walls", Vector3((x0 + x1) * 0.5, 10.0, -4.0), Vector3(130.0, 20.0, 34.0))
		lm.box("Trim", Vector3((x0 + x1) * 0.5, 19.6, -4.0), Vector3(130.7, 0.8, 34.7))
		lm.box("Roof", Vector3((x0 + x1) * 0.5, 20.05, -4.0), Vector3(130.0, 0.1, 34.0))
		K.arch_row(lm, "Trim", "Blue", Vector3(x0, 0, 13.05), Vector3(x1, 0, 13.05), Vector3.BACK, 0.6, 20, 4.6, 17.0, 3)
		K.arch_row(lm, "Trim", "Glass", Vector3(x0, 0, -21.05), Vector3(x1, 0, -21.05), Vector3.FORWARD, 1.0, 20, 3.0, 12.0, 1)
		LandmarkFhParts.strips(lm, "Trim", Vector3(x0, 0, 13.0), Vector3(x1, 0, 13.0), Vector3.BACK, 0.0, 19.2, 21,
			1.0, 0.5)
	# The central portal block and its great arch.
	lm.box("Walls", Vector3(0, 14.0, -2.0), Vector3(60.0, 28.0, 40.0))
	lm.box("Trim", Vector3(0, 27.6, -2.0), Vector3(60.8, 0.8, 40.8))
	lm.box("Roof", Vector3(0, 28.05, -2.0), Vector3(60.0, 0.1, 40.0))
	K.arch_window(lm, "Trim", "Blue", Vector3(0, 0.2, 18.05), Vector3.BACK, 16.0, 23.0, 7)
	for s in [-1.0, 1.0]:
		K.arch_window(lm, "Trim", "Blue", Vector3(s * 19.0, 0.2, 18.05), Vector3.BACK, 7.0, 14.0, 3)
		lm.box("Blue", Vector3(s * 19.0, 19.0, 18.1), Vector3(7.0, 3.0, 0.2))
	lm.box("Trim", Vector3(0, 25.0, 18.3), Vector3(30.0, 3.0, 0.6))
	lm.commit(model)

## Baku station (1926, Moorish revival): the cream stone range with its
## crenellated parapets, round-arched windows, raised corner and middle
## pavilions, the great central arch with a round window over it, and the
## low dome behind.
static func baku(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "limestone", "#E3D3AA", "#EFE5C9", "concrete", "#C8BC9E")
	lm.box("Walls", Vector3(0, 6.5, -2.0), Vector3(130.0, 13.0, 30.0))
	lm.box("Trim", Vector3(0, 12.6, -2.0), Vector3(130.7, 0.8, 30.7))
	lm.box("Roof", Vector3(0, 13.05, -2.0), Vector3(130.0, 0.1, 30.0))
	K.arch_row(lm, "Trim", "Glass", Vector3(-62.0, 0, 13.05), Vector3(62.0, 0, 13.05), Vector3.BACK, 1.0, 22, 3.0, 8.0, 1)
	LandmarkFhUtil.window_grid(lm, "Glass", Vector3(-62.0, 0, 13.0), Vector3(62.0, 0, 13.0), Vector3.BACK, 9.5, 1, 3.0,
		22, 1.6, 2.2)
	LandmarkFhUtil.merlons(lm, "Trim", Vector3(-65.0, 13.0, 13.3), Vector3(65.0, 13.0, 13.3), 2.0, 1.0, 1.2, 0.5)
	for x in [-58.0, 0.0, 58.0]:
		var w := 30.0 if x == 0.0 else 18.0
		var ph := 17.0 if x == 0.0 else 21.0
		lm.box("Walls", Vector3(x, ph * 0.5, 0.0), Vector3(w, ph, 32.0))
		lm.box("Trim", Vector3(x, ph - 0.4, 0.0), Vector3(w + 0.7, 0.8, 32.7))
		lm.box("Roof", Vector3(x, ph + 0.05, 0.0), Vector3(w, 0.1, 32.0))
		LandmarkFhUtil.merlons(lm, "Trim", Vector3(x - w * 0.5, ph, 16.3), Vector3(x + w * 0.5, ph, 16.3), 2.0, 1.0,
			1.2, 0.5)
		if x != 0.0:
			LandmarkFhUtil.window_grid(lm, "Glass", Vector3(x - 6.0, 0, 16.05), Vector3(x + 6.0, 0, 16.05), Vector3.BACK,
				13.5, 2, 3.6, 3, 1.6, 2.4)
		for s in [-1.0, 1.0]:
			lm.box("Trim", Vector3(x + s * (w * 0.5 - 0.6), ph * 0.5, 16.2), Vector3(1.2, ph, 0.6))
	K.arch_window(lm, "Trim", "Glass", Vector3(0, 0.2, 16.05), Vector3.BACK, 9.0, 11.5, 5)
	lm.disc("Trim", Vector3(0, 14.2, 16.1), Vector3.BACK, 2.2, 20)
	lm.disc("Glass", Vector3(0, 14.2, 16.2), Vector3.BACK, 1.7, 20)
	lm.lathe("Roof", Vector3(0, 17.0, -6.0), LandmarkFhUtil.dome_prof(9.0, 4.5), 20)
	lm.commit(model)

## Baghdad Central (J. M. Wilson, 1953): the buff brick range with its
## tall white-columned portico, the green copper dome on its drum behind,
## and the two tall square brick clock towers with flat crowns either side.
static func baghdad(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "brick", "#C89A5E", "#EDE5D2", "concrete", "#B3A58C")
	lm.use("Copper", LandmarkMaterials.pbr("copper", "#7FA88A", 2.0))
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 50.0, -4.0, 56.0, 36.0, 0.0, 16.0, "flat", 0.0, 4.0, 5.0)
		# The clock towers.
		var t := Vector3(s * 27.0, 0, 15.0)
		lm.box("Walls", t + Vector3.UP * 20.0, Vector3(7.0, 40.0, 7.0))
		lm.box("Trim", t + Vector3.UP * 33.0, Vector3(7.8, 0.8, 7.8))
		lm.box("Walls", t + Vector3.UP * 41.5, Vector3(6.0, 3.0, 6.0))
		lm.box("Trim", t + Vector3.UP * 43.3, Vector3(6.6, 0.6, 6.6))
		for i in 4:
			var n := Vector3(sin(PI * 0.5 * float(i)), 0, cos(PI * 0.5 * float(i)))
			K.clock(lm, "Dial", "Trim", t + n * 3.55 + Vector3.UP * 36.5, n, 2.0)
		LandmarkFhUtil.openings(lm, "Glass", t + Vector3(-1.5, 0, 3.55), t + Vector3(1.5, 0, 3.55), Vector3.BACK, 10.0,
			2, 0.8, 18.0, false)
	# The central hall and its portico.
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 46.0, 40.0, 0.0, 18.0, "flat", 0.0, 4.0, 5.0)
	LandmarkFhUtil.columns(lm, "Trim", Vector3(-19.0, 0, 22.5), Vector3(19.0, 0, 22.5), 10, 14.0, 0.8)
	lm.box("Trim", Vector3(0, 15.0, 21.5), Vector3(42.0, 2.0, 4.0))
	lm.box("Roof", Vector3(0, 16.1, 21.5), Vector3(42.0, 0.2, 4.0))
	lm.box("Glass", Vector3(0, 7.0, 20.1), Vector3(36.0, 14.0, 0.2))
	var c := Vector3(0, 18.0, -2.0)
	lm.lathe("Walls", c, PackedVector2Array([Vector2(12.0, 0.0), Vector2(12.0, 4.0)]), 24)
	lm.lathe("Trim", c + Vector3.UP * 4.0, PackedVector2Array([Vector2(12.6, 0.0), Vector2(12.6, 0.6)]), 24)
	lm.lathe("Copper", c + Vector3.UP * 4.6, LandmarkFhUtil.dome_prof(12.4, 15.0), 24)
	lm.commit(model)
