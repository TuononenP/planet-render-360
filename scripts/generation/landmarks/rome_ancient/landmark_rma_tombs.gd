class_name LandmarkRmATombs
extends RefCounted

## The Mausoleum of Augustus, the Ara Pacis in its museum pavilion and the
## Tomb of Caecilia Metella, in true metres.

# --- Mausoleum of Augustus ----------------------------------------------

## The 87 m drum as it stands: three broken concentric brick rings tied by
## radial walls over the paved ambulatory floor, the entrance passage
## toward +Z, and the grassed core mound (14 m) that carried the cypresses
## and the bronze Augustus.
static func mausoleum(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8F6548", 2.5))
	lm.use("Opus", LandmarkMaterials.pbr("concrete", "#9A8C74", 3.0))
	lm.use("Lawn", LandmarkMaterials.pbr("lawn", "#6B7A47", 4.0))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#A39981", 3.0))
	lm.use("Travertine", LandmarkMaterials.pbr("limestone", "#C4B592", 3.0))
	lm.disc("Paving", Vector3(0, 0.05, 0), Vector3.UP, 43.0, 48)
	_ring(lm, "Brick", 41.7, 4.4, 56, 7.0, 12.4, 0.9)
	_ring(lm, "Opus", 31.5, 3.2, 44, 8.0, 11.0, 0.9)
	_ring(lm, "Brick", 21.5, 3.0, 34, 9.0, 12.0, 0.9)
	for i in 14:
		var a := TAU * (float(i) + 0.5) / 14.0
		if absf(wrapf(a - PI * 0.5, -PI, PI)) < 0.3:
			continue
		RmAUtil.ruin_wall(lm, "Opus", Vector3(cos(a) * 13.0, 0, sin(a) * 13.0), Vector3(cos(a) * 40.0, 0, sin(a) * 40.0),
			1.8, 0.0, 4.5, 9.0, 4.0, float(i))
	# Core drum and its grassed mound.
	lm.lathe("Brick", Vector3.ZERO, PackedVector2Array([Vector2(12.6, 0), Vector2(12.6, 9.0)]), 32)
	lm.lathe("Lawn", Vector3(0, 9.0, 0), PackedVector2Array([Vector2(12.9, 0), Vector2(11.0, 2.2),
		Vector2(7.5, 4.0), Vector2(3.5, 4.8), Vector2(0, 5.0)]), 32)
	# Entrance passage: two parallel walls through the rings.
	for sx in [-1.0, 1.0]:
		lm.box("Travertine", Vector3(sx * 3.4, 5.0, 28.0), Vector3(1.6, 10.0, 34.0))
	lm.box("Travertine", Vector3(0, 10.4, 40.0), Vector3(8.2, 0.8, 6.0))
	lm.commit(model)

## Ring of broken wall: `n` straight segments at radius r, crown height
## between hmin and hmax (highest toward the north), a gap at the entrance.
static func _ring(lm: LandmarkMesh, key: String, r: float, thick: float, n: int, hmin: float,
		hmax: float, jitter: float) -> void:
	for i in n:
		var a0 := TAU * float(i) / float(n)
		var a1 := TAU * float(i + 1) / float(n)
		var am := (a0 + a1) * 0.5
		if absf(wrapf(am - PI * 0.5, -PI, PI)) < 0.12 * 41.7 / r:
			continue
		var h := hmin + (hmax - hmin) * (0.5 - 0.5 * sin(am)) - jitter * absf(sin(float(i) * 12.9898))
		RmAUtil.seg_box(lm, key, Vector3(cos(a0) * r, 0, sin(a0) * r), Vector3(cos(a1) * r, 0, sin(a1) * r),
			thick, 0.0, maxf(h, hmin * 0.6))

# --- Ara Pacis ------------------------------------------------------------

## The Altar of Augustan Peace (13-9 BC) under Richard Meier's 2006
## museum: the white marble precinct (11.65 x 10.6 m, 3.7 m walls with
## the acanthus and procession friezes, east and west doors, stepped
## altar), inside a glass hall with travertine piers, the Res Gestae wall
## along the Tiber side and the deep cantilevered roof slab. Long axis
## along Z; yaw_deg 6 turns it onto the Lungotevere.
static func ara_pacis(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E0D9C9", 3.0))
	lm.use("Relief", LandmarkMaterials.pbr("limestone", "#B8AE98", 2.0))
	lm.use("Travertine", LandmarkMaterials.pbr("limestone", "#CBBE9F", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2E3A40"))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4B4237", 3.0))
	lm.box("Travertine", Vector3(0, 0.3, 4.0), Vector3(30.0, 0.6, 78.0))
	# Glass hall: long glass walls with travertine mullions, solid north end.
	for sx in [-1.0, 1.0]:
		lm.box("Glass", Vector3(sx * 9.5, 5.4, -1.0), Vector3(0.2, 9.6, 50.0))
		for k in 11:
			lm.box("Travertine", Vector3(sx * 9.6, 5.4, -26.0 + 5.0 * float(k)), Vector3(0.4, 9.6, 0.6))
	lm.box("Glass", Vector3(0, 5.4, 24.0), Vector3(19.0, 9.6, 0.2))
	lm.box("Travertine", Vector3(0, 5.7, -26.6), Vector3(21.0, 10.2, 1.2))
	# Res Gestae wall on the Tiber side and the entrance piers.
	lm.box("Travertine", Vector3(-13.4, 5.9, 4.0), Vector3(1.6, 11.8, 64.0))
	lm.box("Relief", Vector3(-12.55, 6.2, 4.0), Vector3(0.1, 6.0, 40.0))
	for px in [-9.0, -3.0, 3.0, 9.0]:
		lm.box("Travertine", Vector3(px, 5.4, 37.0), Vector3(1.6, 10.8, 1.6))
	# Roof slab, cantilevered far over the entrance.
	lm.box("Travertine", Vector3(-1.0, 11.4, 4.0), Vector3(30.0, 1.2, 76.0))
	# The altar precinct inside the hall.
	var az := -2.0
	lm.box("Marble", Vector3(0, 1.0, az), Vector3(12.4, 0.8, 11.2))
	for sz in [-1.0, 1.0]:
		lm.box("Marble", Vector3(0, 2.65, az + sz * 5.0), Vector3(11.65, 3.7, 0.6))
		lm.box("Relief", Vector3(0, 1.9, az + sz * 5.34), Vector3(10.4, 1.7, 0.1))
		lm.box("Relief", Vector3(0, 3.6, az + sz * 5.34), Vector3(10.4, 1.2, 0.1))
		for sx in [-1.0, 1.0]:
			lm.box("Marble", Vector3(sx * 5.5, 2.65, az + sz * 3.4), Vector3(0.6, 3.7, 3.7))
			lm.box("Relief", Vector3(sx * 5.84, 2.7, az + sz * 3.4), Vector3(0.1, 2.6, 3.2))
	lm.box("Marble", Vector3(0, 1.6, az), Vector3(6.6, 0.8, 5.2))
	lm.box("Marble", Vector3(0, 2.6, az), Vector3(4.4, 1.2, 3.3))
	SEuUtil.steps_up(lm, "Marble", Vector3(-3.3, 0.8, az), Vector3.LEFT, 3.0, 0.5, 0.2, 4)
	lm.commit(model)

# --- Tomb of Caecilia Metella -------------------------------------------

## The Via Appia tomb: a square travertine podium (8.3 m), the 29.5 m
## drum rising 12 m with its festoon-and-bucrania frieze and inscription,
## the Caetani battlements (21.7 m in all), and the brick castle block
## and corner tower of the Castrum Caetani behind. Front toward +Z.
static func caecilia(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Travertine", LandmarkMaterials.pbr("limestone", "#C0B08C", 3.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#D6CDB8", 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#94694D", 2.5))
	lm.use("Tuff", LandmarkMaterials.pbr("stone", "#9B8D74", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4B4237", 3.0))
	lm.box("Travertine", Vector3(0, 4.15, 0), Vector3(30.4, 8.3, 30.4))
	lm.box("Marble", Vector3(0, 8.5, 0), Vector3(31.0, 0.4, 31.0))
	lm.frustum("Travertine", Vector3(0, 8.7, 0), 14.8, 14.75, 11.6, 40)
	lm.frustum("Marble", Vector3(0, 17.4, 0), 14.9, 14.9, 2.4, 40)
	# Festoons and ox skulls on the frieze, the inscription tablet below.
	for i in 24:
		var a := TAU * (float(i) + 0.5) / 24.0
		lm.box("Shadow", Vector3(cos(a) * 14.95, 18.4, sin(a) * 14.95), Vector3(0.3, 1.4, 1.1), Basis(Vector3.UP, -a))
	lm.box("Marble", Vector3(0, 13.5, 14.85), Vector3(4.2, 2.2, 0.2))
	lm.box("Shadow", Vector3(0, 13.5, 14.96), Vector3(3.4, 1.4, 0.1))
	RmAUtil.merlons_ring(lm, "Tuff", Vector3.ZERO, 14.4, 20.3, 26, 1.4, 1.4, 1.0)
	# Castrum Caetani: brick block and a corner tower behind the drum.
	lm.box("Brick", Vector3(0, 6.0, -24.0), Vector3(30.0, 12.0, 14.0))
	lm.box("Tuff", Vector3(0, 12.3, -24.0), Vector3(30.8, 0.6, 14.8))
	for sx in [-1.0, 1.0]:
		for k in 5:
			lm.box("Brick", Vector3(sx * 14.8, 13.2, -24.0 + 3.0 * float(k) - 6.0), Vector3(1.0, 1.2, 1.4))
	lm.box("Brick", Vector3(-10.0, 8.0, -33.0), Vector3(7.0, 16.0, 7.0))
	lm.box("Tuff", Vector3(-10.0, 16.3, -33.0), Vector3(7.8, 0.6, 7.8))
	for k in 4:
		lm.box("Brick", Vector3(-10.0 + (-2.6 + 1.7 * float(k)), 17.2, -36.6), Vector3(1.1, 1.2, 1.0))
	lm.commit(model)
