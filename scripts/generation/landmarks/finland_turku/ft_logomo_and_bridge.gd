class_name FtLogomoAndBridge
extends RefCounted

## Logomo (1876 VR locomotive workshop / 2011 cultural hub) & Logomon silta
## (2021 undulating dark-weathering-steel pedestrian bridge over Turku railyard)
## in true metres (+X ENE along Veturikatu/railyard, -Z NNW, +Z SSE across the
## tracks toward Ratapihankatu, turned by yaw_deg = -33.2°):
##   - Measured from OSM way:157394020 (60.456985, 22.258005, 166.5 x 93.9 m,
##     LoD2 height 22.7 m, complex roof 24°) and Logomonsilta way:912901301 /
##     way:687299560 (60.456171, 22.259050, height 15 m).
##   - Historic 1876 red-brick VR locomotive workshop halls: stepped granite
##     plinth, long rhythmic arched industrial window bays separated by brick
##     pilasters, sawtooth & gabled clerestory roofs with dark standing-seam
##     zinc/metal cladding, and iconic brick end gables.
##   - Logomo-sali (4-storey dark corten/anthracite concert hall volume rising
##     to 22.6 m) and Logomo Konttori (5-storey brick/glass office wing at -X)
##     plus Logomo Kitchen glazed foyer pavilion (+X).
##   - Logomon silta (2021): sweeping 195 m visible railyard span (full 455 m
##     path incl. approach ramps) extending SSE (+Z) from Logomo plaza over the
##     tracks toward Ratapihankatu, sculpted undulating dark-weathering-steel
##     (corten) structural side ribs, twin concrete/steel Y-piers, glazed wind
##     screens, staircase/lift towers, and continuous warm LED rib lighting.
## Surfaces: 10 merged PBR parts (Brick, BrickDark, Corten, Stone, Roof, Trim,
## Steel, Concrete, Glass, Lamp).

