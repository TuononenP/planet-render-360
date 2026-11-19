class_name LandmarkFtPaavoNurmi
extends RefCounted

## Paavo Nurmi Stadium (Paavo Nurmen stadion, Turku):
## Historic athletics stadium in Turun Urheilupuisto featuring the 1989
## Nurmela-Raimoranta-Tasa two-tier white main grandstand, 400 m 8-lane
## brick-red Class 1 track, striped grass infield, 9,000-seat horseshoe
## embankment stands, NE scoreboard, and historic twin entrance kiosks.
## Origin at pitch centre (60.442548, 22.260900), +X NE, +Z SE open bowl,
## -Z NW main grandstand; turned onto the map by yaw_deg = -42.0.

const TRACK_HL := 44.0
const TRACK_R_IN := 34.8
const TRACK_R_OUT := 44.6
const LANE_W := 1.22
const GROUND_Y := 0.20

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	_track_and_infield(lm)
	_main_grandstand(lm)
	_horseshoe_embankment(lm)
	_scoreboard(lm)
	lm.commit(model)
	_rear_plaza_buildings(model, lm)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("Pitch", LandmarkMaterials.pbr("lawn", "#48782E", 6.0))
	lm.use("PitchStripe", LandmarkMaterials.pbr("lawn", "#588C38", 6.0))
	lm.use("Track", LandmarkMaterials.pbr("asphalt", "#A84434", 4.0))
	lm.use("WhiteLine", LandmarkMaterials.pbr("pavement", "#F0EFEA", 2.0))
	lm.use("Sand", LandmarkMaterials.pbr("sand", "#D4C29C", 2.5))
	lm.use("Concrete", LandmarkMaterials.pbr("render", "#ECEAE2", 3.5))
	lm.use("ConcreteDark", LandmarkMaterials.pbr("pavement", "#969EA4", 3.5))
	lm.use("SteelDark", LandmarkMaterials.paint("#5E666E", 0.45, 0.5))
	lm.use("SeatOchre", LandmarkMaterials.pbr("wood", "#C89830", 2.0, 0.65))
	lm.use("Screen", LandmarkMaterials.paint("#1A1E22", 0.3, 0.2))
	lm.use("KioskRoof", LandmarkMaterials.pbr("sheet_metal", "#4C5854", 2.5))

static func _rect(lm: LandmarkMesh, key: String, x0: float, x1: float, z0: float, z1: float,
		y0: float, y1: float, bevel: float = -1.0) -> void:
	lm.box(key, Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, (z0 + z1) * 0.5),
		Vector3(absf(x1 - x0), absf(y1 - y0), absf(z1 - z0)), Basis(), bevel)

static func _oval_ring(hl: float, r: float, y: float) -> PackedVector3Array:
	var pts := PackedVector3Array()
	var straight := 10
	var bend := 24
	for i in straight:
		pts.append(Vector3(-hl + 2.0 * hl * float(i) / float(straight), y, r))
	for i in bend:
		var a := PI * 0.5 - PI * float(i) / float(bend)
		pts.append(Vector3(hl + cos(a) * r, y, sin(a) * r))
	for i in straight:
		pts.append(Vector3(hl - 2.0 * hl * float(i) / float(straight), y, -r))
	for i in bend:
		var a := -PI * 0.5 - PI * float(i) / float(bend)
		pts.append(Vector3(-hl + cos(a) * r, y, sin(a) * r))
	pts.append(pts[0])
	return pts

