class_name StoChurchSofia
extends RefCounted

## Sofia kyrka, Vitabergsparken (Gustaf Hermansson, 1906). Origin at the OSM
## footprint centre (way 1350868500, 47.3 x 36.1 m, bearing 75.0: registry
## yaw -14.3 puts model +X on the long axis). 78 m to the cross.
##
## The plan text of the S-1 table says "dome-and-lantern crown"; the photos
## (visual-plan/refs/landmarks/sofia_church_stockholm/) show no dome. This
## builds what they show:
## - A Greek cross of equal 19 m wide arms (x arms 44.8 m, z arms 35.6 m
##   to match the measured footprint) in rock-faced pink-brown granite on a
##   plinth, eaves 18.5 m, steep copper gables (ridge 31.5 m). Each gable
##   end has a stepped raking course, a 6 m rose window with twelve spokes,
##   a row of five small arches under the eave line, an oculus near the
##   apex and three tall round-headed windows at the foot.
## - Over the crossing a square tower with a faint batter, string courses,
##   paired round-arched belfry louvres, a stone gablet with a clock on
##   each face and a four-sided copper spire that ends in a small
##   lantern, a gilt ball and a cross.
## - Four round stair turrets with conical copper roofs stand in the
##   re-entrant corners of the cross, as high as the gable apexes; two
##   lower ones flank the south arm, which also has a gabled porch.
## Sources: Church of Sweden, "Sofia kyrka" building record (equal cross
## arms, octagonal tower in the record; the photos show the tower square
## to the belfry); OSM way 1350868500 (height 78); Commons photos.

const AW := 9.5
const AX := 22.4
const AZ := 17.8
const EAVE := 18.5
const RISE := 13.0
const TH := 46.5
const TW0 := 7.6
const TW1 := 6.1

static func hw(y: float) -> float:
	return lerpf(TW0, TW1, y / TH)

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	var mats := StoChurchKit.materials("stone", "#A97B5D", "#CFA382", "#6F9C8A")
	StoChurchKit.use_all(lm, mats)
	_arms(lm, mats)
	_tower(lm, mats)
	_turrets(lm)
	lm.commit(model)
	StoChurchKit.flood(model, Vector3.ZERO, 50.0, 17.0)

static func _arms(lm: LandmarkMesh, mats: Dictionary) -> void:
	lm.box("Trim", Vector3(0, 0.6, 0), Vector3(AX * 2.0 + 0.5, 1.2, AW * 2.0 + 0.5))
	lm.box("Trim", Vector3(0, 0.6, 0), Vector3(AW * 2.0 + 0.5, 1.2, AZ * 2.0 + 0.5))
	lm.box("Wall", Vector3(0, EAVE * 0.5, 0), Vector3(AX * 2.0, EAVE, AW * 2.0))
	lm.box("Wall", Vector3(0, EAVE * 0.5, 0), Vector3(AW * 2.0, EAVE, AZ * 2.0))
	LandmarkFhUtil.ridge_x(lm, "Copper", "Wall", Vector3(0, EAVE, 0), AX * 2.0, AW * 2.0, RISE, 0.4)
	LandmarkFhUtil.ridge_z(lm, "Copper", "Wall", Vector3(0, EAVE, 0), AW * 2.0, AZ * 2.0, RISE, 0.4)
	var end := _gable_end(mats)
	for d in [[Vector3.RIGHT, AX], [Vector3.LEFT, AX], [Vector3.BACK, AZ], [Vector3.FORWARD, AZ]]:
		var out: Vector3 = d[0]
		StoChurchKit.place(lm, end, out * float(d[1]), out)
	_porch(lm)

## One arm end facing +Z, 19 m wide: foot windows, rose, small arcade, oculus,
## raking course and the cornice. Built once, merged to the four arms.
static func _gable_end(mats: Dictionary) -> LandmarkMesh:
	var u := LandmarkMesh.new()
	StoChurchKit.use_all(u, mats)
	u.box("Trim", Vector3(0, EAVE - 0.3, 0.25), Vector3(AW * 2.0 + 0.9, 0.6, 0.7))
	u.box("Trim", Vector3(0, 1.35, 0.15), Vector3(AW * 2.0 + 0.3, 0.3, 0.4))
	for x in [-5.0, 0.0, 5.0]:
		LandmarkDetail.window(u, "Trim", "Glass", Vector3(float(x), 2.4 + 2.7, 0.02), Vector3.BACK, 1.8, 5.4, true, 0.3)
	var rose := Vector3(0, 13.2, 0.0)
	LandmarkFhParts.ring(u, "Trim", rose, Vector3.BACK, 3.0, 4.0, 0.3, 20)
	u.disc("Glass", rose + Vector3(0, 0, 0.05), Vector3.BACK, 3.0, 20)
	for k in 12:
		var a := TAU * float(k) / 12.0
		var tip := rose + Vector3(cos(a), sin(a), 0) * 3.0 + Vector3(0, 0, 0.12)
		u.beam("Trim", rose + Vector3(0, 0, 0.12), tip, 0.18, 0.12, Vector3.BACK)
	u.lathe("Trim", rose + Vector3(0, 0, 0.1), PackedVector2Array([Vector2(0.6, 0), Vector2(0.5, 0.2)]), 12,
		1.0, 1.0, 0.0, true, true)
	for i in 5:
		var x := (float(i) - 2.0) * 1.35
		LandmarkDetail.window(u, "Trim", "Glass", Vector3(x, EAVE + 1.4, 0.02), Vector3.BACK, 0.9, 2.2, true, 0.25)
	LandmarkFhParts.ring(u, "Trim", Vector3(0, 26.0, 0), Vector3.BACK, 0.6, 1.1, 0.25, 12)
	u.disc("Glass", Vector3(0, 26.0, 0.05), Vector3.BACK, 0.6, 12)
	# Raking course along both slopes, stepped on its underside.
	var apex := Vector3(0, EAVE + RISE + 0.3, 0.15)
	for s in [-1.0, 1.0]:
		var sg: float = s
		var foot := Vector3(sg * (AW + 0.3), EAVE - 0.1, 0.15)
		u.beam("Trim", foot, apex, 0.7, 0.55, Vector3.BACK)
		for k in 8:
			var t := (float(k) + 0.8) / 9.0
			var p := foot.lerp(apex, t * 0.85)
			u.box("Trim", p + Vector3(-sg * 0.65, -0.55, 0), Vector3(0.9, 0.5, 0.45), Basis(), 0.0)
	return u

