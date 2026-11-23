class_name FtSuomenJoutsen
extends RefCounted

## Suomen Joutsen (1902, St-Nazaire, ex-Laënnec / Oldenburg): iconic white
## steel-hulled 3-masted full-rigged museum ship permanently moored starboard-
## side-to at Forum Marinum quay on Aurajoki in true metres (+X bow pointing
## downstream SW via registry yaw_deg = 146.1°, +Z starboard facing the quay,
## -Z port facing open river, y = 0 at waterline, base = "water"):
##   - True ultra-smooth lofted steel clipper hull (84 m hull, 96 m LOA with
##     bowsprit/jibboom, 12.4 m beam, 4.9 m freeboard, graceful overhanging
##     clipper stem & elliptical counter stern, vivid sea-green anti-fouling
##     boot-top, gleaming marine-white topsides with double porthole rows).
##   - Integrated curved forecastle (+X) and poop (-X) decks following the
##     hull sheer with open white steel stanchion railings, solid waist
##     bulwarks with teak cap rails, stern cabin windows & Finnish ensign.
##   - Steeply raked gleaming white bowsprit & jibboom with dolphin striker,
##     whisker booms, bobstays & netting; dark flying swan emblem & sweeping
##     trailboard scrollwork; hanging black stock anchors with draped chain
##     catenaries; crisp "SUOMEN JOUTSEN" lettering on both bows.
##   - Authentic museum deck layout: low white deckhouses, dark sloped waist
##     awning, aft white-framed visitor canopy, double spoked helm wheel,
##     6 curved white radial davits & 2 clinker lifeboats, starboard boarding
##     staircase & mooring hawsers to Forum Marinum quay.
##   - Full 3-masted square rig built by FtSuomenJoutsenRig (15 braced white
##     yards, 3-tone white/varnished-mahogany/white masts, ratlines, braces).
## Surfaces: 12 merged parts (Hull, Boot, Deck, MastWood, Sail, Dark, Brass,
## Glass, WoodDark, Lamp, FlagBlue, Nameplate).

const Rig := preload("res://scripts/generation/landmarks/finland_turku/ft_suomen_joutsen_rig.gd")

const HULL_SPEC := {
	"length": 84.0,
	"beam": 12.4,
	"freeboard": 4.9,
	"draft": 1.8,
	"entry": 0.35,
	"bow_pow": 1.75,
	"stern_w": 0.44,
	"stern_round": 0.96,
	"stern_tail": 0.24,
	"flare": 0.16,
	"bow_rise": 1.65,
	"stern_rise": 1.10,
	"stem_rake": 5.4,
	"stern_rake": 4.6,
	"boot_m": 1.25,
	"lod": 0,
	"ultra": true,
}

const QUAY_Z := 11.4
const QUAY_Y := 1.45

## Compact 5x7 uppercase bitmap font for crisp "SUOMEN JOUTSEN" bow lettering.
const FONT_5X7 := {
	"S": ["01110", "10001", "10000", "01110", "00001", "10001", "01110"],
	"U": ["10001", "10001", "10001", "10001", "10001", "10001", "01110"],
	"O": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
	"M": ["10001", "11011", "10101", "10101", "10001", "10001", "10001"],
	"E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
	"N": ["10001", "11001", "10101", "10011", "10001", "10001", "10001"],
	"J": ["00111", "00010", "00010", "00010", "10010", "10010", "01100"],
	"T": ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
	" ": ["00000", "00000", "00000", "00000", "00000", "00000", "00000"],
}

static var _nameplate_mat: StandardMaterial3D

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	HullLoft.loft(lm, HULL_SPEC, {"hull": "Hull", "boot": "Boot", "bottom": "Boot", "deck": "Deck"})
	_build_bulwarks_and_decks(lm)
	_build_portholes_and_stern(lm)
	var bow_pts := _build_bow_and_bowsprit(lm)
	_build_deckhouses_and_boats(lm)
	Rig.build(lm, HULL_SPEC, bow_pts)
	_build_gangway_and_mooring(lm)
	lm.commit(model)
	_set_night_floods(model)

