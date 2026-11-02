class_name LandmarkFrNorth
extends RefCounted

## Landmarks of the Finnish north and of Lahti in true metres: the
## Arktikum science centre and the Lumberjack's Candle Bridge in
## Rovaniemi, Santa Claus Village on the Arctic Circle, and the Salpausselka
## ski jumping hills in Lahti. Plans follow the OpenStreetMap footprints
## and the frame of each model is given with it.

## Arktikum (Birch & Krogboe, 1992), Rovaniemi: the science centre cut into
## the bank of the Kemijoki, its low concrete body (85 x 55 m, turf roofs)
## and the 172 m glass corridor, an A-frame of glass and white steel, that
## runs the whole length of the complex towards the river on the north-north-
## east and stands out beyond the building at both ends. X along the corridor
## (+X towards the river, bearing about 30 degrees).
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
	# Building: concrete body with green roofs, a raised hall and glazed fronts.
	var body := PackedVector2Array(ARKTIKUM_BODY)
	lm.poly_prism("Concrete", body, -0.5, 8.0, false)
	lm.poly_prism("Turf", body, 8.0, 8.7)
	LandmarkFrKit.rect(lm, "Concrete", -12.0, 26.0, -14.0, 14.0, 8.7, 11.2)
	LandmarkFrKit.rect(lm, "Turf", -12.3, 26.3, -14.3, 14.3, 11.2, 11.8)
	for k in 5:
		lm.box("Glass", Vector3(-24.0 + 11.0 * float(k), 4.0, 24.2), Vector3(7.0, 5.0, 0.2))
	lm.box("Glass", Vector3(42.55, 4.0, -8.0), Vector3(0.2, 5.0, 14.0))
	# Glass corridor: A-frame ribs every 8 m, glazed roof and the glass tip.
	var x0 := -100.0
	var x1 := 72.0
	var hw := 7.0
	var top := 10.5
	LandmarkFrKit.rect(lm, "Floor", x0, x1, -hw, hw, 0.0, 0.4)
	for s in [-1.0, 1.0]:
		LandmarkFrKit.rect(lm, "Concrete", x0, x1, s * hw - 0.35, s * hw + 0.35, 0.0, 0.9)
		lm.quad("Glass", Vector3(x0, 0.9, s * hw), Vector3(x1, 0.9, s * hw), Vector3(x1, top, 0), Vector3(x0, top, 0),
			Vector3(0, hw, s * top).normalized())
	lm.tri("Glass", Vector3(x1, 0.9, -hw), Vector3(x1, 0.9, hw), Vector3(x1, top, 0), Vector3.RIGHT, Vector3.RIGHT,
		Vector3.RIGHT, Vector2(0, 0), Vector2(2.0 * hw, 0), Vector2(hw, -top))
	lm.tri("Glass", Vector3(x0, 0.9, -hw), Vector3(x0, 0.9, hw), Vector3(x0, top, 0), Vector3.LEFT, Vector3.LEFT,
		Vector3.LEFT, Vector2(0, 0), Vector2(2.0 * hw, 0), Vector2(hw, -top))
	var ribs := int((x1 - x0) / 8.0)
	for k in ribs + 1:
		var x := x0 + (x1 - x0) * float(k) / float(ribs)
		lm.beam("Steel", Vector3(x, 0.9, -hw), Vector3(x, top, 0), 0.45, 0.45, Vector3.RIGHT)
		lm.beam("Steel", Vector3(x, 0.9, hw), Vector3(x, top, 0), 0.45, 0.45, Vector3.RIGHT)
	lm.beam("Steel", Vector3(x0, top, 0), Vector3(x1, top, 0), 0.6, 0.6)
	lm.commit(model)

