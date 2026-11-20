class_name StoBridgeSkeppsholm
extends RefCounted

## Skeppsholmsbron (1861, Motala Verkstad): the parametric five-bay iron arch
## deck of its BridgeSpecs row (BridgeParam) plus what the table cannot carry,
## from visual-plan/refs/landmarks/skeppsholmsbron and sv/en Wikipedia:
## - two gilded royal crowns, one on each railing at the midpoint of the
##   bridge (a closed crown on a beaded band: four arches, a ribbed cap, an
##   orb and a cross), about 0.75 m tall
## - slim iron lamp standards with a lantern each along the north-east railing
##   over every pier
## Surface keys of the extras: Gold, Iron, Lamp (the base keeps BridgeParam's).

const CROWN_M := 0.75
const CROWN_LONG_M := 0.9
const CROWN_DEEP_M := 0.6
## The real crowns stand about a metre tall on the railing (about three times
## the rail's width in the photo): the crown is built at 0.75 m and scaled up.
const CROWN_SCALE := 1.3
const LAMP_M := 3.6

static func build(model: Node3D, row: Dictionary) -> void:
	BridgeParam.build(model, row)
	var lm := LandmarkMesh.new()
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Iron", LandmarkMaterials.paint("#2D3236", 0.5, 0.45))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE2A8", 0.9))
	var c := float(row["clear"])
	var width := float(row["width"])
	var top := c + BridgeSpec.PARAPET_M
	var one := LandmarkMesh.new()
	one.use("Gold", LandmarkMaterials.gold())
	crown(one, Vector3.ZERO)
	for z in [-width * 0.5 + 0.1, width * 0.5 - 0.1]:
		lm.merge(one, Transform3D(Basis.from_scale(Vector3.ONE * CROWN_SCALE), Vector3(0, top, z)))
	var xs := BridgeParam.supports(row)
	for i in range(1, xs.size() - 1):
		lamp(lm, Vector3(xs[i], c, width * 0.5 - 0.1))
	BridgeCamber.apply(lm, BridgeParam.half_length(row), c, float(row.get("camber", 0.0)),
		float(row.get("tilt", 0.0)))
	lm.commit(model)

## Crown with its base centred at `at`, long axis along the bridge.
static func crown(lm: LandmarkMesh, at: Vector3) -> void:
	var rx := CROWN_LONG_M * 0.5
	var rz := CROWN_DEEP_M * 0.5
	var band := PackedVector2Array([Vector2(1.0, 0.0), Vector2(1.04, 0.05), Vector2(1.04, 0.16), Vector2(0.96, 0.2)])
	lm.lathe("Gold", at, band, 16, rx, rz)
	# Ribbed cap under the arches.
	var cap := PackedVector2Array([Vector2(0.9, 0.2), Vector2(0.85, 0.4), Vector2(0.6, 0.56), Vector2(0.0, 0.6)])
	lm.lathe("Gold", at, cap, 14, rx, rz)
	# Four arches rising from the band to the orb.
	var apex := at + Vector3(0, CROWN_M - 0.2, 0)
	for k in 4:
		var a := PI * 0.25 + PI * 0.5 * float(k)
		var foot := at + Vector3(cos(a) * rx * 0.95, 0.17, sin(a) * rz * 0.95)
		var prev := foot
		for j in range(1, 6):
			var t := float(j) / 5.0
			var p := foot.lerp(apex, t)
			p.y = lerpf(foot.y, apex.y, sin(t * PI * 0.5))
			p.x = lerpf(foot.x, apex.x, 1.0 - cos(t * PI * 0.5))
			p.z = lerpf(foot.z, apex.z, 1.0 - cos(t * PI * 0.5))
			lm.beam("Gold", prev, p, 0.05, 0.05)
			prev = p
	lm.lathe("Gold", apex - Vector3(0, 0.06, 0), PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.09, 0.08),
		Vector2(0.1, 0.16), Vector2(0.0, 0.24)]), 10)
	lm.box("Gold", apex + Vector3(0, 0.3, 0), Vector3(0.04, 0.18, 0.04), Basis(), 0.0)
	lm.box("Gold", apex + Vector3(0, 0.32, 0), Vector3(0.13, 0.04, 0.04), Basis(), 0.0)

## Slim iron standard with one lantern at `base`.
static func lamp(lm: LandmarkMesh, base: Vector3) -> void:
	lm.lathe("Iron", base, PackedVector2Array([Vector2(0.14, 0.0), Vector2(0.09, 0.4), Vector2(0.06, LAMP_M - 0.5)]), 8)
	lm.box("Lamp", base + Vector3(0, LAMP_M - 0.2, 0), Vector3(0.3, 0.4, 0.3), Basis(), 0.0)
	lm.spire("Iron", base + Vector3(0, LAMP_M, 0), 0.2, 0.18, 0.03)
