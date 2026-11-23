class_name LandmarkMiMarineStadium
extends RefCounted

## Miami Marine Stadium — Virginia Key (MI-10)
## Site: 3501 Rickenbacker Causeway, OSM way 477122363 (25.742885, -80.169891, yaw_deg 44.5).
## Architect: Hilario Candela (Pancoast, Ferendino, Grafton, Skeels & Burnham, 1963).
## Measured envelope & materials (Commons quarter/front/side, HABS/Docomomo 98.8 x 31.3 m, H = 21.0 m):
##   - Spanning 98.8 m along X (x = -49.4..+49.4 m) and 31.3 m along Z (z = -15.65..+15.65 m):
##     -Z faces the Virginia Key rowing basin (waterfront stage side), +Z faces the landward plaza.
##   - Roof: 8 dramatic folded-plate raw concrete hyperbolic-paraboloid cantilevers (plus half-end
##     wings) projecting 20 m forward over the seating bowl; front cantilever crowns reach exact
##     y = 21.0 m, rear crowns 17.6 m, valleys 13.4..15.8 m.
##   - Rear structure (+Z, quarter.jpg): 8 pairs of angled raw concrete V/A-frame compression/tension
##     struts rising from plinth pads (z = +13.8 m) to a heavy continuous concrete box-girder tie
##     beam (y = 11.4..13.4 m), balanced over 9 transverse fulcrum piers & raked grandstand bents.
##   - Bowl: 6,566-seat raked concrete grandstand tiers (y = 1.0..13.8 m) with weathered MiMo aqua
##     and gold seating bands, suspended press box, concourse decks & switchback entry ramps.

const HEIGHT_M := 21.0
const BAYS := 8
const BAY_W := 12.1
const HALF_SPAN := BAYS * BAY_W * 0.5 # 48.4 m (+ 1.0 m end overhangs = 98.8 m)

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#BEB9AE", 3.6))
	lm.use("ShellConcrete", LandmarkMaterials.pbr("roof_concrete", "#CBC6BC", 4.2))
	lm.use("DarkConcrete", LandmarkMaterials.pbr("concrete", "#8B877E", 3.2))
	lm.use("SeatAqua", LandmarkMaterials.paint("#3B8D94", 0.54, 0.08))
	lm.use("SeatGold", LandmarkMaterials.paint("#C9973E", 0.56, 0.08))
	lm.use("MuralAccent", LandmarkMaterials.pbr("render", "#4C7CA8", 3.5))
	lm.use("Steel", LandmarkMaterials.paint("#43494E", 0.48, 0.55))
	lm.use("Glass", LandmarkMaterials.glass("#263842"))

	_build_plinth_and_bents(lm)
	_build_seating_bowl_and_concourse(lm)
	_build_rear_aframes(lm)
	_build_folded_hypar_roof(lm)
	lm.commit(model)

	var cool := Color(0.84, 0.90, 1.0)
	var warm := Color(1.0, 0.86, 0.66)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-32.0, 2.0, -16.5), Vector3(-24.0, 17.5, -6.0), 58.0, 1.15, 42.0, warm],
		[Vector3(0.0, 2.0, -16.5), Vector3(0.0, 18.0, -6.0), 58.0, 1.15, 42.0, warm],
		[Vector3(32.0, 2.0, -16.5), Vector3(24.0, 17.5, -6.0), 58.0, 1.15, 42.0, warm],
		[Vector3(-28.0, 1.5, 17.5), Vector3(-20.0, 14.5, 9.0), 54.0, 1.00, 38.0, cool],
		[Vector3(28.0, 1.5, 17.5), Vector3(20.0, 14.5, 9.0), 54.0, 1.00, 38.0, cool],
	])

