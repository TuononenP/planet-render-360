extends RefCounted

## Havis Amanda (Ville Vallgren, 1908), the mermaid fountain at the head of
## Market Square. Model origin on the OSM artwork node (1376320186), yaw 0.
##
## Broad shallow basin of polished red-pink granite on two low steps with a
## rounded rim, four bronze sea lions lying on the rim spouting water jets
## inward, a central mass of rock and fish heads in patinated bronze carrying
## a shallow dish, and above it the sculpted standing bronze mermaid figure
## rising to 5.0 m, with warm basin floodlights.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const ENTRY := {"type": "havis_amanda", "name": "Havis Amanda", "lat": 60.1675863, "lon": 24.9513987,
	"radius_m": 1500.0, "wiki_title": "Havis Amanda", "height_m": 5.0, "clear_m": 7.0,
	"kind": "Fountain", "aliases": ["havis amanda", "havis amanda fountain", "manta helsinki"]}

const RIM := 0.9

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#A06B63", 1.2))
	lm.use("Step", LandmarkMaterials.pbr("stone", "#8E8A86", 2.0))
	lm.use("Bronze", LandmarkMaterials.paint("#3E5B4C", 0.45, 0.65))
	lm.use("Water", LandmarkMaterials.glass("#6E9992"))
	# Two low paving steps and the basin: a rounded rim, the water inside.
	lm.lathe("Step", Vector3.ZERO, PackedVector2Array([Vector2(6.8, 0), Vector2(6.8, 0.14),
		Vector2(6.3, 0.16), Vector2(6.3, 0.30), Vector2(5.9, 0.32)]), 64)
	lm.lathe("Granite", Vector3(0, 0.3, 0), PackedVector2Array([Vector2(5.8, 0), Vector2(5.8, RIM - 0.3),
		Vector2(5.65, RIM - 0.08), Vector2(5.45, RIM), Vector2(5.2, RIM - 0.08),
		Vector2(5.15, 0.3), Vector2(5.1, 0.1)]), 64)
	lm.disc("Water", Vector3(0, RIM - 0.15, 0), Vector3.UP, 5.1, 64)
	# Rock-and-fish pedestal in the middle, then the dish under the figure.
	lm.lathe("Bronze", Vector3(0, 0.3, 0), PackedVector2Array([Vector2(1.7, 0), Vector2(1.45, 0.4),
		Vector2(1.7, 0.9), Vector2(1.2, 1.4), Vector2(1.0, 1.9), Vector2(0.8, 2.3), Vector2(0.55, 2.5)]), 32)
	lm.lathe("Bronze", Vector3(0, 2.55, 0), PackedVector2Array([Vector2(0.5, 0), Vector2(1.5, 0.12),
		Vector2(2.0, 0.34), Vector2(1.9, 0.4), Vector2(1.3, 0.3), Vector2(0.4, 0.22)]), 40)
	_sea_lions_and_jets(lm)
	_mermaid_figure(lm, Vector3(0.0, 2.86, 0.0))
	lm.commit(model)
	var warm := Color(1.0, 0.88, 0.66)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(4.2, RIM + 0.1, 4.2), Vector3(0.0, 3.8, 0.0), 50.0, 0.9, 14.0, warm],
		[Vector3(-4.2, RIM + 0.1, 4.2), Vector3(0.0, 3.8, 0.0), 50.0, 0.9, 14.0, warm],
		[Vector3(-4.2, RIM + 0.1, -4.2), Vector3(0.0, 3.8, 0.0), 50.0, 0.9, 14.0, warm],
		[Vector3(4.2, RIM + 0.1, -4.2), Vector3(0.0, 3.8, 0.0), 50.0, 0.9, 14.0, warm],
	])