static func _track_and_infield(lm: LandmarkMesh) -> void:
	# Concrete perimeter apron outside the track and sprint straight under grandstand front.
	lm.grid("ConcreteDark", [_oval_ring(TRACK_HL, TRACK_R_OUT, GROUND_Y - 0.01),
		_oval_ring(TRACK_HL, 47.4, GROUND_Y - 0.01)], Vector3.UP)
	_rect(lm, "ConcreteDark", -56.0, 57.0, -54.0, -44.6, -0.8, GROUND_Y - 0.01, 0.0)
	# Extended sprint straight in front of main grandstand (-Z).
	_rect(lm, "Track", -54.0, 54.0, -46.8, -44.5, 0.0, GROUND_Y, 0.0)
	# Brick-red 8-lane 400 m synthetic track oval.
	lm.grid("Track", [_oval_ring(TRACK_HL, TRACK_R_IN, GROUND_Y),
		_oval_ring(TRACK_HL, TRACK_R_OUT, GROUND_Y)], Vector3.UP)
	# Semicircular red athletics D-zones at both ends + inner grass along the straights.
	for sx: float in [-1.0, 1.0]:
		var cx := sx * TRACK_HL
		var d_poly := PackedVector2Array()
		var segs := 20
		for k in segs + 1:
			var a := (-PI * 0.5 + PI * float(k) / float(segs)) if sx > 0.0 \
				else (PI * 0.5 + PI * float(k) / float(segs))
			d_poly.append(Vector2(cx + cos(a) * TRACK_R_IN, sin(a) * TRACK_R_IN))
		lm.poly_prism("Track", d_poly, 0.0, GROUND_Y)
	# Natural grass infield: 10 alternating mown strips (101.6 x 62 m pitch + kerb-safe side aprons).
	for i in 10:
		var x0 := lerpf(-50.8, 50.8, float(i) / 10.0)
		var x1 := lerpf(-50.8, 50.8, float(i + 1) / 10.0)
		var mat := "Pitch" if i % 2 == 0 else "PitchStripe"
		_rect(lm, mat, x0, x1, -31.0, 31.0, 0.0, GROUND_Y + 0.01, 0.0)
		var subs := 1 if maxf(absf(x0), absf(x1)) <= TRACK_HL else 4
		for s in subs:
			var sx0 := lerpf(x0, x1, float(s) / float(subs))
			var sx1 := lerpf(x0, x1, float(s + 1) / float(subs))
			var dx := maxf(maxf(absf(sx0), absf(sx1)) - TRACK_HL, 0.0)
			var z_lim := sqrt(maxf(TRACK_R_IN * TRACK_R_IN - dx * dx, 0.0)) - 0.1
			if z_lim > 31.0:
				_rect(lm, mat, sx0, sx1, -z_lim, -31.0, 0.0, GROUND_Y + 0.01, 0.0)
				_rect(lm, mat, sx0, sx1, 31.0, z_lim, 0.0, GROUND_Y + 0.01, 0.0)
	# White track kerb and 8 flat concentric lane dividers.
	var kerb := _oval_ring(TRACK_HL, TRACK_R_IN, GROUND_Y + 0.02)
	for i in kerb.size() - 1:
		lm.beam("WhiteLine", kerb[i], kerb[i + 1], 0.08, 0.14, Vector3.UP)
	for k in range(1, 9):
		var lane := _oval_ring(TRACK_HL, TRACK_R_IN + LANE_W * float(k), GROUND_Y + 0.012)
		for i in lane.size() - 1:
			lm.beam("WhiteLine", lane[i], lane[i + 1], 0.02, 0.07, Vector3.UP)
	_rect(lm, "WhiteLine", -24.08, -23.92, -46.8, -TRACK_R_IN, GROUND_Y, GROUND_Y + 0.02, 0.0)
	# White football pitch markings (101.6 x 62.0 m) + centre circle.
	var py := GROUND_Y + 0.022
	_rect(lm, "WhiteLine", -50.8, 50.8, -31.08, -30.92, GROUND_Y, py, 0.0)
	_rect(lm, "WhiteLine", -50.8, 50.8, 30.92, 31.08, GROUND_Y, py, 0.0)
	_rect(lm, "WhiteLine", -50.88, -50.72, -31.0, 31.0, GROUND_Y, py, 0.0)
	_rect(lm, "WhiteLine", 50.72, 50.88, -31.0, 31.0, GROUND_Y, py, 0.0)
	_rect(lm, "WhiteLine", -0.08, 0.08, -31.0, 31.0, GROUND_Y, py, 0.0)
	for i in 32:
		var a0 := TAU * float(i) / 32.0
		var a1 := TAU * float(i + 1) / 32.0
		lm.beam("WhiteLine", Vector3(cos(a0) * 9.15, GROUND_Y + 0.014, sin(a0) * 9.15),
			Vector3(cos(a1) * 9.15, GROUND_Y + 0.014, sin(a1) * 9.15), 0.02, 0.14, Vector3.UP)
	for sx: float in [-1.0, 1.0]:
		var gx := sx * 50.8
		var px := sx * 34.3
		_rect(lm, "WhiteLine", minf(gx, px), maxf(gx, px), -20.23, -20.07, GROUND_Y, py, 0.0)
		_rect(lm, "WhiteLine", minf(gx, px), maxf(gx, px), 20.07, 20.23, GROUND_Y, py, 0.0)
		_rect(lm, "WhiteLine", px - 0.08, px + 0.08, -20.15, 20.15, GROUND_Y, py, 0.0)
	# Long jump sand pit (way 777857691) & runway tucked inside the inner kerb (clear of lanes).
	_rect(lm, "Concrete", 28.8, 41.2, -34.4, -31.4, GROUND_Y, GROUND_Y + 0.04, 0.0)
	_rect(lm, "Sand", 29.1, 40.9, -34.1, -31.7, GROUND_Y, GROUND_Y + 0.06, 0.0)
	_rect(lm, "Track", -4.0, 29.1, -33.5, -32.3, GROUND_Y, GROUND_Y + 0.04, 0.0)

