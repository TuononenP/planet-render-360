class_name CarSpecs
extends RefCounted

## Body specs for the procedural cars and the city bus (VehicleKit.body), in metres with
## +X forward and the origin under the middle of the car. Each kind is a
## handful of proportions (BASE plus its own row); spec() expands them
## into the profile tables the loft reads. Generic shapes, no real model.

const BASE := {
	"len": 4.62, "wid": 1.80, "h": 1.44, "clear": 0.17,
	"belt_h": 0.93, "tail_h": 0.95, "bonnet_h": 0.92, "nose_h": 0.75,
	"wheel_r": 0.325, "tyre_w": 0.215, "front_oh": 0.9, "wb": 2.72,
	# Glasshouse: rear window foot and head, windscreen head and foot.
	"gh": [-1.72, -1.02, 0.22, 1.02], "drop_f": 0.06, "drop_r": 0.07,
	"tumble": 0.2, "rear_pillar": 0.5, "rear_glass": true, "extra_pillar": false,
	"clad": 0.0, "valance": 0.1, "spokes": 5, "twin": false, "tail_glass": false, "sign": false, "rails": false,
	# Window pillars this far apart along the side glass (0: per door).
	"pillar_step": 0.0,
	# Two-tone: the paint above this height takes livery_col (taxis).
	"livery_y": 100.0, "livery_col": Color.WHITE,
	"lamp_f": Vector2(0.6, 0.86), "lamp_r": Vector2(0.56, 0.84), "grille": Vector2(0.14, 0.48),
	# Head lamps: how deep into the nose they reach (share of the end rings)
	# and where their bezel's inner edge falls (share of the half width).
	"lamp_in": 0.3, "lamp_k": 0.68,
	# The front plate's height on the nose (share of the face).
	"plate_t": 0.3,
	# A bus's destination sign: this deep a band across the windscreen's
	# head (metres; 0: none), and a centre pillar splitting the screen.
	"board": 0.0, "split": false,
	# Plan: how far the nose and tail corners round in (metres), how wide
	# the end faces stay (share of the half width), how square the corners
	# are (superellipse power), the barrel's waist and how far the faces
	# bow out ahead of the corners.
	"corner_f": 0.34, "corner_r": 0.32, "end_w_f": 0.78, "end_w_r": 0.8, "corner_pow": 2.8,
	"taper": 0.035, "bulge_f": 0.12, "bulge_r": 0.08,
	# Section: the side's bow up the flank (height share, share of the half
	# width), the shoulder's character line (height share, metres stepped
	# in above it), the arch flares (metres out), the crowns.
	"bulge": [Vector2(0.0, 0.93), Vector2(0.12, 0.975), Vector2(0.4, 1.0), Vector2(0.75, 0.99),
		Vector2(0.94, 0.965), Vector2(1.0, 0.94)],
	"shoulder": Vector2(0.8, 0.012), "flare": 0.025, "roof_crown": 0.05, "glass_crown": 0.09,
	# End faces lean back above the bumper: this far at the belt (metres),
	# from this share of the face height up.
	"rake_f": 0.13, "rake_r": 0.07, "bumper_t": 0.42,
	# The side glass stops this far behind the windscreen's foot (metres).
	"a_gap": 0.1,
	# Lamp clusters: the inner end's share of the lamp height (a swept,
	# narrowing lamp below 1) and how far they wrap round onto the flank (metres).
	"lamp_taper_f": 0.6, "lamp_taper_r": 0.85, "wrap_f": 0.12, "wrap_r": 0.1,
	# The tail lamp's inner edge (share of the half width; upright lamps sit
	# out at the corners).
	"lamp_k_r": 0.45,
	# Details (CarDetails): a cabin seen through the glass and its rear
	# seats, the driver on the right, a chrome window line and grille
	# surround, a rear wiper, an open load bed behind the cab.
	"cabin": true, "rear_seats": true, "rhd": false, "chrome": false, "rear_wiper": false, "bed": false,
}