static func _build_plinth_and_bents(lm: LandmarkMesh) -> void:
	# Seawall apron (-Z facing rowing basin) & landward foundation slab (+Z) within 98.8 x 31.3 m
	lm.box("DarkConcrete", Vector3(0.0, 0.25, 0.0), Vector3(99.2, 1.30, 31.4))
	# Basin-side low concrete promenade & floating stage quay apron (-Z edge)
	lm.box("Concrete", Vector3(0.0, 1.05, -13.6), Vector3(98.4, 0.65, 4.0))
	lm.box("Concrete", Vector3(0.0, 1.25, -15.2), Vector3(26.0, 0.85, 2.4))

	# 9 transverse reinforced-concrete structural bents every 12.1 m supporting the bowl & roof fulcrum
	for b: int in BAYS + 1:
		var bx := -HALF_SPAN + float(b) * BAY_W
		# Main central fulcrum pier at z = +2.8 m carrying the 20 m roof cantilever
		lm.box("Concrete", Vector3(bx, 7.6, 2.8), Vector3(1.15, 13.8, 2.4))
		# Forward basin-side short pier at z = -8.6 m
		lm.box("Concrete", Vector3(bx, 2.6, -8.6), Vector3(0.95, 3.8, 1.5))
		# Rear concourse column at z = +9.8 m
		lm.box("Concrete", Vector3(bx, 6.4, 9.8), Vector3(0.95, 11.4, 1.4))
		# Sloped raker beam under the grandstand tiers from (-9.8, 1.6) up to (+9.8, 13.2)
		lm.beam("Concrete", Vector3(bx, 1.6, -9.8), Vector3(bx, 13.2, 9.8), 0.90, 1.25, Vector3.RIGHT)
		# Cantilever fulcrum spine haunch connecting central pier (2.8, 14.2) to rear tie beam (10.6, 13.0)
		lm.beam("Concrete", Vector3(bx, 14.4, 2.2), Vector3(bx, 13.0, 10.6), 0.95, 1.35, Vector3.RIGHT)

static func _build_seating_bowl_and_concourse(lm: LandmarkMesh) -> void:
	# 16 raked concrete seating tiers rising from z = -10.4 m (y = 1.5 m) to z = +9.2 m (y = 13.5 m)
	var tiers := 16
	for t: int in tiers:
		var u := float(t) / float(tiers - 1)
		var tz := lerpf(-10.4, 9.2, u)
		var ty := lerpf(1.55, 13.50, u)
		lm.box("Concrete", Vector3(0.0, ty - 0.32, tz), Vector3(96.8, 0.78, 1.32), Basis(), 0.0)
		# Skip central vomitory breaks on middle tiers for authentic aisle rhythm
		var seat_key := "SeatAqua" if (t % 3 != 2) else "SeatGold"
		for seg: int in 4:
			var sx := -36.5 + float(seg) * 24.33
			lm.box(seat_key, Vector3(sx, ty + 0.18, tz - 0.12), Vector3(21.8, 0.28, 0.62), Basis(), 0.0)

	# Front basin-side concrete parapet & safety rail along z = -11.2 m
	lm.box("Concrete", Vector3(0.0, 1.85, -11.2), Vector3(97.2, 1.05, 0.42))
	lm.beam("Steel", Vector3(-48.4, 2.55, -11.2), Vector3(48.4, 2.55, -11.2), 0.08, 0.08)

	# Multi-level open rear concourse slabs (+Z, y = 4.6 m and y = 8.6 m) + heritage mural wall bands
	lm.box("Concrete", Vector3(0.0, 4.6, 6.4), Vector3(96.4, 0.42, 7.6))
	lm.box("Concrete", Vector3(0.0, 8.6, 8.0), Vector3(96.4, 0.42, 4.8))
	for b: int in BAYS:
		var cx := -HALF_SPAN + (float(b) + 0.5) * BAY_W
		var mural_key := "MuralAccent" if (b % 2 == 0) else "SeatGold"
		lm.box(mural_key, Vector3(cx, 2.5, 4.2), Vector3(8.6, 2.8, 0.36))
		lm.box("Concrete", Vector3(cx, 6.4, 6.8), Vector3(7.4, 2.6, 0.34))

	# Elevated central press & broadcast box tucked beneath the upper cantilever (z = +5.2 m, y = 13.8..16.2 m)
	lm.box("Concrete", Vector3(0.0, 14.9, 5.4), Vector3(22.0, 2.4, 3.6))
	lm.box("Glass", Vector3(0.0, 15.0, 3.55), Vector3(20.4, 1.65, 0.24), Basis(), 0.0)

	# Symmetric east & west switchback pedestrian concrete entry ramps on rear flank (+Z)
	for sx: float in [-1.0, 1.0]:
		var rx := sx * 38.0
		lm.beam("Concrete", Vector3(rx - sx * 7.5, 0.9, 14.4), Vector3(rx + sx * 7.5, 4.65, 11.8),
			2.4, 0.42, Vector3(0.0, 0.0, 1.0))
		lm.beam("Concrete", Vector3(rx + sx * 7.5, 4.65, 11.8), Vector3(rx - sx * 6.5, 8.65, 10.6),
			2.2, 0.42, Vector3(0.0, 0.0, 1.0))

