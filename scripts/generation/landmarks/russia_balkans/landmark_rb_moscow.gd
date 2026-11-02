class_name LandmarkRbMoscow
extends RefCounted

## Two Moscow landmarks in true metres: the Ivan the Great Bell Tower
## (three white octagonal tiers under a gilded helm, 81 m, with its
## Assumption Belfry and the five-domed Assumption Cathedral beside it)
## and the Cathedral of Christ the Saviour (white marble Greek cross
## under the great gilded dome, 103 m).

const IVAN_TOP := 81.0
const ASSUMPTION_AT := Vector3(-64.6, 0.0, -41.1)
const BELFRY_AT := Vector3(-4.4, 0.0, -26.0)

## Gilded helm dome of base radius r and height h.
static func _helm(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float, seg: int = 16) -> void:
	lm.lathe(key, base, PackedVector2Array([Vector2(r * 0.92, 0), Vector2(r, h * 0.12), Vector2(r, h * 0.3),
		Vector2(r * 0.84, h * 0.55), Vector2(r * 0.5, h * 0.8), Vector2(r * 0.18, h * 0.95), Vector2(0, h)]), seg)

## Origin at the foot of the tower. The Assumption Belfry and Filaret's
## annex run north from it and the Assumption Cathedral stands 76 m to
## the west-north-west; the built frame is turned 15 degrees (yaw) so the
## cathedral keeps its real east-west axis.
static func ivan_great(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#EFEADB", 4.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#E6E1D2", 4.0))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#9A9486", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#6F7E74", 3.0, 0.6, 0.2))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Tower: three octagonal tiers (36, 17 and 12 m), each ending in a
	# cornice ring, then the drum, helm and cross. Rows are r0, r1, y0, h
	# and the opening bottom, width and height.
	var tiers := [[9.0, 8.7, 0.0, 36.0, 17.0, 3.0, 12.0], [7.2, 6.9, 37.2, 16.8, 41.0, 3.0, 10.0],
		[5.5, 5.3, 55.0, 12.0, 58.0, 2.0, 7.0]]
	for t in tiers:
		var r0: float = t[0]
		var y0: float = t[2]
		var h: float = t[3]
		lm.frustum("Wall", Vector3(0, y0, 0), r0, float(t[1]), h, 8, PI / 8.0)
		lm.frustum("Stone", Vector3(0, y0 + h, 0), r0 + 0.8, r0 + 0.8, 1.2, 8, PI / 8.0)
		SEuUtil.ring_openings(lm, "Windows", Vector3.ZERO, r0, 8, 8, float(t[4]), float(t[5]), float(t[6]), true)
		for k in 8:
			var a := PI / 8.0 + TAU * float(k) / 8.0
			lm.box("Stone", Vector3(cos(a) * (r0 + 0.1), y0 + h * 0.5, sin(a) * (r0 + 0.1)), Vector3(0.9, h, 0.9),
				Basis(Vector3.UP, -a))
	lm.box("Plinth", Vector3(0, 0.6, 0), Vector3(25.0, 1.2, 25.0))
	for k in 4:
		var out := Vector3(cos(PI * 0.5 * k), 0, sin(PI * 0.5 * k))
		SEuUtil.opening(lm, "Windows", out * 8.4 + Vector3(0, 1.2, 0), Vector3.UP.cross(out), Vector3.UP, 3.0, 7.0)
	lm.frustum("Wall", Vector3(0, 68.2, 0), 3.9, 3.9, 4.6, 16)
	lm.frustum("Stone", Vector3(0, 72.8, 0), 4.3, 4.3, 0.6, 16)
	_helm(lm, "Gilt", Vector3(0, 73.4, 0), 4.2, 4.4)
	LandmarkRbParts.cross(lm, "Gilt", Vector3(0, 77.8, 0), IVAN_TOP - 77.8)
	_belfry(lm)
	_assumption(lm, ASSUMPTION_AT)
	lm.commit(model)

## Assumption Belfry (36 m, three arched openings a side) and Filaret's
## annex (24 m) north of the tower, turned 10 degrees off the built axes.
static func _belfry(lm: LandmarkMesh) -> void:
	var bb := Basis(Vector3.UP, -deg_to_rad(10.0))
	var parts := [["Wall", 10.5, 15.0, 34.0], ["Wall", -7.0, 20.0, 24.0]]
	for p in parts:
		var z: float = p[1]
		var d: float = p[2]
		var h: float = p[3]
		lm.box(p[0], BELFRY_AT + bb * Vector3(0, h * 0.5, z), Vector3(24.0, h, d), bb)
		lm.box("Stone", BELFRY_AT + bb * Vector3(0, h + 0.4, z), Vector3(25.0, 0.8, d + 1.0), bb)
		for sx in [-1.0, 1.0]:
			var o := BELFRY_AT + bb * Vector3(sx * 12.05, 0, z)
			var out := bb * Vector3(sx, 0, 0)
			var right := bb * Vector3(0, 0, 1)
			LandmarkRbParts.windows(lm, "Windows", o, right, out, 2.5, 2 if d < 16.0 else 3, 6.0, 2.2, h * 0.55)
	LandmarkRbParts.onion_on_drum(lm, "Wall", "Gilt", "Gilt", BELFRY_AT + bb * Vector3(0, 34.8, 10.5), 4.0, 4.0, 5.5, 2.6, 16)
	lm.gable("Roof", BELFRY_AT + bb * Vector3(0, 24.8, -7.0), 19.0, 23.0, 3.5, bb * Basis(Vector3.UP, PI * 0.5), 0.5, "Wall")

## Assumption Cathedral centred at `c` (axis east-west, altar east):
## white limestone cube 38 x 35 m, five gilded domes (38 m).
static func _assumption(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Plinth", c + Vector3(0, 0.6, 0), Vector3(39.0, 1.2, 36.0))
	lm.box("Stone", c + Vector3(0, 11.0, 0), Vector3(38.0, 22.0, 35.0))
	lm.box("Wall", c + Vector3(0, 22.4, 0), Vector3(38.8, 0.8, 35.8))
	for sz in [-1.0, 1.0]:
		var o := c + Vector3(0, 0, sz * 17.55)
		LandmarkRbParts.windows(lm, "Windows", o, Vector3.RIGHT, Vector3(0, 0, sz), 3.0, 3, 11.0, 1.4, 5.0)
		LandmarkRbParts.windows(lm, "Windows", o, Vector3.RIGHT, Vector3(0, 0, sz), 11.0, 3, 11.0, 1.4, 5.0)
		for i in 4:
			lm.box("Wall", o + Vector3((float(i) - 1.5) * 11.0, 11.0, 0.0), Vector3(1.0, 21.0, 0.5))
	LandmarkRbParts.windows(lm, "Windows", c + Vector3(-19.05, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0), 3.0, 3, 8.0, 1.4, 5.0)
	for z in [-9.0, 0.0, 9.0]:
		var r := 5.2 if z == 0.0 else 3.6
		lm.frustum("Stone", c + Vector3(19.0, 0, z), r, r, 11.0 if z == 0.0 else 9.0, 12)
		lm.lathe("Roof", c + Vector3(19.0, 11.0 if z == 0.0 else 9.0, z),
			LandmarkRbParts.dome_profile(r + 0.2, r * 0.5, 4), 12)
	LandmarkRbParts.onion_on_drum(lm, "Wall", "Gilt", "Gilt", c + Vector3(0, 22.8, 0), 4.6, 7.0, 5.6, 3.2, 16)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			LandmarkRbParts.onion_on_drum(lm, "Wall", "Gilt", "Gilt", c + Vector3(sx * 12.0, 22.8, sz * 11.0), 2.5, 4.5, 3.6, 2.4, 12)

# --- Cathedral of Christ the Saviour ---

const CHRIST_TOP := 103.0

## Origin at the dome axis. Greek cross on a 5 m podium: a 46 m central
## cube with four 26 m gabled arms, the 30 m windowed drum under the
## gilded dome, lantern and cross, and four gilded corner domes.
static func christ_saviour(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E9E5D8", 4.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#F2EFE6", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8E8B85", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#5E6D64", 3.0, 0.6, 0.25))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var y0 := 5.0
	lm.box("Granite", Vector3(0, 2.5, 0), Vector3(92.0, 5.0, 92.0))
	lm.box("Marble", Vector3(0, y0 + 18.0, 0), Vector3(46.0, 36.0, 46.0))
	lm.box("Trim", Vector3(0, y0 + 36.5, 0), Vector3(47.2, 1.0, 47.2))
	lm.box("Roof", Vector3(0, y0 + 37.2, 0), Vector3(42.0, 0.4, 42.0))
	# Four arms with gables, doors and window rows, and their stairs.
	for k in 4:
		var out := Vector3(cos(PI * 0.5 * k), 0, sin(PI * 0.5 * k))
		var b := LandmarkRbParts.facing(out)
		var right := b.x
		lm.box("Marble", out * 30.0 + Vector3(0, y0 + 14.0, 0), Vector3(26.0, 28.0, 14.0), b)
		lm.box("Trim", out * 30.0 + Vector3(0, y0 + 28.2, 0), Vector3(27.2, 0.9, 15.2), b)
		lm.gable("Roof", out * 30.0 + Vector3(0, y0 + 28.6, 0), 26.0, 14.0, 7.0, b, 0.6, "Marble")
		SEuUtil.opening(lm, "Windows", out * 37.05 + Vector3(0, y0 + 1.0, 0), right, Vector3.UP, 10.0, 18.0)
		LandmarkRbParts.windows(lm, "Windows", out * 37.0, right, out, y0 + 8.0, 2, 19.0, 2.4, 8.0)
		LandmarkRbParts.windows(lm, "Windows", out * 37.0, right, out, y0 + 19.0, 2, 19.0, 2.4, 6.0)
		LandmarkRbParts.steps(lm, "Granite", out * 46.0, out, 34.0, 0.9, 0.5, 10)
		for sgn in [-1.0, 1.0]:
			lm.box("Trim", out * 37.2 + right * sgn * 13.0 + Vector3(0, y0 + 14.0, 0), Vector3(1.4, 28.0, 0.8), b)
	# Central drum, windows, gilded dome, lantern, cross.
	var d0 := y0 + 37.7
	lm.frustum("Marble", Vector3(0, d0, 0), 17.5, 15.6, 3.0, 24)
	lm.frustum("Marble", Vector3(0, d0 + 3.0, 0), 15.6, 15.6, 19.0, 24)
	SEuUtil.ring_openings(lm, "Windows", Vector3(0, d0, 0), 15.6, 24, 12, 8.0, 2.4, 8.0, true, PI / 24.0)
	for i in 12:
		var a := TAU * float(i) / 12.0 + PI / 24.0 + PI / 12.0
		lm.box("Trim", Vector3(cos(a) * 15.7, d0 + 12.5, sin(a) * 15.7), Vector3(1.0, 19.0, 1.0), Basis(Vector3.UP, -a))
	lm.frustum("Trim", Vector3(0, d0 + 22.0, 0), 17.0, 17.0, 1.6, 24)
	var dy := d0 + 23.6
	lm.lathe("Gilt", Vector3(0, dy, 0), LandmarkRbParts.dome_profile(15.2, 17.0, 10), 32)
	var ly := dy + 17.0
	lm.frustum("Marble", Vector3(0, ly, 0), 3.6, 3.4, 6.0, 12)
	lm.frustum("Trim", Vector3(0, ly + 6.0, 0), 4.2, 4.2, 0.6, 12)
	lm.lathe("Gilt", Vector3(0, ly + 6.6, 0), LandmarkRbParts.dome_profile(3.8, 2.6, 5), 12)
	LandmarkRbParts.cross(lm, "Gilt", Vector3(0, ly + 9.2, 0), CHRIST_TOP - (ly + 9.2))
	# Corner towers with their gilded domes.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var c := Vector3(sx * 21.0, y0 + 36.8, sz * 21.0)
			lm.box("Marble", c + Vector3(0, 3.0, 0), Vector3(11.0, 6.0, 11.0))
			lm.frustum("Marble", c + Vector3(0, 6.0, 0), 4.4, 4.4, 10.0, 16)
			lm.frustum("Trim", c + Vector3(0, 16.0, 0), 4.9, 4.9, 0.6, 16)
			_helm(lm, "Gilt", c + Vector3(0, 16.6, 0), 4.7, 9.5)
			LandmarkRbParts.cross(lm, "Gilt", c + Vector3(0, 26.1, 0), 5.0)
	lm.commit(model)