static func _sea_lions_and_jets(lm: LandmarkMesh) -> void:
	for i in 4:
		var a := TAU * float(i) / 4.0 + PI * 0.25
		var d := Vector3(cos(a), 0, sin(a))
		var right := Vector3.UP.cross(d).normalized()
		var p := d * 4.75 + Vector3(0, RIM + 0.05, 0)
		# Smooth arched sea-lion body, flippers, raised neck and head.
		var body := PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.26, 0.14), Vector2(0.36, 0.45),
			Vector2(0.34, 0.85), Vector2(0.24, 1.2), Vector2(0.10, 1.45), Vector2(0.0, 1.55)])
		var sub := LandmarkMesh.new()
		sub.use("Bronze", null)
		sub.lathe("Bronze", Vector3.ZERO, body, 14, 0.85, 1.0)
		lm.merge(sub, Transform3D(Basis(right, -d, Vector3.UP), p + d * 0.65 + Vector3(0, 0.22, 0)))
		lm.beam("Bronze", p + Vector3(0, 0.25, 0), p - d * 0.72 + Vector3(0, 0.82, 0), 0.26, 0.24, right)
		lm.lathe("Bronze", p - d * 0.78 + Vector3(0, 0.76, 0), U.ball(0.20), 14, 0.85, 1.1)
		for s in [-1.0, 1.0]:
			lm.beam("Bronze", p - d * 0.2 + right * s * 0.24 + Vector3(0, 0.16, 0),
				p - d * 0.4 + right * s * 0.56 + Vector3(0, 0.02, 0), 0.14, 0.06)
		# Parabolic water jet arching from sea lion mouth into the basin.
		var mouth := p - d * 0.94 + Vector3(0, 0.90, 0)
		var land := d * 1.9 + Vector3(0, RIM - 0.14, 0)
		_water_arc(lm, mouth, land, 0.55)
		# Fish heads on the central pedestal also spouting into the basin.
		var fish_m := d * 1.45 + Vector3(0, 1.45, 0)
		lm.beam("Bronze", d * 0.85 + Vector3(0, 1.32, 0), fish_m, 0.26, 0.24)
		_water_arc(lm, fish_m, d * 3.1 + Vector3(0, RIM - 0.14, 0), 0.35)

static func _water_arc(lm: LandmarkMesh, a: Vector3, b: Vector3, arc_h: float) -> void:
	var prev := a
	for k in range(1, 9):
		var t := float(k) / 8.0
		var pt := a.lerp(b, t) + Vector3(0, sin(t * PI) * arc_h, 0)
		lm.beam("Water", prev, pt, 0.045, 0.045)
		prev = pt

## Vallgren's standing bronze mermaid figure with sculpted multi-ring anatomy.
static func _mermaid_figure(lm: LandmarkMesh, base: Vector3) -> void:
	# Smooth sculpted legs (left weight-bearing, right slightly bent).
	_taper(lm, base + Vector3(-0.11, 0.0, 0.0), base + Vector3(-0.10, 0.45, 0.0), 0.065, 0.085)
	_taper(lm, base + Vector3(-0.10, 0.45, 0.0), base + Vector3(-0.12, 0.92, -0.02), 0.085, 0.115)
	_taper(lm, base + Vector3(0.14, 0.0, 0.06), base + Vector3(0.15, 0.44, 0.10), 0.060, 0.082)
	_taper(lm, base + Vector3(0.15, 0.44, 0.10), base + Vector3(0.11, 0.90, 0.0), 0.082, 0.110)
	# Pelvis, slender waist, ribcage and shoulders (multi-ring lathe).
	var torso := PackedVector2Array([
		Vector2(0.16, 0.0), Vector2(0.20, 0.12), Vector2(0.14, 0.34),
		Vector2(0.17, 0.54), Vector2(0.20, 0.72), Vector2(0.18, 0.86), Vector2(0.08, 0.92)])
	lm.lathe("Bronze", base + Vector3(0.0, 0.86, 0.0), torso, 20, 1.0, 0.72)
	# Neck, tilted head and hair chignon reaching exact 5.0 m.
	lm.frustum("Bronze", base + Vector3(0.0, 1.76, 0.0), 0.068, 0.060, 0.14, 14)
	lm.lathe("Bronze", base + Vector3(0.0, 1.88, 0.01), PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.075, 0.03), Vector2(0.105, 0.11),
		Vector2(0.095, 0.19), Vector2(0.06, 0.24), Vector2(0.0, 0.26)]), 16, 0.88, 1.0)
	lm.lathe("Bronze", base + Vector3(0.0, 1.96, -0.09), U.ball(0.075), 12)
	# Gracefully curved arms (right raised toward hair/chin, left resting by hip).
	var sh_l := base + Vector3(-0.20, 1.66, 0.0)
	var el_l := base + Vector3(-0.30, 1.32, 0.04)
	var ha_l := base + Vector3(-0.21, 1.02, 0.08)
	_taper(lm, sh_l, el_l, 0.058, 0.045)
	_taper(lm, el_l, ha_l, 0.045, 0.035)
	var sh_r := base + Vector3(0.20, 1.68, 0.0)
	var el_r := base + Vector3(0.32, 1.56, 0.10)
	var ha_r := base + Vector3(0.14, 1.82, 0.09)
	_taper(lm, sh_r, el_r, 0.058, 0.045)
	_taper(lm, el_r, ha_r, 0.045, 0.035)

static func _taper(lm: LandmarkMesh, a: Vector3, b: Vector3, r0: float, r1: float) -> void:
	var axis := b - a
	if axis.length() < 0.001:
		return
	var y := axis.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	var piece := LandmarkMesh.new()
	piece.use("Bronze", null)
	piece.frustum("Bronze", Vector3.ZERO, r0, r1, axis.length(), 12)
	lm.merge(piece, Transform3D(Basis(x, y, x.cross(y)), a))