static func _build_rear_aframes(lm: LandmarkMesh) -> void:
	# Iconic rear horizontal raw-concrete box-girder tie beam & angled V-struts (quarter.jpg!)
	lm.box("Concrete", Vector3(0.0, 12.25, 10.8), Vector3(98.4, 2.10, 1.55))

	# 8 pairs of inclined concrete A/V struts rising from rear ground pads (z = +13.8 m, y = 0.6 m)
	# to the crown peaks along the rear tie girder (z = +10.4 m, y = 13.55 m)
	for b: int in BAYS:
		var x_left := -HALF_SPAN + float(b) * BAY_W
		var x_peak := x_left + BAY_W * 0.5
		var x_right := x_left + BAY_W
		lm.box("DarkConcrete", Vector3(x_left, 0.85, 13.8), Vector3(1.5, 0.9, 1.8))
		if b == BAYS - 1:
			lm.box("DarkConcrete", Vector3(x_right, 0.85, 13.8), Vector3(1.5, 0.9, 1.8))
		lm.beam("Concrete", Vector3(x_left + 0.25, 0.9, 13.8), Vector3(x_peak - 0.15, 13.55, 10.5),
			0.72, 0.88, Vector3(0.0, 0.0, 1.0))
		lm.beam("Concrete", Vector3(x_right - 0.25, 0.9, 13.8), Vector3(x_peak + 0.15, 13.55, 10.5),
			0.72, 0.88, Vector3(0.0, 0.0, 1.0))

	# Continuous upper rear concrete fascia spine wall behind the rear gable peaks (seen in quarter.jpg)
	lm.box("Concrete", Vector3(0.0, 16.4, 3.2), Vector3(97.6, 3.4, 0.65))

