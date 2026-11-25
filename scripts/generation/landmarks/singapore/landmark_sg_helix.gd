class_name LandmarkSgHelix
extends RefCounted

## Helix Bridge (280 m curved pedestrian DNA double-helix bridge, SG-2.6):
## - Curved 280 m plan following way 164881537 (-140..+140 m along X, gentle bayward curve in Z).
## - Counter-wound major (outer, r=5.4 m) and minor (inner, r=4.1 m) tubular stainless-steel
##   double-helix spirals linked by radial tension struts and elliptical framing rings.
## - Fritted-glass and perforated-steel sun-canopy segments over the walkway deck.
## - 4 cantilevered oval viewing pods projecting bayward (+Z), tapered Y-shaped stainless piers
##   seated in Marina Bay water (`base: water`), and violet/cyan/white LED night ribbons.

const DECK_Y := 4.5
const SPAN_HALF := 140.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Steel", LandmarkMaterials.pbr("sheet_metal", "#DCE0E6", 2.0, 0.22, 0.88))
	lm.use("Deck", LandmarkMaterials.pbr("concrete", "#C8C4BC", 3.0))
	lm.use("Pier", LandmarkMaterials.pbr("concrete", "#B4B0A8", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#88B8CE"))
	lm.use("VioletLamp", LandmarkMaterials.lit("#A85CFF", 2.8))
	lm.use("CyanLamp", LandmarkMaterials.lit("#56D8FF", 2.4))

	var segs := 64
	var major_pts: Array = []
	var minor_pts: Array = []
	var prev_deck := _spine(0.0)

	# Curved pedestrian deck, railings, and counter-wound double-helix steel spirals.
	for i in segs + 1:
		var t := float(i) / float(segs)
		var c := _spine(t)
		var ang_maj := t * TAU * 4.5
		var ang_min := -t * TAU * 4.5 + PI * 0.65
		var p_maj := c + Vector3(0.0, 3.4 + sin(ang_maj) * 3.8, cos(ang_maj) * 4.8)
		var p_min := c + Vector3(0.0, 3.4 + sin(ang_min) * 3.1, cos(ang_min) * 3.8)
		var p_maj2 := c + Vector3(0.0, 3.4 + sin(ang_maj + PI) * 3.8, cos(ang_maj + PI) * 4.8)
		major_pts.append(p_maj)
		minor_pts.append(p_min)
		if i > 0:
			var dp := c - prev_deck
			var yaw := -atan2(dp.z, dp.x)
			var b := Basis(Vector3.UP, yaw)
			lm.box("Deck", (prev_deck + c) * 0.5, Vector3(dp.length() + 0.3, 0.75, 6.2), b)
			# Double-helix stainless tubes (major pair + minor inner spiral).
			var prev_m: Vector3 = major_pts[i - 1]
			var prev_n: Vector3 = minor_pts[i - 1]
			lm.beam("Steel", prev_m, p_maj, 0.42, 0.42)
			lm.beam("Steel", prev_n, p_min, 0.32, 0.32)
			# Second opposing major tube.
			var t_prev := float(i - 1) / float(segs)
			var c_prev := _spine(t_prev)
			var am_prev := t_prev * TAU * 4.5
			var p_maj2_prev := c_prev + Vector3(0.0, 3.4 + sin(am_prev + PI) * 3.8, cos(am_prev + PI) * 4.8)
			lm.beam("Steel", p_maj2_prev, p_maj2, 0.42, 0.42)
			# Night LED ribbons tracing the double helix.
			lm.beam("VioletLamp", prev_m + Vector3(0.0, 0.25, 0.0), p_maj + Vector3(0.0, 0.25, 0.0), 0.16, 0.16)
			lm.beam("CyanLamp", prev_n + Vector3(0.0, 0.22, 0.0), p_min + Vector3(0.0, 0.22, 0.0), 0.14, 0.14)
			# Fritted-glass sun canopies along top curve.
			if i % 2 == 0 and t > 0.06 and t < 0.94:
				lm.box("Glass", c + Vector3(0.0, 7.0, 0.0), Vector3(dp.length() * 1.9, 0.16, 5.4), b)
		# Radial ring struts tying major & minor spirals every 4 segments.
		if i % 4 == 0 and i > 2 and i < segs - 2:
			lm.beam("Steel", p_maj, p_min, 0.20, 0.20)
			lm.beam("Steel", p_maj2, p_min, 0.20, 0.20)
			lm.beam("Steel", c + Vector3(0.0, 0.3, -3.1), p_maj, 0.16, 0.16)
			lm.beam("Steel", c + Vector3(0.0, 0.3, 3.1), p_maj2, 0.16, 0.16)
		prev_deck = c

	# 4 cantilevered oval bay-side viewing pods projecting toward Marina Bay (+Z).
	for pt: float in [0.22, 0.41, 0.59, 0.78]:
		var pc := _spine(float(pt)) + Vector3(0.0, 0.0, 6.4)
		lm.frustum("Deck", pc + Vector3(0.0, -0.35, 0.0), 6.2, 5.6, 0.7, 14)
		lm.frustum("CyanLamp", pc + Vector3(0.0, -0.5, 0.0), 6.3, 6.3, 0.22, 14)
		lm.beam("Steel", _spine(float(pt)) + Vector3(0.0, -0.4, 2.8), pc + Vector3(0.0, -0.4, 3.5), 0.55, 0.55)

	# 4 tapered Y-shaped stainless piers seated down into Marina Bay water (y = -4.0..DECK_Y).
	for pt: float in [0.16, 0.39, 0.61, 0.84]:
		var pc := _spine(float(pt))
		lm.frustum("Pier", Vector3(pc.x, -4.0, pc.z), 2.2, 1.5, 5.5, 10)
		lm.beam("Steel", Vector3(pc.x, 1.2, pc.z), Vector3(pc.x, DECK_Y - 0.3, pc.z - 2.6), 0.85, 0.85)
		lm.beam("Steel", Vector3(pc.x, 1.2, pc.z), Vector3(pc.x, DECK_Y - 0.3, pc.z + 2.6), 0.85, 0.85)

	lm.commit(model)

static func _spine(t: float) -> Vector3:
	var x := lerpf(-SPAN_HALF, SPAN_HALF, t)
	var z := -10.0 + 24.0 * sin(t * PI)
	var y := DECK_Y + 2.6 * sin(t * PI)
	return Vector3(x, y, z)
