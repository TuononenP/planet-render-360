class_name CarSpecs
extends RefCounted

## Body specs for the procedural cars and the city bus (VehicleKit.body), in metres with
## +X forward and the origin under the middle of the car. Each kind is a
## handful of proportions (BASE plus its own row); spec() expands them
## into the profile tables the loft reads. Generic shapes, no real model.

const BASE := {
	# The base is the saloon: a low fastback on a long wheelbase, its belt
	# rising to a high tail, wheels out at the corners.
	"len": 4.72, "wid": 1.85, "h": 1.43, "clear": 0.15,
	"belt_h": 0.97, "tail_h": 1.03, "bonnet_h": 0.94, "nose_h": 0.7,
	"wheel_r": 0.345, "tyre_w": 0.235, "front_oh": 0.88, "wb": 2.9,
	# The gap between the tyre and its arch (metres), and the least the arch's
	# roof may stay under the body's top line: a low nose needs the arch
	# roof to clear the tyre, whatever that leaves of the wing.
	"arch_gap": 0.045, "arch_margin": 0.08,
	# Glasshouse: rear window foot and head, windscreen head and foot.
	"gh": [-1.86, -0.95, 0.2, 1.06], "drop_f": 0.05, "drop_r": 0.05,
	"tumble": 0.24, "rear_pillar": 0.6, "rear_glass": true, "extra_pillar": false,
	"clad": 0.0, "valance": 0.1, "valance_r": 0.1, "spokes": 5, "twin": false, "tail_glass": false,
	"sign": false, "rails": false,
	# Window pillars this far apart along the side glass (0: per door).
	"pillar_step": 0.0,
	# Two-tone: the paint above this height takes livery_col (taxis).
	"livery_y": 100.0, "livery_col": Color.WHITE,
	"lamp_f": Vector2(0.68, 0.87), "lamp_r": Vector2(0.66, 0.85), "grille": Vector2(0.12, 0.44),
	# Head lamps: how deep into the nose they reach (share of the end rings)
	# and where their bezel's inner edge falls (share of the half width).
	"lamp_in": 0.3, "lamp_k": 0.6,
	# The front plate's height on the nose (share of the face).
	"plate_t": 0.28,
	# A bus's destination sign: this deep a band across the windscreen's
	# head (metres; 0: none), and a centre pillar splitting the screen.
	"board": 0.0, "split": false,
	# Plan: how far the nose and tail corners round in (metres), how wide
	# the end faces stay (share of the half width), how square the corners
	# are (superellipse power), the barrel's waist and how far the faces
	# bow out ahead of the corners.
	"corner_f": 0.3, "corner_r": 0.26, "end_w_f": 0.8, "end_w_r": 0.84, "corner_pow": 3.0,
	"taper": 0.03, "bulge_f": 0.13, "bulge_r": 0.07,
	# Section: the side's bow up the flank (height share, share of the half
	# width), the shoulder's character line (height share, metres stepped
	# in above it), the sill line (height share, metres tucked under below
	# it), the arch flares (metres out), the crowns.
	"bulge": [Vector2(0.0, 0.955), Vector2(0.22, 0.985), Vector2(0.5, 1.0), Vector2(0.8, 0.994),
		Vector2(0.94, 0.972), Vector2(1.0, 0.95)],
	"shoulder": Vector2(0.84, 0.014), "sill": Vector2(0.26, 0.016), "flare": 0.03,
	"roof_crown": 0.05, "glass_crown": 0.09,
	# End faces lean back above the bumper: this far at the belt (metres),
	# from this share of the face height up. The tail's top edge may kick
	# up into a lip (metres).
	"rake_f": 0.16, "rake_r": 0.08, "bumper_t": 0.4, "kick": 0.0,
	# The side glass stops this far behind the windscreen's foot (metres).
	"a_gap": 0.1,
	# Lamp clusters: the inner end's share of the lamp height (a swept,
	# narrowing lamp below 1) and how far they wrap round onto the flank (metres).
	"lamp_taper_f": 0.55, "lamp_taper_r": 0.8, "wrap_f": 0.16, "wrap_r": 0.12,
	# The tail lamp's inner edge (share of the half width; upright lamps sit
	# out at the corners).
	"lamp_k_r": 0.4,
	# Details (CarDetails): a cabin seen through the glass and its rear
	# seats, the driver on the right, a chrome window line and grille
	# surround, a rear wiper, an open load bed behind the cab.
	"cabin": true, "rear_seats": true, "rhd": false, "chrome": false, "rear_wiper": false, "bed": false,
	# Two long doors (doors_n 2: one per side, no centre post) instead of a
	# front and a rear pair; an engine behind the seats (louvres over the
	# rear deck, intakes behind the doors); the bonnet's and the deck's crowns.
	"doors_n": 4, "mid_engine": false, "aero_f": false,
	# How far the nose's floor edge stands above the road at its tip (metres, over `clear`).
	"nose_floor": 0.12,
	# Head lamps as slim blades: a thick daytime strip and one lens, no round projectors.
	"lamp_blade": false, "crown_f": 0.06, "crown_r": 0.03,
	# Styling: gloss-black pillars under a floating roof, a glass roof
	# panel, a black rim, red calipers, light bars joining the head and the
	# tail lamps, a nose without an upper grille, corner vents in the front
	# bumper, a lip over the rear window.
	"black_pillars": false, "roof_glass": false, "dark_wheels": false, "sport": false,
	"bar_f": false, "bar_r": false, "grille_closed": false, "vents": true, "spoiler": false,
}