## Lumberjack's Candle Bridge (Jatkankynttila), Rovaniemi, 1989: Finland's
## first road cable-stayed bridge over the Kemijoki, 320 m in five spans
## (42 + 42 + 126 + 42 + 42 m) on a 25.5 m wide steel box deck; the pylon of
## two concrete columns of unequal height (the taller 47 m over the deck),
## their tops sawn aslant like a lumberjack's candle and lit, carries eight
## fan stays over the main span and eight parallel back stays to the abutment
## on the Ounasvaara side. Along +X (towards Ounasvaara), y = 0 at the water.
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
	var y := CANDLE_DECK_Y
	var hw := 12.75
	# Box-girder deck with the road slab and the two walkway edges.
	lm.box("Deck", Vector3(0, y - 0.3, 0), Vector3(320.0, 0.6, 2.0 * hw))
	lm.box("Steel", Vector3(0, y - 1.7, 0), Vector3(320.0, 2.2, 2.0 * hw - 6.0))
	for s in [-1.0, 1.0]:
		lm.box("Steel", Vector3(0, y + 0.4, s * (hw - 0.15)), Vector3(320.0, 1.0, 0.3))
	# Piers every 42 m and at the ends of the main span, two columns each.
	for px in [-147.0, -105.0, -63.0, 63.0, 105.0, 147.0]:
		for s in [-1.0, 1.0]:
			lm.box("Pylon", Vector3(px, (y - 2.8 - 4.0) * 0.5, s * 6.5), Vector3(2.6, y - 2.8 + 4.0, 3.2))
		lm.box("Pylon", Vector3(px, y - 3.6, 0), Vector3(3.2, 1.6, 2.0 * hw - 8.0))
	# The two pylon columns, sawn aslant at the top, with the candle flames.
	_sawn_column(lm, "Pylon", CANDLE_PYLON_X, -1.6, 1.15, y - 2.0, y + 43.0, 4.0, 12)
	_sawn_column(lm, "Pylon", CANDLE_PYLON_X, 1.6, 1.15, y - 2.0, y + 32.5, 3.5, 12)
	lm.frustum("Lit", Vector3(CANDLE_PYLON_X, y + 43.0, -1.6), 0.7, 0.0, 1.4, 8)
	lm.frustum("Lit", Vector3(CANDLE_PYLON_X, y + 32.5, 1.6), 0.7, 0.0, 1.4, 8)
	# Stays: eight fan pairs over the main span, eight parallel back stays.
	for k in 8:
		var h := y + 22.0 + 1.9 * float(k)
		var xd := CANDLE_PYLON_X - 14.0 - 14.5 * float(k)
		for s in [-1.0, 1.0]:
			lm.beam("Stay", Vector3(CANDLE_PYLON_X - 1.2, h, s * 1.6), Vector3(xd, y + 0.3, s * (hw - 1.8)),
				0.28, 0.28)
		var xb := CANDLE_PYLON_X + 18.0 + 9.5 * float(k)
		for s in [-1.0, 1.0]:
			lm.beam("Stay", Vector3(CANDLE_PYLON_X + 1.2, h + 2.0, s * 1.6), Vector3(xb, y + 0.3, s * (hw - 1.8)),
				0.28, 0.28)
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
## tower with a star, a few log cabins of the village, and the Arctic Circle
## line drawn across the plaza (true east-west, so oblique in this frame,
## which is turned onto the real building by yaw_deg).
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
	# Post office: L-shaped hall under a steep roof, porch gable and tower.
	LandmarkFrKit.house(lm, "Timber", "Roof", -12.1, 12.1, -9.1, 9.1, 0.0, 5.6, 6.2, 0.8, 1)
	LandmarkFrKit.house(lm, "Log", "Roof", -4.0, 4.0, 9.0, 14.0, 0.0, 4.6, 3.8, 0.5, 0)
	LandmarkFrKit.windows(lm, "Glass", Vector3(0, 2.4, 14.05), Vector3.RIGHT, 1, 1.0, Vector3(3.0, 3.2, 0.15))
	LandmarkFrKit.windows(lm, "Glass", Vector3(0, 3.2, 9.15), Vector3.RIGHT, 6, 3.6, Vector3(1.4, 1.8, 0.15))
	LandmarkFrKit.windows(lm, "Glass", Vector3(0, 3.2, -9.15), Vector3.RIGHT, 6, 3.6, Vector3(1.4, 1.8, 0.15))
	lm.frustum("Log", Vector3(10.0, 0, 7.0), 3.4, 3.1, 15.0, 8, PI / 8.0)
	lm.lathe("Roof", Vector3(10.0, 15.0, 7.0), PackedVector2Array([Vector2(4.2, 0), Vector2(0.15, 6.0)]), 8, 1.0, 1.0,
		PI / 8.0, false)
	lm.lathe("Gilt", Vector3(10.0, 20.6, 7.0), LandmarkFrKit.ball(0.45), 8)
	LandmarkFrKit.cross(lm, "Gilt", Vector3(10.0, 21.4, 7.0), 1.1)
	for k in 4:
		lm.box("Glass", Vector3(10.0 + 3.1 * cos(PI * 0.25 + PI * 0.5 * float(k)), 11.0,
			7.0 + 3.1 * sin(PI * 0.25 + PI * 0.5 * float(k))), Vector3(0.15, 2.0, 1.2),
			Basis(Vector3.UP, -(PI * 0.25 + PI * 0.5 * float(k))))
	# Log cabins of the village.
	for c in [Vector3(-30, 0, -16), Vector3(-28, 0, 14), Vector3(30, 0, -20), Vector3(30, 0, 8)]:
		LandmarkFrKit.house(lm, "Log", "Roof", c.x - 3.5, c.x + 3.5, c.z - 3.0, c.z + 3.0, 0.0, 3.2, 2.6, 0.5, 1)
	# The Arctic Circle line (true east-west, 12 m north of the hall) and its sign.
	var d := Vector3(0.259, 0, 0.966)
	var p := Vector3(11.6, 0.14, -3.1)
	var yaw := atan2(-d.z, d.x)
	lm.box("Line", p, Vector3(80.0, 0.06, 0.45), Basis(Vector3.UP, yaw))
	for s in [-1.0, 1.0]:
		lm.box("Log", p + d * 6.0 * float(s) + Vector3(0, 2.0, 0), Vector3(0.3, 4.0, 0.3))
	lm.box("Timber", p + Vector3(0, 3.5, 0), Vector3(12.0, 1.2, 0.2), Basis(Vector3.UP, yaw))
	lm.commit(model)

