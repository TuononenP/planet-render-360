class_name StoChurchGerman
extends RefCounted

## Tyska kyrkan (Sankta Gertrud) in Gamla stan, 96 m with the spire. Origin
## at the OSM footprint centre (way 8049509, 35.5 x 29.0 m, bearing 46.8;
## registry yaw -43 puts model +X on the long axis, tower at -X).
##
## From the photos (visual-plan/refs/landmarks/tyska_kyrkan/):
## - Nave: a broad red-brick hall (23.5 x 29 m) under a green copper hip roof
##   with a small flat ridge. Four bays on each flank, sandstone pilasters with copper
##   caps carrying a dentilled cornice, a tall pointed window in every bay
##   and a copper gargoyle spout over each pilaster. The middle bay of the
##   south flank is the sandstone portal (two pilasters, an arched door, a
##   pediment with a gilt arms plate and steps); a baroque stone gablet
##   with volutes and ball finials stands over it and over the north
##   middle bay. The east wall has three windows.
## - Tower at the south-west corner, flush with the south flank and the west
##   end (the aerial photo shows its south face continuing the nave wall; the
##   footprint is L-shaped, the north-west corner is empty). 12 m square in brick with sandstone bands every few
##   metres and corner quoins, a sandstone entablature at 44 m with
##   dragon-headed gargoyle spouts at the corners, and a round copper-capped
##   stair turret on each side beside the nave.
## - Crown (dark copper): a flared skirt, four corner pinnacles with
##   spires, a louvred and clock stage, a cornice, an open octagonal lantern
##   with arched openings behind a balustrade, a bell cap and the needle
##   spire ending in a gilt ball and vane.
## Sources: Stockholms läns museum, "Tyska kyrkan"; en Wikipedia, "German
## Church, Stockholm" (96 m, 1638-1642 enlargement); Commons photos; OSM
## footprint. The photos show a hipped nave roof, so the "ornate nave
## gables" of the S-1 table are modelled as the two baroque gablets over the
## middle flank bays rather than full-height gables.

const TX := -11.75
const TZ := 8.5
const TW := 6.0
const NX0 := -5.75
const NX1 := 17.75
const NZ := 14.5
const EAVE := 17.0
const RISE := 6.0
const SHAFT := 44.0
const BAY := 5.875

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	var mats := StoChurchKit.materials("brick", "#AE5B3D", "#DABF99", "#6E9C8A")
	mats["Dark"] = LandmarkMaterials.pbr("concrete", "#506A5C", 2.0, 0.5, 0.35)
	StoChurchKit.use_all(lm, mats)
	_nave(lm, mats)
	var portal := LandmarkMesh.new()
	StoChurchKit.use_all(portal, mats)
	_portal(portal)
	StoChurchKit.place(lm, portal, Vector3(NX0 + BAY * 2.5, 0, 0), Vector3.BACK)
	_tower(lm, mats)
	_crown(lm, mats)
	lm.commit(model)
	StoChurchKit.flood(model, Vector3(TX, 0, TZ), 60.0, 12.0)