static func _marine_paint(hex: String, roughness: float, metallic: float) -> StandardMaterial3D:
	# Clean satin marine enamel over subtle render micro-grain, without
	# LandmarkShader's concrete formwork & muddy architectural damp band.
	var m := StandardMaterial3D.new()
	m.albedo_texture = LandmarkMaterials.tex("render", "diff")
	m.albedo_color = LandmarkMaterials.tint("render", hex)
	m.normal_enabled = true
	m.normal_texture = LandmarkMaterials.tex("render", "nor")
	m.normal_scale = 0.22
	m.roughness = roughness
	m.metallic = metallic
	m.uv1_scale = Vector3(0.25, 0.25, 0.25)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m

static func _nameplate_material() -> StandardMaterial3D:
	if _nameplate_mat != null:
		return _nameplate_mat
	var text := "SUOMEN JOUTSEN"
	var scale := 6
	var char_w := 7 * scale
	var pad_x := 18
	var w := pad_x * 2 + text.length() * char_w
	var h := 11 * scale
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.08, 0.11, 0.16, 0.0))
	var ink := Color("#121924")
	var ox := pad_x
	var oy := 2 * scale
	for ci in text.length():
		var ch := text.substr(ci, 1)
		var rows: Array = FONT_5X7.get(ch, FONT_5X7[" "])
		for r in rows.size():
			var row_s: String = rows[r]
			for c in row_s.length():
				if row_s.substr(c, 1) == "1":
					for py in scale:
						for px in scale + 2:
							img.set_pixel(mini(ox + c * scale + px, w - 1), oy + r * scale + py, ink)
		ox += char_w
	img.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.5
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.texture_repeat = false
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_nameplate_mat = m
	return m

static func _materials(lm: LandmarkMesh) -> void:
	var white := _marine_paint("#F5F3EE", 0.34, 0.08)
	lm.use("Hull", white)
	lm.use("White", white)
	lm.use("Boot", _marine_paint("#187B54", 0.44, 0.06))
	lm.use("Deck", LandmarkMaterials.pbr("wood", "#A68258", 2.4, 0.72))
	lm.use("MastWood", LandmarkMaterials.pbr("wood", "#8E552A", 2.0, 0.42))
	lm.use("Sail", _marine_paint("#F1EEE6", 0.78, 0.0))
	lm.use("Dark", LandmarkMaterials.paint("#1D2228", 0.48, 0.42))
	lm.use("Steel", LandmarkMaterials.paint("#4B535B", 0.45, 0.55))
	lm.use("Brass", LandmarkMaterials.gold())
	lm.use("Glass", LandmarkMaterials.glass("#1E2F3B"))
	lm.use("WoodDark", LandmarkMaterials.pbr("wood", "#4F3624", 2.0, 0.68))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE8BC", 1.5))
	lm.use("FlagBlue", _marine_paint("#003580", 0.75, 0.0))
	lm.use("Nameplate", _nameplate_material())

static func _side(t: float, drop: float) -> Vector3:
	var pts := HullLoft.section(HULL_SPEC, t)
	var top: Vector3 = pts[0]
	var mid: Vector3 = pts[1]
	var q := top.lerp(mid, drop / maxf(top.y - mid.y, 0.2))
	return Vector3(q.x, q.y, absf(q.z))

