class_name LandmarkFrNorth
extends RefCounted

## Landmarks of the Finnish north in true metres: the Arktikum science
## centre, the Lumberjack's Candle Bridge and Santa Claus Village in
## Rovaniemi. Plans follow the OpenStreetMap footprints and the frame of
## each model is given with it. The Lahti ski jumps are in LandmarkFrLahti.

## Arktikum (Birch-Bonderup & Thorup-Waade, opened 6 December 1992),
## Rovaniemi: the science centre and Arctic Centre with its exhibitions
## cut into the bank of the Kemijoki, the low concrete body (85 x 55 m,
## turf roofs, glazed fronts) and the 172 m glass corridor, the "Gateway
## to the North": a glass vault on white steel frames that runs the whole
## length of the complex towards the river on the north-north-east and
## stands out beyond the building at both ends. X along the corridor (+X
## towards the river, bearing about 30 degrees).
const ARKTIKUM_TOP := 11.8
const ARKTIKUM_BODY := [Vector2(-42.5, -27.6), Vector2(-42.5, 27.6), Vector2(-30.2, 27.2), Vector2(-29.3, 8.1),
	Vector2(-18.4, 7.6), Vector2(-19.2, 27.6), Vector2(42.5, 24.1), Vector2(42.5, -25.7), Vector2(-17.6, -26.7),
	Vector2(-17.8, -16.6), Vector2(-29.7, -16.8), Vector2(-29.5, -27.4)]

