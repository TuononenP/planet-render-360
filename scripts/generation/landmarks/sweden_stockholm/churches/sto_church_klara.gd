class_name StoChurchKlara
extends RefCounted

## Klara kyrka (S:ta Clara), Norrmalm. Origin at the OSM footprint centre
## (way 163637452, 61.5 x 32.2 m, bearing 98.8, so the registry yaw 8.7 puts
## model +X on the long axis, tower to the west, -X). 116 m with the spire.
##
## From the photos (visual-plan/refs/landmarks/klara_church/):
## - The west tower is a battered red-brick shaft, 14 m square at the foot
##   and 10.6 m at 52 m, with sandstone string courses, a pointed portal and
##   a clock under the crown. Four corner piers with corbelled feet rise
##   from the shaft's upper third and each carries an octagonal copper
##   spirelet. Between them every face ends in a crow-stepped brick gable.
## - From the crown the octagonal copper spire (64 m) tapers to a gilt
##   orb and a weathervane. Four louvred spirelets stand on its lower
##   third.
## - The nave is a red-brick hall, 26 m wide and six bays long, on a
##   sandstone plinth: tall pointed windows with stone surrounds, flat
##   brick piers between them and a cornice. Its green copper roof runs
##   from the tower to a hip over the east end. A small gabled projection
##   on each flank (south one pedimented) carries a taller arched window;
##   the east wall has three lancets and an oculus.
## Sources: Church of Sweden, "S:ta Clara kyrkas historia" (tower rebuilt
## in the 1880s); Commons photos; OSM footprint and height 116.
## Eave height and window sizes are measured off the aerial photo, so they
## are approximate.

const TX := -23.75
const TW0 := 7.0
const TW1 := 5.3
const TOP := 52.0
const NX0 := -17.0
const NX1 := 30.75
const NHZ := 13.0
const EAVE := 15.6
const RISE := 8.8
const TILT := 0.0327

static func hw(y: float) -> float:
	return lerpf(TW0, TW1, y / TOP)

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	var mats := StoChurchKit.materials("brick", "#A54A30", "#CDB78F")
	StoChurchKit.use_all(lm, mats)
	var lancet := StoChurchKit.lancet_unit(mats, 3.2, 10.5)
	_nave(lm, mats, lancet)
	_tower(lm, mats)
	_spire(lm)
	lm.commit(model)
	StoChurchKit.flood(model, Vector3(TX, 0, 0), 60.0, 14.0)

static func _nave(lm: LandmarkMesh, mats: Dictionary, lancet: LandmarkMesh) -> void:
	var cx := (NX0 + NX1) * 0.5
	var len := NX1 - NX0
	lm.box("Trim", Vector3(cx, 0.6, 0), Vector3(len + 0.5, 1.2, NHZ * 2.0 + 0.5))
	lm.box("Wall", Vector3(cx, EAVE * 0.5, 0), Vector3(len, EAVE, NHZ * 2.0))
	lm.box("Trim", Vector3(cx, EAVE - 0.25, 0), Vector3(len + 0.9, 0.5, NHZ * 2.0 + 0.9))
	StoChurchKit.half_hip(lm, "Copper", "Wall", NX0, NX1, NHZ, EAVE, RISE, 0.6)
	# Bays: windows between flat brick piers; the east bay of each flank is
	# the gabled projection.
	var bay := 7.75
	for i in 6:
		var x := NX0 + 0.5 + bay * (float(i) + 0.5)
		var px := NX0 + 0.5 + bay * float(i)
		for s in [-1.0, 1.0]:
			var sg: float = s
			var out := Vector3(0, 0, sg)
			if i != 5:
				StoChurchKit.place(lm, lancet, Vector3(x, 3.2, sg * NHZ), out)
			lm.box("Wall", Vector3(px, EAVE * 0.5, sg * (NHZ + 0.3)), Vector3(1.2, EAVE, 0.6))
			lm.box("Trim", Vector3(px, EAVE - 0.9, sg * (NHZ + 0.35)), Vector3(1.5, 0.4, 0.8))
	# Gabled projections, a hall-width window in each.
	var gx := NX0 + 0.5 + bay * 5.5
	for s in [-1.0, 1.0]:
		var sg: float = s
		var zc := sg * (NHZ + 1.55)
		lm.box("Trim", Vector3(gx, 0.6, zc), Vector3(12.4, 1.2, 3.4))
		lm.box("Wall", Vector3(gx, 8.0, zc), Vector3(12.0, 16.0, 3.1))
		lm.gable("Copper", Vector3(gx, 16.0, zc), 3.1, 12.0, 4.0, Basis(Vector3.UP, 0.0), 0.4, "Trim")
		var wide := StoChurchKit.lancet_unit(mats, 4.2, 11.5)
		StoChurchKit.place(lm, wide, Vector3(gx, 2.6, sg * (NHZ + 3.1)), Vector3(0, 0, sg))
		for k in [-1.0, 1.0]:
			var side := StoChurchKit.lancet_unit(mats, 1.6, 7.0, 0.3, false)
			StoChurchKit.place(lm, side, Vector3(gx + float(k) * 4.2, 4.0, sg * (NHZ + 3.1)), Vector3(0, 0, sg))
	# East end: three lancets over the plinth and a round window in the hip's wall.
	for k in [-1.0, 0.0, 1.0]:
		var east := StoChurchKit.lancet_unit(mats, 2.6, 9.5)
		StoChurchKit.place(lm, east, Vector3(NX1, 3.4, float(k) * 6.5), Vector3.RIGHT)
	lm.box("Trim", Vector3(NX1 + 0.1, 12.6, 0), Vector3(0.3, 2.8, 2.8), Basis(), 0.0)
	lm.disc("Glass", Vector3(NX1 + 0.3, 12.6, 0), Vector3.RIGHT, 1.1, 16)