static func _build_bulwarks_and_decks(lm: LandmarkMesh) -> void:
	# Solid white steel bulwarks along waist + integrated raised forecastle (+X)
	# and poop (-X) decks following the curved hull sheer and half-beam.
	var bh := 1.15
	var th := 0.16
	var n := 48
	for s: float in [-1.0, 1.0]:
		var ob := PackedVector3Array()
		var ot := PackedVector3Array()
		var ib := PackedVector3Array()
		var it := PackedVector3Array()
		var cap: Array = []
		for i in n + 1:
			var t := lerpf(0.0, 0.99, float(i) / float(n))
			var q := _side(t, 0.0)
			var zi := maxf(q.z - th, 0.04)
			var h := bh
			if t > 0.80:
				h = bh + 0.35 * smoothstep(0.80, 0.84, t)
			elif t < 0.22:
				h = bh + 0.30 * (1.0 - smoothstep(0.18, 0.22, t))
			ob.append(Vector3(q.x, q.y, q.z * s))
			ot.append(Vector3(q.x, q.y + h, q.z * s))
			ib.append(Vector3(q.x, q.y, zi * s))
			it.append(Vector3(q.x, q.y + h, zi * s))
			cap.append(Vector3(q.x, q.y + h + 0.04, (q.z + zi) * 0.5 * s))
		lm.grid("Hull", [ob, ot], Vector3(0, 0, s))
		lm.grid("Hull", [ib, it], Vector3(0, 0, -s))
		HullLoft.tube(lm, "WoodDark", cap, 0.095, 6)
		# Open white steel stanchion railings atop the raised forecastle and poop decks.
		_stanchion_rail(lm, 0.82, 0.985, 1.50, 0.95, s, 14)
		_stanchion_rail(lm, 0.01, 0.20, 1.45, 0.95, s, 16)
	# Curved raised teak forecastle deck (t = 0.82..0.985) and poop deck (t = 0.005..0.20).
	_curved_deck(lm, 0.82, 0.985, 1.38, 12)
	_curved_deck(lm, 0.005, 0.20, 1.34, 14)
	# Break bulkheads closing the aft face of forecastle & forward face of poop.
	_break_bulkhead(lm, 0.82, 1.38, Vector3.LEFT)
	_break_bulkhead(lm, 0.20, 1.34, Vector3.RIGHT)
	# Closed white transom bulwark + cap rail across the stern.
	var st := _side(0.0, 0.0)
	var st_h := bh + 0.30
	lm.quad("Hull", Vector3(st.x, st.y, st.z), Vector3(st.x, st.y, -st.z),
		Vector3(st.x, st.y + st_h, -st.z), Vector3(st.x, st.y + st_h, st.z), Vector3.LEFT)
	HullLoft.tube(lm, "WoodDark", [Vector3(st.x, st.y + st_h + 0.04, -st.z),
		Vector3(st.x, st.y + st_h + 0.04, st.z)], 0.095, 6)

static func _stanchion_rail(lm: LandmarkMesh, t0: float, t1: float, y_off: float, rail_h: float, s: float, steps: int) -> void:
	var top_bar: Array = []
	var mid_bar: Array = []
	for i in steps + 1:
		var t := lerpf(t0, t1, float(i) / float(steps))
		var q := _side(t, 0.0)
		var base := Vector3(q.x, q.y + y_off, maxf(q.z - 0.10, 0.05) * s)
		top_bar.append(base + Vector3(0, rail_h, 0))
		mid_bar.append(base + Vector3(0, rail_h * 0.5, 0))
		HullLoft.tube(lm, "Hull", [base, base + Vector3(0, rail_h, 0)], 0.025, 4)
	HullLoft.tube(lm, "Hull", top_bar, 0.032, 4)
	HullLoft.tube(lm, "Hull", mid_bar, 0.020, 4)

static func _curved_deck(lm: LandmarkMesh, t0: float, t1: float, y_off: float, steps: int) -> void:
	var rows: Array = []
	for i in steps + 1:
		var t := lerpf(t0, t1, float(i) / float(steps))
		var q := _side(t, 0.0)
		var hz := maxf(q.z - 0.14, 0.04)
		var y := q.y + y_off
		var row := PackedVector3Array()
		for j in 5:
			var f := lerpf(-1.0, 1.0, float(j) / 4.0)
			row.append(Vector3(q.x, y + (1.0 - f * f) * 0.12, hz * f))
		rows.append(row)
	lm.grid("Deck", rows, Vector3.UP)

static func _break_bulkhead(lm: LandmarkMesh, t: float, h: float, face: Vector3) -> void:
	var q := _side(t, 0.0)
	var hz := maxf(q.z - 0.14, 0.1)
	lm.quad("Hull", Vector3(q.x, q.y, -hz), Vector3(q.x, q.y, hz),
		Vector3(q.x, q.y + h, hz), Vector3(q.x, q.y + h, -hz), face)
	# Twin teak companionway doors in the break bulkhead.
	for sz: float in [-1.8, 1.8]:
		lm.box("WoodDark", Vector3(q.x + face.x * 0.04, q.y + h * 0.45, sz), Vector3(0.08, h * 0.78, 0.82))