static func _main_grandstand(lm: LandmarkMesh) -> void:
	# 1989 Nurmela-Raimoranta-Tasa two-tier grandstand (way 777857700, CityGML 103248831E).
	var gx0 := -55.6
	var gx1 := 56.8
	# Front trackside concrete parapet & metal guardrail.
	_rect(lm, "Concrete", gx0, gx1, -54.2, -53.6, -0.5, 1.15, 0.0)
	lm.beam("SteelDark", Vector3(gx0, 1.75, -53.9), Vector3(gx1, 1.75, -53.9), 0.06)
	for k in 29:
		var rx := lerpf(gx0, gx1, float(k) / 28.0)
		lm.beam("SteelDark", Vector3(rx, 1.15, -53.9), Vector3(rx, 1.78, -53.9), 0.05)
	# Lower seating tier (10 stepped rows, 6 ochre bench bays + 7 concrete stair aisles).
	_rect(lm, "ConcreteDark", gx0, gx1, -72.2, -63.6, -1.5, 5.2, 0.0)
	var aisles := [-54.8, -36.2, -17.6, 1.0, 19.6, 38.2, 56.0]
	for bay in 6:
		var bx0 := float(aisles[bay]) + 0.75
		var bx1 := float(aisles[bay + 1]) - 0.75
		for row in 10:
			var rz0 := -54.4 - float(row + 1) * 0.94
			var rz1 := -54.4 - float(row) * 0.94
			var ry := 1.2 + float(row) * 0.40
			_rect(lm, "Concrete", bx0 - 0.75, bx1 + 0.75, rz0, rz1, 0.0, ry, 0.0)
			_rect(lm, "SeatOchre", bx0, bx1, rz0 + 0.16, rz1 - 0.14, ry, ry + 0.12, 0.0)
	for ax in aisles:
		for row in 10:
			var rz0 := -54.4 - float(row + 1) * 0.94
			var ry := 1.24 + float(row) * 0.40
			_rect(lm, "ConcreteDark", ax - 0.72, ax + 0.72, rz0, rz0 + 0.94, ry - 0.1, ry + 0.12, 0.0)
		lm.beam("SteelDark", Vector3(ax, 2.0, -54.6), Vector3(ax, 5.8, -63.5), 0.04)
	# Flank retaining walls at SW & NE ends of the grandstand.
	for sx in [gx0, gx1 - 0.7]:
		_rect(lm, "Concrete", sx, sx + 0.7, -72.4, -54.0, -1.5, 13.0, 0.0)
	# Open see-through mid-level concourse gallery on 10 portal columns + rear stairs.
	var cols_x := PackedFloat32Array()
	for i in 10:
		cols_x.append(lerpf(-54.6, 55.8, float(i) / 9.0))
	for cx in cols_x:
		_rect(lm, "Concrete", cx - 0.35, cx + 0.35, -62.4, -61.5, 4.8, 7.6, 0.0)
		_rect(lm, "Concrete", cx - 0.38, cx + 0.38, -72.2, -71.3, 5.0, 15.4, 0.0)
	_rect(lm, "Concrete", gx0, gx1, -62.5, -60.5, 7.0, 8.1, 0.0)
	lm.beam("SteelDark", Vector3(gx0, 8.85, -60.6), Vector3(gx1, 8.85, -60.6), 0.06)
	for i in 30:
		var rx := lerpf(gx0, gx1, float(i) / 29.0)
		lm.beam("SteelDark", Vector3(rx, 8.1, -60.6), Vector3(rx, 8.88, -60.6), 0.04)
	# Rear concourse stair flights visible through the open gallery.
	for sx in [-36.2, -17.6, 1.0, 19.6, 38.2]:
		lm.beam("ConcreteDark", Vector3(sx, 5.2, -64.0), Vector3(sx, 8.6, -70.6), 1.4, 0.45, Vector3.RIGHT)
	# Cantilevered upper seating tier (11 stepped rows, 4 bench bays + 5 aisles) + 3 vomitories.
	var aisles_up := [-54.6, -26.0, 2.0, 31.0, 55.8]
	for row in 11:
		var rz0 := -60.6 - float(row + 1) * 1.04
		var rz1 := -60.6 - float(row) * 1.04
		var ry := 7.6 + float(row) * 0.49
		_rect(lm, "Concrete", gx0 + 0.6, gx1 - 0.6, rz0, rz1, 7.1, ry, 0.0)
		if row < 10:
			for bay in 4:
				var bx0 := float(aisles_up[bay]) + 0.75
				var bx1 := float(aisles_up[bay + 1]) - 0.75
				_rect(lm, "SeatOchre", bx0, bx1, rz0 + 0.16, rz1 - 0.14, ry, ry + 0.12, 0.0)
	for ax in aisles_up:
		var ax_f := float(ax)
		var ax0 := maxf(ax_f - 0.72, gx0 + 0.7)
		var ax1 := minf(ax_f + 0.72, gx1 - 0.7)
		for row in 10:
			var rz0 := -60.6 - float(row + 1) * 1.04
			var ry := 7.64 + float(row) * 0.49
			_rect(lm, "ConcreteDark", ax0, ax1, rz0, rz0 + 1.04, ry - 0.1, ry + 0.12, 0.0)
	for vx: float in [-26.0, 2.0, 31.0]:
		_rect(lm, "Screen", vx - 1.5, vx + 1.5, -68.2, -65.4, 9.6, 12.1, 0.0)
		_rect(lm, "ConcreteDark", vx - 1.7, vx + 1.7, -66.0, -64.8, 9.5, 10.6, 0.0)
	# SW Broadcast / Commentator Box (selostamo).
	_rect(lm, "ConcreteDark", -43.5, -31.0, -72.0, -65.2, 10.2, 13.6, 0.0)
	_rect(lm, "Screen", -43.2, -31.3, -65.3, -65.1, 11.2, 13.1, 0.0)
	_rect(lm, "SteelDark", -43.6, -30.9, -72.1, -65.0, 13.4, 13.7, 0.0)
	# Open gridded rear windscreen above the upper tier so sky and park trees show through.
	for ry: float in [13.0, 14.05, 15.1]:
		lm.beam("SteelDark", Vector3(gx0 + 0.6, ry, -72.0), Vector3(gx1 - 0.6, ry, -72.0), 0.06)
	for i in 48:
		var mx := lerpf(gx0 + 0.6, gx1 - 0.6, float(i) / 47.0)
		lm.beam("SteelDark", Vector3(mx, 13.0, -72.0), Vector3(mx, 15.1, -72.0), 0.05)
	# Soaring thin white wing canopy roof (rear y=17.6 m -> front y=19.2 m) + 10 V-struts.
	_canopy_roof(lm, gx0 + 0.2, gx1 - 0.1, -72.8, -53.4, 17.6, 19.2, 0.55)
	for cx in cols_x:
		lm.beam("ConcreteDark", Vector3(cx, 17.3, -72.2), Vector3(cx, 18.85, -54.0), 0.42, 0.36, Vector3.RIGHT)
		lm.beam("ConcreteDark", Vector3(cx, 13.2, -71.7), Vector3(cx, 18.4, -57.5), 0.34, 0.42, Vector3.RIGHT)
		lm.beam("ConcreteDark", Vector3(cx, 13.2, -71.7), Vector3(cx, 17.5, -70.2), 0.28, 0.34, Vector3.RIGHT)
		lm.beam("ConcreteDark", Vector3(cx, 15.5, -65.4), Vector3(cx, 15.5, -71.6), 0.18, 0.22, Vector3.UP)
	# Six roof-lip stadium floodlight racks.
	for lx: float in [-47.0, -28.0, -9.0, 10.0, 29.0, 48.0]:
		_rect(lm, "SteelDark", lx - 1.8, lx + 1.8, -54.2, -53.6, 19.2, 19.6, 0.0)
		for k in 4:
			var fx := lx - 1.2 + float(k) * 0.8
			lm.box("WhiteLine", Vector3(fx, 19.85, -53.8), Vector3(0.45, 0.38, 0.24))
	# Flush rear concourse deck behind gallery (y=5.2 m) + west wing (CityGML Roof 0 at 6.15 m).
	_rect(lm, "ConcreteDark", gx0, gx1 + 0.8, -73.0, -69.5, -1.5, 5.2, 0.0)
	_rect(lm, "ConcreteDark", gx0, -32.6, -90.6, -72.6, -1.5, 6.15, 0.0)
	lm.beam("SteelDark", Vector3(gx0, 7.1, -90.5), Vector3(-32.6, 7.1, -90.5), 0.05)