## Salpausselka ski jumping hills, Lahti: the three hills of the stadium
## side by side along the ridge (large K116/HS130 on the west with its 73 m
## tower and observation deck, normal K90/HS100, medium K64/HS70), each with
## the concrete start tower, the steel in-run trestle down to the take-off
## table and the plastic-covered landing slope falling to the outrun; the
## judges' towers beside the slopes. Slopes face north (-Z); y = 0 is the
## outrun, so the tables stand on built-up ground.
const LAHTI_TOP := 73.0
# Hill rows: x, tower height, tower z, start y, table y, landing length.
const LAHTI_HILLS := [[-132.0, 73.0, 56.0, 66.0, 25.0, 128.0], [0.0, 52.0, 44.0, 46.0, 18.0, 98.0],
	[122.0, 34.0, 28.0, 30.0, 11.0, 70.0]]
## The built frame is shifted so the origin sits at the middle of the hills.
const LAHTI_ZOFF := 35.0

static func lahti(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#BDBAB1", 4.0))
	lm.use("Steel", LandmarkMaterials.paint("#CFD2D3", 0.5, 0.4))
	lm.use("Glass", LandmarkMaterials.glass("#2A3A44"))
	lm.use("Slope", LandmarkMaterials.pbr("lawn", "#58944A", 4.0))
	lm.use("Rail", LandmarkMaterials.paint("#8E9A9F", 0.5, 0.4))
	for row in LAHTI_HILLS:
		_hill(lm, row[0] as float, row[1] as float, row[2] as float, row[3] as float, row[4] as float,
			row[5] as float)
	var pivot := Node3D.new()
	pivot.position = Vector3(0, 0, LAHTI_ZOFF)
	model.add_child(pivot)
	lm.commit(pivot)

static func _hill(lm: LandmarkMesh, cx: float, th: float, tz: float, start_y: float, table_y: float,
		slope_len: float) -> void:
	# Tower: tapering square concrete shaft, glass cabin and roof slab.
	lm.frustum("Concrete", Vector3(cx, -3.0, tz), 7.2, 4.9, th - 6.0 + 3.0, 4, PI / 4.0)
	lm.box("Glass", Vector3(cx, th - 4.6, tz), Vector3(11.0, 3.0, 6.4))
	lm.box("Concrete", Vector3(cx, th - 1.2, tz), Vector3(12.4, 2.4, 7.6))
	lm.box("Concrete", Vector3(cx, th - 6.6, tz), Vector3(9.4, 1.0, 6.4))
	# In-run: two chords, vertical trestle legs and diagonals down to the table.
	var z0 := tz - 4.0
	var z1 := 3.0
	var n := 8
	var prev := Vector3(cx, start_y, z0)
	for k in range(1, n + 1):
		var t := float(k) / float(n)
		var p := Vector3(cx, lerpf(start_y, table_y, t), lerpf(z0, z1, t))
		lm.beam("Steel", prev, p, 1.4, 0.8, Vector3.RIGHT)
		lm.beam("Rail", prev - Vector3(0, 3.0, 0), p - Vector3(0, 3.0, 0), 1.0, 0.7, Vector3.RIGHT)
		lm.beam("Rail", p - Vector3(0, 3.0, 0), p, 0.5, 0.5, Vector3.RIGHT)
		if k < n:
			lm.beam("Rail", p - Vector3(0, 3.0, 0), Vector3(p.x - 2.2, 0.0, p.z), 0.8, 0.8, Vector3.RIGHT)
			lm.beam("Rail", p - Vector3(0, 3.0, 0), Vector3(p.x + 2.2, 0.0, p.z), 0.8, 0.8, Vector3.RIGHT)
		prev = p
	# Take-off table on its support, then the landing slope in strips.
	lm.box("Concrete", Vector3(cx, table_y * 0.5 - 1.0, -1.0), Vector3(7.0, table_y - 2.0, 6.0))
	lm.box("Concrete", Vector3(cx, table_y - 1.0, -1.0), Vector3(5.0, 1.2, 6.2))
	var segs := 10
	var half0 := 7.0
	var half1 := 17.0 + slope_len * 0.05
	for k in segs:
		var ta := float(k) / float(segs)
		var tb := float(k + 1) / float(segs)
		var ya := table_y * pow(1.0 - ta, 1.7) - 0.05
		var yb := table_y * pow(1.0 - tb, 1.7) - 0.05
		var za := -4.0 - slope_len * ta
		var zb := -4.0 - slope_len * tb
		var ha := lerpf(half0, half1, ta)
		var hb := lerpf(half0, half1, tb)
		LandmarkFrKit.face(lm, "Slope", [Vector3(cx - ha, ya, za), Vector3(cx + ha, ya, za), Vector3(cx + hb, yb, zb),
			Vector3(cx - hb, yb, zb)])
		for s in [-1.0, 1.0]:
			var side := Vector3(s, 0, 0)
			lm.quad("Concrete", Vector3(cx + s * ha, ya, za), Vector3(cx + s * hb, yb, zb),
				Vector3(cx + s * hb, -0.2, zb), Vector3(cx + s * ha, -0.2, za), side)
	# Judges' tower beside the landing slope.
	lm.box("Concrete", Vector3(cx + half1 + 4.0, 7.0, -slope_len * 0.55), Vector3(5.0, 14.0, 4.0))
	lm.box("Glass", Vector3(cx + half1 + 4.0, 12.5, -slope_len * 0.55 + 2.05), Vector3(4.4, 2.0, 0.15))