static func _build_folded_hypar_roof(lm: LandmarkMesh) -> void:
	# 8 hyperbolic-paraboloid folded-plate raw concrete shell bays spanning z = +10.8 m to z = -15.4 m.
	# Each half-bay (valley-to-peak or peak-to-valley) is a ruled hypar surface built via lm.grid
	# with upper ShellConcrete skin and underside Concrete soffit + crisp front/rear edge fascias.
	var z_rear := 10.8
	var z_mid := 2.6
	var z_front := -15.4
	var thick := 0.34

	for b: int in BAYS:
		var x0 := -HALF_SPAN + float(b) * BAY_W
		var xm := x0 + BAY_W * 0.5
		var x1 := x0 + BAY_W
		_emit_hypar_panel(lm, x0, xm, z_rear, z_mid, z_front,
			13.45, 17.65, 14.35, 18.65, 15.80, HEIGHT_M, thick)
		_emit_hypar_panel(lm, xm, x1, z_rear, z_mid, z_front,
			17.65, 13.45, 18.65, 14.35, HEIGHT_M, 15.80, thick)

		# Crisp front (-Z) & rear (+Z) folded concrete gable edge beams + vertical tie mullions at rear
		var p_fl := Vector3(x0, 15.80 - thick * 0.5, z_front)
		var p_fm := Vector3(xm, HEIGHT_M - 0.16, z_front)
		var p_fr := Vector3(x1, 15.80 - thick * 0.5, z_front)
		lm.beam("ShellConcrete", p_fl, p_fm, 0.32, 0.42, Vector3(0.0, 0.0, -1.0))
		lm.beam("ShellConcrete", p_fm, p_fr, 0.32, 0.42, Vector3(0.0, 0.0, -1.0))

		var p_rl := Vector3(x0, 13.45 - thick * 0.5, z_rear)
		var p_rm := Vector3(xm, 17.65 - thick * 0.5, z_rear)
		var p_rr := Vector3(x1, 13.45 - thick * 0.5, z_rear)
		lm.beam("ShellConcrete", p_rl, p_rm, 0.36, 0.48, Vector3(0.0, 0.0, 1.0))
		lm.beam("ShellConcrete", p_rm, p_rr, 0.36, 0.48, Vector3(0.0, 0.0, 1.0))

		# Slender vertical steel/concrete mullions in rear triangular clerestories (visible in quarter.jpg)
		for m: float in [-2.2, 0.0, 2.2]:
			var mx := xm + m
			var frac := 1.0 - absf(m) / (BAY_W * 0.5)
			var my_top := lerpf(13.45, 17.50, frac)
			lm.beam("Steel", Vector3(mx, 13.30, z_rear - 0.15), Vector3(mx, my_top, z_rear - 0.15), 0.10, 0.10)

	# Short end-cantilever half-wings at x = +-HALF_SPAN out to +-49.4 m
	for sx: float in [-1.0, 1.0]:
		var xe_in := sx * HALF_SPAN
		var xe_out := sx * 49.4
		var x_lo := minf(xe_in, xe_out)
		var x_hi := maxf(xe_in, xe_out)
		var y_l := 15.80 if sx > 0.0 else 16.50
		var y_r := 16.50 if sx > 0.0 else 15.80
		_emit_hypar_panel(lm, x_lo, x_hi, z_rear, z_mid, z_front,
			13.45, 13.85, 14.35, 14.85, y_l, y_r, thick)

static func _emit_hypar_panel(lm: LandmarkMesh, xa: float, xb: float,
		zr: float, zm: float, zf: float,
		yar: float, ybr: float, yam: float, ybm: float, yaf: float, ybf: float,
		thick: float) -> void:
	var nu := 4
	var top_rows: Array = []
	var bot_rows: Array = []
	var z_stops: Array[float] = [zr, lerpf(zr, zm, 0.5), zm, lerpf(zm, zf, 0.5), zf]
	var ya_stops: Array[float] = [yar, (yar + yam) * 0.5, yam, (yam + yaf) * 0.5, yaf]
	var yb_stops: Array[float] = [ybr, (ybr + ybm) * 0.5, ybm, (ybm + ybf) * 0.5, ybf]
	for j: int in z_stops.size():
		var z: float = z_stops[j]
		var ya: float = ya_stops[j]
		var yb: float = yb_stops[j]
		var r_top := PackedVector3Array()
		var r_bot := PackedVector3Array()
		for i: int in nu:
			var t := float(i) / float(nu - 1)
			var x := lerpf(xa, xb, t)
			var y := lerpf(ya, yb, t)
			r_top.append(Vector3(x, y, z))
			r_bot.append(Vector3(x, y - thick, z))
		top_rows.append(r_top)
		bot_rows.append(r_bot)
	lm.grid("ShellConcrete", top_rows, Vector3.UP)
	lm.grid("Concrete", bot_rows, Vector3.DOWN)
