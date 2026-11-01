class_name LandmarkBurj
extends RefCounted

## Burj Khalifa in true metres: the Y-shaped (tripartite) plan of three
## wings at 120° round a hexagonal core, the wings stepping back one at
## a time in a spiral up the tower until the core alone rises into the
## crown, then the steel spire to the 828 m tip. Silver reflective glass
## with vertical steel fins on every wing nose.

const TIP_M := 828.0
## Top of the stepped glass tower (highest occupied floor ~585 m).
const ROOF_M := 585.0
const CROWN_M := 640.0
const TIERS := 27
const WING_M := 70.0
const WING_TOP_M := 16.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#B4C2CC"))
	lm.use("Fins", LandmarkMaterials.paint("#C9CED3", 0.35, 0.8))
	lm.use("Steel", LandmarkMaterials.paint("#D6DADD", 0.3, 0.85))
	lm.use("Podium", LandmarkMaterials.pbr("concrete", "#CFC8BC", 3.0))
	var tier_h := ROOF_M / TIERS
	for k in TIERS:
		var y0 := tier_h * k
		var f := float(k) / TIERS
		var w := lerpf(30.0, 13.0, f)
		for i in 3:
			# Wing i has stepped back once for every tier ≤ k numbered i
			# mod 3: the setbacks spiral round the tower.
			var steps := floori(float(k + (3 - i) % 3) / 3.0)
			var length := lerpf(WING_M, WING_TOP_M, float(steps) / (TIERS / 3.0))
			var a := TAU * i / 3.0 - PI * 0.5
			var dir := Vector3(cos(a), 0, sin(a))
			var basis := Basis(Vector3.UP, atan2(dir.x, dir.z))
			lm.box("Glass", dir * length * 0.5 + Vector3(0, y0 + tier_h * 0.5, 0),
				Vector3(w, tier_h, length), basis)
			# Rounded nose and its steel fin.
			lm.frustum("Glass", dir * length + Vector3(0, y0, 0), w * 0.5, w * 0.5, tier_h, 12)
			lm.box("Fins", dir * (length + w * 0.5) + Vector3(0, y0 + tier_h * 0.5, 0),
				Vector3(w * 0.25, tier_h, 1.2), basis)
			# Mechanical floor band at the top of each tier.
			lm.box("Fins", dir * length * 0.5 + Vector3(0, y0 + tier_h - 0.6, 0),
				Vector3(w + 0.4, 1.2, length + 0.4), basis)
		var r := lerpf(22.0, 13.0, f)
		lm.frustum("Glass", Vector3(0, y0, 0), r, r, tier_h, 6, PI / 6.0)
	# Crown: the core alone, tapering, ringed by its fins.
	lm.frustum("Glass", Vector3(0, ROOF_M, 0), 13.0, 8.0, CROWN_M - ROOF_M, 6, PI / 6.0)
	for i in 6:
		var a := TAU * i / 6.0
		var dir := Vector3(cos(a), 0, sin(a))
		lm.beam("Fins", dir * 13.5 + Vector3(0, ROOF_M, 0),
			dir * 8.6 + Vector3(0, CROWN_M + 10.0, 0), 1.4, 2.4)
	# Steel spire to the tip.
	lm.lathe("Steel", Vector3(0, CROWN_M, 0), PackedVector2Array([Vector2(7.5, 0),
		Vector2(5.5, 60.0), Vector2(3.0, 130.0), Vector2(1.2, 175.0),
		Vector2(0.15, TIP_M - CROWN_M)]), 12)
	for y in [CROWN_M + 30.0, CROWN_M + 75.0, CROWN_M + 115.0]:
		var rr := LandmarkMesh.profile_at(PackedVector2Array([Vector2(0, 7.5),
			Vector2(60.0, 5.5), Vector2(130.0, 3.0), Vector2(175.0, 1.2)]), y - CROWN_M)
		lm.frustum("Fins", Vector3(0, y, 0), rr + 0.5, rr + 0.5, 1.5, 12)
	# Podium base round the core.
	lm.frustum("Podium", Vector3(0, -1.0, 0), 34.0, 32.0, 9.0, 6, PI / 6.0)
	lm.commit(model)