## Gabled porch and the two stair turrets beside the south arm.
static func _porch(lm: LandmarkMesh) -> void:
	var z := AZ + 1.5
	lm.box("Wall", Vector3(0, 3.1, z), Vector3(7.2, 6.2, 3.0))
	lm.gable("Copper", Vector3(0, 6.2, z), 7.2, 3.0, 2.8, Basis(), 0.3, "Trim")
	LandmarkDetail.window(lm, "Trim", "Glass", Vector3(0, 2.5, z + 1.52), Vector3.BACK, 2.6, 4.6, true, 0.4)
	for x in [-1.0, 1.0]:
		var xs: float = x
		var r := 1.7
		var c := Vector3(xs * 6.4, 0, AZ - 0.2)
		lm.frustum("Wall", c, r, r, 11.0, 12)
		lm.frustum("Trim", c + Vector3(0, 10.7, 0), r * 1.1, r * 1.1, 0.5, 12)
		lm.lathe("Copper", c + Vector3(0, 11.2, 0), PackedVector2Array([Vector2(r * 1.25, 0), Vector2(0, 4.5)]), 12)

static func _tower(lm: LandmarkMesh, mats: Dictionary) -> void:
	StoChurchKit.tapered_shaft(lm, "Wall", 0.0, 0.0, 0.0, TH, TW0, TW1)
	var tilt := atan((TW0 - TW1) / TH)
	for y in [33.0, 42.0]:
		StoChurchKit.tower_band(lm, "Trim", 0.0, 0.0, hw(y), y, 0.45, 0.25)
	StoChurchKit.tower_band(lm, "Trim", 0.0, 0.0, hw(TH), TH - 0.3, 0.6, 0.5)
	var louvre := StoChurchKit.round_unit(mats, 1.7, 4.8)
	var slit := StoChurchKit.round_unit(mats, 0.7, 2.0, 0.2)
	for d in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
		var out: Vector3 = d
		var side := Vector3.UP.cross(out)
		for s in [-1.0, 1.0]:
			var at := out * hw(35.0) + side * float(s) * 2.5 + Vector3(0, 35.0, 0)
			StoChurchKit.place(lm, louvre, at, out, tilt)
		for k in [-1.0, 0.0, 1.0]:
			StoChurchKit.place(lm, slit, out * hw(43.0) + side * float(k) * 1.5 + Vector3(0, 43.0, 0), out, tilt)
		# Stone gablet over each face with its clock; copper flashing on the rake.
		var basis := Basis() if absf(out.z) > 0.5 else Basis(Vector3.UP, PI * 0.5)
		lm.gable("Copper", out * (hw(TH) - 0.5) + Vector3(0, TH, 0), 5.6, 2.2, 4.6, basis, 0.2, "Trim")
		StoChurchKit.clock(lm, out * (hw(TH) + 0.6) + Vector3(0, TH + 1.5, 0), out, 1.1)
	# Spire, lantern and cross.
	var base := Vector3(0, TH + 0.3, 0)
	lm.spire("Copper", base, 5.9, 25.0, 0.7)
	var top := base + Vector3(0, 25.0, 0)
	lm.box("Trim", top + Vector3(0, 1.0, 0), Vector3(1.5, 2.0, 1.5))
	lm.box("Glass", top + Vector3(0, 1.0, 0), Vector3(1.0, 1.1, 1.6), Basis(), 0.0)
	lm.box("Glass", top + Vector3(0, 1.0, 0), Vector3(1.6, 1.1, 1.0), Basis(), 0.0)
	lm.spire("Copper", top + Vector3(0, 2.0, 0), 0.95, 2.6)
	StoChurchKit.finial(lm, top + Vector3(0, 4.6, 0), 0.3, 78.0 - top.y - 4.6)

## Four round turrets in the re-entrant corners, conical copper roofs.
static func _turrets(lm: LandmarkMesh) -> void:
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var c := Vector3(float(sx) * (AW + 0.7), 0, float(sz) * (AW + 0.7))
			var r := 2.0
			lm.frustum("Wall", c, r, r * 0.92, 28.5, 12)
			lm.frustum("Trim", c + Vector3(0, 12.0, 0), r * 1.1, r * 1.1, 0.4, 12)
			for k in 4:
				var a := TAU * float(k) / 4.0 + PI * 0.25
				var d := Vector3(cos(a), 0, sin(a))
				LandmarkDetail.window(lm, "Trim", "Glass", c + d * r * 0.93 + Vector3(0, 24.5, 0), d, 0.8, 2.4, true, 0.2)
			lm.frustum("Trim", c + Vector3(0, 28.3, 0), r * 1.12, r * 1.12, 0.5, 12)
			lm.lathe("Copper", c + Vector3(0, 28.8, 0), PackedVector2Array([Vector2(r * 1.25, 0), Vector2(0, 7.2)]), 12)
			lm.lathe("Gilt", c + Vector3(0, 36.0, 0), LandmarkFhUtil.ball(0.22), 6)