static func _nave(lm: LandmarkMesh, mats: Dictionary) -> void:
	var cx := (NX0 + NX1) * 0.5
	var len := NX1 - NX0
	lm.box("Trim", Vector3(cx, 0.6, 0), Vector3(len + 0.5, 1.2, NZ * 2.0 + 0.5))
	lm.box("Wall", Vector3(cx, EAVE * 0.5, 0), Vector3(len, EAVE, NZ * 2.0))
	lm.box("Trim", Vector3(cx, EAVE - 0.3, 0), Vector3(len + 1.0, 0.6, NZ * 2.0 + 1.0))
	lm.box("Trim", Vector3(cx, EAVE - 0.9, 0), Vector3(len + 0.5, 0.5, NZ * 2.0 + 0.5))
	# Hip roof; its ridge is the short flat run the aerial photo shows.
	var hip := LandmarkMesh.new()
	StoChurchKit.use_all(hip, mats)
	StoChurchKit.half_hip(hip, "Copper", "", -len * 0.5, len * 0.5, NZ, EAVE, RISE, 0.8, true)
	hip.box("Copper", Vector3(0, EAVE + RISE - 0.1, 0), Vector3(1.2, 0.2, 1.2), Basis(), 0.0)
	lm.merge(hip, Transform3D(Basis(), Vector3(cx, 0, 0)))
	var win := StoChurchKit.lancet_unit(mats, 2.8, 9.5)
	var spout := LandmarkMesh.new()
	StoChurchKit.use_all(spout, mats)
	spout.beam("Dark", Vector3(0, 0, 0), Vector3(0, -0.7, 1.3), 0.28, 0.28)
	spout.box("Dark", Vector3(0, -0.8, 1.35), Vector3(0.4, 0.4, 0.4), Basis(), 0.0)
	# Pilasters, dentil course and spouts on the flanks, windows between them.
	for s in [-1.0, 1.0]:
		var sg: float = s
		var out := Vector3(0, 0, sg)
		for i in 5:
			var x := NX0 + BAY * float(i)
			lm.box("Trim", Vector3(x, (EAVE - 0.9) * 0.5, sg * (NZ + 0.25)), Vector3(1.4, EAVE - 0.9, 0.5))
			lm.box("Copper", Vector3(x, EAVE - 0.8, sg * (NZ + 0.3)), Vector3(1.7, 0.25, 0.75))
			StoChurchKit.place(lm, spout, Vector3(x, EAVE - 0.9, sg * (NZ + 0.9)), out)
		for i in 4:
			var cx2 := NX0 + BAY * (float(i) + 0.5)
			if not (i == 2 and sg > 0.0):
				StoChurchKit.place(lm, win, Vector3(cx2, 3.6, sg * NZ), out)
		for k in int(len / 0.5):
			lm.box("Trim", Vector3(NX0 + 0.25 + float(k) * 0.5, EAVE - 1.3, sg * (NZ + 0.1)), Vector3(0.28, 0.3, 0.4), Basis(), 0.0)
		# Baroque gablet over the middle bay.
		_gablet(lm, mats, Vector3(NX0 + BAY * 2.5, EAVE - 0.3, sg * (NZ + 0.35)), out)
	for z in [-9.5, 0.0, 9.5]:
		StoChurchKit.place(lm, win, Vector3(NX1, 3.6, float(z)), Vector3.RIGHT)
	StoChurchKit.place(lm, StoChurchKit.lancet_unit(mats, 2.6, 8.5), Vector3(-NX1, 3.6, -8.0), Vector3.LEFT)

## Stone gablet with volute brackets and ball finials, facing `out`, on the cornice.
static func _gablet(lm: LandmarkMesh, mats: Dictionary, base: Vector3, out: Vector3) -> void:
	var u := LandmarkMesh.new()
	StoChurchKit.use_all(u, mats)
	u.box("Trim", Vector3(0, 1.0, 0), Vector3(7.0, 2.0, 1.0))
	u.gable("Trim", Vector3(0, 2.0, 0), 7.0, 1.0, 2.6, Basis(), 0.0, "Trim")
	u.box("Trim", Vector3(0, 2.1, 0.55), Vector3(7.6, 0.25, 0.3), Basis(), 0.0)
	u.disc("Glass", Vector3(0, 2.4, 0.52), Vector3.BACK, 0.7, 12)
	for s in [-1.0, 1.0]:
		var sg: float = s
		u.beam("Trim", Vector3(sg * 3.9, 0.2, 0.1), Vector3(sg * 2.6, 2.8, 0.1), 0.6, 0.7, Vector3.BACK)
		u.lathe("Trim", Vector3(sg * 3.9, 0.0, 0.1), LandmarkFhUtil.ball(0.45), 8)
		u.lathe("Gilt", Vector3(0, 4.6, 0), LandmarkFhUtil.ball(0.3), 8)
	StoChurchKit.place(lm, u, base, out)

## South portal: sandstone aedicule, arched door, pediment with the arms, steps.
static func _portal(lm: LandmarkMesh) -> void:
	var z := NZ + 0.35
	lm.box("Trim", Vector3(0, 4.6, z), Vector3(6.4, 9.2, 0.7))
	lm.box("Glass", Vector3(0, 2.6, z + 0.38), Vector3(2.6, 4.4, 0.1), Basis(), 0.0)
	LandmarkDetail.arch(lm, "Trim", Vector3(0, 4.8, z + 0.36), Vector3.BACK, 2.6, 0.5, 0.35)
	lm.box("Glass", Vector3(0, 5.1, z + 0.38), Vector3(2.0, 1.2, 0.1), Basis(), 0.0)
	for x in [-1.0, 1.0]:
		var xs: float = x
		lm.box("Trim", Vector3(xs * 2.5, 4.0, z + 0.55), Vector3(0.9, 8.0, 0.4))
		lm.lathe("Trim", Vector3(xs * 1.9, 0.0, z + 0.9), PackedVector2Array([
			Vector2(0.38, 0), Vector2(0.3, 1.0), Vector2(0.3, 7.0), Vector2(0.4, 7.4)]), 10)
	lm.box("Trim", Vector3(0, 8.2, z + 0.7), Vector3(6.9, 0.7, 1.2))
	lm.gable("Trim", Vector3(0, 8.55, z + 0.6), 6.9, 1.1, 1.7, Basis(), 0.0, "Trim")
	lm.box("Gilt", Vector3(0, 9.6, z + 1.2), Vector3(1.0, 1.2, 0.12), Basis(), 0.0)
	for k in 3:
		lm.box("Trim", Vector3(0, 0.15 + float(k) * 0.3, z + 1.7 - float(k) * 0.4), Vector3(5.6 - float(k) * 0.6, 0.3, 1.2 + float(k) * 0.8 - 0.8), Basis(), 0.0)