const KINDS := {
	"sedan": {"twin": true, "chrome": true, "extra_pillar": true, "bar_r": true, "kick": 0.025, "valance_r": 0.2,
		"roof_glass": true},
	# A hot hatch: short tail, lip spoiler, red calipers.
	"hatch": {"len": 4.12, "wid": 1.79, "h": 1.45, "tail_h": 1.05, "bonnet_h": 0.93, "nose_h": 0.71,
		"wheel_r": 0.335, "front_oh": 0.84, "wb": 2.63, "gh": [-1.92, -1.45, 0.26, 1.02], "rear_pillar": 0.4,
		"lamp_r": Vector2(0.62, 0.86), "lamp_k_r": 0.5, "corner_f": 0.32, "end_w_f": 0.78, "rake_r": 0.0,
		"flare": 0.035, "rear_wiper": true, "spoiler": true, "sport": true, "valance_r": 0.2, "black_pillars": true},
	"wagon": {"len": 4.78, "h": 1.46, "tail_h": 1.03, "gh": [-2.24, -1.9, 0.2, 1.06], "rear_pillar": 0.3,
		"extra_pillar": true, "rails": true, "lamp_r": Vector2(0.62, 0.88), "lamp_k_r": 0.55, "rake_r": 0.02,
		"twin": true, "chrome": true, "rear_wiper": true, "spoiler": true},
	# A big SUV: high belt, glass roof, black wheels, light bar.
	"suv": {"len": 4.72, "wid": 1.92, "h": 1.67, "clear": 0.21, "belt_h": 1.09, "tail_h": 1.15,
		"bonnet_h": 1.07, "nose_h": 0.86, "wheel_r": 0.385, "tyre_w": 0.26, "front_oh": 0.9, "wb": 2.84,
		"gh": [-2.2, -1.85, 0.2, 0.98], "tumble": 0.2, "rear_pillar": 0.34, "extra_pillar": true,
		"clad": 0.15, "rails": true, "lamp_f": Vector2(0.72, 0.88), "lamp_r": Vector2(0.68, 0.86),
		"corner_f": 0.28, "end_w_f": 0.84, "corner_pow": 3.4, "flare": 0.045, "shoulder": Vector2(0.84, 0.016),
		"rake_f": 0.1, "rake_r": 0.03, "lamp_taper_f": 0.7, "rear_wiper": true, "spoiler": true,
		"roof_glass": true, "dark_wheels": true, "bar_r": true, "grille": Vector2(0.16, 0.5)},
	"van": {"len": 5.0, "wid": 1.95, "h": 1.96, "clear": 0.19, "belt_h": 1.12, "tail_h": 1.14,
		"bonnet_h": 1.1, "nose_h": 0.88, "wheel_r": 0.35, "front_oh": 0.95, "wb": 3.1,
		"gh": [-2.62, -2.56, 1.05, 1.72], "drop_f": 0.04, "drop_r": 0.02, "tumble": 0.08,
		"rear_glass": false, "lamp_f": Vector2(0.54, 0.74), "lamp_r": Vector2(0.3, 0.75),
		"corner_f": 0.3, "corner_r": 0.16, "end_w_f": 0.82, "end_w_r": 0.9, "corner_pow": 3.4, "bulge_r": 0.03,
		"taper": 0.015, "flare": 0.015, "shoulder": Vector2(0.55, 0.01), "sill": Vector2(0.22, 0.008),
		"rake_f": 0.1, "rake_r": 0.0, "lamp_taper_f": 0.8, "rear_seats": false, "lamp_k_r": 0.8,
		"valance": 0.26, "valance_r": 0.26, "vents": false, "bulge": [Vector2(0.0, 0.975), Vector2(0.2, 0.992), Vector2(0.5, 1.0), Vector2(0.85, 0.996), Vector2(1.0, 0.98)]},
	# A crew cab ahead of an open load bed.
	"pickup": {"len": 5.4, "wid": 2.0, "h": 1.92, "clear": 0.27, "belt_h": 1.22, "tail_h": 1.24,
		"bonnet_h": 1.24, "nose_h": 1.1, "wheel_r": 0.42, "tyre_w": 0.285, "front_oh": 0.95, "wb": 3.4,
		"arch_gap": 0.075, "gh": [-0.66, -0.52, 0.7, 1.34], "drop_f": 0.04, "drop_r": 0.03, "tumble": 0.1,
		"rear_pillar": 0.2, "clad": 0.13, "valance": 0.16, "spokes": 6, "lamp_f": Vector2(0.68, 0.86),
		"lamp_r": Vector2(0.5, 0.88), "corner_f": 0.24, "corner_r": 0.12, "end_w_f": 0.9, "end_w_r": 0.94,
		"corner_pow": 3.8, "bulge_f": 0.07, "bulge_r": 0.03, "flare": 0.06, "shoulder": Vector2(0.76, 0.016),
		"sill": Vector2(0.22, 0.01), "rake_f": 0.04, "rake_r": 0.0, "lamp_taper_f": 1.0, "lamp_k": 0.66,
		"lamp_k_r": 0.82, "bed": true, "dark_wheels": true, "grille": Vector2(0.18, 0.56),
		"vents": false, "bulge": [Vector2(0.0, 0.975), Vector2(0.2, 0.992), Vector2(0.5, 1.0), Vector2(0.85, 0.996), Vector2(1.0, 0.98)]},
	# Tall, short and narrow: the Japanese light car.
	"kei": {"len": 3.4, "wid": 1.48, "h": 1.72, "clear": 0.15, "belt_h": 0.96, "tail_h": 0.98,
		"bonnet_h": 1.0, "nose_h": 0.86, "wheel_r": 0.285, "tyre_w": 0.165, "front_oh": 0.58, "wb": 2.4,
		"gh": [-1.82, -1.76, 0.72, 1.24], "drop_f": 0.04, "drop_r": 0.02, "tumble": 0.07,
		"rear_pillar": 0.34, "tail_glass": true, "lamp_f": Vector2(0.6, 0.82), "lamp_r": Vector2(0.3, 0.6),
		"corner_f": 0.26, "corner_r": 0.16, "end_w_f": 0.82, "end_w_r": 0.88, "corner_pow": 3.2, "bulge_r": 0.03,
		"taper": 0.01, "flare": 0.012, "rake_f": 0.07, "rake_r": 0.0, "lamp_taper_f": 0.8, "rhd": true,
		"lamp_k_r": 0.72, "sill": Vector2(0.22, 0.008), "black_pillars": true, "vents": false, "bulge": [Vector2(0.0, 0.975), Vector2(0.2, 0.992), Vector2(0.5, 1.0), Vector2(0.85, 0.996), Vector2(1.0, 0.98)]},
	"minivan": {"len": 4.85, "wid": 1.9, "h": 1.76, "clear": 0.17, "belt_h": 1.02, "tail_h": 1.05,
		"bonnet_h": 1.03, "nose_h": 0.84, "wheel_r": 0.35, "front_oh": 0.95, "wb": 3.0,
		"gh": [-2.56, -2.5, 0.85, 1.68], "drop_f": 0.05, "drop_r": 0.02, "tumble": 0.12,
		"rear_pillar": 0.5, "extra_pillar": true, "tail_glass": true,
		"lamp_f": Vector2(0.64, 0.82), "lamp_r": Vector2(0.4, 0.8),
		"corner_r": 0.22, "flare": 0.02, "rake_f": 0.12, "rake_r": 0.0, "lamp_k_r": 0.7, "bar_f": true, "grille_closed": true,
		"black_pillars": true},
	# A crossover: black pillars under a floating roof.
	"compact_suv": {"len": 4.34, "wid": 1.82, "h": 1.58, "clear": 0.2, "belt_h": 1.04, "tail_h": 1.11,
		"bonnet_h": 1.01, "nose_h": 0.84, "wheel_r": 0.365, "tyre_w": 0.24, "front_oh": 0.86, "wb": 2.66,
		"gh": [-2.03, -1.7, 0.26, 0.98], "tumble": 0.2, "rear_pillar": 0.3, "clad": 0.14,
		"lamp_f": Vector2(0.72, 0.88), "lamp_r": Vector2(0.64, 0.86), "flare": 0.04, "shoulder": Vector2(0.84, 0.015),
		"rake_f": 0.11, "rake_r": 0.03, "rear_wiper": true, "spoiler": true, "black_pillars": true,
		"grille_closed": true, "bar_f": true, "bar_r": true, "valance_r": 0.18},
	# The tall, upright London cab.
	"cab_london": {"len": 4.6, "wid": 1.86, "h": 1.84, "clear": 0.17, "belt_h": 1.02, "tail_h": 1.04,
		"bonnet_h": 1.04, "nose_h": 0.92, "wheel_r": 0.335, "front_oh": 0.78, "wb": 2.9,
		"gh": [-2.12, -1.88, 0.5, 1.2], "drop_f": 0.04, "drop_r": 0.04, "tumble": 0.1,
		"rear_pillar": 0.5, "sign": true, "lamp_f": Vector2(0.6, 0.84), "lamp_r": Vector2(0.45, 0.8),
		"corner_f": 0.42, "end_w_f": 0.7, "corner_pow": 2.4, "flare": 0.06, "shoulder": Vector2(0.75, 0.0),
		"sill": Vector2(0.22, 0.0), "rake_f": 0.08, "rake_r": 0.04, "lamp_taper_f": 1.0, "lamp_k": 0.68,
		"lamp_k_r": 0.45, "wrap_f": 0.1, "rhd": true, "chrome": true, "vents": false, "arch_gap": 0.06},
	# A twelve-metre city bus: a glazed box on a low floor.
	"bus": {"len": 12.0, "wid": 2.55, "h": 3.05, "clear": 0.3, "belt_h": 1.1, "tail_h": 1.1,
		"bonnet_h": 1.3, "nose_h": 1.28, "wheel_r": 0.48, "tyre_w": 0.3, "front_oh": 2.7, "wb": 5.9,
		"gh": [-6.2, -6.14, 5.55, 5.86], "drop_f": 0.05, "drop_r": 0.02, "tumble": 0.03,
		"rear_pillar": 0.9, "tail_glass": true, "pillar_step": 1.45, "spokes": 8,
		"lamp_f": Vector2(0.3, 0.74), "lamp_r": Vector2(0.3, 0.6), "grille": Vector2(0.12, 0.22),
		"lamp_in": 0.5, "lamp_k": 0.45, "lamp_k_r": 0.45, "valance": 0.26, "valance_r": 0.26, "plate_t": 0.13,
		"board": 0.34, "split": true, "arch_gap": 0.06,
		"corner_f": 0.25, "corner_r": 0.25, "end_w_f": 0.9, "end_w_r": 0.9, "corner_pow": 4.0, "taper": 0.005,
		"bulge_f": 0.06, "bulge_r": 0.04, "flare": 0.0, "shoulder": Vector2(0.5, 0.0), "sill": Vector2(0.2, 0.0),
		"rake_f": 0.0, "rake_r": 0.0, "lamp_taper_f": 1.0, "lamp_taper_r": 1.0, "wrap_f": 0.05, "wrap_r": 0.05,
		"cabin": false, "vents": false,
		"bulge": [Vector2(0.0, 0.985), Vector2(0.1, 1.0), Vector2(1.0, 1.0)]},
	# London double-decker bus (New Routemaster proportions: 11.2 m x 2.55 m x 4.38 m).
	"bus_double": {"len": 11.2, "wid": 2.55, "h": 4.38, "clear": 0.3, "belt_h": 1.15, "tail_h": 1.15,
		"bonnet_h": 1.35, "nose_h": 1.3, "wheel_r": 0.48, "tyre_w": 0.3, "front_oh": 2.5, "wb": 5.8,
		"gh": [-5.7, -5.62, 5.15, 5.45], "drop_f": 0.06, "drop_r": 0.03, "tumble": 0.03,
		"rear_pillar": 0.85, "tail_glass": true, "pillar_step": 1.4, "spokes": 8, "rhd": true,
		"lamp_f": Vector2(0.3, 0.74), "lamp_r": Vector2(0.3, 0.6), "grille": Vector2(0.12, 0.22),
		"lamp_in": 0.5, "lamp_k": 0.45, "lamp_k_r": 0.45, "valance": 0.26, "valance_r": 0.26, "plate_t": 0.13,
		"board": 0.34, "split": true, "arch_gap": 0.06,
		"corner_f": 0.28, "corner_r": 0.26, "end_w_f": 0.88, "end_w_r": 0.9, "corner_pow": 4.0, "taper": 0.005,
		"bulge_f": 0.06, "bulge_r": 0.04, "flare": 0.0, "shoulder": Vector2(0.5, 0.0), "sill": Vector2(0.2, 0.0),
		"rake_f": 0.0, "rake_r": 0.0, "lamp_taper_f": 1.0, "lamp_taper_r": 1.0, "wrap_f": 0.05, "wrap_r": 0.05,
		"cabin": false, "vents": false,
		"bulge": [Vector2(0.0, 0.985), Vector2(0.1, 1.0), Vector2(1.0, 1.0)]},
	# A two-door, two-seat mid-engined coupe: cab-forward, a short low nose,
	# the glasshouse set far forward and a long raised engine deck behind it
	# (louvres on the cover, intakes behind the doors), wide rear haunches,
	# a ducktail, slim lamps, a glass roof, big black wheels, red calipers.
	"sports": {"len": 4.64, "wid": 1.96, "h": 1.13, "clear": 0.11, "belt_h": 0.78, "tail_h": 0.9,
		"bonnet_h": 0.84, "nose_h": 0.52, "wheel_r": 0.335, "tyre_w": 0.29, "front_oh": 1.0, "wb": 2.64,
		"arch_gap": 0.06, "arch_margin": 0.035, "gh": [-0.95, -0.42, 0.34, 1.12], "drop_f": 0.03, "drop_r": 0.03, "tumble": 0.3,
		"rear_pillar": 0.55, "rear_glass": true, "extra_pillar": false, "valance": 0.2, "valance_r": 0.24,
		"spokes": 5, "twin": true, "lamp_f": Vector2(0.7, 0.88), "lamp_r": Vector2(0.6, 0.86), "lamp_blade": true,
		"grille": Vector2(0.05, 0.62), "lamp_k": 0.42, "lamp_k_r": 0.33, "lamp_taper_f": 0.35, "lamp_taper_r": 0.7,
		"wrap_f": 0.14, "corner_f": 0.5, "corner_r": 0.28, "end_w_f": 0.62, "end_w_r": 0.82, "corner_pow": 2.4,
		"taper": 0.0, "bulge_f": 0.08, "nose_floor": 0.05, "flare": 0.08, "shoulder": Vector2(0.8, 0.02),
		"sill": Vector2(0.3, 0.022), "rake_f": 0.16, "rake_r": 0.08, "bumper_t": 0.38, "kick": 0.04,
		"roof_crown": 0.05, "glass_crown": 0.09, "rear_seats": false, "black_pillars": true, "roof_glass": true,
		"dark_wheels": true, "sport": true, "bar_f": false, "bar_r": true, "grille_closed": true,
		"vents": false, "spoiler": true, "rear_wiper": false, "doors_n": 2, "mid_engine": true, "aero_f": true,
		"crown_f": 0.05, "crown_r": 0.03},
	# Saloon cabs: a roof sign, and where the city has one, a roof colour.
	"taxi": {"sign": true, "twin": true, "chrome": true, "extra_pillar": true, "bar_r": true, "kick": 0.025},
	"taxi_lisbon": {"sign": true, "chrome": true, "extra_pillar": true, "bar_r": true, "kick": 0.025,
		"livery_y": 1.12, "livery_col": Color(0.0, 0.42, 0.36)},
}