static func _canopy_roof(lm: LandmarkMesh, x0: float, x1: float, z0: float, z1: float,
		y_rear: float, y_front: float, thick: float) -> void:
	var t0 := Vector3(x0, y_rear, z0)
	var t1 := Vector3(x1, y_rear, z0)
	var t2 := Vector3(x1, y_front, z1)
	var t3 := Vector3(x0, y_front, z1)
	var b0 := t0 - Vector3(0, thick, 0)
	var b1 := t1 - Vector3(0, thick, 0)
	var b2 := t2 - Vector3(0, thick, 0)
	var b3 := t3 - Vector3(0, thick, 0)
	lm.quad("Concrete", t0, t1, t2, t3, Vector3.UP)
	lm.quad("Concrete", b3, b2, b1, b0, Vector3.DOWN)
	lm.quad("Concrete", b3, b2, t2, t3, Vector3.BACK)
	lm.quad("Concrete", b1, b0, t0, t1, Vector3.FORWARD)
	lm.quad("Concrete", b0, b3, t3, t0, Vector3.LEFT)
	lm.quad("Concrete", b2, b1, t1, t2, Vector3.RIGHT)

static func _horseshoe_ring(r: float, y: float, segs_end: int = 16, segs_str: int = 10) -> PackedVector3Array:
	var pts := PackedVector3Array()
	var stop := asin(clampf(36.0 / r, 0.0, 0.94))
	# +X bend from NW end (-stop) down to SE (+PI/2)
	for i in segs_end + 1:
		var a := lerpf(-stop, PI * 0.5, float(i) / float(segs_end))
		pts.append(Vector3(TRACK_HL + cos(a) * r, y, sin(a) * r))
	# +Z back straight (+hl -> -hl)
	for i in range(1, segs_str):
		var x := lerpf(TRACK_HL, -TRACK_HL, float(i) / float(segs_str))
		pts.append(Vector3(x, y, r))
	# -X bend from SE (+PI/2) up to SW-NW end (PI + stop)
	for i in segs_end + 1:
		var a := lerpf(PI * 0.5, PI + stop, float(i) / float(segs_end))
		pts.append(Vector3(-TRACK_HL + cos(a) * r, y, sin(a) * r))
	return pts