static func _tower(lm: LandmarkMesh, mats: Dictionary) -> void:
	var c := Vector3(TX, 0, TZ)
	# Stepped base, the shaft, corner quoins and the sandstone banding.
	lm.box("Trim", c + Vector3(0, 0.7, 0), Vector3(TW * 2.0 + 1.6, 1.4, TW * 2.0 + 1.6))
	lm.box("Wall", c + Vector3(0, SHAFT * 0.5, 0), Vector3(TW * 2.0, SHAFT, TW * 2.0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Trim", c + Vector3(float(sx) * (TW - 0.2), SHAFT * 0.5 - 1.0, float(sz) * (TW - 0.2)),
				Vector3(1.4, SHAFT - 2.0, 1.4))
	for y in [4.0, 8.0, 12.0, 16.0, 24.0, 28.0, 32.0, 36.0]:
		lm.box("Trim", c + Vector3(0, y, 0), Vector3(TW * 2.0 + 0.3, 0.4, TW * 2.0 + 0.3))
	for y in [19.5, 40.0]:
		lm.box("Trim", c + Vector3(0, y + 0.3, 0), Vector3(TW * 2.0 + 1.4, 0.6, TW * 2.0 + 1.4))
		lm.box("Trim", c + Vector3(0, y - 0.3, 0), Vector3(TW * 2.0 + 0.8, 0.5, TW * 2.0 + 0.8))
	# Entablature: architrave, a dentil row on each face, the cornice.
	lm.box("Trim", c + Vector3(0, SHAFT - 1.8, 0), Vector3(TW * 2.0 + 0.8, 1.4, TW * 2.0 + 0.8))
	for d in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
		var out: Vector3 = d
		var side := Vector3.UP.cross(out)
		var basis := Basis(side, Vector3.UP, out)
		for k in 22:
			var s := (float(k) - 10.5) * 0.55
			lm.box("Trim", c + out * (TW + 0.55) + side * s + Vector3(0, SHAFT - 0.9, 0), Vector3(0.3, 0.45, 0.5), basis, 0.0)
	lm.box("Trim", c + Vector3(0, SHAFT - 0.3, 0), Vector3(TW * 2.0 + 2.0, 0.6, TW * 2.0 + 2.0))
	# Faces: pointed portal on the west and south, the first-floor window, the belfry window.
	var portal := StoChurchKit.lancet_unit(mats, 3.0, 7.0, 0.5)
	var upper := StoChurchKit.lancet_unit(mats, 2.8, 8.5)
	var mid := StoChurchKit.lancet_unit(mats, 1.8, 4.4)
	for d in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
		var out: Vector3 = d
		if out.x < 0.0 or out.z > 0.0:
			StoChurchKit.place(lm, portal, c + out * TW + Vector3(0, 1.4, 0), out)
		if out.x <= 0.0:
			StoChurchKit.place(lm, mid, c + out * TW + Vector3(0, 12.8, 0), out)
		StoChurchKit.place(lm, upper, c + out * TW + Vector3(0, 28.8, 0), out)
	# Round stair turret at the south-east corner, where tower and nave meet.
	var t := Vector3(NX0 + 0.6, 0, NZ - 0.2)
	lm.frustum("Wall", t, 1.7, 1.6, 19.0, 12)
	lm.frustum("Trim", t + Vector3(0, 8.0, 0), 1.8, 1.8, 0.35, 12)
	lm.frustum("Trim", t + Vector3(0, 18.8, 0), 2.0, 2.0, 0.4, 12)
	lm.lathe("Copper", t + Vector3(0, 19.2, 0), PackedVector2Array([Vector2(2.0, 0), Vector2(1.9, 0.5),
		Vector2(1.3, 1.4), Vector2(0.7, 1.9), Vector2(0.7, 2.2)]), 12)
	lm.box("Glass", t + Vector3(0, 21.6, 0), Vector3(0.7, 0.9, 0.7), Basis(), 0.0)
	lm.spire("Copper", t + Vector3(0, 22.0, 0), 0.55, 3.2)
	LandmarkDetail.window(lm, "Trim", "Glass", t + Vector3(0, 13.5, 1.62), Vector3.BACK, 0.8, 2.4, true, 0.2)

static func _crown(lm: LandmarkMesh, mats: Dictionary) -> void:
	var c := Vector3(TX, 0, TZ)
	# Flared collar, four corner pinnacles and the gargoyle spouts at the cornice corners.
	lm.lathe("Dark", c + Vector3(0, SHAFT, 0), PackedVector2Array([Vector2(8.8, 0), Vector2(8.0, 0.8),
		Vector2(6.6, 3.4), Vector2(6.2, 4.4)]), 4, 1.0, 1.0, PI * 0.25, false)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := c + Vector3(float(sx) * 5.0, SHAFT + 0.9, float(sz) * 5.0)
			lm.frustum("Dark", p, 1.1, 0.95, 6.5, 8, PI / 8.0)
			lm.frustum("Trim", p + Vector3(0, 6.5, 0), 1.2, 1.2, 0.3, 8, PI / 8.0)
			lm.lathe("Dark", p + Vector3(0, 6.8, 0), PackedVector2Array([Vector2(1.1, 0), Vector2(0.55, 4.5),
				Vector2(0.15, 8.0)]), 8, 1.0, 1.0, PI / 8.0, false)
			lm.lathe("Gilt", p + Vector3(0, 14.8, 0), LandmarkFhUtil.ball(0.2), 6)
			var gd := Vector3(float(sx), 0, float(sz)).normalized()
			lm.beam("Dark", c + Vector3(float(sx) * 6.3, SHAFT - 0.6, float(sz) * 6.3),
				c + Vector3(float(sx) * 6.3, SHAFT - 1.3, float(sz) * 6.3) + gd * 2.8, 0.4, 0.3)
			lm.box("Dark", c + Vector3(float(sx) * 6.3, SHAFT - 1.4, float(sz) * 6.3) + gd * 2.9, Vector3(0.5, 0.5, 0.7),
				Basis(Vector3.UP, atan2(gd.x, gd.z)), 0.0)
	# Clock and louvre stage.
	var y0 := SHAFT + 4.4
	lm.box("Dark", c + Vector3(0, y0 + 3.4, 0), Vector3(8.4, 6.8, 8.4))
	var louvre := StoChurchKit.lancet_unit(mats, 1.5, 3.4, 0.25, false)
	for d in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
		var out: Vector3 = d
		var side := Vector3.UP.cross(out)
		StoChurchKit.place(lm, louvre, c + out * 4.2 + side * 1.9 + Vector3(0, y0 + 0.6, 0), out)
		StoChurchKit.place(lm, louvre, c + out * 4.2 - side * 1.9 + Vector3(0, y0 + 0.6, 0), out)
		StoChurchKit.clock(lm, c + out * 4.2 + Vector3(0, y0 + 4.7, 0), out, 1.2)
	lm.box("Trim", c + Vector3(0, y0 + 6.95, 0), Vector3(9.2, 0.3, 9.2))
	# Open octagonal lantern behind a balustrade, bell cap and needle spire.
	var yl := y0 + 7.1
	lm.frustum("Trim", c + Vector3(0, yl, 0), 4.3, 4.1, 1.0, 8, PI / 8.0)
	lm.frustum("Dark", c + Vector3(0, yl + 1.0, 0), 3.5, 3.3, 5.6, 8, PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0 + PI / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.window(lm, "Trim", "Glass", c + d * 3.1 + Vector3(0, yl + 3.4, 0), d, 1.2, 3.4, true, 0.2)
	var yb := yl + 6.6
	lm.frustum("Trim", c + Vector3(0, yb, 0), 3.7, 3.7, 0.3, 8, PI / 8.0)
	lm.lathe("Dark", c + Vector3(0, yb + 0.3, 0), PackedVector2Array([Vector2(3.5, 0), Vector2(3.9, 0.6), Vector2(3.2, 1.8),
		Vector2(1.9, 3.2), Vector2(1.1, 4.2), Vector2(1.35, 4.8), Vector2(0.8, 5.4), Vector2(0.5, 6.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	var ys := yb + 6.3
	var tip := 94.0
	lm.lathe("Copper", c + Vector3(0, ys, 0), PackedVector2Array([Vector2(0.9, 0), Vector2(0.7, 7.0),
		Vector2(0.4, 15.0), Vector2(0.2, tip - ys)]), 8, 1.0, 1.0, PI / 8.0, false)
	StoChurchKit.finial(lm, c + Vector3(0, tip, 0), 0.25, 2.0)