const KINDS := {
	"sedan": {"twin": true, "chrome": true},
	"hatch": {"len": 4.06, "wid": 1.76, "h": 1.47, "clear": 0.16, "tail_h": 0.98, "bonnet_h": 0.92,
		"nose_h": 0.72, "wheel_r": 0.31, "front_oh": 0.85, "wb": 2.56,
		"gh": [-1.93, -1.5, 0.3, 1.02], "rear_pillar": 0.42, "lamp_r": Vector2(0.6, 0.9),
		"corner_f": 0.38, "end_w_f": 0.74, "bulge_f": 0.13, "rake_r": 0.0, "flare": 0.03, "rear_wiper": true},
	"wagon": {"len": 4.72, "h": 1.47, "tail_h": 0.97, "wb": 2.76,
		"gh": [-2.24, -1.93, 0.22, 1.04], "rear_pillar": 0.3, "extra_pillar": true, "rails": true,
		"lamp_r": Vector2(0.6, 0.9), "rake_r": 0.02, "twin": true,
		"chrome": true, "rear_wiper": true},
	"suv": {"len": 4.66, "wid": 1.86, "h": 1.68, "clear": 0.22, "belt_h": 1.04, "tail_h": 1.08,
		"bonnet_h": 1.05, "nose_h": 0.88, "wheel_r": 0.365, "tyre_w": 0.235, "wb": 2.7,
		"gh": [-2.2, -1.9, 0.25, 0.95], "tumble": 0.17, "rear_pillar": 0.32, "extra_pillar": true,
		"clad": 0.16, "rails": true, "lamp_f": Vector2(0.58, 0.88), "lamp_r": Vector2(0.6, 0.88),
		"corner_f": 0.3, "end_w_f": 0.82, "corner_pow": 3.2, "flare": 0.045, "shoulder": Vector2(0.78, 0.016),
		"rake_f": 0.1, "rake_r": 0.02, "lamp_taper_f": 0.7, "rear_wiper": true},
	"van": {"len": 5.0, "wid": 1.95, "h": 1.96, "clear": 0.19, "belt_h": 1.12, "tail_h": 1.14,
		"bonnet_h": 1.1, "nose_h": 0.88, "wheel_r": 0.34, "front_oh": 0.95, "wb": 3.1,
		"gh": [-2.62, -2.56, 1.05, 1.72], "drop_f": 0.04, "drop_r": 0.02, "tumble": 0.08,
		"rear_glass": false, "lamp_f": Vector2(0.5, 0.76), "lamp_r": Vector2(0.3, 0.75),
		"corner_f": 0.3, "corner_r": 0.16, "end_w_f": 0.82, "end_w_r": 0.9, "corner_pow": 3.4, "bulge_r": 0.03,
		"taper": 0.015, "flare": 0.015, "shoulder": Vector2(0.55, 0.01), "rake_f": 0.1, "rake_r": 0.0,
		"lamp_taper_f": 0.8, "rear_seats": false, "lamp_k_r": 0.8, "bulge": [Vector2(0.0, 0.965), Vector2(0.15, 0.99), Vector2(0.5, 1.0), Vector2(0.85, 0.995), Vector2(1.0, 0.975)]},
	# A crew cab ahead of a covered load bed.
	"pickup": {"len": 5.35, "wid": 1.95, "h": 1.84, "clear": 0.24, "belt_h": 1.14, "tail_h": 1.16,
		"bonnet_h": 1.16, "nose_h": 1.0, "wheel_r": 0.39, "tyre_w": 0.26, "front_oh": 0.95, "wb": 3.3,
		"gh": [-0.62, -0.5, 0.72, 1.38], "drop_f": 0.04, "drop_r": 0.03, "tumble": 0.12,
		"rear_pillar": 0.2, "clad": 0.12, "spokes": 6, "lamp_f": Vector2(0.6, 0.8),
		"lamp_r": Vector2(0.45, 0.85), "corner_f": 0.28, "corner_r": 0.14, "end_w_f": 0.86, "end_w_r": 0.92,
		"corner_pow": 3.4, "bulge_r": 0.03, "flare": 0.05, "shoulder": Vector2(0.7, 0.015), "rake_f": 0.06,
		"rake_r": 0.0, "lamp_taper_f": 0.9, "lamp_k_r": 0.8, "bed": true},
	# Tall, short and narrow: the Japanese light car.
	"kei": {"len": 3.4, "wid": 1.48, "h": 1.72, "clear": 0.15, "belt_h": 0.96, "tail_h": 0.98,
		"bonnet_h": 1.0, "nose_h": 0.86, "wheel_r": 0.275, "tyre_w": 0.165, "front_oh": 0.62, "wb": 2.46,
		"gh": [-1.82, -1.76, 0.72, 1.24], "drop_f": 0.04, "drop_r": 0.02, "tumble": 0.07,
		"rear_pillar": 0.34, "tail_glass": true, "lamp_f": Vector2(0.56, 0.8), "lamp_r": Vector2(0.3, 0.6),
		"corner_f": 0.26, "corner_r": 0.16, "end_w_f": 0.82, "end_w_r": 0.88, "corner_pow": 3.2, "bulge_r": 0.03,
		"taper": 0.01, "flare": 0.01, "rake_f": 0.07, "rake_r": 0.0, "lamp_taper_f": 0.8, "rhd": true,
		"lamp_k_r": 0.72, "bulge": [Vector2(0.0, 0.965), Vector2(0.15, 0.99), Vector2(0.5, 1.0), Vector2(0.85, 0.995), Vector2(1.0, 0.975)]},
	"minivan": {"len": 4.85, "wid": 1.9, "h": 1.76, "clear": 0.17, "belt_h": 1.0, "tail_h": 1.02,
		"bonnet_h": 1.03, "nose_h": 0.86, "wheel_r": 0.335, "front_oh": 0.95, "wb": 3.0,
		"gh": [-2.56, -2.5, 0.85, 1.68], "drop_f": 0.05, "drop_r": 0.02, "tumble": 0.12,
		"rear_pillar": 0.5, "extra_pillar": true, "tail_glass": true,
		"lamp_f": Vector2(0.58, 0.8), "lamp_r": Vector2(0.4, 0.8),
		"corner_r": 0.22, "flare": 0.02, "rake_f": 0.12, "rake_r": 0.0, "lamp_k_r": 0.7},
	"compact_suv": {"len": 4.3, "wid": 1.8, "h": 1.6, "clear": 0.2, "belt_h": 1.0, "tail_h": 1.04,
		"bonnet_h": 1.0, "nose_h": 0.85, "wheel_r": 0.345, "tyre_w": 0.225, "front_oh": 0.86, "wb": 2.6,
		"gh": [-2.03, -1.76, 0.28, 0.96], "tumble": 0.17, "rear_pillar": 0.3, "clad": 0.14, "rails": true,
		"lamp_f": Vector2(0.58, 0.88), "lamp_r": Vector2(0.6, 0.88), "flare": 0.04, "shoulder": Vector2(0.78, 0.015),
		"rake_f": 0.11, "rake_r": 0.03, "rear_wiper": true},
	# The tall, upright London cab.
	"cab_london": {"len": 4.6, "wid": 1.86, "h": 1.84, "clear": 0.17, "belt_h": 1.02, "tail_h": 1.04,
		"bonnet_h": 1.04, "nose_h": 0.92, "wheel_r": 0.33, "front_oh": 0.78, "wb": 2.9,
		"gh": [-2.12, -1.88, 0.5, 1.2], "drop_f": 0.04, "drop_r": 0.04, "tumble": 0.1,
		"rear_pillar": 0.5, "sign": true, "lamp_f": Vector2(0.6, 0.84), "lamp_r": Vector2(0.45, 0.8),
		"corner_f": 0.42, "end_w_f": 0.7, "corner_pow": 2.4, "flare": 0.06, "shoulder": Vector2(0.75, 0.0),
		"rake_f": 0.08, "rake_r": 0.04, "lamp_taper_f": 1.0, "rhd": true, "chrome": true},
	# A twelve-metre city bus: a glazed box on a low floor.
	"bus": {"len": 12.0, "wid": 2.55, "h": 3.05, "clear": 0.3, "belt_h": 1.1, "tail_h": 1.1,
		"bonnet_h": 1.3, "nose_h": 1.28, "wheel_r": 0.48, "tyre_w": 0.3, "front_oh": 2.7, "wb": 5.9,
		"gh": [-6.2, -6.14, 5.55, 5.86], "drop_f": 0.05, "drop_r": 0.02, "tumble": 0.03,
		"rear_pillar": 0.9, "tail_glass": true, "pillar_step": 1.45, "spokes": 8,
		"lamp_f": Vector2(0.3, 0.74), "lamp_r": Vector2(0.3, 0.6), "grille": Vector2(0.12, 0.22),
		"lamp_in": 0.5, "lamp_k": 0.45, "valance": 0.26, "plate_t": 0.13, "board": 0.34, "split": true,
		"corner_f": 0.25, "corner_r": 0.25, "end_w_f": 0.9, "end_w_r": 0.9, "corner_pow": 4.0, "taper": 0.005,
		"bulge_f": 0.06, "bulge_r": 0.04, "flare": 0.0, "shoulder": Vector2(0.5, 0.0), "rake_f": 0.0, "rake_r": 0.0,
		"lamp_taper_f": 1.0, "lamp_taper_r": 1.0, "wrap_f": 0.05, "wrap_r": 0.05, "cabin": false,
		"bulge": [Vector2(0.0, 0.985), Vector2(0.1, 1.0), Vector2(1.0, 1.0)]},
	# Saloon cabs: a roof sign, and where the city has one, a roof colour.
	"taxi": {"sign": true, "twin": true, "chrome": true},
	"taxi_lisbon": {"sign": true, "chrome": true, "livery_y": 1.0, "livery_col": Color(0.0, 0.42, 0.36)},
}