static func arktikum(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#C2BFB6", 4.0))
	lm.use("Turf", LandmarkMaterials.pbr("lawn", "#6F8F55", 4.0))
	lm.use("Steel", LandmarkMaterials.paint("#E4E5E3", 0.5, 0.4))
	lm.use("Glass", LandmarkMaterials.glass("#2A3A44"))
	lm.use("Floor", LandmarkMaterials.pbr("pavement", "#9A978F", 3.0))
	# Building: concrete body with turf roofs, a raised hall and glazed
	# fronts behind steel mullions; a concrete upstand round the turf.
	var body := PackedVector2Array(ARKTIKUM_BODY)
	lm.poly_prism("Concrete", body, 0.0, 8.0, false)
	lm.poly_prism("Turf", body, 8.0, 8.7)
	for i in body.size():
		var p := body[i]
		var q := body[(i + 1) % body.size()]
		lm.beam("Concrete", Vector3(p.x, 8.85, p.y), Vector3(q.x, 8.85, q.y), 0.3, 0.6, Vector3.UP)
	LandmarkFrKit.rect(lm, "Concrete", -12.0, 26.0, -14.0, 14.0, 8.7, 11.2)
	LandmarkFrKit.rect(lm, "Turf", -12.3, 26.3, -14.3, 14.3, 11.2, 11.8)
	LandmarkFrParts.facade(lm, "Concrete", "Glass", Vector3(-12.0, 8.7, 14.0), Vector3(26.0, 8.7, 14.0), Vector3.BACK,
		2.5, 12, 1, Vector2(2.2, 1.6), 0.5, 2.0, 0.2)
	LandmarkFrParts.facade(lm, "Concrete", "Glass", Vector3(-12.0, 8.7, -14.0), Vector3(26.0, 8.7, -14.0),
		Vector3.FORWARD, 2.5, 12, 1, Vector2(2.2, 1.6), 0.5, 2.0, 0.2)
	for k in 5:
		var gx := -24.0 + 11.0 * float(k)
		var gz := 27.6 - (gx + 19.2) * (3.5 / 61.7) if gx > -19.2 else 27.6
		_glazing(lm, Vector3(gx - 3.5, 1.0, gz), Vector3(gx + 3.5, 1.0, gz), Vector3.BACK, 5.0)
	_glazing(lm, Vector3(42.5, 1.0, -15.0), Vector3(42.5, 1.0, -1.0), Vector3.RIGHT, 5.0)
	_glazing(lm, Vector3(42.5, 1.0, 4.0), Vector3(42.5, 1.0, 18.0), Vector3.RIGHT, 5.0)
	_glazing(lm, Vector3(-42.5, 1.0, -20.0), Vector3(-42.5, 1.0, -8.0), Vector3.LEFT, 4.0)
	# Glass corridor: an A-frame of white steel ribs every 4 m with tie
	# beams and purlins carrying the glazing, the floor and the low
	# concrete walls, the glazed end gables with mullions.
	var x0 := -100.0
	var x1 := 72.0
	var hw := 7.0
	var top := 10.5
	LandmarkFrKit.rect(lm, "Floor", x0, x1, -hw, hw, 0.0, 0.4)
	for s: float in [-1.0, 1.0]:
		LandmarkFrKit.rect(lm, "Concrete", x0, x1, s * hw - 0.35, s * hw + 0.35, 0.0, 0.9)
		lm.quad("Glass", Vector3(x0, 0.9, s * hw), Vector3(x1, 0.9, s * hw), Vector3(x1, top, 0), Vector3(x0, top, 0),
			Vector3(0, hw, s * top).normalized())
		for k in 6:
			var t := float(k + 1) / 7.0
			var pa := Vector3(x0, 0.9, s * hw).lerp(Vector3(x0, top, 0), t)
			lm.beam("Steel", pa + Vector3(0, 0.12, 0), pa + Vector3(x1 - x0, 0.12, 0), 0.14, 0.22,
				Vector3(0, hw, s * top).normalized())
	for xe: float in [x0, x1]:
		var en := Vector3(signf(xe), 0, 0)
		lm.tri("Glass", Vector3(xe, 0.9, -hw), Vector3(xe, 0.9, hw), Vector3(xe, top, 0), en, en, en, Vector2(0, 0),
			Vector2(2.0 * hw, 0), Vector2(hw, -top))
		for k in 5:
			var zz := -hw + 2.0 * hw * float(k + 1) / 6.0
			var hh := 0.9 + (top - 0.9) * (1.0 - absf(zz) / hw)
			lm.beam("Steel", Vector3(xe, 0.9, zz), Vector3(xe, hh, zz), 0.16, 0.16)
		lm.beam("Steel", Vector3(xe, 4.0, -hw * 0.68), Vector3(xe, 4.0, hw * 0.68), 0.16, 0.16)
	var ribs := int((x1 - x0) / 4.0)
	for k in ribs + 1:
		var x := x0 + (x1 - x0) * float(k) / float(ribs)
		lm.beam("Steel", Vector3(x, 0.9, -hw), Vector3(x, top, 0), 0.4, 0.3, Vector3.RIGHT)
		lm.beam("Steel", Vector3(x, 0.9, hw), Vector3(x, top, 0), 0.4, 0.3, Vector3.RIGHT)
		if k % 2 == 0:
			lm.beam("Steel", Vector3(x, 6.2, -hw * 0.43), Vector3(x, 6.2, hw * 0.43), 0.14, 0.14)
	lm.beam("Steel", Vector3(x0, top, 0), Vector3(x1, top, 0), 0.6, 0.6)
	lm.commit(model)

## A glazed curtain wall from a to b (bottom line), h tall: glass with
## steel mullions every 1.2 m and two transoms.
static func _glazing(lm: LandmarkMesh, a: Vector3, b: Vector3, n: Vector3, h: float) -> void:
	lm.quad("Glass", a + n * 0.05, b + n * 0.05, b + Vector3(0, h, 0) + n * 0.05, a + Vector3(0, h, 0) + n * 0.05, n)
	var cnt := int(a.distance_to(b) / 1.2)
	for i in cnt + 1:
		var p := a.lerp(b, float(i) / float(cnt))
		lm.box("Steel", p + Vector3(0, h * 0.5, 0) + n * 0.1, Vector3(0.1, h, 0.1), Basis(), 0.0)
	for y: float in [0.0, h * 0.55, h]:
		lm.beam("Steel", a + Vector3(0, y, 0) + n * 0.1, b + Vector3(0, y, 0) + n * 0.1, 0.12, 0.12)

## Lumberjack's Candle Bridge (Jatkankynttila), Rovaniemi, competition
## 1982, opened 28 September 1989: Finland's first road cable-stayed bridge
## over the Kemijoki, 320 m in five spans (42 + 42 + 126 + 42 + 42 m), a
## 25.5 m wide steel box girder with a concrete slab carrying four lanes
## and a footway and cycle path on each side; the pylon of two reinforced
## concrete columns about 2.3 m across and of unequal height (the taller
## 47 m over the deck), their tops sawn aslant like a lumberjack's candle
## with electric flames, carries eight fan stay pairs over the main span
## and eight parallel back-stay pairs to the abutment on the Ounasvaara
## side. Along +X (towards Ounasvaara), y = 0 at the water.
const CANDLE_DECK_Y := 13.0
const CANDLE_PYLON_X := 63.0
const CANDLE_TOP := 60.0

static func candle_bridge(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#3B3B3B", 4.0))
	lm.use("Steel", LandmarkMaterials.paint("#CFD2D3", 0.58, 0.35))
	lm.use("Pylon", LandmarkMaterials.pbr("concrete", "#B9B6AE", 4.0))
	lm.use("Stay", LandmarkMaterials.paint("#ECE8DC", 0.45, 0.4))
	lm.use("Lit", LandmarkMaterials.lit("#FFC261", 0.9))
	lm.use("Walk", LandmarkMaterials.pbr("concrete", "#A19E96", 3.0))
	var y := CANDLE_DECK_Y
	var hw := 12.75
	# Box-girder deck: road slab, the sloped box webs, the raised footway
	# and cycle paths with kerbs, the edge fascias and railings.
	lm.box("Deck", Vector3(0, y - 0.3, 0), Vector3(320.0, 0.6, 2.0 * hw - 6.0))
	lm.box("Steel", Vector3(0, y - 1.7, 0), Vector3(320.0, 2.2, 2.0 * hw - 9.0))
	for s: float in [-1.0, 1.0]:
		lm.box("Walk", Vector3(0, y - 0.2, s * (hw - 1.5)), Vector3(320.0, 0.8, 3.0))
		lm.box("Steel", Vector3(0, y - 0.7, s * (hw - 0.1)), Vector3(320.0, 1.4, 0.2))
		lm.quad("Steel", Vector3(-160.0, y - 0.6, s * (hw - 3.0)), Vector3(160.0, y - 0.6, s * (hw - 3.0)),
			Vector3(160.0, y - 2.8, s * (hw - 4.5)), Vector3(-160.0, y - 2.8, s * (hw - 4.5)), Vector3(0, -0.5, s))
		lm.box("Walk", Vector3(0, y + 0.3, s * (hw - 3.1)), Vector3(320.0, 0.3, 0.3))
		LandmarkFrParts.railing(lm, "Steel", Vector3(-160.0, y + 0.2, s * (hw - 0.15)), Vector3(160.0, y + 0.2,
			s * (hw - 0.15)), 1.2, 2.5, 0.07)
		# Lamp posts along the footways.
		for k in 11:
			var lx := -150.0 + 30.0 * float(k)
			lm.box("Steel", Vector3(lx, y + 4.2, s * (hw - 2.9)), Vector3(0.2, 8.0, 0.2))
			lm.beam("Steel", Vector3(lx, y + 8.1, s * (hw - 2.9)), Vector3(lx, y + 8.1, s * (hw - 4.6)), 0.14, 0.14)
			lm.box("Lit", Vector3(lx, y + 7.95, s * (hw - 4.6)), Vector3(0.5, 0.16, 0.3))
	# Abutments at both ends.
	for sx: float in [-1.0, 1.0]:
		lm.box("Pylon", Vector3(sx * 157.0, (y - 2.8) * 0.5, 0), Vector3(6.0, y - 2.8, 2.0 * hw + 2.0))
	# Piers every 42 m and at the ends of the main span: two columns on a
	# footing, a cross head under the girder.
	for px: float in [-147.0, -105.0, -63.0, 63.0, 105.0, 147.0]:
		lm.box("Pylon", Vector3(px, 0.75, 0), Vector3(5.0, 1.5, 2.0 * hw - 4.0))
		for s2: float in [-1.0, 1.0]:
			lm.frustum("Pylon", Vector3(px, 1.5, s2 * 6.5), 1.45, 1.3, y - 2.8 - 1.5, 20)
		lm.box("Pylon", Vector3(px, y - 3.6, 0), Vector3(3.2, 1.6, 2.0 * hw - 8.0))
	# The two pylon columns, sawn aslant at the top, with the candle flames,
	# tied by a cross beam under the deck.
	_sawn_column(lm, "Pylon", CANDLE_PYLON_X, -1.6, 1.15, y - 2.0, y + 43.0, 4.0, 32)
	_sawn_column(lm, "Pylon", CANDLE_PYLON_X, 1.6, 1.15, y - 2.0, y + 32.5, 3.5, 32)
	lm.frustum("Pylon", Vector3(CANDLE_PYLON_X, 0, 0), 3.6, 3.2, y - 2.0, 24, 0.0, 1.0, 1.4)
	for s3: float in [-1.0, 1.0]:
		var top_y: float = y + (43.0 if s3 < 0.0 else 32.5)
		var tilt: float = 4.0 if s3 < 0.0 else 3.5
		lm.lathe("Lit", Vector3(CANDLE_PYLON_X + 0.3, top_y + tilt * 0.2, s3 * 1.6), PackedVector2Array([
			Vector2(0.15, 0), Vector2(0.6, 0.5), Vector2(0.55, 1.2), Vector2(0.25, 2.0), Vector2(0.0, 2.6)]), 12)
	# Stays: eight fan pairs over the main span, eight parallel back stays,
	# each with its anchor box on the deck edge.
	for k in 8:
		var h := y + 22.0 + 1.9 * float(k)
		var xd := CANDLE_PYLON_X - 14.0 - 14.5 * float(k)
		var xb := CANDLE_PYLON_X + 18.0 + 9.5 * float(k)
		for s4: float in [-1.0, 1.0]:
			var da := Vector3(xd, y + 0.3, s4 * (hw - 1.8))
			lm.beam("Stay", Vector3(CANDLE_PYLON_X - 1.2, h, s4 * 1.6), da, 0.28, 0.28)
			lm.box("Steel", da, Vector3(0.9, 0.6, 0.9))
			var db := Vector3(xb, y + 0.3, s4 * (hw - 1.8))
			lm.beam("Stay", Vector3(CANDLE_PYLON_X + 1.2, h + 2.0, s4 * 1.6), db, 0.28, 0.28)
			lm.box("Steel", db, Vector3(0.9, 0.6, 0.9))
			lm.box("Steel", Vector3(CANDLE_PYLON_X - 1.1, h, s4 * 1.6), Vector3(0.5, 0.5, 0.7))
	lm.commit(model)

## Vertical column whose top is cut aslant: a wall ring and a tilted cap,
## `tilt` m of rise from the centre to the high side (towards +X).
static func _sawn_column(lm: LandmarkMesh, key: String, cx: float, cz: float, r: float, y0: float,
		y_mid: float, tilt: float, seg: int) -> void:
	var bot := PackedVector3Array()
	var top := PackedVector3Array()
	for i in seg + 1:
		var a := TAU * float(i) / float(seg)
		bot.append(Vector3(cx + cos(a) * r, y0, cz + sin(a) * r))
		top.append(Vector3(cx + cos(a) * r, y_mid + tilt * cos(a), cz + sin(a) * r))
	var n_cap := Vector3(-tilt / r, 1.0, 0.0).normalized()
	for i in seg:
		var am := TAU * (float(i) + 0.5) / float(seg)
		lm.quad(key, bot[i], bot[i + 1], top[i + 1], top[i], Vector3(cos(am), 0, sin(am)))
		lm.tri(key, Vector3(cx, y_mid, cz), top[i], top[i + 1], n_cap, n_cap, n_cap, Vector2(cx, cz),
			Vector2(top[i].x, top[i].z), Vector2(top[i + 1].x, top[i + 1].z))

## Santa Claus Village (Joulupukin Pajakyla) on the Arctic Circle at
## Napapiiri: Santa Claus' Main Post Office, the log-and-timber hall (24 x 18
## m) with its steep roof, gabled entrance porch and the octagonal log
## tower with a star, a few log cabins of the village, and the white line
## of the Arctic Circle (at its 1865 position) drawn across the plaza
## (true east-west, so oblique in this frame, which is turned onto the
## real building by yaw_deg).
const SANTA_TOP := 22.5

static func santa_village(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Timber", LandmarkMaterials.pbr("wood", "#7B3A2B", 2.0))
	lm.use("Log", LandmarkMaterials.pbr("wood", "#A06A3E", 2.0))
	lm.use("Roof", LandmarkFrKit.shingle("#463B35"))
	lm.use("Glass", LandmarkMaterials.glass("#24303A"))
	lm.use("Line", LandmarkMaterials.pbr("render", "#F1F1EC", 2.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Pad", LandmarkMaterials.pbr("pavement", "#A8A59C", 3.0))
	LandmarkFrKit.rect(lm, "Pad", -40.0, 40.0, -32.0, 30.0, 0.0, 0.12)
	# Post office: hall under a steep roof with white-framed windows, log
	# corners, the gabled porch on posts and the tower.
	LandmarkFrKit.house(lm, "Timber", "Roof", -12.1, 12.1, -9.1, 9.1, 0.12, 5.6, 6.2, 0.8, 1)
	LandmarkFrParts.roof_trim(lm, "Line", -12.1, 12.1, -9.1, 9.1, 5.6, 6.2, 0.8, 1, 0.3)
	LandmarkFrParts.log_corners(lm, "Log", -12.1, 12.1, -9.1, 9.1, 0.12, 5.6, 0.32, 0.4)
	for sz: float in [-1.0, 1.0]:
		LandmarkFrParts.battens(lm, "Log", Vector3(-12.1, 0.12, sz * 9.1), Vector3(12.1, 0.12, sz * 9.1),
			Vector3(0, 0, sz), 5.4, 0.9, 0.12)
		LandmarkFrParts.openings(lm, "Line", "Glass", Vector3(-10.8, 1.6, sz * 9.1), Vector3(10.8, 1.6, sz * 9.1),
			Vector3(0, 0, sz), 6, 1.4, 1.8, LandmarkFrParts.HEAD_FLAT, 0.14, 0.12, 1)
		for k in 3:
			LandmarkFrParts.dormer(lm, "Timber", "Roof", "Glass", Vector3(-6.0 + 6.0 * float(k), 7.7, sz * 6.6),
				Vector3(0, 0, sz), 1.8, 1.5, 1.4)
	for sx: float in [-1.0, 1.0]:
		LandmarkFrParts.openings(lm, "Line", "Glass", Vector3(sx * 12.1, 1.6, -6.0), Vector3(sx * 12.1, 1.6, 6.0),
			Vector3(sx, 0, 0), 3, 1.4, 1.8, LandmarkFrParts.HEAD_FLAT, 0.14, 0.12, 1)
		LandmarkFrParts.opening(lm, "Line", "Glass", Vector3(sx * 12.1, 7.6, 0.0), Vector3(sx, 0, 0), 1.6, 1.6,
			LandmarkFrParts.HEAD_ROUND, 0.14, 0.12, 1)
	LandmarkFrKit.house(lm, "Log", "Roof", -4.0, 4.0, 9.0, 14.0, 0.12, 4.6, 3.8, 0.5, 0)
	LandmarkFrParts.roof_trim(lm, "Line", -4.0, 4.0, 9.0, 14.0, 4.6, 3.8, 0.5, 0, 0.25)
	LandmarkFrParts.log_corners(lm, "Log", -4.0, 4.0, 9.0, 14.0, 0.12, 4.6, 0.32, 0.35)
	LandmarkFrParts.opening(lm, "Line", "Glass", Vector3(0, 0.12, 14.0), Vector3.BACK, 2.6, 3.0,
		LandmarkFrParts.HEAD_FLAT, 0.2, 0.15, 1)
	LandmarkFrParts.opening(lm, "Line", "Glass", Vector3(0, 5.2, 14.0), Vector3.BACK, 1.0, 1.4,
		LandmarkFrParts.HEAD_ROUND, 0.12, 0.1)
	for s2: float in [-1.0, 1.0]:
		lm.box("Log", Vector3(s2 * 3.4, 2.4, 15.6), Vector3(0.35, 4.6, 0.35))
	LandmarkFrKit.gable(lm, "Roof", -4.0, 4.0, 14.0, 16.2, 4.6, 3.8, 0.4, "Timber", 0)
	# Octagonal log tower: log courses, windows, gallery, spire and star.
	var tc := Vector3(10.0, 0.12, 7.0)
	lm.frustum("Log", tc, 3.4, 3.1, 15.0, 8, PI / 8.0)
	for k in 30:
		var yy := 0.25 + 0.5 * float(k)
		var rr := 3.4 - 0.3 * yy / 15.0
		lm.frustum("Log", tc + Vector3(0, yy, 0), rr + 0.07, rr + 0.07, 0.18, 8, PI / 8.0)
	for row in 3:
		LandmarkFrParts.ring_openings(lm, "Line", "Glass", tc + Vector3(0, 3.0 + 3.8 * float(row), 0),
			3.1 * cos(PI / 8.0), 4, 0.9, 1.5, LandmarkFrParts.HEAD_FLAT, PI * 0.25 + PI * 0.25 * float(row % 2), 0.12)
	lm.frustum("Timber", tc + Vector3(0, 13.0, 0), 4.0, 4.0, 0.3, 8, PI / 8.0)
	LandmarkFrParts.ring_railing(lm, "Line", tc + Vector3(0, 13.3, 0), 3.9, 1.0, 16, 0.08)
	lm.lathe("Roof", tc + Vector3(0, 14.88, 0), PackedVector2Array([Vector2(4.2, 0), Vector2(2.6, 1.6),
		Vector2(0.15, 5.6)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.lathe("Gilt", tc + Vector3(0, 20.48, 0), LandmarkFrKit.ball(0.45), 10)
	LandmarkFrKit.cross(lm, "Gilt", tc + Vector3(0, 21.28, 0), 1.1)
	# Log cabins of the village: log corners, door, window, chimney.
	for c in [Vector3(-30, 0, -16), Vector3(-28, 0, 14), Vector3(30, 0, -20), Vector3(30, 0, 8),
			Vector3(-30, 0, -2), Vector3(22, 0, 24)]:
		var cc: Vector3 = c
		LandmarkFrKit.house(lm, "Log", "Roof", cc.x - 3.5, cc.x + 3.5, cc.z - 3.0, cc.z + 3.0, 0.12, 3.2, 2.6, 0.5, 1)
		LandmarkFrParts.log_corners(lm, "Log", cc.x - 3.5, cc.x + 3.5, cc.z - 3.0, cc.z + 3.0, 0.12, 3.2, 0.3, 0.3)
		LandmarkFrParts.roof_trim(lm, "Line", cc.x - 3.5, cc.x + 3.5, cc.z - 3.0, cc.z + 3.0, 3.2, 2.6, 0.5, 1, 0.2)
		LandmarkFrParts.opening(lm, "Line", "Glass", Vector3(cc.x - 1.2, 0.12, cc.z + 3.0), Vector3.BACK, 1.0, 2.0,
			LandmarkFrParts.HEAD_FLAT, 0.12, 0.1)
		LandmarkFrParts.opening(lm, "Line", "Glass", Vector3(cc.x + 1.5, 1.2, cc.z + 3.0), Vector3.BACK, 1.0, 1.0,
			LandmarkFrParts.HEAD_FLAT, 0.12, 0.1, 1)
		LandmarkFrParts.chimney(lm, "Pad", Vector3(cc.x + 2.0, 4.0, cc.z - 1.0), 6.4, 0.6)
	# The Arctic Circle line (true east-west, 12 m north of the hall), its
	# arch of posts with the sign, and marker lamps along it.
	var d := Vector3(0.259, 0, 0.966)
	var p := Vector3(11.6, 0.14, -3.1)
	var yaw := atan2(-d.z, d.x)
	lm.box("Line", p, Vector3(80.0, 0.06, 0.45), Basis(Vector3.UP, yaw))
	for s3: float in [-1.0, 1.0]:
		lm.box("Log", p + d * 6.0 * s3 + Vector3(0, 2.0, 0), Vector3(0.3, 4.0, 0.3))
	lm.box("Timber", p + Vector3(0, 3.5, 0), Vector3(12.0, 1.2, 0.2), Basis(Vector3.UP, yaw))
	for k in 9:
		var lp := p + d * (-36.0 + 9.0 * float(k))
		lm.box("Log", lp + Vector3(0, 0.6, 0), Vector3(0.2, 1.2, 0.2))
		lm.lathe("Gilt", lp + Vector3(0, 1.2, 0), LandmarkFrKit.ball(0.15), 6)
	lm.commit(model)
