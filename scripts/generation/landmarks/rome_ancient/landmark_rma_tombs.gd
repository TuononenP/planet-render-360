class_name LandmarkRmATombs
extends RefCounted

## The Mausoleum of Augustus, the Ara Pacis in its museum pavilion and the
## Tomb of Caecilia Metella, in true metres.

# --- Mausoleum of Augustus ----------------------------------------------

## The 87 m drum as it stands after the 2021 restoration: the outer ring
## of opus reticulatum with the stumps of its travertine facing course,
## the radial walls dividing the outer annulus into chambers, the middle
## and inner rings pierced by their doorways, over the paved ambulatory
## floor; the entrance passage (dromos) toward +Z through a travertine
## portal flanked by the two piers that carried the bronze Res Gestae;
## and the grassed core mound (14 m) that carried the cypresses and the
## bronze Augustus.
static func mausoleum(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8F6548", 2.5))
	lm.use("Opus", LandmarkMaterials.pbr("concrete", "#9A8C74", 3.0))
	lm.use("Lawn", LandmarkMaterials.pbr("lawn", "#6B7A47", 4.0))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#A39981", 3.0))
	lm.use("Travertine", LandmarkMaterials.pbr("limestone", "#C4B592", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4B4237", 3.0))
	lm.use("Bronze", LandmarkMaterials.paint("#5E5A45", 0.5, 0.5))
	lm.disc("Paving", Vector3(0, 0.05, 0), Vector3.UP, 43.0, 64)
	_ring(lm, "Opus", 41.7, 4.4, 72, 7.0, 12.4, 0.9)
	# Travertine facing course left at the foot of the outer ring, with its
	# moulded plinth.
	for i in 72:
		var a0 := TAU * float(i) / 72.0
		var a1 := TAU * float(i + 1) / 72.0
		var am := (a0 + a1) * 0.5
		if absf(wrapf(am - PI * 0.5, -PI, PI)) < 0.14:
			continue
		var p0 := Vector3(cos(a0), 0, sin(a0)) * 44.1
		var p1 := Vector3(cos(a1), 0, sin(a1)) * 44.1
		var f := absf(sin(float(i) * 7.31))
		RmAUtil.seg_box(lm, "Travertine", p0, p1, 0.6, 0.0, 1.6 + 2.6 * f)
		RmAUtil.seg_box(lm, "Travertine", p0 * 1.006, p1 * 1.006, 0.5, 0.0, 0.5)
	# Middle and inner rings with their doorways (12 and 8), the
	# radial walls of the outer chambers.
	_door_ring(lm, "Brick", 31.5, 3.2, 12, 8.0, 11.0)
	_door_ring(lm, "Brick", 21.5, 3.0, 8, 9.0, 12.0)
	for i in 28:
		var a := TAU * (float(i) + 0.5) / 28.0
		if absf(wrapf(a - PI * 0.5, -PI, PI)) < 0.25:
			continue
		var d := Vector3(cos(a), 0, sin(a))
		RmAUtil.ruin_wall(lm, "Opus", d * 33.3, d * 39.4, 1.6, 0.0, 6.5, 10.5, 2.0, float(i))
	for i in 14:
		var a := TAU * (float(i) + 0.5) / 14.0
		if absf(wrapf(a - PI * 0.5, -PI, PI)) < 0.3:
			continue
		var d := Vector3(cos(a), 0, sin(a))
		RmAUtil.ruin_wall(lm, "Opus", d * 13.0, d * 19.8, 1.8, 0.0, 4.5, 9.0, 3.0, float(i) + 0.5)
		RmAUtil.ruin_wall(lm, "Opus", d * 23.2, d * 29.7, 1.8, 0.0, 5.0, 9.0, 3.0, float(i) + 0.7)
	# Core drum, its cornice and the grassed mound.
	lm.lathe("Brick", Vector3.ZERO, PackedVector2Array([Vector2(12.6, 0), Vector2(12.6, 9.0)]), 48)
	lm.lathe("Travertine", Vector3(0, 8.6, 0), PackedVector2Array([Vector2(12.6, 0), Vector2(12.85, 0.2),
		Vector2(12.95, 0.4), Vector2(12.9, 0.5)]), 48)
	lm.lathe("Lawn", Vector3(0, 9.0, 0), PackedVector2Array([Vector2(12.9, 0), Vector2(11.0, 2.2),
		Vector2(7.5, 4.0), Vector2(3.5, 4.8), Vector2(0, 5.0)]), 48)
	# Dromos: two walls through the rings under a barrel vault, the
	# travertine portal and the Res Gestae piers.
	for sx in [-1.0, 1.0]:
		lm.box("Travertine", Vector3(sx * 3.4, 3.5, 28.0), Vector3(1.6, 7.0, 34.0))
		lm.box("Travertine", Vector3(sx * 3.4, 7.2, 28.0), Vector3(1.9, 0.4, 34.0))
	RmAUtil.barrel_vault(lm, "Opus", "Shadow", Vector3(0, 7.0, 44.0), Vector3(0, 0, -1), Vector3.RIGHT,
		12.0, 5.2, 2.6, 0.8, 0, 0, 10)
	RmAUtil.arch_wall(lm, "Travertine", "Shadow", Vector3(0, 0, 45.0), Vector3.RIGHT, Vector3.BACK,
		-4.6, 4.6, 0.0, 10.8, [[0.0, 5.2, 7.0, 0.0]], 1.2, 10)
	LandmarkDetail.arch(lm, "Travertine", Vector3(0, 7.0, 45.0), Vector3.BACK, 5.2, 0.5, 0.2)
	LandmarkDetail.cornice(lm, "Travertine", Vector3(-4.6, 10.2, 45.0), Vector3(4.6, 10.2, 45.0), Vector3.BACK, 0.6, true)
	for sx in [-1.0, 1.0]:
		var pc := Vector3(sx * 9.0, 0, 47.5)
		RmADetail.pedestal(lm, "Travertine", pc, 2.4, 1.6, 4.4)
		RmADetail.panel(lm, "Travertine", "Bronze", pc + Vector3(0, 2.3, 0.8), Vector3.BACK, 1.8, 2.4, 0.04, 0.12)
		RmADetail.inscription(lm, "Shadow", pc + Vector3(0, 2.3, 0.85), Vector3.BACK, 1.6, 2.2, 10, sx)
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

## A ring wall at radius r with `doors` arched doorways (2.4 m wide)
## evenly round it, the dromos gap at +Z, crown hmin..hmax.
static func _door_ring(lm: RmAMesh, key: String, r: float, thick: float, doors: int, hmin: float,
		hmax: float) -> void:
	var span := TAU / float(doors)
	var gap := 2.0 / r
	for i in doors:
		var ad := PI * 0.5 + span * float(i)
		for k in 3:
			var t0 := ad + gap + (span - gap * 2.0) * float(k) / 3.0
			var t1 := ad + gap + (span - gap * 2.0) * float(k + 1) / 3.0
			var f := absf(sin(float(i * 3 + k) * 4.1 + r))
			RmAUtil.seg_box(lm, key, Vector3(cos(t0), 0, sin(t0)) * r, Vector3(cos(t1), 0, sin(t1)) * r,
				thick, 0.0, hmin + (hmax - hmin) * f)
		if i == 0:
			continue
		var out := Vector3(cos(ad), 0, sin(ad))
		lm.place(out.x * r, out.z * r, rad_to_deg(atan2(out.x, -out.z)))
		RmAUtil.arch_wall(lm, key, "Shadow", Vector3(0, 0, thick * 0.5), Vector3.RIGHT, Vector3.BACK,
			-2.0, 2.0, 0.0, hmin, [[0.0, 2.4, 2.4, 0.0]], thick, 8)
		lm.home()

# --- Ara Pacis ------------------------------------------------------------

## The Altar of Augustan Peace (13-9 BC) under Richard Meier's 2006
## museum: the white marble precinct (11.65 x 10.6 m) on its podium, its
## east and west doors with the stair up the west, fluted corner and door
## pilasters, the acanthus-scroll lower register under a meander band,
## the processions on the long sides and the four myth panels flanking
## the doors, garlands and bucrania inside, and the stepped altar with
## its volute wings; around it the glass hall on a fine mullion grid
## between travertine piers, the coffered skylight roof slab
## cantilevered over the entrance loggia, the travertine Res Gestae wall
## along the Lungotevere with the stair and the fountain. Long axis
## along Z; yaw_deg 6 turns it onto the Lungotevere.
static func ara_pacis(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E0D9C9", 3.0))
	lm.use("Relief", LandmarkMaterials.pbr("limestone", "#B8AE98", 2.0))
	lm.use("Travertine", LandmarkMaterials.pbr("limestone", "#CBBE9F", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2E3A40"))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4B4237", 3.0))
	lm.use("Render", LandmarkMaterials.pbr("render", "#E6E3DA", 3.0))
	lm.use("Steel", LandmarkMaterials.paint("#D8D8D4", 0.4, 0.4))
	lm.box("Travertine", Vector3(0, 0.3, 4.0), Vector3(30.0, 0.6, 78.0))
	# Glass hall: long glass walls on a mullion grid, solid north end.
	for sx in [-1.0, 1.0]:
		lm.box("Glass", Vector3(sx * 9.5, 5.4, -1.0), Vector3(0.12, 9.6, 50.0), Basis(), 0.0)
		for k in 41:
			lm.box("Steel", Vector3(sx * 9.6, 5.4, -26.0 + 1.25 * float(k)), Vector3(0.12, 9.6, 0.1), Basis(), 0.0)
		for y in [3.2, 6.4]:
			lm.box("Steel", Vector3(sx * 9.6, float(y), -1.0), Vector3(0.12, 0.1, 50.0), Basis(), 0.0)
		for k in 11:
			lm.box("Travertine", Vector3(sx * 9.75, 5.4, -26.0 + 5.0 * float(k)), Vector3(0.4, 9.6, 0.6))
	lm.box("Glass", Vector3(0, 5.4, 24.0), Vector3(19.0, 9.6, 0.12), Basis(), 0.0)
	for k in 16:
		lm.box("Steel", Vector3(-9.375 + 1.25 * float(k), 5.4, 24.1), Vector3(0.1, 9.6, 0.12), Basis(), 0.0)
	for y in [3.2, 6.4]:
		lm.box("Steel", Vector3(0, float(y), 24.1), Vector3(19.0, 0.1, 0.12), Basis(), 0.0)
	LandmarkDetail.pierced_face(lm, "Render", "Glass", Vector3(-10.5, 0.6, -27.2), Vector3.RIGHT, Vector3.FORWARD,
		21.0, 10.2, 6, 2, Vector2(1.6, 2.6), 1.4, 4.6, 0.4)
	lm.box("Travertine", Vector3(0, 5.7, -26.6), Vector3(21.0, 10.2, 1.2))
	# Res Gestae wall on the Tiber side with its inscription, the entrance
	# loggia piers, the stair and the fountain basin.
	lm.box("Travertine", Vector3(-13.4, 5.9, 4.0), Vector3(1.6, 11.8, 64.0))
	RmADetail.inscription(lm, "Shadow", Vector3(-12.6, 6.2, 4.0), Vector3.RIGHT, 40.0, 6.0, 12, 2.0)
	for k in 13:
		lm.box("Travertine", Vector3(-12.55, 0.9 + 0.9 * float(k), 4.0), Vector3(0.1, 0.04, 64.0), Basis(), 0.0)
	for px in [-9.0, -3.0, 3.0, 9.0]:
		lm.box("Travertine", Vector3(px, 5.4, 37.0), Vector3(1.6, 10.8, 1.6))
		lm.box("Travertine", Vector3(px, 0.75, 37.0), Vector3(2.0, 0.3, 2.0))
	SEuUtil.steps_up(lm, "Travertine", Vector3(0, 0, 43.0), Vector3.BACK, 18.0, 0.4, 0.15, 4)
	lm.box("Travertine", Vector3(7.5, 0.9, 30.0), Vector3(7.0, 0.6, 4.0))
	lm.box("Glass", Vector3(7.5, 1.15, 30.0), Vector3(6.4, 0.1, 3.4), Basis(), 0.0)
	# Roof slab, its edge fascia and the coffered skylight grid over the hall.
	lm.box("Render", Vector3(-1.0, 11.4, 4.0), Vector3(30.0, 1.2, 76.0))
	lm.box("Render", Vector3(-1.0, 11.95, 4.0), Vector3(30.4, 0.1, 76.4), Basis(), 0.0)
	for i in 5:
		for j in 16:
			lm.box("Glass", Vector3(-6.0 + 3.0 * float(i), 12.02, -22.0 + 3.0 * float(j)), Vector3(2.2, 0.06, 2.2), Basis(), 0.0)
	for i in 6:
		lm.box("Steel", Vector3(-7.5 + 3.0 * float(i), 10.6, -1.0), Vector3(0.3, 0.4, 48.0), Basis(), 0.0)
	_altar(lm, -2.0)
	lm.commit(model)

## The marble altar precinct centred at z = az on the hall floor (0.6 m):
## podium, walls with doors east and west (+/-X), pilasters, registers,
## cornice; garlands inside; the altar and its stair.
static func _altar(lm: RmAMesh, az: float) -> void:
	var fy := 0.6
	lm.box("Marble", Vector3(0, fy + 0.4, az), Vector3(12.4, 0.8, 11.2))
	var top := fy + 0.8
	var wh := 3.7
	var hx := 5.5
	var hz := 5.0
	# Long walls (N and S, solid) and the door walls (E and W).
	for sz in [-1.0, 1.0]:
		lm.box("Marble", Vector3(0, top + wh * 0.5, az + sz * hz), Vector3(11.65, wh, 0.6))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Marble", Vector3(sx * hx, top + wh * 0.5, az + sz * 3.4), Vector3(0.6, wh, 3.7))
		lm.box("Marble", Vector3(sx * hx, top + wh - 0.25, az), Vector3(0.6, 0.5, 3.2))
	var faces := [[Vector3(0, 0, 1), hz + 0.3, 5.8], [Vector3(0, 0, -1), hz + 0.3, 5.8],
		[Vector3(1, 0, 0), hx + 0.3, 5.3], [Vector3(-1, 0, 0), hx + 0.3, 5.3]]
	for f in faces:
		var n: Vector3 = f[0]
		var off: float = f[1]
		var half: float = f[2]
		var right := Vector3.UP.cross(n)
		var c := Vector3(0, top, az) + n * off
		# Base moulding, meander band, cornice.
		lm.box("Marble", c + Vector3(0, 0.15, 0) + n * 0.06, Vector3(half * 2.0, 0.3, 0.12) if absf(n.z) > 0.5 else Vector3(0.12, 0.3, half * 2.0), Basis(), 0.0)
		lm.box("Relief", c + Vector3(0, 1.9, 0) + n * 0.04, Vector3(half * 2.0, 0.22, 0.08) if absf(n.z) > 0.5 else Vector3(0.08, 0.22, half * 2.0), Basis(), 0.0)
		LandmarkDetail.cornice(lm, "Marble", c + Vector3(0, wh - 0.35, 0) - right * half,
			c + Vector3(0, wh - 0.35, 0) + right * half, n, 0.35, true)
		# Fluted pilasters at the corners (and either side of the doors).
		var pxs: Array = [-half + 0.3, half - 0.3]
		if absf(n.x) > 0.5:
			pxs.append_array([-1.9, 1.9])
		for px in pxs:
			lm.box("Marble", c + right * float(px) + Vector3(0, wh * 0.5, 0) + n * 0.08,
				Vector3(0.5, wh - 0.3, 0.16) if absf(n.z) > 0.5 else Vector3(0.16, wh - 0.3, 0.5))
			for fl in 3:
				lm.box("Relief", c + right * (float(px) + (float(fl) - 1.0) * 0.13) + Vector3(0, wh * 0.5, 0) + n * 0.17,
					Vector3(0.05, wh - 0.8, 0.03) if absf(n.z) > 0.5 else Vector3(0.03, wh - 0.8, 0.05), Basis(), 0.0)
		# Lower register: the acanthus scrolls.
		var spans: Array = []
		if absf(n.x) > 0.5:
			spans = [[-half + 0.6, -2.2], [2.2, half - 0.6]]
		else:
			spans = [[-half + 0.6, half - 0.6]]
		for sp in spans:
			var x0: float = sp[0]
			var x1: float = sp[1]
			var count := maxi(int((x1 - x0) / 0.85), 1)
			for i in count:
				var x := x0 + (x1 - x0) * (float(i) + 0.5) / float(count)
				var sc := c + right * x + Vector3(0, 0.95 + 0.25 * float(i % 2), 0) + n * 0.02
				RmADetail.ring_frame(lm, "Relief", sc, n, 0.32, 0.07, 0.07, 8)
				lm.disc("Relief", sc + n * 0.08, n, 0.1, 6)
			# Upper register: procession (long sides) or a myth panel.
			if absf(n.z) > 0.5:
				RmADetail.figure_row(lm, "Relief", c + right * x0 + Vector3(0, 2.05, 0), c + right * x1 + Vector3(0, 2.05, 0),
					n, 1.15, 16)
			else:
				var pcx := (x0 + x1) * 0.5
				RmADetail.figure_row(lm, "Relief", c + right * (pcx - 1.1) + Vector3(0, 2.05, 0),
					c + right * (pcx + 1.1) + Vector3(0, 2.05, 0), n, 1.15, 3)
	# Inside: garlands hung between bucrania under the cornice.
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, -sz)
		var zf: float = az + sz * (hz - 0.3)
		for i in 7:
			var x := -4.8 + 1.6 * float(i)
			RmADetail.bucranium(lm, "Relief", Vector3(x, top + 2.9, zf), n, 0.5)
			if i < 6:
				RmADetail.garland(lm, "Relief", Vector3(x + 0.2, top + 2.95, zf - sz * 0.08),
					Vector3(x + 1.4, top + 2.95, zf - sz * 0.08), n, 0.45, 0.2, 6)
	# The altar: stepped base, table, volute wings; stair on the west.
	lm.box("Marble", Vector3(0, top + 0.4, az), Vector3(6.6, 0.8, 5.2))
	lm.box("Marble", Vector3(0.6, top + 1.4, az), Vector3(3.4, 1.2, 3.3))
	for sz in [-1.0, 1.0]:
		lm.box("Marble", Vector3(0.6, top + 1.5, az + sz * 1.9), Vector3(3.4, 1.4, 0.5))
		lm.lathe("Marble", Vector3(-1.1, top + 2.2, az + sz * 1.9), PackedVector2Array([Vector2(0.0, 0),
			Vector2(0.3, 0.05), Vector2(0.32, 0.45), Vector2(0.0, 0.5)]), 10, 0.6, 1.0)
		RmADetail.figure_row(lm, "Relief", Vector3(-0.8, top + 0.85, az + sz * 2.16), Vector3(2.0, top + 0.85, az + sz * 2.16),
			Vector3(0, 0, sz), 0.55, 6)
	SEuUtil.steps_up(lm, "Marble", Vector3(-1.1, top + 0.8, az), Vector3.LEFT, 2.6, 0.35, 0.2, 3)
	SEuUtil.steps_up(lm, "Marble", Vector3(-hx - 0.3, fy, az), Vector3.LEFT, 3.0, 0.4, 0.16, 5)

# --- Tomb of Caecilia Metella -------------------------------------------

## The Via Appia tomb (c. 30-10 BC): the square podium (8.3 m) stripped
## to its concrete core, the 29.5 m (100 ft) travertine drum rising 12 m,
## its marble frieze of ox skulls (whence Capo di Bove), garlands and
## paterae under a dentilled cornice, the inscription CAECILIAE Q CRETICI
## F METELLAE CRASSI toward the road with the trophy relief over it, the
## Caetani crenellated parapet (21.7 m in all); behind, the Castrum
## Caetani of 1302 with its Gothic two-light windows, merlons and corner
## tower; across the road the roofless Gothic church of San Nicola.
## Front toward +Z.
static func caecilia(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Travertine", LandmarkMaterials.pbr("limestone", "#C0B08C", 3.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#D6CDB8", 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#94694D", 2.5))
	lm.use("Tuff", LandmarkMaterials.pbr("stone", "#9B8D74", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4B4237", 3.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#8E8472", 3.0))
	lm.box("Concrete", Vector3(0, 4.15, 0), Vector3(30.4, 8.3, 30.4))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Travertine", Vector3(sx * 13.9, 3.0, sz * 13.9), Vector3(2.8, 6.0, 2.8))
	lm.box("Marble", Vector3(0, 8.5, 0), Vector3(31.0, 0.4, 31.0))
	lm.lathe("Travertine", Vector3(0, 8.7, 0), PackedVector2Array([Vector2(15.0, 0), Vector2(15.0, 0.3),
		Vector2(14.8, 0.6), Vector2(14.75, 8.7)]), 64)
	# Frieze: ox skulls, garlands and paterae, cornice with dentils.
	lm.lathe("Marble", Vector3(0, 17.4, 0), PackedVector2Array([Vector2(14.85, 0), Vector2(14.85, 2.0)]), 64)
	var nb := 30
	for i in nb:
		var a := TAU * float(i) / float(nb)
		var o := Vector3(cos(a), 0, sin(a))
		_bucranium_ring(lm, o * 14.85 + Vector3(0, 18.6, 0), o, 0.9)
		var a2 := TAU * (float(i) + 1.0) / float(nb)
		var o2 := Vector3(cos(a2), 0, sin(a2))
		var om := (o + o2).normalized()
		RmADetail.garland(lm, "Marble", o * 15.0 + Vector3(0, 18.8, 0), o2 * 15.0 + Vector3(0, 18.8, 0), om, 0.55, 0.3, 6)
		lm.disc("Marble", om * 14.95 + Vector3(0, 18.75, 0), om, 0.22, 10)
	lm.lathe("Marble", Vector3(0, 19.4, 0), PackedVector2Array([Vector2(14.85, 0), Vector2(15.05, 0.12),
		Vector2(15.1, 0.25), Vector2(15.35, 0.4), Vector2(15.4, 0.55), Vector2(15.2, 0.6)]), 64)
	for i in 120:
		var a := TAU * float(i) / 120.0
		lm.box("Marble", Vector3(cos(a) * 15.02, 19.62, sin(a) * 15.02), Vector3(0.22, 0.15, 0.25),
			Basis(Vector3.UP, -a), 0.0)
	# The inscription and the trophy relief above it, toward the road.
	RmADetail.panel(lm, "Marble", "Marble", Vector3(0, 13.4, 14.75), Vector3.BACK, 4.4, 2.2, 0.15, 0.25)
	RmADetail.inscription(lm, "Shadow", Vector3(0, 13.4, 14.92), Vector3.BACK, 3.8, 1.8, 3, 1.0)
	RmADetail.relief_figure(lm, "Marble", Vector3(-0.9, 14.8, 14.8), Vector3.BACK, 1.9)
	RmADetail.relief_figure(lm, "Marble", Vector3(0.9, 14.8, 14.8), Vector3.BACK, 1.8)
	lm.beam("Marble", Vector3(0, 14.8, 14.85), Vector3(0, 16.9, 14.85), 0.15, 0.15)
	# Caetani parapet: brick drum on the cornice and its merlons.
	lm.frustum("Brick", Vector3(0, 19.8, 0), 14.6, 14.6, 0.5, 64)
	RmAUtil.merlons_ring(lm, "Tuff", Vector3.ZERO, 14.4, 20.3, 30, 1.4, 1.4, 1.0)
	# Castrum Caetani: the palace block behind, its two storeys of Gothic
	# windows, the merlons and the corner tower.
	var pc := Vector3(0, 0, -24.0)
	lm.box("Brick", pc + Vector3(0, 6.0, 0), Vector3(30.0, 12.0, 14.0))
	lm.box("Tuff", pc + Vector3(0, 12.3, 0), Vector3(30.8, 0.6, 14.8))
	for sx in [-1.0, 1.0]:
		var n := Vector3(sx, 0, 0)
		for k in 3:
			_gothic_window(lm, pc + Vector3(sx * 15.0, 7.0, -4.0 + 4.0 * float(k)), n)
		RmADetail.merlons(lm, "Brick", pc + Vector3(sx * 14.8, 12.6, -6.8), pc + Vector3(sx * 14.8, 12.6, 6.8),
			1.4, 1.5, 0.9, true)
	for k in 6:
		_gothic_window(lm, pc + Vector3(-12.5 + 5.0 * float(k), 7.0, -7.0), Vector3.FORWARD)
		SEuUtil.opening(lm, "Shadow", pc + Vector3(-12.5 + 5.0 * float(k), 2.5, -7.06), Vector3.LEFT, Vector3.UP, 0.6, 1.4)
	RmADetail.merlons(lm, "Brick", pc + Vector3(-14.6, 12.6, -6.8), pc + Vector3(14.6, 12.6, -6.8), 1.4, 1.5, 0.9, true)
	var tc := Vector3(-10.0, 0, -33.0)
	lm.box("Brick", tc + Vector3(0, 8.0, 0), Vector3(7.0, 16.0, 7.0))
	lm.box("Tuff", tc + Vector3(0, 16.3, 0), Vector3(7.8, 0.6, 7.8))
	for k in 4:
		var a := PI * 0.5 * float(k)
		var out := Vector3(sin(a), 0, cos(a))
		var right := Vector3.UP.cross(out)
		RmADetail.merlons(lm, "Brick", tc + out * 3.5 - right * 3.3 + Vector3(0, 16.6, 0),
			tc + out * 3.5 + right * 3.3 + Vector3(0, 16.6, 0), 1.1, 1.4, 0.8, true)
		SEuUtil.opening(lm, "Shadow", tc + out * 3.56 + Vector3(0, 11.0, 0), right, Vector3.UP, 0.5, 1.6, true)
	_san_nicola(lm, Vector3(0, 0, 33.0))
	lm.commit(model)

## One ox skull of the frieze, set on the drum at `c` facing `out`.
static func _bucranium_ring(lm: LandmarkMesh, c: Vector3, out: Vector3, s: float) -> void:
	var right := Vector3.UP.cross(out).normalized()
	lm.box("Marble", c + out * 0.1, Vector3(s * 0.45, s * 0.6, s * 0.3), Basis(right, Vector3.UP, out), 0.0)
	for sd in [-1.0, 1.0]:
		var h0 := c + right * float(sd) * s * 0.2 + Vector3.UP * s * 0.25 + out * 0.12
		var h1 := h0 + right * float(sd) * s * 0.32 + Vector3.UP * s * 0.18
		lm.beam("Marble", h0, h1, s * 0.09, s * 0.09, out)

## A Gothic two-light window: pointed openings, a colonnette between, a
## tuff surround.
static func _gothic_window(lm: LandmarkMesh, c: Vector3, n: Vector3) -> void:
	var right := Vector3.UP.cross(n).normalized()
	var p := c + n * 0.06
	for s in [-1.0, 1.0]:
		SEuUtil.opening(lm, "Shadow", p + right * float(s) * 0.42 - Vector3(0, 1.0, 0), right,
			Vector3.UP, 0.62, 2.0, true)
	lm.beam("Tuff", p - Vector3(0, 1.0, 0), p + Vector3(0, 0.6, 0), 0.14, 0.14)
	var basis := Basis(right, Vector3.UP, n)
	lm.box("Tuff", c + n * 0.08 - Vector3(0, 1.1, 0), Vector3(2.0, 0.18, 0.3), basis, 0.0)
	lm.box("Tuff", c + n * 0.05 + Vector3(0, 1.2, 0), Vector3(2.0, 0.25, 0.2), basis, 0.0)
	for s in [-1.0, 1.0]:
		lm.box("Tuff", c + n * 0.05 + right * float(s) * 0.92, Vector3(0.16, 2.2, 0.2), basis, 0.0)

## San Nicola a Capo di Bove (c. 1303), across the Via Appia: a roofless
## aisleless Cistercian Gothic church, 26 x 11 m, its gabled facade with
## the portal and oculus, buttressed side walls with lancets.
static func _san_nicola(lm: LandmarkMesh, c: Vector3) -> void:
	var hw := 5.5
	var hl := 13.0
	for sx in [-1.0, 1.0]:
		RmAUtil.ruin_wall(lm, "Tuff", c + Vector3(sx * hw, 0, -hl), c + Vector3(sx * hw, 0, hl), 1.0, 0.0, 6.5, 8.0, 2.6, sx)
		for k in 5:
			var z := -hl + 4.0 + 4.5 * float(k)
			lm.box("Tuff", c + Vector3(sx * (hw + 0.8), 3.0, z), Vector3(1.2, 6.0, 1.0))
			SEuUtil.opening(lm, "Shadow", c + Vector3(sx * (hw + 0.52), 3.2, z + 2.25), Vector3(0, 0, -sx),
				Vector3.UP, 0.7, 2.8, true)
	# Gabled west front facing the road (-Z) and the flat east end.
	for sz in [-1.0, 1.0]:
		var zf: float = sz * hl
		lm.box("Tuff", c + Vector3(0, 4.0, zf), Vector3(hw * 2.0 + 1.0, 8.0, 1.0))
		RmAUtil.pediment(lm, "Tuff", c + Vector3(0, 8.0, zf), Vector3.RIGHT, Vector3(0, 0, sz), hw * 2.0 + 1.0, 3.6, 1.0)
	var fz := c + Vector3(0, 0, -hl - 0.52)
	SEuUtil.opening(lm, "Shadow", fz, Vector3.LEFT, Vector3.UP, 2.0, 4.0, true)
	LandmarkDetail.arch(lm, "Tuff", fz + Vector3(0, 3.0, 0), Vector3.FORWARD, 2.0, 0.3, 0.2)
	RmADetail.ring_frame(lm, "Tuff", fz + Vector3(0, 8.4, 0), Vector3.FORWARD, 0.9, 0.22, 0.2, 14)
	lm.disc("Shadow", fz + Vector3(0, 8.4, -0.02), Vector3.FORWARD, 0.8, 14)
