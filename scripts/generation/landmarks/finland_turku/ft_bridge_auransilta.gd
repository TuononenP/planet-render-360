class_name FtBridgeAuransilta
extends RefCounted

## Auransilta (1907, Carl Nyström & Karl Lindahl): Turku's flagship Art Nouveau
## granite-clad single-span arch bridge over Aurajoki linking Aurakatu and
## Kaskenkatu. Built along +X (yaw_deg = 54.5°, bearing 144.5°, base = "water",
## y = 0 at Aurajoki water level):
##   - Plan: 45.2 m total span (-22.6..+22.6 m), 17.5 m deck width (-8.75..+8.75 m),
##     deck road surface at y = 4.5 m, height_m = 10.6 m (top of Jugend lamps).
##   - Structure: 34 m clear single-span elliptical granite-clad arch springing at
##     y = 0.6 m to crown y = 3.85 m, flanked by heavy rusticated Finnish granite
##     abutment piers reaching y = -2.5 m into the riverbed.
##   - Signature features:
##     1. Curved mid-span stone viewing balconies projecting +/-1.65 m on both sides
##        at x = 0 supported on stepped granite corbels with curved stone parapets.
##     2. Molded granite stringcourse, stone end piers, and cast-iron Art Nouveau
##        scrolled railings between stone pilasters.
##     3. Four ornate Jugend bronze/dark-iron multi-globe lamp standards standing on
##        granite pedestals at x = +/-9.5 m, z = +/-8.6 m, each with scrolled arms
##        carrying 3 warm glowing milk-glass globes (top y = 10.6 m).
##   - Night lighting: warm glowing lamp globes + warm arch-soffit floodlights.
## Surfaces: 7 merged PBR parts (Granite, GraniteDark, Deck, Sidewalk, Iron,
## Bronze, Lamp).

const SPAN_HALF := 22.6
const HALF_W := 8.75
const DECK_Y := 4.5
const ARCH_HALF := 16.5
const FOOT_Y := 0.0

static func build(model: Node3D, row: Dictionary = {}) -> void:
	if row.is_empty():
		row = BridgeSpecs.row_for("br_turku_auransilta")
	var h := BridgeParam.half_length(row)
	var half_w := float(row.get("width", HALF_W * 2.0)) * 0.5
	var c := float(row.get("clear", DECK_Y))
	var lm := LandmarkMesh.new()
	_materials(lm)
	_build_arch_and_abutments(lm, h, c, half_w)
	_build_deck_and_sidewalks(lm, h, c, half_w)
	_build_midspan_balconies(lm, c, half_w)
	_build_parapets_and_railings(lm, h, c, half_w)
	_build_jugend_lamps(lm, c, half_w)
	BridgeCamber.apply(lm, h, c, float(row.get("camber", 0.0)), float(row.get("tilt", 0.0)))
	lm.commit(model)
	_set_night_floods(model, c)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#988D85", 2.6))
	lm.use("GraniteDark", LandmarkMaterials.pbr("stone", "#6D6560", 2.4))
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#3B3C3E", 3.5))
	lm.use("Sidewalk", LandmarkMaterials.pbr("stone", "#ACA59B", 2.0))
	lm.use("Iron", LandmarkMaterials.paint("#23282B", 0.42, 0.58))
	lm.use("Bronze", LandmarkMaterials.paint("#3E473E", 0.38, 0.62))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE8B8", 2.2))