static func _horseshoe_embankment(lm: LandmarkMesh) -> void:
	# Galvanized perimeter fence around the horseshoe bowl (r = 47.0 m).
	lm.grid("SteelDark", [
		_horseshoe_ring(46.94, GROUND_Y),
		_horseshoe_ring(46.94, GROUND_Y + 1.15),
		_horseshoe_ring(47.06, GROUND_Y + 1.15),
		_horseshoe_ring(47.06, GROUND_Y),
	])
	# 8 stepped concrete-and-bench embankment tiers + outer backing & trimmed park hedge.
	var rows := [
		_horseshoe_ring(47.4, -1.8),
		_horseshoe_ring(47.4, 1.15),
	]
	for k in 8:
		var r0 := 47.7 + float(k) * 0.95
		var r1 := r0 + 0.95
		var y := 1.25 + float(k) * 0.45
		rows.append(_horseshoe_ring(r0, y))
		rows.append(_horseshoe_ring(r1, y))
	rows.append(_horseshoe_ring(55.4, 4.9))
	lm.grid("Concrete", rows, Vector3.UP)
	for k in 8:
		var r_b := 48.0 + float(k) * 0.95
		var y_b := 1.31 + float(k) * 0.45
		var strip := _horseshoe_ring(r_b, y_b)
		for i in strip.size() - 1:
			lm.beam("SeatOchre", strip[i], strip[i + 1], 0.10, 0.44, Vector3.UP)
	# Trimmed green park hedge crowning the outer rim down into Urheilupuisto slope.
	lm.grid("Pitch", [
		_horseshoe_ring(55.4, 4.9),
		_horseshoe_ring(55.5, 6.2),
		_horseshoe_ring(57.8, 6.2),
		_horseshoe_ring(58.4, -1.8),
	], Vector3.UP)
	# Cap both open ends of the embankment at z = -36 m cleanly.
	var inner_end := _horseshoe_ring(47.4, 0.0)
	var outer_end := _horseshoe_ring(55.4, 0.0)
	for sx: float in [-1.0, 1.0]:
		var idx := 0 if sx > 0.0 else (inner_end.size() - 1)
		var i_pt := inner_end[idx]
		var o_pt := outer_end[idx]
		var dir := (o_pt - i_pt).normalized()
		var n := Vector3(dir.z, 0.0, -dir.x) * sx
		lm.quad("Concrete", Vector3(i_pt.x, -1.8, i_pt.z), Vector3(o_pt.x, -1.8, o_pt.z),
			Vector3(o_pt.x, 4.9, o_pt.z), Vector3(i_pt.x, 1.15, i_pt.z), n)
	# Radial concrete stair aisles along the back straight.
	for ax in [-32.0, -10.5, 10.5, 32.0]:
		lm.beam("ConcreteDark", Vector3(ax, 1.25, 47.7), Vector3(ax, 4.95, 55.3), 1.4, 0.22, Vector3.RIGHT)