static var _specs := {}

static func has(kind: String) -> bool:
	return kind == "tuk_tuk" or KINDS.has(kind)

static func length_m(kind: String) -> float:
	if kind == "tuk_tuk":
		return TukTukModel.LENGTH_M
	return float((KINDS.get(kind, {}) as Dictionary).get("len", BASE["len"]))

static func width_m(kind: String) -> float:
	if kind == "tuk_tuk":
		return TukTukModel.WIDTH_M
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
	var arch := float(p["wheel_r"]) + float(p["arch_gap"])
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
		Vector2(half, clear + float(p["nose_floor"]))])
	# The tail's top edge holds its height (a wedge) and may kick up into a lip.
	var belt := PackedVector2Array([Vector2(-half, float(p["tail_h"]) + float(p["kick"]) - 0.02),
		Vector2(-half + 0.1, float(p["tail_h"]) + float(p["kick"])),
		Vector2(-half + 0.34, float(p["tail_h"])), Vector2(gh[2], belt_h), Vector2(gh[3], float(p["bonnet_h"])),
		Vector2((gh[3] + half) * 0.5, lerpf(float(p["bonnet_h"]), float(p["nose_h"]), 0.42)),
		Vector2(half - 0.18, float(p["nose_h"])), Vector2(half, float(p["nose_h"]) - 0.07)])
	belt.sort()
	s["belt"] = belt
	var crown := PackedVector2Array([Vector2(-half, float(p["crown_r"])), Vector2(gh[3], float(p["crown_f"])),
		Vector2(half, float(p["crown_f"]) * 0.7)])
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
	# A two-door body hangs one long door from the front arch back to
	# behind the seats (its rear and middle cuts coincide: no centre post).
	var two_doors := int(p["doors_n"]) == 2
	if two_doors:
		door_r = lerpf(door_f, door_r, 0.58)
		door_b = door_r
	s["doors"] = PackedFloat32Array([door_r, door_b, door_f])
	var glass_r := gh[0] + float(p["rear_pillar"]) if bool(p["rear_glass"]) else door_b + 0.05
	var glass_f := gh[3] - float(p["a_gap"])
	s["side_glass"] = Vector2(glass_r, glass_f)
	var pillars: Array[Vector2] = []
	if bool(p["rear_glass"]) and not two_doors:
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
	if bool(p["roof_glass"]):
		(s["cuts"] as Array).append_array([gh[1] + 0.14, gh[2] - 0.14])
	return s