static func _build_arch_and_abutments(lm: LandmarkMesh, h: float, c: float, half_w: float) -> void:
	# Main granite-clad spandrel wall with elliptical arch opening via LandmarkBrKit.
	var spring := clampf(c * 0.14, 0.25, 0.65)
	var rise := maxf(0.5, c - 0.65 - spring)
	var arch_half := minf(ARCH_HALF, h - 4.0)
	var poly := PackedVector2Array([
		Vector2(-h, FOOT_Y),
		Vector2(-arch_half, FOOT_Y),
		Vector2(-arch_half, spring),
	])
	poly.append_array(LandmarkBrKit.arch_pts(0.0, spring, arch_half, rise, 16))
	poly.append_array(PackedVector2Array([
		Vector2(arch_half, spring),
		Vector2(arch_half, FOOT_Y),
		Vector2(h, FOOT_Y),
		Vector2(h, c - 0.15),
		Vector2(-h, c - 0.15),
	]))
	LandmarkBrKit.extrude_xy(lm, "Granite", poly, -half_w, half_w)
	# Rusticated dark-granite voussoir ring & waterline plinth on both facades.
	var arch := LandmarkBrKit.arch_pts(0.0, spring, arch_half, rise, 16)
	var foot_h := clampf(c * 0.42, 0.8, 1.8)
	for s: float in [-1.0, 1.0]:
		var z_face := s * (half_w + 0.12)
		for i in arch.size() - 1:
			var a := Vector3(arch[i].x, arch[i].y + 0.24, z_face)
			var b := Vector3(arch[i + 1].x, arch[i + 1].y + 0.24, z_face)
			lm.beam("GraniteDark", a, b, 0.52, 0.28)
		# Heavy rusticated waterline footing blocks at both abutments.
		for sx: float in [-1.0, 1.0]:
			lm.box("GraniteDark", Vector3(sx * (h - 3.0), foot_h * 0.5, s * (half_w + 0.15)),
				Vector3(6.0, foot_h, 0.45), Basis(), 0.0)
		# Projecting granite stringcourse molding along deck level.
		lm.box("GraniteDark", Vector3(0.0, c - 0.12, s * (half_w + 0.18)),
			Vector3(h * 2.0 + 0.4, 0.34, 0.42), Basis(), 0.0)

static func _build_deck_and_sidewalks(lm: LandmarkMesh, h: float, c: float, half_w: float) -> void:
	# Asphalt carriageway (-5.5..+5.5 m) and raised granite-kerb sidewalks.
	lm.box("Deck", Vector3(0.0, c - 0.08, 0.0), Vector3(h * 2.0, 0.18, 11.2), Basis(), 0.0)
	for s: float in [-1.0, 1.0]:
		lm.box("Sidewalk", Vector3(0.0, c + 0.02, s * (half_w - 1.6)), Vector3(h * 2.0, 0.20, 3.1), Basis(), 0.0)
		lm.box("GraniteDark", Vector3(0.0, c + 0.05, s * 5.62), Vector3(h * 2.0, 0.22, 0.24), Basis(), 0.0)

static func _build_midspan_balconies(lm: LandmarkMesh, c: float, half_w: float) -> void:
	# Curved Art Nouveau stone viewing balconies projecting outward at mid-span (x = 0).
	var segs := 8
	var rx := 3.6
	var rz := 1.65
	for s: float in [-1.0, 1.0]:
		var base_z := s * half_w
		var poly := PackedVector2Array([Vector2(-rx, base_z)])
		for i in segs + 1:
			var a := PI * (1.0 - float(i) / float(segs))
			poly.append(Vector2(cos(a) * rx, base_z + s * sin(a) * rz))
		poly.append(Vector2(rx, base_z))
		# Balcony floor slab + stepped granite corbel beneath.
		lm.poly_prism("Sidewalk", poly, c - 0.22, c + 0.12)
		var corb1 := PackedVector2Array([Vector2(-rx * 0.85, base_z)])
		for i in segs + 1:
			var a := PI * (1.0 - float(i) / float(segs))
			corb1.append(Vector2(cos(a) * rx * 0.85, base_z + s * sin(a) * rz * 0.72))
		corb1.append(Vector2(rx * 0.85, base_z))
		lm.poly_prism("GraniteDark", corb1, c - 0.85, c - 0.22)
		# Curved stone parapet wall + heavy coping around the balcony edge.
		for i in segs:
			var a0 := PI * (1.0 - float(i) / float(segs))
			var a1 := PI * (1.0 - float(i + 1) / float(segs))
			var p0 := Vector3(cos(a0) * (rx - 0.16), c + 0.62, base_z + s * sin(a0) * (rz - 0.16))
			var p1 := Vector3(cos(a1) * (rx - 0.16), c + 0.62, base_z + s * sin(a1) * (rz - 0.16))
			lm.beam("Granite", p0, p1, 0.96, 0.36)
			lm.beam("GraniteDark", p0 + Vector3(0, 0.52, 0), p1 + Vector3(0, 0.52, 0), 0.14, 0.44)