static func _build_portholes_and_stern(lm: LandmarkMesh) -> void:
	# Authentic double row of neat small round portholes + subtle white/steel rims.
	for s: float in [-1.0, 1.0]:
		var normal := Vector3(0, 0, s)
		# Lower main-deck row (22 portholes along the hull).
		for k in 22:
			var t := lerpf(0.07, 0.89, float(k) / 21.0)
			var p := _side(t, 1.95)
			lm.disc("Hull", Vector3(p.x, p.y, (p.z + 0.03) * s), normal, 0.21, 8)
			lm.disc("Dark", Vector3(p.x, p.y, (p.z + 0.05) * s), normal, 0.15, 8)
		# Upper row under forecastle & poop/midships.
		for t_up: float in [0.10, 0.14, 0.18, 0.78, 0.82, 0.86, 0.90]:
			var p := _side(t_up, 0.65)
			lm.disc("Hull", Vector3(p.x, p.y, (p.z + 0.03) * s), normal, 0.17, 8)
			lm.disc("Dark", Vector3(p.x, p.y, (p.z + 0.05) * s), normal, 0.12, 8)
	# Stern cabin windows & gilded counter trim across the rounded transom.
	var stern := _side(0.0, 0.0)
	var sy := stern.y - 0.75
	var sx := HullLoft.transom_x(HULL_SPEC, sy) - 0.05
	for k in 5:
		var sz := lerpf(-stern.z * 0.62, stern.z * 0.62, float(k) / 4.0)
		lm.box("Brass", Vector3(sx, sy, sz), Vector3(0.08, 0.54, 0.46))
		lm.box("Glass", Vector3(sx - 0.03, sy, sz), Vector3(0.05, 0.40, 0.34))
	# Slender white stern ensign staff & Finnish flag (white field + blue Nordic cross).
	var staff_base := Vector3(stern.x - 0.2, stern.y + 1.45, 0.0)
	var staff_tip := staff_base + Vector3(-2.6, 5.2, 0.0)
	HullLoft.tube(lm, "Hull", [staff_base, staff_tip], 0.055, 6)
	lm.lathe("Brass", staff_tip, LandmarkFrKit.ball(0.10), 6)
	var f0 := staff_tip - Vector3(-0.35, 0.70, 0.0)
	var fw := 2.4
	var fh := 1.45
	lm.box("Hull", f0 + Vector3(-fw * 0.5, -fh * 0.35, 0.0), Vector3(fw, fh, 0.04))
	lm.box("FlagBlue", f0 + Vector3(-fw * 0.5, -fh * 0.35, 0.0), Vector3(fw + 0.02, fh * 0.27, 0.06))
	lm.box("FlagBlue", f0 + Vector3(-fw * 0.34, -fh * 0.35, 0.0), Vector3(fw * 0.16, fh + 0.02, 0.06))