static var _specs := {}

static func has(kind: String) -> bool:
	return KINDS.has(kind)

static func length_m(kind: String) -> float:
	return float((KINDS.get(kind, {}) as Dictionary).get("len", BASE["len"]))

static func width_m(kind: String) -> float:
	return float((KINDS.get(kind, {}) as Dictionary).get("wid", BASE["wid"]))

static func spec(kind: String) -> Dictionary:
	if not _specs.has(kind):
		var p: Dictionary = BASE.duplicate()
		p.merge(KINDS.get(kind, {}), true)
		_specs[kind] = _expand(p)
	return _specs[kind]

static func _expand(p: Dictionary) -> Dictionary:
	var s: Dictionary = p.duplicate()
	var half := float(p["len"]) * 0.5
	var clear := float(p["clear"])
	var axle_f := half - float(p["front_oh"])
	var axle_r := axle_f - float(p["wb"])
	var arch := float(p["wheel_r"]) + 0.06
	var g: Array = p["gh"]
	var gh := PackedFloat32Array([g[0], g[1], g[2], g[3]])
	var belt_h := float(p["belt_h"])
	s["axle_f"] = axle_f
	s["axle_r"] = axle_r
	s["arch_r"] = arch
	s["gh"] = gh
	s["well"] = 0.27
	s["shelf"] = 0.04
	s["lamp_wrap"] = 0.2
	s["lamp_wrap_f"] = 0.1
	s["lamp_in_r"] = 0.5
	s["floor"] = PackedVector2Array([Vector2(-half, clear + 0.17), Vector2(axle_r - 0.4, clear + 0.03),
		Vector2(axle_r, clear), Vector2(axle_f, clear), Vector2(axle_f + 0.4, clear + 0.03),
		Vector2(half, clear + 0.12)])
	var belt := PackedVector2Array([Vector2(-half, float(p["tail_h"]) - 0.07),
		Vector2(-half + 0.3, float(p["tail_h"])), Vector2(gh[2], belt_h), Vector2(gh[3], float(p["bonnet_h"])),
		Vector2((gh[3] + half) * 0.5, lerpf(float(p["bonnet_h"]), float(p["nose_h"]), 0.42)),
		Vector2(half - 0.18, float(p["nose_h"])), Vector2(half, float(p["nose_h"]) - 0.07)])
	belt.sort()
	s["belt"] = belt
	var crown := PackedVector2Array([Vector2(-half, 0.03), Vector2(gh[3], 0.06), Vector2(half, 0.04)])
	s["crown"] = crown
	s["bulge"] = PackedVector2Array(p["bulge"])
	s["gh_w"] = PackedVector2Array([Vector2(gh[0], 0.8), Vector2(minf(gh[1] + 0.35, gh[2]), 0.92),
		Vector2(gh[2], 0.92), Vector2(gh[3], 0.86)])
	var h := float(p["h"])
	var deck_r := VehicleKit.lin(belt, gh[0]) + 0.012 + VehicleKit.lin(crown, gh[0])
	var deck_f := VehicleKit.lin(belt, gh[3]) + 0.012 + VehicleKit.lin(crown, gh[3])
	s["roof"] = PackedVector2Array([Vector2(gh[0], deck_r), Vector2(gh[1], h - float(p["drop_r"])),
		Vector2(lerpf(gh[1], gh[2], 0.45), h), Vector2(gh[2], h - float(p["drop_f"])), Vector2(gh[3], deck_f)])
	s["gh_full"] = h - 0.05 - belt_h
	# The sign band's foot: where the screen has fallen `board` from its head.
	var bx := gh[2]
	if float(p["board"]) > 0.0:
		var head := VehicleKit.soft(s["roof"], gh[2], 0.07)
		while bx < gh[3] and VehicleKit.soft(s["roof"], bx, 0.07) > head - float(p["board"]):
			bx += 0.002
	s["board_x"] = bx
	# Doors: the front cut behind the front arch, the rear ahead of the
	# rear arch, the centre pillar between.
	var door_f := axle_f - arch - 0.1
	var door_r := axle_r + arch + 0.08
	var door_b := lerpf(door_r, door_f, 0.52)
	s["doors"] = PackedFloat32Array([door_r, door_b, door_f])
	var glass_r := gh[0] + float(p["rear_pillar"]) if bool(p["rear_glass"]) else door_b + 0.05
	var glass_f := gh[3] - float(p["a_gap"])
	s["side_glass"] = Vector2(glass_r, glass_f)
	var pillars: Array[Vector2] = []
	if bool(p["rear_glass"]):
		pillars.append(Vector2(door_b - 0.05, door_b + 0.05))
	var step := float(p["pillar_step"])
	if step > 0.0:
		pillars.clear()
		var px := glass_r + step
		while px < gh[3] - 0.6:
			pillars.append(Vector2(px - 0.05, px + 0.05))
			px += step
	if bool(p["extra_pillar"]):
		pillars.append(Vector2(door_r - 0.2, door_r - 0.1))
	s["pillars"] = pillars
	var cuts: Array[float] = [glass_r, glass_f, half - float(p["bulge_f"]) - 0.2, -half + float(p["bulge_r"]) + 0.2]
	for pl in pillars:
		cuts.append_array([pl.x, pl.y])
	s["cuts"] = cuts
	s["cuts_far"] = [glass_r, glass_f]
	# An open bed from behind the cab to the tailgate's inner face.
	s["bed_x"] = Vector2(-half + float(p["bulge_r"]) + 0.1, gh[0] - 0.06)
	if bool(p["bed"]):
		(s["cuts"] as Array).append_array([s["bed_x"].x, s["bed_x"].y])
	return s