static func _tower(lm: LandmarkMesh, mats: Dictionary) -> void:
	StoChurchKit.tapered_shaft(lm, "Wall", TX, 0.0, 0.0, TOP, TW0, TW1)
	lm.box("Trim", Vector3(TX, 0.7, 0), Vector3(TW0 * 2.0 + 1.0, 1.4, TW0 * 2.0 + 1.0))
	for y in [9.0, 21.0, 35.0, 48.0]:
		StoChurchKit.tower_band(lm, "Trim", TX, 0.0, hw(y), y, 0.5, 0.25)
	# Corbelled brick cornice under the crown, with a stone cap slab on top.
	StoChurchKit.tower_band(lm, "Trim", TX, 0.0, TW1, TOP - 0.5, 0.5, 0.45)
	lm.box("Trim", Vector3(TX, TOP + 0.2, 0), Vector3(TW1 * 2.0 + 0.9, 0.4, TW1 * 2.0 + 0.9))
	# Faces: portal, first-stage lancets, the belfry louvres, the clock.
	var portal := StoChurchKit.lancet_unit(mats, 3.8, 10.0, 0.5)
	var low := StoChurchKit.lancet_unit(mats, 2.2, 6.5)
	var belfry := StoChurchKit.lancet_unit(mats, 2.4, 9.5)
	for d in [Vector3.LEFT, Vector3.FORWARD, Vector3.BACK, Vector3.RIGHT]:
		var out: Vector3 = d
		var base := Vector3(TX, 0, 0)
		if out.x < 0.0:
			StoChurchKit.place(lm, portal, base + out * (hw(1.5) + 0.05) + Vector3(0, 1.5, 0), out, TILT)
		if out.x <= 0.0:
			StoChurchKit.place(lm, low, base + out * hw(14.0) + Vector3(0, 14.0, 0), out, TILT)
		if out.x == 0.0:
			StoChurchKit.place(lm, low, base + out * hw(4.0) + Vector3(0, 4.0, 0), out, TILT)
		StoChurchKit.place(lm, belfry, base + out * hw(30.0) + Vector3(0, 30.0, 0), out, TILT)
		StoChurchKit.clock(lm, base + out * hw(46.0) + Vector3(0, 46.0, 0), out, 1.5)
	# Corner piers on corbelled feet, each with its stone cap and copper spirelet.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var c := Vector3(TX + float(sx) * 5.0, 0, float(sz) * 5.0)
			lm.lathe("Wall", c + Vector3(0, 20.0, 0), PackedVector2Array([
				Vector2(0.9, 0), Vector2(1.75, 5.0), Vector2(1.35, 32.5)]) , 4, 1.41421356, 1.41421356,
				PI * 0.25, false)
			lm.box("Trim", c + Vector3(0, TOP + 0.7, 0), Vector3(3.3, 0.5, 3.3))
			StoChurchKit.pinnacle(lm, c + Vector3(0, TOP + 0.95, 0), 1.4, 2.0, 20.0)
	# Crow-stepped brick gable on each face between the piers.
	for d in [Vector3.LEFT, Vector3.FORWARD, Vector3.BACK, Vector3.RIGHT]:
		var out: Vector3 = d
		LandmarkFhParts.crow_gable(lm, "Wall", "Trim", Vector3(TX, 0, 0) + out * (TW1 - 0.1), out, 6.8,
			TOP + 0.4, 6.5, 4, 0.9)

static func _spire(lm: LandmarkMesh) -> void:
	var c := Vector3(TX, TOP + 0.4, 0)
	var prof := PackedVector2Array([Vector2(5.5, 0), Vector2(4.4, 8), Vector2(3.1, 20), Vector2(2.0, 34),
		Vector2(1.2, 46), Vector2(0.6, 58), Vector2(0.3, 61.6)])
	lm.lathe("Copper", c, prof, 8, 1.0, 1.0, PI / 8.0, false)
	# Louvred spirelets on the lower third of the spire, one per face.
	for d in [Vector3.LEFT, Vector3.FORWARD, Vector3.BACK, Vector3.RIGHT]:
		var out: Vector3 = d
		var at := c + out * 2.35 + Vector3(0, 31.0, 0)
		lm.box("Glass", at + Vector3(0, 0.9, 0), Vector3(0.9, 1.8, 0.9), Basis(Vector3.UP, atan2(out.x, out.z)), 0.0)
		lm.spire("Copper", at + Vector3(0, 1.8, 0), 0.75, 4.0)
	StoChurchKit.finial(lm, c + Vector3(0, 61.6, 0), 0.55, 116.0 - c.y - 61.6)