static func _build_bow_and_bowsprit(lm: LandmarkMesh) -> Dictionary:
	var stem := _side(0.99, 0.0)
	# Steeply raked gleaming white bowsprit & jibboom (~23° rise, 96 m LOA).
	var heel := Vector3(stem.x - 4.8, stem.y + 0.85, 0.0)
	var cap := Vector3(stem.x + 7.4, stem.y + 5.05, 0.0)
	var mid_jib := Vector3(stem.x + 11.4, stem.y + 6.75, 0.0)
	var tip := Vector3(stem.x + 15.2, stem.y + 8.35, 0.0)
	HullLoft.tube(lm, "Hull", [heel, cap], 0.32, 10)
	HullLoft.tube(lm, "Hull", [cap - Vector3(1.1, 0.45, 0.0), tip], 0.18, 8)
	lm.box("Dark", cap, Vector3(0.45, 0.85, 0.72))
	# White dolphin striker (martingale), whisker booms, bobstays & bowsprit netting.
	var striker := cap + Vector3(-0.45, -3.1, 0.0)
	HullLoft.tube(lm, "Hull", [cap, striker], 0.08, 6)
	var cutwater := Vector3(stem.x - 1.6, 1.25, 0.0)
	HullLoft.tube(lm, "Dark", [tip, striker, cutwater], 0.040, 4)
	HullLoft.tube(lm, "Dark", [mid_jib, striker], 0.032, 4)
	HullLoft.tube(lm, "Dark", [cap, cutwater + Vector3(0.3, 0.65, 0.0)], 0.050, 4)
	HullLoft.tube(lm, "Dark", [cap, cutwater], 0.045, 4)
	for s: float in [-1.0, 1.0]:
		var w_tip := cap + Vector3(-0.6, -0.35, 2.6 * s)
		HullLoft.tube(lm, "Hull", [cap + Vector3(-0.6, -0.25, 0.0), w_tip], 0.055, 5)
		HullLoft.tube(lm, "Dark", [tip, w_tip, Vector3(stem.x - 3.5, stem.y + 0.2, 2.2 * s)], 0.028, 4)
		# Bowsprit footropes / netting lines under the bowsprit.
		VesselEquipment.line(lm, Vector3(stem.x + 0.2, stem.y + 0.6, 0.55 * s),
			cap + Vector3(0, -0.5, 0.45 * s), 0.55, 0.018)
		VesselEquipment.line(lm, cap + Vector3(0, -0.5, 0.45 * s),
			tip + Vector3(-0.4, -0.35, 0.15 * s), 0.40, 0.014)

	# Iconic dark navy/black trailboard scroll, flying swan emblem, hawsepipe,
	# hanging Admiralty stock anchor & draped anchor chain catenary on both bows.
	for s: float in [-1.0, 1.0]:
		# Sweeping dark trailboard line following the clipper bow cheeks.
		var scroll: Array = []
		for i in 9:
			var q := _side(lerpf(0.87, 0.988, float(i) / 8.0), 0.72)
			scroll.append(Vector3(q.x, q.y, (q.z + 0.045) * s))
		HullLoft.tube(lm, "Dark", scroll, 0.048, 5)
		# Dark flying swan silhouette on the bow cheek near the stem.
		var sw := _side(0.955, 0.42)
		var sw_z := (sw.z + 0.06) * s
		lm.beam("Dark", Vector3(sw.x - 0.95, sw.y - 0.18, sw_z), Vector3(sw.x + 0.85, sw.y + 0.22, sw_z), 0.18, 0.07)
		lm.beam("Dark", Vector3(sw.x - 0.15, sw.y + 0.02, sw_z), Vector3(sw.x - 0.85, sw.y + 0.68, sw_z), 0.15, 0.06)
		lm.beam("Dark", Vector3(sw.x + 0.15, sw.y + 0.06, sw_z), Vector3(sw.x + 0.95, sw.y + 0.42, sw_z), 0.11, 0.06)
		# Hawsepipe, hanging black stock anchor & draped anchor chain loop.
		var hp := _side(0.925, 1.05)
		var hp_p := Vector3(hp.x, hp.y, (hp.z + 0.05) * s)
		VesselEquipment.ring(lm, "Hull", hp_p, Vector3(0, 0, s), 0.30, 0.07)
		lm.disc("Dark", hp_p + Vector3(0, 0, 0.02 * s), Vector3(0, 0, s), 0.22, 8)
		var anc_top := hp_p + Vector3(0.0, -0.35, 0.12 * s)
		var anc_bot := anc_top + Vector3(0.0, -2.55, 0.0)
		HullLoft.tube(lm, "Dark", [anc_top, anc_bot], 0.11, 6)
		HullLoft.tube(lm, "Dark", [anc_top + Vector3(-0.75, -0.25, 0), anc_top + Vector3(0.75, -0.25, 0)], 0.08, 5)
		HullLoft.tube(lm, "Dark", [anc_bot + Vector3(-1.05, 0.72, 0), anc_bot, anc_bot + Vector3(1.05, 0.72, 0)], 0.11, 6)
		# Draped chain catenary from hawsepipe back to bow cleat (iconic in photos!).
		var ch_aft := _side(0.865, 0.65)
		VesselEquipment.line(lm, hp_p + Vector3(-0.15, -0.1, 0.04 * s),
			Vector3(ch_aft.x, ch_aft.y, (ch_aft.z + 0.09) * s), 1.45, 0.065)
		# Crisp "SUOMEN JOUTSEN" painted lettering curved smoothly along the convex white bow.
		var t_a := 0.725
		var t_b := 0.855
		var h_txt := 1.05
		var segs := 8
		var nrm := Vector3.BACK if s > 0.0 else Vector3.FORWARD
		for k in segs:
			var u0 := float(k) / float(segs)
			var u1 := float(k + 1) / float(segs)
			var qa := _side(lerpf(t_a, t_b, u0), 0.95)
			var qb := _side(lerpf(t_a, t_b, u1), 0.95)
			var a0 := Vector3(qa.x, qa.y - h_txt * 0.5, (qa.z + 0.07) * s)
			var a1 := Vector3(qa.x, qa.y + h_txt * 0.5, (qa.z + 0.07) * s)
			var b0 := Vector3(qb.x, qb.y - h_txt * 0.5, (qb.z + 0.07) * s)
			var b1 := Vector3(qb.x, qb.y + h_txt * 0.5, (qb.z + 0.07) * s)
			if s > 0.0:
				# Starboard (+Z): left-to-right when viewed from +Z is stern (-X) -> bow (+X).
				lm.tri("Nameplate", a0, b0, b1, nrm, nrm, nrm,
					Vector2(u0, 1), Vector2(u1, 1), Vector2(u1, 0))
				lm.tri("Nameplate", a0, b1, a1, nrm, nrm, nrm,
					Vector2(u0, 1), Vector2(u1, 0), Vector2(u0, 0))
			else:
				# Port (-Z): left-to-right when viewed from -Z is bow (+X) -> stern (-X).
				var pu0 := 1.0 - u0
				var pu1 := 1.0 - u1
				lm.tri("Nameplate", b0, a0, a1, nrm, nrm, nrm,
					Vector2(pu1, 1), Vector2(pu0, 1), Vector2(pu0, 0))
				lm.tri("Nameplate", b0, a1, b1, nrm, nrm, nrm,
					Vector2(pu1, 1), Vector2(pu0, 0), Vector2(pu1, 0))

	return {
		"stem_top": Vector3(stem.x, stem.y + 1.4, 0.0),
		"cap": cap,
		"mid_jib": mid_jib,
		"tip": tip,
	}