static func _scoreboard(lm: LandmarkMesh) -> void:
	# NE curve electronic scoreboard turned toward the main grandstand.
	var sb_pos := Vector3(84.0, 4.4, 18.0)
	var b := Basis(Vector3.UP, -0.85)
	for sx in [-2.6, 2.6]:
		lm.box("SteelDark", sb_pos + b * Vector3(sx, 2.2, 0.0), Vector3(0.35, 5.2, 0.35), b)
	lm.box("SteelDark", sb_pos + b * Vector3(0.0, 5.8, 0.0), Vector3(9.4, 4.4, 0.65), b, 0.05)
	lm.box("Screen", sb_pos + b * Vector3(0.0, 5.7, -0.34), Vector3(8.6, 3.6, 0.08), b, 0.0)
	lm.box("Concrete", sb_pos + b * Vector3(0.0, 7.8, -0.35), Vector3(8.6, 0.35, 0.08), b, 0.0)

static func _rear_plaza_buildings(model: Node3D, base_lm: LandmarkMesh) -> void:
	# Rear NW plaza pavilions and historic twin ticket kiosks seated via SEAT_META.
	var copy_mats := func(dst: LandmarkMesh, keys: Array) -> void:
		for k in keys:
			dst.use(k, (base_lm._surfs[k] as LandmarkMesh.Surf).mat)
	# 1. West rear pavilion (way 1555925065, CityGML 29.7 m ASL).
	var lm1 := LandmarkMesh.new()
	copy_mats.call(lm1, ["Concrete"])
	_rect(lm1, "Concrete", -2.9, 2.9, -2.9, 2.9, -3.0, 3.6, 0.0)
	_add_seated_child(model, "WestRearPavilion", Vector3(-54.0, 0.0, -88.5), lm1)
	# 2. North park service pavilion (way 988585369).
	var lm2 := LandmarkMesh.new()
	copy_mats.call(lm2, ["Concrete", "Screen"])
	_rect(lm2, "Concrete", -14.8, 14.8, -3.2, 3.2, -3.0, 3.5, 0.0)
	_rect(lm2, "Screen", -15.0, 15.0, -3.4, 3.4, 3.5, 3.75, 0.0)
	_rect(lm2, "Screen", -11.0, 11.0, 3.16, 3.24, 1.1, 2.6, 0.0)
	_add_seated_child(model, "NorthServiceBuilding", Vector3(13.0, 0.0, -96.5), lm2)
	# 3. Historic twin entrance kiosks (ways 133733575 & 133733573).
	var lm3 := LandmarkMesh.new()
	copy_mats.call(lm3, ["Concrete", "KioskRoof"])
	for kx: float in [-3.8, 3.8]:
		_rect(lm3, "Concrete", kx - 2.75, kx + 2.75, -2.75, 2.75, -3.0, 3.1, 0.0)
		LandmarkFrKit.hip(lm3, "KioskRoof", kx - 2.85, kx + 2.85, -2.85, 2.85, 3.1, 1.85, 0.35)
		_rect(lm3, "KioskRoof", kx - 1.4, kx + 1.4, 2.71, 2.80, 1.0, 2.3, 0.0)
		_rect(lm3, "KioskRoof", kx - 1.8, kx + 1.8, 2.75, 3.55, 2.35, 2.50, 0.0)
	_add_seated_child(model, "EntranceKiosks", Vector3(50.9, 0.0, -96.0), lm3)

static func _add_seated_child(model: Node3D, node_name: String, pos: Vector3, lm: LandmarkMesh) -> void:
	var child := Node3D.new()
	child.name = node_name
	child.position = pos
	child.set_meta(LandmarkTerrain.SEAT_META, true)
	model.add_child(child)
	lm.commit(child)

static func _set_night_floods(model: Node3D) -> void:
	var spots: Array = []
	for lx in [-47.0, -28.0, -9.0, 10.0, 29.0, 48.0]:
		spots.append([Vector3(lx, 19.5, -52.5), Vector3(lx * 0.7, 0.2, 4.0),
			62.0, 0.9, 130.0, Color(0.95, 0.97, 1.0)])
	model.set_meta(LandmarkLights.FLOOD_META, spots)
