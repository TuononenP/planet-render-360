class_name CarSpecs
extends RefCounted

## Body specs for the procedural cars (VehicleKit.body), in metres with
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
	"clad": 0.0, "valance": 0.1, "spokes": 5,
	"lamp_f": Vector2(0.6, 0.86), "lamp_r": Vector2(0.56, 0.84), "grille": Vector2(0.14, 0.48),
}

const KINDS := {
	"sedan": {},
	"hatch": {"len": 4.06, "wid": 1.76, "h": 1.47, "clear": 0.16, "tail_h": 0.98, "bonnet_h": 0.92,
		"nose_h": 0.72, "wheel_r": 0.31, "front_oh": 0.85, "wb": 2.56,
		"gh": [-1.93, -1.5, 0.3, 1.02], "rear_pillar": 0.42, "lamp_r": Vector2(0.6, 0.9)},
	"wagon": {"len": 4.72, "h": 1.47, "tail_h": 0.97, "wb": 2.76,
		"gh": [-2.24, -1.93, 0.22, 1.04], "rear_pillar": 0.3, "extra_pillar": true,
		"lamp_r": Vector2(0.6, 0.9)},
	"suv": {"len": 4.66, "wid": 1.86, "h": 1.68, "clear": 0.22, "belt_h": 1.04, "tail_h": 1.08,
		"bonnet_h": 1.05, "nose_h": 0.88, "wheel_r": 0.365, "tyre_w": 0.235, "wb": 2.7,
		"gh": [-2.2, -1.9, 0.25, 0.95], "tumble": 0.17, "rear_pillar": 0.32, "extra_pillar": true,
		"clad": 0.16, "lamp_f": Vector2(0.64, 0.86), "lamp_r": Vector2(0.6, 0.88)},
	"van": {"len": 5.0, "wid": 1.95, "h": 1.96, "clear": 0.19, "belt_h": 1.12, "tail_h": 1.14,
		"bonnet_h": 1.1, "nose_h": 0.88, "wheel_r": 0.34, "front_oh": 0.95, "wb": 3.1,
		"gh": [-2.62, -2.56, 1.05, 1.72], "drop_f": 0.04, "drop_r": 0.02, "tumble": 0.08,
		"rear_glass": false, "lamp_f": Vector2(0.52, 0.7), "lamp_r": Vector2(0.3, 0.75)},
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
	s["bulge_f"] = 0.1
	s["bulge_r"] = 0.08
	s["corner_f"] = 0.42
	s["corner_r"] = 0.38
	s["corner_pow"] = 2.4
	s["end_w_f"] = 0.7
	s["end_w_r"] = 0.74
	s["taper"] = 0.035
	s["well"] = 0.27
	s["shelf"] = 0.04
	s["roof_crown"] = 0.05
	s["glass_crown"] = 0.09
	s["lamp_wrap"] = 0.2
	s["lamp_in"] = 0.5
	s["floor"] = PackedVector2Array([Vector2(-half, clear + 0.17), Vector2(axle_r - 0.4, clear + 0.03),
		Vector2(axle_r, clear), Vector2(axle_f, clear), Vector2(axle_f + 0.4, clear + 0.03),
		Vector2(half, clear + 0.12)])
	var belt := PackedVector2Array([Vector2(-half, float(p["tail_h"]) - 0.07),
		Vector2(-half + 0.3, float(p["tail_h"])), Vector2(gh[2], belt_h), Vector2(gh[3], float(p["bonnet_h"])),
		Vector2((gh[3] + half) * 0.5, lerpf(float(p["bonnet_h"]), float(p["nose_h"]), 0.42)),
		Vector2(half - 0.18, float(p["nose_h"])), Vector2(half, float(p["nose_h"]) - 0.07)])
	s["belt"] = belt
	var crown := PackedVector2Array([Vector2(-half, 0.03), Vector2(gh[3], 0.06), Vector2(half, 0.04)])
	s["crown"] = crown
	s["bulge"] = PackedVector2Array([Vector2(0.0, 0.93), Vector2(0.12, 0.975), Vector2(0.4, 1.0),
		Vector2(0.75, 0.99), Vector2(0.94, 0.965), Vector2(1.0, 0.94)])
	s["gh_w"] = PackedVector2Array([Vector2(gh[0], 0.8), Vector2(minf(gh[1] + 0.35, gh[2]), 0.92),
		Vector2(gh[2], 0.92), Vector2(gh[3], 0.86)])
	var h := float(p["h"])
	var deck_r := VehicleKit.lin(belt, gh[0]) + 0.012 + VehicleKit.lin(crown, gh[0])
	var deck_f := VehicleKit.lin(belt, gh[3]) + 0.012 + VehicleKit.lin(crown, gh[3])
	s["roof"] = PackedVector2Array([Vector2(gh[0], deck_r), Vector2(gh[1], h - float(p["drop_r"])),
		Vector2(lerpf(gh[1], gh[2], 0.45), h), Vector2(gh[2], h - float(p["drop_f"])), Vector2(gh[3], deck_f)])
	s["gh_full"] = h - 0.05 - belt_h
	# Doors: the front cut behind the front arch, the rear ahead of the
	# rear arch, the centre pillar between.
	var door_f := axle_f - arch - 0.1
	var door_r := axle_r + arch + 0.08
	var door_b := lerpf(door_r, door_f, 0.52)
	s["doors"] = PackedFloat32Array([door_r, door_b, door_f])
	var glass_r := gh[0] + float(p["rear_pillar"]) if bool(p["rear_glass"]) else door_b + 0.05
	s["side_glass"] = Vector2(glass_r, gh[3] - 0.22)
	var pillars: Array[Vector2] = []
	if bool(p["rear_glass"]):
		pillars.append(Vector2(door_b - 0.05, door_b + 0.05))
	if bool(p["extra_pillar"]):
		pillars.append(Vector2(door_r - 0.2, door_r - 0.1))
	s["pillars"] = pillars
	var cuts: Array[float] = [glass_r, gh[3] - 0.22, half - 0.1 - 0.2, -half + 0.08 + 0.2]
	for pl in pillars:
		cuts.append_array([pl.x, pl.y])
	s["cuts"] = cuts
	s["cuts_far"] = [glass_r, gh[3] - 0.22]
	return s