static func _build_deckhouses_and_boats(lm: LandmarkMesh) -> void:
	var deck_y := 4.92
	# Authentic low white forward deckhouse (galley / museum space, x = 4.0..14.5).
	LandmarkFrKit.rect(lm, "Hull", 4.0, 14.5, -2.9, 2.9, deck_y, deck_y + 2.05)
	LandmarkFrKit.rect(lm, "WoodDark", 3.85, 14.65, -3.05, 3.05, deck_y + 2.05, deck_y + 2.22)
	# Dark sloped museum waist awning over the midship deckhouse (seen in quarter.jpg).
	lm.gable("WoodDark", Vector3(9.2, deck_y + 2.22, 0.0), 6.4, 11.2, 0.72, Basis(Vector3.UP, PI * 0.5))
	# Low white midship charthouse / companionway (x = -14.0..-5.5) with mahogany skylight.
	LandmarkFrKit.rect(lm, "Hull", -14.0, -5.5, -2.7, 2.7, deck_y, deck_y + 2.0)
	LandmarkFrKit.rect(lm, "WoodDark", -14.15, -5.35, -2.85, 2.85, deck_y + 2.0, deck_y + 2.16)
	LandmarkFrKit.rect(lm, "WoodDark", -12.0, -7.5, -1.35, 1.35, deck_y + 2.16, deck_y + 2.68)
	LandmarkFrKit.rect(lm, "Glass", -11.7, -7.8, -1.15, 1.15, deck_y + 2.68, deck_y + 2.88)
	LandmarkFrKit.rect(lm, "Lamp", -11.5, -8.0, -1.0, 1.0, deck_y + 2.28, deck_y + 2.62)
	for sz: float in [-1.0, 1.0]:
		for k in 5:
			var px := lerpf(5.2, 13.3, float(k) / 4.0)
			lm.disc("Brass", Vector3(px, deck_y + 1.25, 2.94 * sz), Vector3(0, 0, sz), 0.22, 8)
			lm.disc("Glass", Vector3(px, deck_y + 1.25, 2.96 * sz), Vector3(0, 0, sz), 0.16, 8)
		for k in 4:
			var px := lerpf(-12.8, -6.7, float(k) / 3.0)
			lm.disc("Brass", Vector3(px, deck_y + 1.20, 2.74 * sz), Vector3(0, 0, sz), 0.22, 8)
			lm.disc("Glass", Vector3(px, deck_y + 1.20, 2.76 * sz), Vector3(0, 0, sz), 0.16, 8)
	# Aft poop deck white visitor canopy frame (arches + crisp white awning, seen in night.jpg & 08).
	var poop_y := HullLoft.sheer(HULL_SPEC, -31.0) + 1.38
	var canopy_h := 2.45
	for ax: float in [-37.5, -34.5, -31.5, -28.5, -25.5]:
		var hz := minf(HullLoft.half(HULL_SPEC, ax) - 0.35, 4.4)
		var arch: Array = []
		for j in 9:
			var a := lerpf(-PI * 0.5, PI * 0.5, float(j) / 8.0)
			arch.append(Vector3(ax, poop_y + canopy_h - 0.35 + 0.55 * cos(a), hz * sin(a)))
		HullLoft.tube(lm, "Hull", [Vector3(ax, poop_y, -hz), arch[0]], 0.045, 5)
		HullLoft.tube(lm, "Hull", [Vector3(ax, poop_y, hz), arch[8]], 0.045, 5)
		HullLoft.tube(lm, "Hull", arch, 0.045, 5)
	var canopy_rows: Array = []
	for ax: float in [-37.5, -34.5, -31.5, -28.5, -25.5]:
		var hz := minf(HullLoft.half(HULL_SPEC, ax) - 0.35, 4.4)
		var row := PackedVector3Array()
		for j in 7:
			var a := lerpf(-PI * 0.45, PI * 0.45, float(j) / 6.0)
			row.append(Vector3(ax, poop_y + canopy_h - 0.30 + 0.55 * cos(a), hz * sin(a)))
		canopy_rows.append(row)
	lm.grid("Sail", canopy_rows, Vector3.UP)
	# Double spoked wooden helm wheel & binnacle on the poop deck.
	var helm_at := Vector3(-35.0, poop_y, 0.0)
	lm.box("WoodDark", helm_at + Vector3(0, 0.55, 0), Vector3(0.42, 1.1, 0.36))
	for wx: float in [-0.28, 0.28]:
		var wc := helm_at + Vector3(wx, 1.12, 0.0)
		VesselEquipment.ring(lm, "WoodDark", wc, Vector3.RIGHT, 0.62, 0.035)
		for sp in 8:
			var ang := TAU * float(sp) / 8.0
			HullLoft.tube(lm, "WoodDark", [wc, wc + Vector3(0, cos(ang), sin(ang)) * 0.78], 0.022, 4)
	# Foredeck anchor windlass/capstan, cargo hatch & cowl ventilators.
	var fc_y := HullLoft.sheer(HULL_SPEC, 31.0) + 1.42
	VesselEquipment.winch(lm, Vector3(31.5, fc_y, 0.0), 0.55)
	LandmarkFrKit.rect(lm, "WoodDark", 16.0, 19.2, -1.9, 1.9, deck_y, deck_y + 0.58)
	LandmarkFrKit.rect(lm, "Deck", 16.2, 19.0, -1.7, 1.7, deck_y + 0.58, deck_y + 0.68)
	for vx: float in [15.5, 2.5, -15.5]:
		for sz: float in [-3.4, 3.4]:
			VesselEquipment.vent(lm, Vector3(vx, deck_y, sz), 0.32)
	# Iconic curved white steel radial boat davits (3 pairs/side) & 2 lofted clinker lifeboats.
	var boat_spec := {
		"length": 6.4, "beam": 2.05, "freeboard": 0.68, "draft": 0.35,
		"double_ended": true, "entry": 0.35, "end_width": 0.08, "boot_m": 0.10, "lod": 1,
	}
	for bx: float in [-18.5, -10.5, 2.0]:
		for s: float in [-1.0, 1.0]:
			var hz := HullLoft.half(HULL_SPEC, bx) - 0.25
			for dx: float in [-2.5, 2.5]:
				var d0 := Vector3(bx + dx, deck_y + 0.3, hz * s)
				var d1 := Vector3(bx + dx, deck_y + 3.1, hz * s)
				var d2 := Vector3(bx + dx, deck_y + 3.75, (hz - 0.75) * s)
				var d3 := Vector3(bx + dx, deck_y + 3.55, (hz - 1.35) * s)
				HullLoft.tube(lm, "Hull", [d0, d1, d2, d3], 0.075, 6)
	for s: float in [-1.0, 1.0]:
		var by := deck_y + 1.65
		var bz := s * 4.45
		HullLoft.loft(lm, boat_spec, {"hull": "Hull", "boot": "Hull", "bottom": "Hull", "deck": "Sail"},
			Vector3(-10.5, by, bz))

