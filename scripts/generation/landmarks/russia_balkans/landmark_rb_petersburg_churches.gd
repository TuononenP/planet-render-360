class_name LandmarkRbPetersburgChurches
extends RefCounted

## Two Saint Petersburg churches in true metres: the Peter and Paul
## Cathedral (Trezzini, 1712-1733: a 61 x 27.5 m cream Petrine Baroque
## hall with its stepped bell tower, the gilded spire and the angel,
## 122.5 m) and the Church of the Saviour on Spilled Blood (Parland,
## 1883-1907: red-brick Muscovite revival with nine domes, the tented
## central tower 81 m).

const PP_TOP := 122.5
const PP_EAVE := 17.0
const PP_TX := -19.0

## Origin near the hall centre; the bell tower stands in the west end
## (-X), the apse at the east end (+X); the long walls face north and
## south. 62 m from the west portico to the apse, 27.5 m wide.
static func peter_paul(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E4D5A4", 4.0))
	lm.use("White", LandmarkMaterials.pbr("render", "#F1EDE0", 3.0))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#8A8478", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#5F8E78", 3.0, 0.55, 0.3))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Hall (eaves 17 m) on its plinth, the moulded cornice, the nave roof
	# east of the tower and the apse.
	lm.box("Plinth", Vector3(-1.0, 0.6, 0), Vector3(51.0, 1.2, 28.5))
	lm.box("Wall", Vector3(-1.0, PP_EAVE * 0.5, 0), Vector3(50.0, PP_EAVE, 27.5))
	lm.box("White", Vector3(-1.0, PP_EAVE - 0.9, 0), Vector3(50.4, 1.0, 27.9))
	for sz in [-1.0, 1.0]:
		LandmarkDetail.cornice(lm, "White", Vector3(-26.2, PP_EAVE - 0.4, sz * 13.95),
			Vector3(24.2, PP_EAVE - 0.4, sz * 13.95), Vector3(0, 0, sz), 0.9, true)
	lm.gable("Roof", Vector3(6.75, PP_EAVE, 0), 27.5, 34.5, 7.0, Basis(Vector3.UP, PI * 0.5), 0.7, "Wall")
	lm.frustum("Wall", Vector3(24.0, 0, 0), 8.5, 8.5, 14.0, 16, 0.0, 0.9, 1.0)
	lm.frustum("White", Vector3(24.0, 14.0, 0), 9.0, 9.0, 0.8, 16, 0.0, 0.9, 1.0)
	lm.lathe("Roof", Vector3(24.0, 14.8, 0), PackedVector2Array([Vector2(8.9, 0), Vector2(5.5, 3.6),
		Vector2(0.0, 6.5)]), 16, 0.9, 1.0, 0.0, false)
	for k in 3:
		var a := (float(k) - 1.0) * 0.6
		var d := Vector3(cos(a) * 0.9, 0, sin(a)).normalized()
		LandmarkDetail.window(lm, "White", "Windows", Vector3(24.0, 6.5, 0) + Vector3(cos(a) * 7.7, 0, sin(a) * 8.5),
			d, 1.8, 5.0, true)
	# Long walls: nine bays of pilasters and two tiers of arched windows
	# with cherub-mask keystones.
	var pitch := 50.0 / 9.0
	for sz in [-1.0, 1.0]:
		var out := Vector3(0, 0, sz)
		for i in 10:
			var x := -26.0 + pitch * float(i)
			LandmarkRbParts.pilaster(lm, "White", Vector3(x, 1.2, sz * 13.75), out, 1.0, PP_EAVE - 2.6, 0.3)
		for i in 9:
			var x := -26.0 + pitch * (float(i) + 0.5)
			LandmarkDetail.window(lm, "White", "Windows", Vector3(x, 5.6, sz * 13.75), out, 2.0, 5.2, true)
			LandmarkDetail.window(lm, "White", "Windows", Vector3(x, 12.2, sz * 13.75), out, 1.9, 4.2, true)
	_pp_altar_dome(lm, Vector3(13.0, PP_EAVE + 4.0, 0))
	_pp_tower(lm)
	lm.commit(model)

## The cupola over the altar: drum with pilasters and windows,
## entablature, gilded dome, lantern and needle spire.
static func _pp_altar_dome(lm: LandmarkMesh, cu: Vector3) -> void:
	lm.box("Wall", cu + Vector3(0, 0.5, 0), Vector3(8.4, 4.0, 8.4))
	var db := cu + Vector3(0, 2.5, 0)
	lm.frustum("Wall", db, 3.5, 3.5, 5.0, 16)
	for i in 8:
		var a := TAU * float(i) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("White", db + d * 3.55 + Vector3(0, 2.5, 0), Vector3(0.5, 5.0, 0.3), Basis.looking_at(d))
		var wa := a + PI / 8.0
		LandmarkDetail.window(lm, "White", "Windows", db + Vector3(cos(wa), 0, sin(wa)) * 3.45 + Vector3(0, 2.4, 0),
			Vector3(cos(wa), 0, sin(wa)), 1.0, 2.8, true, 0.15)
	lm.frustum("White", db + Vector3(0, 5.0, 0), 3.9, 3.9, 0.6, 16)
	lm.lathe("Gilt", db + Vector3(0, 5.6, 0), LandmarkRbParts.dome_profile(3.7, 3.4, 6), 16)
	lm.frustum("Gilt", db + Vector3(0, 9.0, 0), 0.9, 0.8, 1.6, 8)
	lm.spire("Gilt", db + Vector3(0, 10.6, 0), 0.5, 7.0, 0.0, 8)

## The bell tower in the west front: the lowest stage with the portico,
## the second with the great volutes and the clock dials, the belfry,
## the gilded octagonal roof with four round lucarnes, the drum, the
## crown, the 40 m spire, ball, angel (3.2 m) and the 6.5 m cross.
static func _pp_tower(lm: LandmarkMesh) -> void:
	var cx := PP_TX
	lm.box("Wall", Vector3(cx, 12.0, 0), Vector3(17.0, 24.0, 18.0))
	lm.box("White", Vector3(cx, 24.4, 0), Vector3(18.0, 0.9, 19.0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("White", Vector3(cx + sx * 8.3, 12.0, sz * 8.8), Vector3(1.2, 23.0, 1.2))
	# West portico: four columns, entablature, pediment, west door.
	var wf := cx - 8.5
	for i in 4:
		var z := (float(i) - 1.5) * 2.8
		LandmarkRbParts.order_column(lm, "White", Vector3(wf - 2.6, 1.2, z), 0.45, 8.0, "tuscan", Vector3(-1, 0, 0), 10)
	lm.box("White", Vector3(wf - 1.6, 9.8, 0), Vector3(3.6, 1.2, 10.4))
	lm.gable("Wall", Vector3(wf - 1.6, 10.4, 0), 10.4, 3.6, 2.6, Basis(Vector3.UP, PI * 0.5), 0.3, "White")
	lm.box("Plinth", Vector3(wf - 1.8, 0.6, 0), Vector3(3.6, 1.2, 11.0))
	LandmarkDetail.window(lm, "White", "Windows", Vector3(wf - 0.02, 5.6, 0), Vector3(-1, 0, 0), 3.0, 7.0, true)
	for i in 6:
		for sz in [-1.0, 1.0]:
			lm.box("White", Vector3(wf - 0.15, 12.0, sz * (6.2 + float(i % 3) * 0.9)), Vector3(0.3, 22.0, 0.6))
	for sz in [-1.0, 1.0]:
		LandmarkDetail.window(lm, "White", "Windows", Vector3(cx, 6.0, sz * 9.0), Vector3(0, 0, sz), 2.2, 6.0, true)
		LandmarkDetail.window(lm, "White", "Windows", Vector3(cx, 16.5, sz * 9.0), Vector3(0, 0, sz), 2.0, 4.8, true)
	LandmarkDetail.window(lm, "White", "Windows", Vector3(wf, 17.5, 0), Vector3(-1, 0, 0), 2.2, 4.8, true)
	# Second stage with clock dials, the great volutes against it.
	lm.box("Wall", Vector3(cx, 31.5, 0), Vector3(12.0, 14.0, 12.0))
	lm.box("White", Vector3(cx, 38.8, 0), Vector3(13.0, 0.8, 13.0))
	for k in 4:
		var out := Vector3(cos(PI * 0.5 * k), 0, sin(PI * 0.5 * k))
		lm.disc("White", Vector3(cx, 32.5, 0) + out * 6.05, out, 2.4, 24)
		lm.disc("Windows", Vector3(cx, 32.5, 0) + out * 6.1, out, 2.0, 24)
		for i in 12:
			var a := TAU * float(i) / 12.0
			var right := Vector3.UP.cross(out)
			lm.box("Gilt", Vector3(cx, 32.5, 0) + out * 6.15 + right * cos(a) * 1.75 + Vector3(0, sin(a) * 1.75, 0),
				Vector3(0.18, 0.18, 0.06), LandmarkRbParts.facing(out), 0.0)
		for sgn in [-1.0, 1.0]:
			var right := Vector3.UP.cross(out)
			lm.box("White", Vector3(cx, 31.5, 0) + out * 6.1 + right * sgn * 5.5, Vector3(0.8, 13.2, 0.3),
				LandmarkRbParts.facing(out))
	# The two pairs of volutes flanking the west front: the lower pair
	# against the second stage, the upper (later) pair against the belfry.
	for sz in [-1.0, 1.0]:
		_volute(lm, Vector3(cx - 5.2, 37.8, sz * 6.0), Vector3(0, 0, sz), 2.8, 12.6, 1.4)
		_volute(lm, Vector3(cx - 4.0, 51.5, sz * 4.7), Vector3(0, 0, sz), 1.6, 12.2, 1.2)
	# Belfry: arched openings between pilasters, two a side.
	lm.box("Wall", Vector3(cx, 46.0, 0), Vector3(9.4, 14.0, 9.4))
	for k in 4:
		var out := Vector3(cos(PI * 0.5 * k), 0, sin(PI * 0.5 * k))
		var right := Vector3.UP.cross(out)
		for sgn in [-1.0, 1.0]:
			SEuUtil.opening(lm, "Windows", Vector3(cx, 41.0, 0) + out * 4.75 + right * sgn * 2.0, right, Vector3.UP, 1.8, 7.5)
			LandmarkDetail.arch(lm, "White", Vector3(cx, 47.6, 0) + out * 4.7 + right * sgn * 2.0, out, 1.8, 0.35, 0.25)
		for t in [-1.0, 0.0, 1.0]:
			lm.box("White", Vector3(cx, 46.0, 0) + out * 4.8 + right * t * 4.1, Vector3(0.7, 13.0, 0.3), LandmarkRbParts.facing(out))
	lm.box("White", Vector3(cx, 53.4, 0), Vector3(10.6, 0.8, 10.6))
	# Gilded octagonal roof (four round lucarnes), drum, crown.
	var r0 := Vector3(cx, 53.8, 0)
	lm.lathe("Gilt", r0, PackedVector2Array([Vector2(5.3, 0), Vector2(5.0, 1.2), Vector2(4.2, 3.6),
		Vector2(3.4, 5.6), Vector2(3.2, 6.7)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 4:
		var out := Vector3(cos(PI * 0.5 * k), 0, sin(PI * 0.5 * k))
		lm.frustum("White", r0 + out * 4.3 + Vector3(0, 1.6, 0), 1.0, 1.0, 1.8, 8)
		lm.disc("White", r0 + out * 5.0 + Vector3(0, 3.0, 0), out, 1.0, 16)
		lm.disc("Windows", r0 + out * 5.05 + Vector3(0, 3.0, 0), out, 0.7, 16)
	var dr := r0 + Vector3(0, 6.7, 0)
	lm.frustum("Wall", dr, 3.0, 3.0, 4.0, 8, PI / 8.0)
	SEuUtil.ring_openings(lm, "Windows", dr, 3.0, 8, 8, 0.6, 0.6, 2.8, false, 0.0)
	lm.frustum("White", dr + Vector3(0, 4.0, 0), 3.3, 3.3, 0.5, 8, PI / 8.0)
	var cr := dr + Vector3(0, 4.5, 0)
	lm.lathe("Gilt", cr, PackedVector2Array([Vector2(3.1, 0), Vector2(3.3, 1.2), Vector2(2.9, 2.8),
		Vector2(1.8, 4.4), Vector2(1.4, 5.0), Vector2(1.7, 5.5), Vector2(1.5, 6.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	# The 40 m spire from 71 m, ball, angel and cross.
	var s0 := Vector3(cx, 71.0, 0)
	lm.lathe("Gilt", s0, PackedVector2Array([Vector2(1.5, 0), Vector2(1.25, 8.0), Vector2(0.95, 18.0),
		Vector2(0.65, 28.0), Vector2(0.38, 36.0), Vector2(0.25, 40.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 3:
		lm.frustum("Gilt", s0 + Vector3(0, 10.0 + k * 10.0, 0), 1.25 - k * 0.3, 1.2 - k * 0.3, 0.4, 8, PI / 8.0)
	var ball := s0 + Vector3(0, 40.0, 0)
	var sphere := PackedVector2Array()
	for i in 9:
		var a := PI * float(i) / 8.0
		sphere.append(Vector2(0.8 * sin(a), 0.8 - 0.8 * cos(a)))
	lm.lathe("Gilt", ball, sphere, 12)
	var ab := ball + Vector3(0, 1.6, 0)
	LandmarkKits.statue_figure(lm, "Gilt", ab, 3.2)
	# Wings 3.8 m tip to tip, swept back.
	for sgn in [-1.0, 1.0]:
		var sh := ab + Vector3(0, 2.4, -0.3)
		lm.tri("Gilt", sh, sh + Vector3(0, 0.9, sgn * 1.9), sh + Vector3(0, -1.3, sgn * 1.2) + Vector3(-0.3, 0, 0),
			Vector3(1, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 0), Vector2.ZERO, Vector2(1.9, 0.9), Vector2(1.2, -1.3))
		lm.tri("Gilt", sh, sh + Vector3(0, 0.9, sgn * 1.9), sh + Vector3(0, -1.3, sgn * 1.2) + Vector3(-0.3, 0, 0),
			Vector3(-1, 0, 0), Vector3(-1, 0, 0), Vector3(-1, 0, 0), Vector2.ZERO, Vector2(1.9, 0.9), Vector2(1.2, -1.3))
	LandmarkRbParts.cross(lm, "Gilt", ab + Vector3(0.4, 3.2, 0), PP_TOP - (ab.y + 3.2))

## Baroque scroll volute against a tower stage: a quarter-ellipse slab
## `w` thick sweeping from `top` (against the wall) out `run` along
## `out` and down `h`, its edge band and the curl at the foot.
static func _volute(lm: LandmarkMesh, top: Vector3, out: Vector3, run: float, h: float, w: float) -> void:
	var right := Vector3.UP.cross(out)
	var n := 8
	var pts: Array[Vector3] = []
	for i in n + 1:
		var t := PI * 0.5 * float(i) / float(n)
		pts.append(top + out * (run * sin(t)) - Vector3(0, h * (1.0 - cos(t)), 0))
	var foot := top - Vector3(0, h, 0)
	for side in [-1.0, 1.0]:
		var off: Vector3 = right * (w * 0.5 * float(side))
		for i in n:
			lm.tri("White", foot + off, pts[i] + off, pts[i + 1] + off, right * float(side), right * float(side),
				right * float(side), Vector2.ZERO, Vector2(1, 0), Vector2(0, 1))
	for i in n:
		lm.beam("White", pts[i], pts[i + 1], w + 0.3, 0.6, right)
	for side in [-1.0, 1.0]:
		lm.disc("White", pts[n] + right * ((w * 0.5 + 0.16) * float(side)) + Vector3(0, 0.6, 0) - out * 0.4,
			right * float(side), 0.9, 12)

# --- Church of the Saviour on Spilled Blood ---

const SOB_TOP := 81.0
const SOB_CX := 1.0

## Origin at the footprint centre; the three apses face +X (the real
## axis runs 102 degrees clockwise from north), the bell tower over the
## canal-side site of the assassination the opposite way (-X).
static func savior_on_blood(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A9503E", 4.0))
	lm.use("White", LandmarkMaterials.pbr("render", "#EFE9DA", 3.0))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#7E7468", 3.0))
	lm.use("Tent", LandmarkMaterials.pbr("terracotta", "#2E8E86", 2.5, 0.45, 0.2))
	lm.use("Blue", LandmarkMaterials.pbr("concrete", "#2F5FA8", 2.0, 0.4, 0.3))
	lm.use("Green", LandmarkMaterials.pbr("concrete", "#2F9460", 2.0, 0.4, 0.3))
	lm.use("Mosaic", LandmarkMaterials.pbr("concrete", "#B89A5E", 2.0, 0.45, 0.35))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# The cubic block on its granite plinth, white cornice.
	lm.box("Plinth", Vector3(SOB_CX, 1.0, 0), Vector3(37.0, 2.0, 30.0))
	lm.box("Brick", Vector3(SOB_CX, 11.0, 0), Vector3(36.0, 20.0, 29.0))
	lm.box("White", Vector3(SOB_CX, 21.0, 0), Vector3(36.8, 0.9, 29.8))
	lm.box("White", Vector3(SOB_CX, 2.4, 0), Vector3(36.4, 0.8, 29.4))
	for sz in [-1.0, 1.0]:
		var out := Vector3(0, 0, sz)
		var face: float = sz * 14.5
		# Two tiers of arched windows in white surrounds, pilaster strips.
		for i in 6:
			var x := SOB_CX + (float(i) - 2.5) * 5.4
			LandmarkDetail.window(lm, "White", "Windows", Vector3(x, 7.0, face), out, 2.0, 5.2, true)
			LandmarkDetail.window(lm, "White", "Windows", Vector3(x, 15.0, face), out, 1.8, 4.4, true)
		for i in 7:
			lm.box("White", Vector3(SOB_CX + (float(i) - 3.0) * 5.4, 11.0, face + sz * 0.15), Vector3(0.6, 18.0, 0.3))
		# Kokoshnik gables with mosaic tympana along the roof edge: the
		# tall central one over each arm, two lower ones beside it.
		for k in [-1.0, 0.0, 1.0]:
			var w := 9.0 if k == 0.0 else 6.5
			LandmarkRbParts.kokoshnik(lm, "White", "Mosaic", Vector3(SOB_CX + k * 9.5, 21.4, face + sz * 0.1), out, w, 0.6,
				k == 0.0)
			lm.box("Brick", Vector3(SOB_CX + k * 9.5, 21.4 + w * 0.25, face - sz * 0.4), Vector3(w, w * 0.5, 0.8))
	# West front: the canopy panel of the assassination site and the
	# mosaic of the Crucifixion over it; three apses on the east.
	lm.box("Mosaic", Vector3(-17.05, 13.5, 0), Vector3(0.1, 6.0, 5.0))
	for k in [-1.0, 0.0, 1.0]:
		var r := 7.0 if k == 0.0 else 4.0
		var c := Vector3(18.5 - absf(k) * 1.5, 0, k * 9.0)
		var h := 16.0 if k == 0.0 else 12.0
		lm.frustum("Brick", c, r, r, h, 16, -PI * 0.5, 1.0, 1.0)
		lm.frustum("White", c + Vector3(0, h, 0), r + 0.4, r + 0.4, 0.8, 16)
		lm.lathe("Tent", c + Vector3(0, h + 0.8, 0), LandmarkRbParts.dome_profile(r + 0.3, r * 0.45, 4), 16)
		LandmarkDetail.window(lm, "White", "Windows", c + Vector3(r - 0.05, h * 0.45, 0), Vector3(1, 0, 0), 1.6, 4.0, true)
		var dh := h + 0.8 + r * 0.45
		LandmarkRbParts.onion_on_drum(lm, "White", "Gilt", "Gilt", c + Vector3(0, dh, 0), 1.2 if k != 0.0 else 1.6,
			2.2, 3.2 if k != 0.0 else 4.0, 1.6, 12)
	# The four corner domes on octagonal drums with kokoshnik crowns,
	# each enamelled differently (blue-green stripes, blue with gold,
	# green and white, white and blue).
	var patterns := [["Blue", "Green"], ["Blue", "Gilt"], ["Green", "White"], ["White", "Blue"]]
	for k in 4:
		var c := Vector3(SOB_CX + (9.8 if k % 2 == 0 else -9.8), 21.5, (9.8 if k < 2 else -9.8))
		lm.frustum("Brick", c, 4.6, 4.2, 12.0, 8, PI / 8.0)
		SEuUtil.ring_openings(lm, "Windows", c, 4.4, 8, 8, 4.5, 1.2, 3.6, false, 0.0)
		for i in 8:
			var a := PI / 8.0 + TAU * float(i) / 8.0
			lm.box("White", c + Vector3(cos(a) * 4.45, 6.0, sin(a) * 4.45), Vector3(0.4, 12.0, 0.4), Basis(Vector3.UP, -a))
			var fa := TAU * float(i) / 8.0
			var d := Vector3(cos(fa), 0, sin(fa))
			LandmarkRbParts.kokoshnik(lm, "White", "Brick", c + d * 4.0 + Vector3(0, 12.0, 0), d, 2.6, 0.3, true)
		lm.frustum("White", c + Vector3(0, 12.0, 0), 4.0, 3.2, 1.6, 8, PI / 8.0)
		lm.frustum("White", c + Vector3(0, 13.6, 0), 2.9, 2.9, 1.7, 12)
		LandmarkRbParts.striped_onion(lm, patterns[k], c + Vector3(0, 15.3, 0), 4.7, 8.5, 12, 0.0, 2)
		LandmarkRbParts.cross(lm, "Gilt", c + Vector3(0, 23.8, 0), 3.2)
	_sob_centre(lm)
	_sob_bell_tower(lm)
	lm.commit(model)

## The central tower: octagonal brick drum with eight kokoshnik-framed
## windows, the patterned tent with its eight dormers ("slukhi"), the
## lantern, the white-green-blue spiral onion and the cross (81 m).
static func _sob_centre(lm: LandmarkMesh) -> void:
	var c := Vector3(SOB_CX, 21.0, 0)
	lm.frustum("Brick", c, 8.4, 8.0, 22.0, 8, PI / 8.0)
	for k in 8:
		var a := PI / 8.0 + TAU * float(k) / 8.0
		lm.box("White", c + Vector3(cos(a) * 8.1, 11.0, sin(a) * 8.1), Vector3(0.9, 22.0, 0.9), Basis(Vector3.UP, -a))
		var fa := TAU * float(k) / 8.0
		var d := Vector3(cos(fa), 0, sin(fa))
		LandmarkDetail.window(lm, "White", "Windows", c + d * 7.6 + Vector3(0, 12.0, 0), d, 2.2, 7.0, true)
		LandmarkRbParts.kokoshnik(lm, "White", "Mosaic", c + d * 7.4 + Vector3(0, 22.0, 0), d, 5.6, 0.5, true)
	lm.frustum("White", c + Vector3(0, 22.0, 0), 8.8, 8.8, 1.2, 8, PI / 8.0)
	lm.frustum("White", c + Vector3(0, 23.2, 0), 8.4, 8.4, 0.6, 8, PI / 8.0)
	var tent := c + Vector3(0, 23.8, 0)
	lm.lathe("Tent", tent, PackedVector2Array([Vector2(8.3, 0), Vector2(6.8, 7.0), Vector2(4.8, 14.0),
		Vector2(3.2, 20.0), Vector2(2.4, 23.5)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := PI / 8.0 + TAU * float(k) / 8.0
		lm.beam("White", tent + Vector3(cos(a) * 8.7, 0.1, sin(a) * 8.7), tent + Vector3(cos(a) * 2.5, 23.4, sin(a) * 2.5), 0.45, 0.35)
		# Dormers on the tent faces: two tiers.
		var fa := TAU * float(k) / 8.0
		var d := Vector3(cos(fa), 0, sin(fa))
		for tier in 2:
			var y := 6.0 + float(tier) * 7.5
			var rr := 7.0 - float(tier) * 2.4
			var dc := tent + d * rr + Vector3(0, y, 0)
			lm.box("White", dc, Vector3(1.6 - tier * 0.4, 2.2 - tier * 0.5, 1.6), Basis.looking_at(d))
			lm.gable("Gilt", dc + Vector3(0, 1.1 - tier * 0.25, 0), 1.7 - tier * 0.4, 1.8, 0.9, Basis.looking_at(d), 0.1)
			SEuUtil.opening(lm, "Windows", dc + d * 0.82 - Vector3(0, 0.8, 0), Vector3.UP.cross(d), Vector3.UP,
				0.7 - tier * 0.15, 1.5 - tier * 0.3)
	lm.frustum("White", tent + Vector3(0, 23.4, 0), 2.4, 2.1, 2.2, 8)
	SEuUtil.ring_openings(lm, "Windows", tent + Vector3(0, 23.4, 0), 2.25, 8, 8, 0.4, 0.4, 1.4, false, PI / 8.0)
	LandmarkRbParts.striped_onion(lm, ["White", "Green", "Blue"], tent + Vector3(0, 25.6, 0), 3.1, 7.4, 12, 1.4, 2)
	LandmarkRbParts.cross(lm, "Gilt", tent + Vector3(0, 33.0, 0), SOB_TOP - (tent.y + 33.0))

## West bell tower: the brick shaft with the mosaic coats of arms, the
## belfry of eight arches between columns, the kokoshnik crown and the
## gilded onion; the two porches with tented roofs either side.
static func _sob_bell_tower(lm: LandmarkMesh) -> void:
	var c := Vector3(-23.0, 0, 0)
	lm.box("Brick", c + Vector3(0, 16.5, 0), Vector3(12.0, 33.0, 17.0))
	lm.box("White", c + Vector3(0, 33.5, 0), Vector3(12.8, 1.0, 17.8))
	SEuUtil.opening(lm, "Windows", c + Vector3(-6.05, 1.0, 0), Vector3(0, 0, -1), Vector3.UP, 4.0, 10.0)
	LandmarkDetail.arch(lm, "White", c + Vector3(-6.0, 9.0, 0), Vector3(-1, 0, 0), 4.0, 0.6, 0.4)
	# Coats-of-arms mosaic panels: rows of shields on three faces.
	for row in 3:
		for i in 4:
			lm.box("Mosaic", c + Vector3(-6.05, 18.5 + row * 4.0, (float(i) - 1.5) * 3.6), Vector3(0.12, 2.6, 2.2), Basis(), 0.0)
	for sz in [-1.0, 1.0]:
		LandmarkDetail.window(lm, "White", "Windows", c + Vector3(0, 25.5, sz * 8.5), Vector3(0, 0, sz), 3.0, 7.0, true)
		for row in 2:
			for i in 3:
				lm.box("Mosaic", c + Vector3((float(i) - 1.0) * 3.4, 12.0 + row * 3.4, sz * 8.56), Vector3(2.2, 2.4, 0.12),
					Basis(), 0.0)
		# The porches flanking the tower: tented roofs with crosses.
		lm.box("Brick", Vector3(-21.0, 9.0, sz * 14.2), Vector3(8.4, 18.0, 10.8))
		lm.box("White", Vector3(-21.0, 18.3, sz * 14.2), Vector3(9.0, 0.7, 11.4))
		LandmarkDetail.window(lm, "White", "Windows", Vector3(-25.2, 6.0, sz * 14.2), Vector3(-1, 0, 0), 2.2, 5.0, true)
		lm.spire("Tent", Vector3(-21.0, 18.6, sz * 14.2), 4.2, 7.0, 0.5, 4)
		LandmarkRbParts.cross(lm, "Gilt", Vector3(-21.0, 25.6, sz * 14.2), 1.8)
	# Belfry: eight arches between columns round an octagon.
	var bb := c + Vector3(0, 34.0, 0)
	lm.frustum("Brick", bb, 6.0, 5.6, 8.0, 8, PI / 8.0)
	SEuUtil.ring_openings(lm, "Windows", bb, 5.8, 8, 8, 1.0, 2.6, 6.0, false, 0.0)
	for k in 8:
		var a := PI / 8.0 + TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkRbParts.order_column(lm, "White", bb + d * 5.7, 0.35, 7.6, "tuscan", d, 8)
		var fa := TAU * float(k) / 8.0
		var fd := Vector3(cos(fa), 0, sin(fa))
		LandmarkRbParts.kokoshnik(lm, "White", "Mosaic", bb + fd * 5.2 + Vector3(0, 9.0, 0), fd, 3.6, 0.4, true)
	lm.frustum("White", bb + Vector3(0, 8.0, 0), 6.4, 6.4, 1.0, 8, PI / 8.0)
	lm.frustum("Brick", bb + Vector3(0, 9.0, 0), 5.4, 5.0, 5.0, 8, PI / 8.0)
	lm.frustum("White", bb + Vector3(0, 14.0, 0), 5.3, 5.3, 0.8, 8, PI / 8.0)
	lm.frustum("Brick", bb + Vector3(0, 14.8, 0), 3.4, 3.4, 3.4, 12)
	SEuUtil.ring_openings(lm, "Windows", bb + Vector3(0, 14.8, 0), 3.4, 12, 6, 0.5, 0.6, 2.2, false, 0.0)
	lm.frustum("White", bb + Vector3(0, 18.2, 0), 3.7, 3.7, 0.6, 12)
	LandmarkCeParts.onion(lm, "Gilt", bb + Vector3(0, 18.8, 0), 4.0, 7.0, 16)
	LandmarkRbParts.cross(lm, "Gilt", bb + Vector3(0, 25.8, 0), 3.2)