static func _build_parapets_and_railings(lm: LandmarkMesh, h: float, c: float, half_w: float) -> void:
	for s: float in [-1.0, 1.0]:
		var z_rail := s * (half_w - 0.22)
		# Heavy stone abutment end pedestals and lamp piers.
		for px: float in [-h + 0.7, -9.5, -3.7, 3.7, 9.5, h - 0.7]:
			var w := 1.15 if absf(px) > 8.5 else 0.75
			lm.box("Granite", Vector3(px, c + 0.65, z_rail), Vector3(w, 1.30, 0.68), Basis(), 0.0)
			lm.box("GraniteDark", Vector3(px, c + 1.34, z_rail), Vector3(w + 0.16, 0.16, 0.80), Basis(), 0.0)
		# Low granite plinth wall + cast-iron Jugend railings between piers.
		for seg: Array in [[-h + 1.3, -10.1], [-8.9, -4.1], [4.1, 8.9], [10.1, h - 1.3]]:
			var x0: float = seg[0]
			var x1: float = seg[1]
			lm.box("Granite", Vector3((x0 + x1) * 0.5, c + 0.22, z_rail), Vector3(x1 - x0, 0.44, 0.36), Basis(), 0.0)
			LandmarkBrKit.railing(lm, "Iron", Vector3(x0, c + 0.44, z_rail),
				Vector3(x1, c + 0.44, z_rail), 0.74, 1.8)

static func _build_jugend_lamps(lm: LandmarkMesh, c: float, half_w: float) -> void:
	# Four iconic 1907 Jugend bronze multi-globe lamp standards (x = +/-9.5, z = +/-8.53).
	var col_prof := PackedVector2Array([
		Vector2(0.32, 0.0), Vector2(0.28, 0.45), Vector2(0.18, 0.85),
		Vector2(0.14, 2.80), Vector2(0.11, 4.10), Vector2(0.16, 4.24), Vector2(0.0, 4.30)
	])
	var globe_prof := PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.18, 0.08), Vector2(0.24, 0.22),
		Vector2(0.20, 0.36), Vector2(0.0, 0.44)
	])
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var base := Vector3(sx * 9.5, c + 1.42, sz * (half_w - 0.22))
			lm.lathe("Bronze", base, col_prof, 8)
			# Central crown globe (top at y = c + 1.42 + 4.68 = c + 6.10 m).
			lm.lathe("Lamp", base + Vector3(0.0, 4.24, 0.0), globe_prof, 8)
			# Two scrolled Jugend side arms carrying lower pendant globes along X.
			for arm: float in [-1.0, 1.0]:
				var root := base + Vector3(0.0, 3.35, 0.0)
				var tip := base + Vector3(arm * 0.72, 3.85, 0.0)
				lm.beam("Bronze", root, tip, 0.06, 0.06)
				lm.lathe("Lamp", tip + Vector3(0.0, 0.02, 0.0), globe_prof, 8)

static func _set_night_floods(model: Node3D, c: float) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, maxf(c * 0.45, 0.8), 10.5), Vector3(0.0, c * 0.75, 4.0), 65.0, 0.85, 24.0, Color("#FFE0B0")],
		[Vector3(0.0, maxf(c * 0.45, 0.8), -10.5), Vector3(0.0, c * 0.75, -4.0), 65.0, 0.85, 24.0, Color("#FFE0B0")],
		[Vector3(-9.5, c + 5.3, 4.0), Vector3(-9.5, c, 0.0), 68.0, 0.75, 20.0, Color("#FFE8B8")],
		[Vector3(9.5, c + 5.3, -4.0), Vector3(9.5, c, 0.0), 68.0, 0.75, 20.0, Color("#FFE8B8")],
	])