static func _build_gangway_and_mooring(lm: LandmarkMesh) -> void:
	# Starboard (+Z) white steel-and-wood museum boarding staircase to Forum Marinum quay.
	var gx := -7.0
	var deck_y := HullLoft.sheer(HULL_SPEC, gx) + 0.15
	var p0 := Vector3(gx, deck_y, HullLoft.half(HULL_SPEC, gx) - 0.05)
	var p1 := Vector3(gx - 3.6, QUAY_Y + 0.05, QUAY_Z - 0.6)
	lm.beam("Hull", p0, p1, 1.75, 0.20, Vector3.UP)
	lm.beam("Deck", p0 + Vector3(0, 0.10, 0), p1 + Vector3(0, 0.10, 0), 1.55, 0.08, Vector3.UP)
	# Upper & lower white landing platforms.
	lm.box("Hull", p0 + Vector3(0, -0.05, 0.45), Vector3(2.2, 0.18, 1.15))
	lm.box("Hull", p1 + Vector3(0, -0.05, 0.45), Vector3(2.2, 0.18, 1.15))
	var side_dir := (p1 - p0).cross(Vector3.UP).normalized()
	for s: float in [-0.84, 0.84]:
		var off := side_dir * s
		lm.beam("Hull", p0 + off + Vector3(0, 1.05, 0), p1 + off + Vector3(0, 1.05, 0), 0.06, 0.06)
		lm.beam("Hull", p0 + off + Vector3(0, 0.55, 0), p1 + off + Vector3(0, 0.55, 0), 0.04, 0.04)
		for k in 7:
			var q := p0.lerp(p1, float(k) / 6.0) + off
			lm.beam("Hull", q, q + Vector3(0, 1.08, 0), 0.05, 0.05)
	# Four mooring hawsers & cast-iron quay bollards on starboard (+Z) side.
	for leg in [[31.0, 36.5], [15.0, 21.0], [-14.0, -20.0], [-33.0, -39.0]]:
		var hx: float = leg[0]
		var bx: float = leg[1]
		var chock := Vector3(hx, HullLoft.sheer(HULL_SPEC, hx) + 0.95, HullLoft.half(HULL_SPEC, hx) - 0.08)
		var bollard := Vector3(bx, QUAY_Y, QUAY_Z)
		VesselEquipment.line(lm, chock, bollard + Vector3(0, 0.25, 0), 0.45, 0.055)
		lm.lathe("Dark", bollard, PackedVector2Array([
			Vector2(0.24, 0.0), Vector2(0.18, 0.28), Vector2(0.26, 0.48), Vector2(0.0, 0.50)]), 8)

static func _set_night_floods(model: Node3D) -> void:
	# Warm night floodlights from the Forum Marinum quay (+Z starboard) onto hull & masts,
	# plus soft river-side rim illumination so the white topsides & rig glow from both banks.
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(20.0, 6.2, 5.2), Vector3(20.0, 26.0, 0.0), 54.0, 0.90, 44.0, Color(1.0, 0.90, 0.72)],
		[Vector3(-1.0, 6.2, 5.2), Vector3(-1.0, 28.0, 0.0), 54.0, 0.95, 46.0, Color(1.0, 0.90, 0.72)],
		[Vector3(-22.0, 6.2, 5.2), Vector3(-22.0, 24.0, 0.0), 54.0, 0.85, 42.0, Color(1.0, 0.90, 0.72)],
		[Vector3(0.0, 2.5, 16.0), Vector3(0.0, 4.5, 4.0), 70.0, 0.85, 44.0, Color(1.0, 0.88, 0.70)],
		[Vector3(0.0, 3.0, -16.0), Vector3(0.0, 6.0, -3.0), 70.0, 0.55, 44.0, Color(1.0, 0.88, 0.72)],
	])
