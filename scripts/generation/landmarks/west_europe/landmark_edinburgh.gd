class_name LandmarkEdinburgh
extends RefCounted

## Edinburgh Castle in true metres, y = 0 on the summit platform (Crown
## Square) with the volcanic crag and the lower works built below it.

## Edinburgh Castle (26 m above the summit platform): the basalt crag,
## the curtain wall on the cliff edge with its batteries and cannon;
## Crown Square — the Royal Palace (east) with its 1616 octagonal stair
## tower and the ogee-capped corner tower, the Great Hall (south, 1511)
## with its tall windows, the Scottish National War Memorial (north,
## 1927) with its apsidal shrine, porch and statues, the Queen Anne
## Building (west); St Margaret's Chapel (c. 1130) by Mons Meg; the
## seven-storey New Barracks on the west; the crow-stepped Governor's
## House; the Argyle Tower over the Portcullis Gate; the Half Moon
## Battery; and the 1888 Gatehouse to the Esplanade (east, +X) with
## Wallace and Bruce in their niches.
static func edinburgh_castle(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Rock", LandmarkMaterials.pbr("cliff", "#7A7466", 4.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#9A917F", 3.0))
	lm.use("Slate", LandmarkMaterials.pbr("slate", "#4F575C", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#20262A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Iron", LandmarkMaterials.paint("#2A2C2E", 0.6, 0.4))
	LandmarkWestEarly.crag(lm, "Rock", PackedVector2Array([Vector2(100, -60), Vector2(94, -46), Vector2(88, -35),
		Vector2(83, -22), Vector2(78, -12), Vector2(73, -5), Vector2(68, 0)]), 32, 0.07, 1.6, 1.0, 11)
	_curtain(lm)
	_crown_square(lm)
	_outworks(lm)
	lm.commit(model)

## Curtain wall following the plateau edge, round towers every fourth
## post, gun embrasures with cannon on the north batteries.
static func _curtain(lm: LandmarkMesh) -> void:
	var n := 24
	for k in n:
		var a0 := TAU * float(k) / float(n)
		var a1 := TAU * float(k + 1) / float(n)
		var p0 := Vector3(cos(a0) * 104.0, 0, sin(a0) * 65.0)
		var p1 := Vector3(cos(a1) * 104.0, 0, sin(a1) * 65.0)
		var d := p1 - p0
		var out := Vector3(d.z, 0, -d.x).normalized()
		if out.dot(p0 + p1) < 0.0:
			out = -out
		lm.box("Stone", (p0 + p1) * 0.5 + Vector3(0, -1.0, 0), Vector3(3.0, 21.0, d.length()),
			Basis(Vector3.UP, atan2(d.x, d.z)))
		LandmarkWestKit.merlons(lm, "Stone", p0 + Vector3(0, 9.5, 0), p1 + Vector3(0, 9.5, 0), 2.4, 1.2, 1.0, 2.6)
		# Corbelled string course under the parapet.
		lm.beam("Stone", p0 + out * 1.7 + Vector3(0, 9.0, 0), p1 + out * 1.7 + Vector3(0, 9.0, 0), 0.6, 0.5)
		if k % 4 == 0:
			lm.frustum("Stone", p0 - Vector3(0, 12, 0), 4.8, 4.2, 26.0, 16)
			lm.frustum("Stone", p0 + Vector3(0, 14, 0), 4.6, 4.6, 0.6, 16)
			lm.lathe("Slate", p0 + Vector3(0, 14.6, 0), LandmarkWestKit.ogee_prof(4.6, 4.2), 16)
		# Cannon on the north batteries (Argyle and Mills Mount).
		if sin(a0) < -0.5:
			for c in 2:
				var p := p0.lerp(p1, 0.25 + 0.5 * float(c)) - out * 2.6 + Vector3(0, 8.6, 0)
				lm.beam("Iron", p - out * 1.4, p + out * 1.6, 0.45, 0.45)
				lm.box("Stone", p - out * 1.0 - Vector3(0, 0.4, 0), Vector3(1.4, 0.5, 1.8), Basis.looking_at(out), 0.0)

## Crown Square and its four ranges, St Margaret's Chapel, Mons Meg.
static func _crown_square(lm: LandmarkMesh) -> void:
	var rot := Basis(Vector3.UP, PI * 0.5)
	# Royal Palace (east): four storeys, dormers, chimneys, towers.
	LandmarkWestKit.blk(lm, "Stone", 18.0, 0, 0, 14.0, 17.0, 30.0)
	LandmarkWestKit.hip(lm, "Slate", Vector3(18.0, 17.0, 0), 15.0, 31.0, 5.0, 0.8)
	LandmarkDetail.pierced_face(lm, "Stone", "Glass", Vector3(11.0, 0, 15.0), Vector3(0, 0, -1), Vector3(-1, 0, 0), 30.0, 17.0,
		7, 3, Vector2(1.3, 2.4), 2.4, 4.8, 0.35)
	LandmarkDetail.pierced_face(lm, "Stone", "Glass", Vector3(25.0, 0, -15.0), Vector3(0, 0, 1), Vector3(1, 0, 0), 30.0, 17.0,
		6, 3, Vector2(1.3, 2.4), 2.4, 4.8, 0.35)
	for k in 4:
		LandmarkWestKit.dormer(lm, "Stone", "Slate", "Glass", Vector3(10.6, 17.4, -9.0 + 6.0 * float(k)), Vector3(-1, 0, 0),
			1.6, 2.6, 1.8)
	for z in [-12.0, 12.0]:
		LandmarkWestKit.chimney(lm, "Stone", Vector3(18.0, 19.0, z), 1.6, 3.4, 4.0)
	LandmarkWestKit.blk(lm, "Stone", 18.0, 0, -17.0, 7.0, 20.0, 7.0)
	LandmarkWestKit.merlons(lm, "Stone", Vector3(14.5, 20.0, -20.5), Vector3(21.5, 20.0, -20.5), 1.4, 0.7, 0.8, 0.5)
	lm.frustum("Stone", Vector3(18.0, 20.0, -17.0), 1.8, 1.8, 2.2, 10)
	lm.lathe("Slate", Vector3(18.0, 22.2, -17.0), LandmarkWestKit.ogee_prof(2.2, 3.4), 10)
	lm.lathe("Gilt", Vector3(18.0, 25.5, -17.0), LandmarkWestKit.ball(0.25), 6)
	# The 1616 octagonal stair tower on Crown Square with its lead cap.
	lm.frustum("Stone", Vector3(9.5, 0, 0), 3.2, 3.2, 19.0, 8, PI / 8.0)
	lm.lathe("Slate", Vector3(9.5, 19.0, 0), LandmarkWestKit.ogee_prof(3.5, 4.0), 8, 1.0, 1.0, PI / 8.0, false)
	lm.box("Gilt", Vector3(6.4, 12.5, 0), Vector3(0.15, 2.2, 1.8), Basis(), 0.0)
	for k in 4:
		lm.box("Glass", Vector3(6.4, 3.5 + 3.8 * float(k), 0), Vector3(0.08, 1.2, 0.6), Basis(Vector3.UP, 0.0), 0.0)
	# Great Hall (south): crenellated wall-head, tall windows both sides.
	LandmarkWestKit.blk(lm, "Stone", -2.0, 0, 17.0, 36.0, 12.0, 12.0)
	lm.gable("Slate", Vector3(-2.0, 12.0, 17.0), 12.0, 36.0, 8.0, rot, 0.6, "Stone")
	for sz in [-1.0, 1.0]:
		var nz := Vector3(0, 0, sz)
		for k in 6:
			LandmarkDetail.window(lm, "Stone", "Glass", Vector3(-15.0 + 5.2 * float(k), 7.0, 17.0 + sz * 6.0), nz, 1.6,
				4.2, true, 0.25)
	_crow_steps(lm, Vector3(-20.0, 12.0, 17.0), Vector3(0, 0, 1), 12.0, 8.0)
	_crow_steps(lm, Vector3(16.0, 12.0, 17.0), Vector3(0, 0, 1), 12.0, 8.0)
	# Scottish National War Memorial (north): battlemented Gothic hall,
	# apsidal shrine, gabled porch with statues on Crown Square.
	LandmarkWestKit.blk(lm, "Stone", 0, 0, -17.0, 30.0, 12.0, 10.0)
	lm.gable("Slate", Vector3(0, 12.0, -17.0), 10.0, 30.0, 6.0, rot, 0.6, "Stone")
	LandmarkWestKit.merlons(lm, "Stone", Vector3(-15, 12.0, -12.2), Vector3(15, 12.0, -12.2), 1.6, 0.8, 1.0, 0.5)
	LandmarkWestKit.merlons(lm, "Stone", Vector3(-15, 12.0, -21.8), Vector3(15, 12.0, -21.8), 1.6, 0.8, 1.0, 0.5)
	for k in 6:
		var x := -12.5 + 5.0 * float(k)
		if absf(x) > 3.0:
			LandmarkWestKit.lancet(lm, "Stone", "Glass", Vector3(x, 3.0, -12.0), Vector3(0, 0, 1), 1.6, 6.0, true)
		LandmarkWestKit.pinnacle(lm, "Stone", Vector3(x - 2.5, 12.0, -11.8), 0.35, 2.4)
	lm.frustum("Stone", Vector3(0, 0, -22.0), 6.0, 6.0, 13.0, 10)
	lm.lathe("Slate", Vector3(0, 13.0, -22.0), PackedVector2Array([Vector2(6.4, 0), Vector2(0.0, 5.0)]), 10)
	for k in 5:
		var a := PI + PI * (float(k) + 0.5) / 5.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkWestKit.lancet(lm, "Stone", "Glass", Vector3(0, 3.0, -22.0) + d * 6.0, d, 1.6, 7.0, true)
	LandmarkWestKit.blk(lm, "Stone", 0, 0, -11.0, 7.0, 10.0, 3.0)
	lm.gable("Stone", Vector3(0, 10.0, -11.0), 7.0, 3.0, 3.5, Basis(), 0.3, "Stone")
	LandmarkWestKit.portal(lm, "Stone", "Glass", Vector3(0, 0, -9.5), Vector3(0, 0, 1), 2.4, 6.0, 3, true)
	for x in [-2.6, 2.6]:
		LandmarkWestKit.figure(lm, "Stone", Vector3(x, 6.6, -9.3), 1.8)
	LandmarkKits.statue_figure(lm, "Stone", Vector3(0, 13.4, -11.0), 2.0, true)
	# Queen Anne Building (west).
	LandmarkWestKit.blk(lm, "Stone", -20.0, 0, 0, 10.0, 15.0, 30.0)
	LandmarkWestKit.hip(lm, "Slate", Vector3(-20.0, 15.0, 0), 11.0, 31.0, 4.0, 0.7)
	LandmarkDetail.pierced_face(lm, "Stone", "Glass", Vector3(-15.0, 0, -15.0), Vector3(0, 0, 1), Vector3(1, 0, 0), 30.0, 15.0,
		8, 3, Vector2(1.2, 2.2), 1.6, 4.6, 0.3)
	for z in [-10.0, 0.0, 10.0]:
		LandmarkWestKit.chimney(lm, "Stone", Vector3(-20.0, 16.5, z), 1.2, 2.6, 2.6)
	LandmarkWestKit.blk(lm, "Stone", 0, 0, 0, 22.0, 0.1, 22.0)
	# St Margaret's Chapel (c. 1130) and Mons Meg on its carriage.
	var sm := Vector3(10.0, 0, -36.0)
	LandmarkWestKit.blk(lm, "Stone", sm.x, 0, sm.z, 10.0, 4.0, 5.5)
	lm.gable("Slate", sm + Vector3(0, 4.0, 0), 5.5, 10.0, 3.0, rot, 0.3, "Stone")
	for x in [-2.5, 0.0, 2.5]:
		LandmarkDetail.window(lm, "Stone", "Glass", sm + Vector3(x, 2.0, 2.75), Vector3(0, 0, 1), 0.5, 1.2, true, 0.15)
	LandmarkWestKit.portal(lm, "Stone", "Glass", sm + Vector3(-5.0, 0, 0), Vector3(-1, 0, 0), 1.0, 2.6, 2, false)
	var mm := sm + Vector3(12.0, 0, -4.0)
	LandmarkWestKit.blk(lm, "Stone", mm.x, 0, mm.z, 2.0, 0.9, 5.0)
	LandmarkWestKit.tube(lm, "Iron", mm + Vector3(0, 1.4, -2.0), mm + Vector3(0, 1.6, 2.3), 0.62, 12)
	for s in [-1.0, 1.0]:
		lm.lathe("Iron", mm + Vector3(s * 0.9, 0.9, -1.0), PackedVector2Array([Vector2(0.6, 0), Vector2(0.6, 0.15)]), 10)

## Crow-stepped gable end on a wall top: `c` the gable's foot centre,
## facing n, w wide, h tall.
static func _crow_steps(lm: LandmarkMesh, c: Vector3, n: Vector3, w: float, h: float) -> void:
	var r := Vector3.UP.cross(n.normalized()).normalized()
	var steps := 6
	for i in steps:
		var t := float(i) / float(steps)
		var y := h * t
		var half := w * 0.5 * (1.0 - t)
		for s in [-1.0, 1.0]:
			lm.box("Stone", c + r * float(s) * (half - 0.45) + Vector3(0, y + h / float(steps) * 0.5, 0),
				Vector3(0.9, h / float(steps), 0.8), Basis.looking_at(n), 0.0)
	lm.box("Stone", c + Vector3(0, h + 0.5, 0), Vector3(0.9, 1.0, 0.8), Basis.looking_at(n), 0.0)

## New Barracks, Governor's House, Argyle Tower and the Portcullis Gate,
## Half Moon Battery, the Gatehouse.
static func _outworks(lm: LandmarkMesh) -> void:
	# New Barracks (1799): long seven-storey block down the west slope.
	var nb := Vector3(-58.0, -14.0, 30.0)
	LandmarkWestKit.blk(lm, "Stone", nb.x, nb.y, nb.z, 64.0, 26.0, 14.0)
	lm.box("Slate", Vector3(nb.x, nb.y + 26.3, nb.z), Vector3(63.0, 0.6, 13.0))
	LandmarkDetail.pierced_face(lm, "Stone", "Glass", Vector3(nb.x - 32.0, nb.y, nb.z + 7.0), Vector3(1, 0, 0),
		Vector3(0, 0, 1), 64.0, 26.0, 21, 7, Vector2(1.2, 2.0), 1.2, 3.5, 0.3)
	LandmarkDetail.cornice(lm, "Stone", Vector3(nb.x - 32.0, nb.y + 25.0, nb.z + 7.0), Vector3(nb.x + 32.0, nb.y + 25.0, nb.z + 7.0),
		Vector3(0, 0, 1), 0.9, false)
	# Governor's House (1742) with crow-stepped gables.
	var gh := Vector3(-30.0, 0, -32.0)
	LandmarkWestKit.blk(lm, "Stone", gh.x, 0, gh.z, 22.0, 11.0, 9.0)
	lm.gable("Slate", gh + Vector3(0, 11.0, 0), 9.0, 22.0, 5.0, Basis(Vector3.UP, PI * 0.5), 0.2)
	for s in [-1.0, 1.0]:
		_crow_steps(lm, gh + Vector3(s * 11.0, 11.0, 0), Vector3(s, 0, 0), 9.0, 5.0)
		LandmarkWestKit.chimney(lm, "Stone", gh + Vector3(s * 10.6, 16.0, 0), 1.0, 2.2, 1.6)
	LandmarkDetail.pierced_face(lm, "Stone", "Glass", gh + Vector3(-11.0, 0, 4.5), Vector3(1, 0, 0), Vector3(0, 0, 1), 22.0, 11.0,
		7, 3, Vector2(1.1, 1.9), 1.0, 3.4, 0.3)
	# Argyle Tower over the Portcullis Gate.
	var at := Vector3(48.0, 0, -38.0)
	LandmarkWestKit.blk(lm, "Stone", at.x, -6.0, at.z, 12.0, 21.0, 10.0)
	lm.gable("Slate", at + Vector3(0, 15.0, 0), 10.0, 12.0, 6.0, Basis(Vector3.UP, PI * 0.5), 0.3, "Stone")
	for q in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
		var tp := at + Vector3(q.x * 6.0, 11.0, q.y * 5.0)
		lm.frustum("Stone", tp, 1.1, 1.1, 4.0, 10)
		lm.spire("Slate", tp + Vector3(0, 4.0, 0), 1.2, 3.4, 0.0, 10)
	LandmarkDetail.arch(lm, "Stone", at + Vector3(6.0, -3.0, 0), Vector3(1, 0, 0), 4.0, 0.7)
	lm.box("Iron", at + Vector3(6.05, -1.0, 0), Vector3(0.1, 4.0, 3.8), Basis(), 0.0)
	# Half Moon Battery (1570s) with its gun embrasures.
	lm.lathe("Stone", Vector3(62, -12, 0), PackedVector2Array([Vector2(16, 0), Vector2(15, 8), Vector2(15, 26)]), 20,
		1.0, 1.0, 0.0, false)
	lm.lathe("Stone", Vector3(62, 14, 0), PackedVector2Array([Vector2(15.5, 0), Vector2(15.5, 1.0)]), 20)
	for k in 9:
		var a := -PI * 0.45 + PI * 0.9 * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Stone", Vector3(62, 15.8, 0) + d * 14.8, Vector3(1.0, 1.6, 2.6), Basis.looking_at(d))
		lm.beam("Iron", Vector3(62, 15.6, 0) + d * 13.0, Vector3(62, 15.8, 0) + d * 16.0, 0.35, 0.35)
	# Gatehouse (1888) with Wallace and Bruce, drawbridge over the ditch.
	var g := Vector3(86.0, -10.0, 0)
	LandmarkWestKit.blk(lm, "Stone", g.x, g.y, g.z, 12.0, 26.0, 16.0)
	for s in [-1.0, 1.0]:
		lm.frustum("Stone", g + Vector3(6.0, 0, s * 8.0), 2.0, 2.0, 30.0, 12)
		LandmarkWestKit.merlons(lm, "Stone", g + Vector3(4.0, 30.0, s * 8.0 - 2.0), g + Vector3(8.0, 30.0, s * 8.0 + 2.0),
			1.2, 0.6, 0.8, 0.4)
		LandmarkKits.statue_figure(lm, "Stone", g + Vector3(6.4, 13.0, s * 4.8), 2.8)
		LandmarkDetail.arch(lm, "Stone", g + Vector3(6.0, 14.4, s * 4.8), Vector3(1, 0, 0), 1.8, 0.4)
	LandmarkWestKit.merlons(lm, "Stone", g + Vector3(6.0, 26.0, -6.0), g + Vector3(6.0, 26.0, 6.0), 1.6, 0.9, 1.0, 0.6)
	LandmarkDetail.arch(lm, "Stone", g + Vector3(6.0, 5.0, 0), Vector3(1, 0, 0), 5.0, 0.8)
	lm.box("Iron", g + Vector3(6.05, 3.0, 0), Vector3(0.1, 6.0, 4.6), Basis(), 0.0)
	lm.box("Iron", g + Vector3(12.0, 0.3, 0), Vector3(10.0, 0.4, 4.6), Basis(), 0.0)
	lm.box("Gilt", g + Vector3(6.15, 10.5, 0), Vector3(0.1, 1.6, 2.0), Basis(), 0.0)
