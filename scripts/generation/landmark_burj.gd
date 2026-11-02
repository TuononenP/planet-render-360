class_name LandmarkBurj
extends RefCounted

## Burj Khalifa in true metres: the Y-shaped (tripartite) plan of three
## wings at 120° round a hexagonal core, the wings stepping back one at
## a time in a spiral up the tower until the core alone rises into the
## crown, then the steel spire to the 828 m tip (242.5 m of it, its
## lower part an open steel frame round the 200 m pinnacle pipe).
## Silver reflective glass (26,000 panels) with vertical stainless
## tubular fins down every face, a spandrel band between floors groups,
## the mechanical floor band at each of the 27 setbacks; the podium of
## the Armani hotel entrance at the foot.

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
			# Vertical tubular fins down both long faces of the wing, a
			# spandrel band half-way up the tier.
			var right := basis.x
			var nf := int((length - 6.0) / 3.0)
			for fi in nf:
				var zf := 6.0 + 3.0 * float(fi)
				for sv in [-1.0, 1.0]:
					var fp := dir * zf + right * float(sv) * (w * 0.5 + 0.3)
					lm.beam("Fins", fp + Vector3(0, y0, 0), fp + Vector3(0, y0 + tier_h, 0), 0.35, 0.6, dir)
			lm.box("Fins", dir * length * 0.5 + Vector3(0, y0 + tier_h * 0.5, 0),
				Vector3(w + 0.25, 0.6, length + 0.1), basis, 0.0)
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
	# Steel spire: an open hexagonal frame round the pinnacle pipe for
	# its first 70 m, then the pipe alone to the tip.
	var sp := PackedVector2Array([Vector2(0, 7.5), Vector2(60.0, 5.5), Vector2(130.0, 3.0), Vector2(175.0, 1.2)])
	lm.lathe("Steel", Vector3(0, CROWN_M, 0), PackedVector2Array([Vector2(3.2, 0),
		Vector2(2.6, 60.0), Vector2(2.2, 130.0), Vector2(1.2, 175.0),
		Vector2(0.15, TIP_M - CROWN_M)]), 12)
	var frame_top := 70.0
	var levels := 7
	for k in levels:
		var y0 := CROWN_M + frame_top * float(k) / float(levels)
		var y1 := CROWN_M + frame_top * float(k + 1) / float(levels)
		var r0 := LandmarkMesh.profile_at(sp, y0 - CROWN_M)
		var r1 := LandmarkMesh.profile_at(sp, y1 - CROWN_M)
		for i in 6:
			var a0 := TAU * float(i) / 6.0
			var a1 := TAU * float(i + 1) / 6.0
			var p0 := Vector3(cos(a0) * r0, y0, sin(a0) * r0)
			var p1 := Vector3(cos(a1) * r0, y0, sin(a1) * r0)
			var q0 := Vector3(cos(a0) * r1, y1, sin(a0) * r1)
			var q1 := Vector3(cos(a1) * r1, y1, sin(a1) * r1)
			lm.beam("Steel", p0, q0, 0.9, 0.9)
			lm.beam("Steel", p0, q1, 0.4, 0.4)
			lm.beam("Steel", p1, q0, 0.4, 0.4)
			lm.beam("Steel", q0, q1, 0.5, 0.5)
	# Cladding rings round the upper spire (the maintenance levels).
	for y in [CROWN_M + 75.0, CROWN_M + 95.0, CROWN_M + 115.0, CROWN_M + 135.0]:
		var rr := LandmarkMesh.profile_at(sp, y - CROWN_M) * 0.55
		lm.frustum("Fins", Vector3(0, y, 0), rr + 0.5, rr + 0.5, 1.5, 12)
	# Podium round the core: the hotel's entrance pavilions between the
	# wings.
	lm.frustum("Podium", Vector3(0, 0, 0), 34.0, 32.0, 8.0, 6, PI / 6.0)
	for i in 3:
		var a := TAU * (float(i) + 0.5) / 3.0 - PI * 0.5
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Podium", d * 40.0 + Vector3(0, 3.0, 0), Vector3(22.0, 6.0, 14.0), Basis(Vector3.UP, atan2(d.x, d.z)))
		lm.box("Glass", d * 47.2 + Vector3(0, 2.8, 0), Vector3(18.0, 4.4, 0.4), Basis(Vector3.UP, atan2(d.x, d.z)), 0.0)
	lm.commit(model)
