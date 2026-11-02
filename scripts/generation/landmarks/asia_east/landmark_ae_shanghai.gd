class_name LandmarkAeShanghai
extends RefCounted

## The Shanghai Pudong skyline in true metres: the Oriental Pearl Tower
## (468 m: tripod legs, two great spheres, pink glass), Shanghai Tower
## (632 m: nine stacked zones of a rounded triangle twisting 120 degrees
## while it tapers), the Shanghai World Financial Center (492 m: a slim
## square prism with the trapezoid aperture at its crown) and the Jin Mao
## Tower (420.5 m: 13 octagonal tiers stepping in like a pagoda, then a
## steel spire).

# --- Oriental Pearl Tower ---

const PEARL_M := 468.0

static func pearl(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#D4D0C8", 4.0))
	lm.use("Pearl", LandmarkMaterials.pbr("render", "#C24F78", 3.0, 0.22, 0.35))
	lm.use("Mast", LandmarkMaterials.paint("#DADDE0", 0.4, 0.6))
	# Three raking legs from the ground to the lower sphere.
	for i in 3:
		var a := TAU * i / 3.0 + PI * 0.5
		var dir := Vector3(cos(a), 0, sin(a))
		LandmarkAeParts.tube(lm, "Concrete", dir * 38.0 + Vector3(0, -3.0, 0),
			dir * 9.0 + Vector3(0, 78.0, 0), 4.8, 4.2, 12)
		# Straight columns between the great spheres, each with two pods.
		LandmarkAeParts.tube(lm, "Concrete", dir * 11.0 + Vector3(0, 108.0, 0),
			dir * 11.0 + Vector3(0, 252.0, 0), 4.5, 4.0, 12)
		LandmarkAeParts.ball(lm, "Pearl", dir * 11.0 + Vector3(0, 150.0, 0), 7.0, 16, 8)
		if i < 2:
			LandmarkAeParts.ball(lm, "Pearl", dir * 11.0 + Vector3(0, 205.0, 0), 6.0, 16, 8)
	LandmarkAeParts.ball(lm, "Pearl", Vector3(0, 93.0, 0), 25.0, 28, 14)
	LandmarkAeParts.ball(lm, "Pearl", Vector3(0, 267.0, 0), 22.5, 28, 14)
	# Central shaft up through both spheres, the top capsule and the antenna.
	lm.frustum("Concrete", Vector3(0, -3.0, 0), 7.5, 6.0, 270.0, 16)
	lm.frustum("Concrete", Vector3(0, 285.0, 0), 5.0, 3.5, 62.0, 14)
	LandmarkAeParts.ball(lm, "Pearl", Vector3(0, 350.0, 0), 8.0, 20, 10)
	lm.lathe("Mast", Vector3(0, 355.0, 0), PackedVector2Array([Vector2(3.4, 0), Vector2(2.6, 40.0),
		Vector2(1.5, 80.0), Vector2(0.4, PEARL_M - 355.0)]), 12)
	lm.commit(model)

# --- Shanghai Tower ---

const SH_M := 632.0
const SH_ZONES := 9
const SH_TWIST := TAU / 3.0
static var SH_SCALE := PackedVector2Array([Vector2(0, 1.0), Vector2(0.2, 0.93),
	Vector2(0.4, 0.8), Vector2(0.6, 0.62), Vector2(0.8, 0.42), Vector2(0.95, 0.26), Vector2(1, 0.22)])

static func shanghai_tower(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#8FA6B3"))
	lm.use("Band", LandmarkMaterials.paint("#C5CBD0", 0.35, 0.8))
	lm.use("Podium", LandmarkMaterials.pbr("concrete", "#CFCBC2", 4.0))
	var slices := 64
	var rings: Array = []
	for k in slices + 1:
		rings.append(_sh_ring(float(k) / slices, 1.0))
	LandmarkAeParts.loft(lm, "Glass", rings)
	# Belt of mechanical floors at the top of each zone.
	for z in range(1, SH_ZONES):
		var f := float(z) / SH_ZONES
		LandmarkAeParts.loft(lm, "Band", [_sh_ring(f, 1.025), _sh_ring(f + 3.0 / SH_M, 1.025)], false)
	lm.frustum("Podium", Vector3(0, -2.0, 0), 50.0, 48.0, 16.0, 36)
	lm.commit(model)

## Rounded-triangle section at height fraction f (scaled by `grow`).
static func _sh_ring(f: float, grow: float) -> PackedVector3Array:
	var r0 := 42.0 * LandmarkMesh.profile_at(SH_SCALE, f) * grow
	var shape: Callable = func(th: float) -> float: return r0 * (0.8 + 0.2 * cos(3.0 * th))
	return LandmarkAeParts.ring(36, SH_M * f, shape, SH_TWIST * f)

# --- Shanghai World Financial Center ---

const SWFC_M := 492.0
const SWFC_AP_Y := 442.0

static func swfc(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#9DB0BA"))
	lm.use("Frame", LandmarkMaterials.paint("#B9C0C5", 0.35, 0.8))
	lm.use("Podium", LandmarkMaterials.pbr("concrete", "#CBC7BE", 4.0))
	var n := 22
	for k in n:
		var y0 := SWFC_AP_Y * k / n
		var y1 := SWFC_AP_Y * (k + 1) / n
		var hx := lerpf(29.0, 27.0, (y0 + y1) * 0.5 / SWFC_M)
		var hz := lerpf(29.0, 23.0, (y0 + y1) * 0.5 / SWFC_M)
		lm.box("Glass", Vector3(0, (y0 + y1) * 0.5, 0), Vector3(hx * 2.0, y1 - y0, hz * 2.0))
		if k % 4 == 3:
			lm.box("Frame", Vector3(0, y1 - 1.0, 0), Vector3(hx * 2.0 + 1.0, 2.0, hz * 2.0 + 1.0))
	# Crown: two piers either side of the trapezoid aperture (wider at the top).
	var steps := 25
	var hx_top := 27.0
	var hz_top := 23.0
	for k in steps:
		var y0 := SWFC_AP_Y + (SWFC_M - SWFC_AP_Y) * k / steps
		var y1 := SWFC_AP_Y + (SWFC_M - SWFC_AP_Y) * (k + 1) / steps
		var ap := lerpf(14.0, 44.0, (k + 0.5) / steps)
		var w := hx_top - ap * 0.5
		for s in [-1.0, 1.0]:
			lm.box("Glass", Vector3(s * (ap * 0.5 + w * 0.5), (y0 + y1) * 0.5, 0),
				Vector3(w, y1 - y0, hz_top * 2.0))
	# Sky-walk bridge across the aperture at the 100th floor.
	lm.box("Frame", Vector3(0, 473.0, 0), Vector3(30.0, 4.0, hz_top * 2.0))
	lm.box("Frame", Vector3(0, SWFC_AP_Y + 1.0, 0), Vector3(14.0, 2.0, hz_top * 2.0))
	lm.box("Podium", Vector3(0, 5.0, 0), Vector3(84.0, 12.0, 84.0))
	lm.commit(model)

# --- Jin Mao Tower ---

const JM_M := 420.5
const JM_TIERS := 13

static func jin_mao(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#A7B4BC"))
	lm.use("Frame", LandmarkMaterials.paint("#AEB4B8", 0.35, 0.8))
	lm.use("Podium", LandmarkMaterials.pbr("concrete", "#C9C4BA", 4.0))
	var y := 0.0
	for i in JM_TIERS:
		var hw := 27.0 - 1.1 * i
		var h := 36.0 - 1.3 * i
		var r := hw / cos(PI / 8.0)
		lm.frustum("Glass", Vector3(0, y, 0), r, r * 0.985, h - 1.4, 8, PI / 8.0)
		lm.frustum("Frame", Vector3(0, y + h - 1.4, 0), r * 1.04, r * 1.04, 1.4, 8, PI / 8.0)
		y += h
	# Octagonal crown lantern, then the steel spire to the tip.
	lm.frustum("Glass", Vector3(0, y, 0), 8.0, 6.0, 12.0, 8, PI / 8.0)
	lm.lathe("Frame", Vector3(0, y + 12.0, 0), PackedVector2Array([Vector2(3.4, 0),
		Vector2(2.2, (JM_M - y - 12.0) * 0.5), Vector2(0.3, JM_M - y - 12.0)]), 10)
	lm.frustum("Podium", Vector3(0, -2.0, 0), 44.0, 42.0, 12.0, 8, PI / 8.0)
	lm.commit(model)