const FOUND := -2.0
const TOP_M := 22.6

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	_build_workshop_halls(lm)
	_build_logomo_sali_and_konttori(lm)
	_build_logomon_silta(lm)
	lm.commit(model)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#944736", 2.6))
	lm.use("BrickDark", LandmarkMaterials.pbr("brick", "#6D3428", 2.4))
	lm.use("Corten", LandmarkMaterials.pbr("concrete", "#6E432F", 2.4, 0.52, 0.55))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#787570", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#3F4449", 2.6, 0.55, 0.45))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#E2DDD2", 2.4))
	lm.use("Steel", LandmarkMaterials.paint("#2D3238", 0.45, 0.65))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#BDB9B0", 2.8))
	lm.use("Glass", LandmarkMaterials.glass("#223442"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFDF9E", 1.5))

static func _build_workshop_halls(lm: LandmarkMesh) -> void:
	# Main 1876 red-brick VR locomotive halls: x = -72..68, z = -34..22.
	LandmarkFrKit.rect(lm, "Stone", -74.0, 70.0, -35.0, 24.0, FOUND, 1.4)
	# Three parallel long brick nave halls with pitched roofs & raised clerestories.
	var halls := [[-33.0, -14.0, 11.2, 4.2], [-14.0, 5.0, 12.0, 4.5], [5.0, 22.0, 10.6, 3.8]]
	for h in halls:
		var z0: float = h[0]
		var z1: float = h[1]
		var eave: float = h[2]
		var rise: float = h[3]
		var zc := (z0 + z1) * 0.5
		var zw := z1 - z0
		LandmarkFrKit.rect(lm, "Brick", -64.0, 62.0, z0, z1, 1.4, eave)
		LandmarkFrKit.rect(lm, "Trim", -64.3, 62.3, z0 - 0.25, z1 + 0.25, eave - 0.55, eave + 0.15)
		lm.gable("Roof", Vector3(-1.0, eave, zc), zw, 126.0, rise, Basis(Vector3.UP, PI * 0.5), 0.4, "Brick")
		# Raised glass-and-steel roof clerestory lantern along each workshop hall.
		LandmarkFrKit.rect(lm, "Glass", -52.0, 50.0, zc - 2.2, zc + 2.2, eave + rise - 0.4, eave + rise + 1.9)
		LandmarkFrKit.rect(lm, "Roof", -52.4, 50.4, zc - 2.5, zc + 2.5, eave + rise + 1.9, eave + rise + 2.35)
		LandmarkFrKit.rect(lm, "Lamp", -50.0, 48.0, zc - 1.5, zc + 1.5, eave + rise - 0.1, eave + rise + 1.5)
	# Rhythmic red-brick pilasters and tall arched industrial workshop windows on south & north fronts.
	for side_z: float in [-33.1, 22.1]:
		var s := -1.0 if side_z < 0.0 else 1.0
		for k in 17:
			var px := lerpf(-61.0, 59.0, float(k) / 16.0)
			lm.box("BrickDark", Vector3(px, 6.2, side_z + 0.18 * s), Vector3(0.75, 9.6, 0.45))
			if k < 16:
				var wx := px + 3.75
				lm.box("Glass", Vector3(wx, 5.8, side_z + 0.05 * s), Vector3(3.4, 5.6, 0.18))
				lm.box("Lamp", Vector3(wx, 5.6, side_z - 0.25 * s), Vector3(2.8, 4.8, 0.14))
				# Arched brick lintel & white sill + mullion grid.
				lm.box("Trim", Vector3(wx, 2.95, side_z + 0.12 * s), Vector3(3.7, 0.24, 0.28))
				lm.box("BrickDark", Vector3(wx, 8.75, side_z + 0.14 * s), Vector3(3.6, 0.45, 0.30))
				lm.box("Steel", Vector3(wx, 5.8, side_z + 0.14 * s), Vector3(0.14, 5.6, 0.20))
				lm.box("Steel", Vector3(wx, 6.4, side_z + 0.14 * s), Vector3(3.4, 0.14, 0.20))
	# East glazed Logomo Kitchen & main entrance lobby canopy (+X = 62..72).
	LandmarkFrKit.rect(lm, "Glass", 62.0, 71.5, -16.0, 16.0, 1.4, 8.2)
	LandmarkFrKit.rect(lm, "Lamp", 63.0, 70.2, -14.5, 14.5, 1.8, 7.6)
	LandmarkFrKit.rect(lm, "Corten", 61.5, 73.2, -17.0, 17.0, 8.2, 9.6)
	for k in 9:
		var gz := lerpf(-15.5, 15.5, float(k) / 8.0)
		lm.box("Steel", Vector3(71.55, 4.8, gz), Vector3(0.24, 6.8, 0.22))

static func _build_logomo_sali_and_konttori(lm: LandmarkMesh) -> void:
	# Logomo-sali (4-storey dark corten & steel concert auditorium box rising to 22.6 m).
	LandmarkFrKit.rect(lm, "Corten", -28.0, 24.0, -24.0, 10.0, 11.5, 22.1)
	LandmarkFrKit.rect(lm, "Roof", -27.5, 23.5, -23.5, 9.5, 22.1, TOP_M)
	# Vertical standing-seam weathering-steel acoustic fins on Logomo-sali.
	for k in 14:
		var fx := lerpf(-26.5, 22.5, float(k) / 13.0)
		lm.box("Steel", Vector3(fx, 16.9, 10.12), Vector3(0.22, 10.4, 0.28))
		lm.box("Steel", Vector3(fx, 16.9, -24.12), Vector3(0.22, 10.4, 0.28))
	# Illuminated LOGOMO fascia band facing the bridge (+Z).
	LandmarkFrKit.rect(lm, "Lamp", -12.0, 12.0, 10.12, 10.30, 18.8, 20.4)
	# Logomo Konttori (5-storey west office wing, x = -78..-56, z = -12..26, H 18.8 m).
	LandmarkFrKit.rect(lm, "Brick", -78.0, -56.0, -12.0, 26.0, 1.4, 18.4)
	LandmarkFrKit.rect(lm, "Roof", -77.6, -56.4, -11.6, 25.6, 18.4, 18.8)
	for fl in 4:
		var fy := 4.4 + float(fl) * 3.4
		LandmarkFrKit.rect(lm, "Glass", -78.12, -77.92, -9.5, 23.5, fy, fy + 1.9)
		LandmarkFrKit.rect(lm, "Glass", -75.5, -58.5, 25.92, 26.12, fy, fy + 1.9)
		if fl % 2 == 0:
			LandmarkFrKit.rect(lm, "Lamp", -77.4, -77.2, -8.5, 22.5, fy + 0.2, fy + 1.6)

static func _build_logomon_silta(lm: LandmarkMesh) -> void:
	# Logomon silta (2021): undulating weathering-steel pedestrian bridge spanning SSE (+Z)
	# from Logomo plaza (z = 24, x = 22) over the VR railyard toward Ratapihankatu (z = 162, x = 44).
	var n_seg := 28
	var deck_w := 5.6
	var p0 := Vector2(22.0, 24.0)
	var p1 := Vector2(46.0, 164.0)
	var dir := (p1 - p0).normalized()
	var perp := Vector2(-dir.y, dir.x)
	var prev_c := Vector3.ZERO
	for i in n_seg + 1:
		var t := float(i) / float(n_seg)
		var xy := p0.lerp(p1, t)
		# Gentle vertical arch over the railway clearance (peaks at 9.2 m over tracks, drops at ends).
		var deck_y := 2.4 + 6.8 * sin(PI * clampf(t * 1.15 - 0.07, 0.0, 1.0))
		if t > 0.12 and t < 0.88:
			deck_y = maxf(deck_y, 7.8 + 1.4 * sin(PI * (t - 0.12) / 0.76))
		# Undulating sculptural weathering-steel side-web height (characteristic wave profile).
		var wave_h := 2.1 + 1.65 * (0.5 + 0.5 * sin(t * TAU * 3.0))
		var cur_c := Vector3(xy.x, deck_y, xy.y)
		if i > 0:
			var mid := (prev_c + cur_c) * 0.5
			var seg_v := cur_c - prev_c
			var seg_l := seg_v.length()
			# Deck slab
			lm.beam("Concrete", prev_c, cur_c, deck_w, 0.65)
			# Sculpted undulating weathering-steel outer girders & warm LED rib lighting.
			for s: float in [-1.0, 1.0]:
				var off := Vector3(perp.x, 0.0, perp.y) * (deck_w * 0.52 * s)
				var a_lo := prev_c + off + Vector3(0, -0.35, 0)
				var b_lo := cur_c + off + Vector3(0, -0.35, 0)
				var a_hi := prev_c + off + Vector3(0, wave_h, 0)
				var b_hi := cur_c + off + Vector3(0, wave_h, 0)
				var n_out := Vector3(perp.x * s, 0.0, perp.y * s)
				lm.quad("Corten", a_lo, b_lo, b_hi, a_hi, n_out)
				lm.quad("Corten", a_lo - off * 0.06, a_hi - off * 0.06, b_hi - off * 0.06, b_lo - off * 0.06, -n_out)
				# Continuous warm LED handrail/rib glow strip along interior face.
				lm.beam("Lamp", prev_c + off * 0.88 + Vector3(0, 1.15, 0),
					cur_c + off * 0.88 + Vector3(0, 1.15, 0), 0.14, 0.14)
				# Glazed windscreen panel above handrail on main over-track span.
				if t > 0.15 and t < 0.85:
					lm.quad("Glass", prev_c + off * 0.94 + Vector3(0, 1.2, 0),
						cur_c + off * 0.94 + Vector3(0, 1.2, 0),
						cur_c + off * 0.94 + Vector3(0, 2.35, 0),
						prev_c + off * 0.94 + Vector3(0, 2.35, 0), n_out)
			# Sculptural diagonal structural ribs every 2 segments.
			if i % 2 == 0 and seg_l > 0.1:
				var o_l := Vector3(perp.x, 0.0, perp.y) * (deck_w * 0.54)
				lm.beam("Corten", mid - o_l + Vector3(0, wave_h, 0), mid + o_l + Vector3(0, wave_h, 0), 0.24, 0.28)
		# V-shaped concrete & steel bridge piers straddling the railyard tracks.
		if i in [4, 10, 16, 22]:
			var base_p := Vector3(xy.x, FOUND, xy.y)
			var o_p := Vector3(perp.x, 0.0, perp.y) * 2.2
			lm.beam("Concrete", base_p, cur_c - o_p, 0.95, 0.95)
			lm.beam("Concrete", base_p, cur_c + o_p, 0.95, 0.95)
			lm.box("Concrete", Vector3(xy.x, 0.4, xy.y), Vector3(2.4, 2.4 - FOUND, 2.4))
		prev_c = cur_c
	# Glazed lift & stair towers at north (Logomo) and south (Ratapihankatu) bridgeheads.
	for end_xy: Vector2 in [p0, p1]:
		var ex := end_xy.x
		var ez := end_xy.y
		LandmarkFrKit.rect(lm, "Glass", ex - 2.4, ex + 2.4, ez - 2.4, ez + 2.4, FOUND, 10.2)
		LandmarkFrKit.rect(lm, "Corten", ex - 2.6, ex + 2.6, ez - 2.6, ez + 2.6, 10.2, 11.4)
		LandmarkFrKit.rect(lm, "Lamp", ex - 1.8, ex + 1.8, ez - 1.8, ez + 1.8, 1.5, 9.5)

static func _set_night_floods(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-30.0, 2.0, 32.0), Vector3(-28.0, 9.0, 22.0), 58.0, 0.80, 44.0, Color(1.0, 0.84, 0.62)],
		[Vector3(12.0, 2.0, 32.0), Vector3(6.0, 14.0, 10.0), 56.0, 0.85, 48.0, Color(1.0, 0.80, 0.55)],
		[Vector3(78.0, 2.0, 0.0), Vector3(68.0, 6.5, 0.0), 54.0, 0.75, 36.0, Color(1.0, 0.88, 0.68)],
		[Vector3(34.0, 2.0, 92.0), Vector3(34.0, 10.0, 92.0), 65.0, 0.70, 42.0, Color(1.0, 0.76, 0.48)],
	])
