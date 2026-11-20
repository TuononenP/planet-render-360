class_name FtSuomenJoutsen
extends RefCounted

## Suomen Joutsen (1902, St-Nazaire, ex-Laënnec / Oldenburg): iconic white
## steel-hulled 3-masted full-rigged museum ship permanently moored at Forum
## Marinum on Aurajoki in true metres (+X bow, y = 0 at waterline, turned by
## registry yaw_deg = -33.9°, base = "water"):
##   - True curved lofted steel clipper hull via HullLoft.loft (84.0 m hull,
##     96.0 m LOA with bowsprit/jibboom, 12.4 m beam, 4.8 m freeboard, 1.8 m
##     underwater hull, 1.15 m red anti-fouling boot-top, gleaming white
##     topsides with painted porthole band & brass-rimmed scuttles).
##   - Solid white bulwarks with teak cap rail, raised forecastle (+X) and
##     poop (-X) decks, sculpted bow figurehead & trailboard scrolls, raked
##     bowsprit & jibboom with dolphin striker, bobstays & furled jibs.
##   - Midship charthouse, bridge wings, deck skylights, cargo hatches, aft
##     wheelhouse, 4 lofted white lifeboats on curved steel davits, and port
##     boarding gangway to Forum Marinum quay.
##   - 3 raked steel masts (Fore +22 m -> 41.5 m, Main 0 m -> 44.0 m, Mizzen
##     -22 m -> 39.5 m) with tops, crosstrees, 5 tapered square-rig yards per
##     mast (15 yards) with furled canvas sails, mizzen spanker gaff/boom,
##     standing shrouds & fore-and-aft stays, and warm mast/hull floodlights.
## Surfaces: 10 merged PBR parts (Hull, Boot, Deck, Mast, Sail, Dark, Brass,
## Glass, WoodDark, Lamp).

const HULL_SPEC := {
	"length": 84.0,
	"beam": 12.4,
	"freeboard": 4.8,
	"draft": 1.8,
	"entry": 0.34,
	"bow_pow": 1.85,
	"stern_w": 0.54,
	"stern_round": 0.85,
	"stern_tail": 0.22,
	"flare": 0.14,
	"bow_rise": 1.45,
	"stern_rise": 0.85,
	"stem_rake": 4.6,
	"stern_rake": 3.4,
	"boot_m": 1.15,
	"lod": 0,
	"ultra": false,
}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	HullLoft.loft(lm, HULL_SPEC, {"hull": "Hull", "boot": "Boot", "bottom": "Boot", "deck": "Deck"})
	_build_bulwarks_and_ports(lm)
	_build_figurehead_and_bowsprit(lm)
	_build_deckhouses_and_boats(lm)
	_build_masts_and_rigging(lm)
	_build_gangway(lm)
	lm.commit(model)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("Hull", LandmarkMaterials.paint("#F3F0E9", 0.45, 0.10))
	lm.use("Boot", LandmarkMaterials.paint("#882620", 0.58, 0.08))
	lm.use("Deck", LandmarkMaterials.pbr("wood", "#9E7B52", 2.4, 0.72))
	lm.use("Mast", LandmarkMaterials.paint("#EAE0CA", 0.48, 0.14))
	lm.use("Sail", LandmarkMaterials.pbr("render", "#EFECE2", 2.0, 0.88))
	lm.use("Dark", LandmarkMaterials.paint("#23272B", 0.50, 0.45))
	lm.use("Brass", LandmarkMaterials.gold())
	lm.use("Glass", LandmarkMaterials.glass("#22303A"))
	lm.use("WoodDark", LandmarkMaterials.pbr("wood", "#5D422C", 2.0, 0.70))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE8BC", 1.5))

static func _side(t: float, drop: float) -> Vector3:
	var pts := HullLoft.section(HULL_SPEC, t)
	var top: Vector3 = pts[0]
	var mid: Vector3 = pts[1]
	var q := top.lerp(mid, drop / maxf(top.y - mid.y, 0.2))
	return Vector3(q.x, q.y, absf(q.z))

static func _build_bulwarks_and_ports(lm: LandmarkMesh) -> void:
	# Solid steel bulwarks following the curved sheer with teak cap rail.
	var bh := 1.15
	var th := 0.18
	var n := 36
	for s: float in [-1.0, 1.0]:
		var ob := PackedVector3Array()
		var ot := PackedVector3Array()
		var ib := PackedVector3Array()
		var it := PackedVector3Array()
		var cap: Array = []
		for i in n + 1:
			var q := _side(lerpf(0.0, 0.985, float(i) / float(n)), 0.0)
			var zi := maxf(q.z - th, 0.05)
			ob.append(Vector3(q.x, q.y, q.z * s))
			ot.append(Vector3(q.x, q.y + bh, q.z * s))
			ib.append(Vector3(q.x, q.y, zi * s))
			it.append(Vector3(q.x, q.y + bh, zi * s))
			cap.append(Vector3(q.x, q.y + bh + 0.05, (q.z + zi) * 0.5 * s))
		lm.grid("Hull", [ob, ot], Vector3(0, 0, s))
		lm.grid("Hull", [ib, it], Vector3(0, 0, -s))
		HullLoft.tube(lm, "WoodDark", cap, 0.11, 6)
		# Brass-rimmed porthole row along white topsides.
		for k in 18:
			var t := lerpf(0.10, 0.86, float(k) / 17.0)
			var p := _side(t, 1.35)
			var normal := Vector3(0, 0, s)
			lm.disc("Brass", Vector3(p.x, p.y, (p.z + 0.05) * s), normal, 0.26, 8)
			lm.disc("Dark", Vector3(p.x, p.y, (p.z + 0.07) * s), normal, 0.18, 8)
	# Stern cabin windows across the rounded/raked transom.
	var stern := _side(0.0, 0.0)
	var sy := stern.y - 0.85
	var sx := HullLoft.transom_x(HULL_SPEC, sy) - 0.06
	for k in 5:
		var sz := lerpf(-stern.z * 0.65, stern.z * 0.65, float(k) / 4.0)
		lm.box("Brass", Vector3(sx, sy, sz), Vector3(0.08, 0.68, 0.58))
		lm.box("Glass", Vector3(sx - 0.03, sy, sz), Vector3(0.06, 0.52, 0.44))

static func _build_figurehead_and_bowsprit(lm: LandmarkMesh) -> void:
	# Clipper bow trailboard gold scroll & white swan figurehead under the bowsprit.
	var stem := _side(0.99, 0.0)
	var bow_tip := Vector3(stem.x + 1.15, stem.y + 0.25, 0.0)
	lm.lathe("Hull", bow_tip - Vector3(0.4, 0.9, 0.0), PackedVector2Array([
		Vector2(0.18, 0.0), Vector2(0.32, 0.55), Vector2(0.24, 1.15), Vector2(0.12, 1.65)]), 8)
	lm.box("Brass", bow_tip + Vector3(0.25, 0.15, 0.0), Vector3(0.9, 0.28, 0.35),
		Basis(Vector3.FORWARD, -0.35))
	for s: float in [-1.0, 1.0]:
		var path: Array = []
		for i in 7:
			var q := _side(lerpf(0.87, 0.985, float(i) / 6.0), 0.75)
			path.append(Vector3(q.x, q.y, (q.z + 0.05) * s))
		HullLoft.tube(lm, "Brass", path, 0.06, 5)
	# Long raked steel bowsprit & jibboom extending +X to x = 55.5 m (96 m LOA).
	var heel := Vector3(stem.x - 4.5, stem.y + 0.25, 0.0)
	var cap := Vector3(stem.x + 7.2, stem.y + 2.9, 0.0)
	var tip := Vector3(stem.x + 14.5, stem.y + 4.8, 0.0)
	HullLoft.tube(lm, "Mast", [heel, cap], 0.34, 10)
	HullLoft.tube(lm, "Mast", [cap - Vector3(1.2, 0.3, 0.0), tip], 0.19, 8)
	# Furled headsails along bowsprit/jibboom, dolphin striker & bobstays.
	HullLoft.tube(lm, "Sail", [stem + Vector3(0.8, 1.2, 0.0), cap + Vector3(0.0, 0.55, 0.0),
		tip - Vector3(0.8, -0.25, 0.0)], 0.24, 8)
	var striker := cap + Vector3(-0.2, -2.6, 0.0)
	HullLoft.tube(lm, "Dark", [cap, striker], 0.08, 6)
	HullLoft.tube(lm, "Dark", [tip, striker, Vector3(stem.x - 1.2, 1.3, 0.0)], 0.045, 4)
	HullLoft.tube(lm, "Dark", [cap, Vector3(stem.x - 0.8, 1.5, 0.0)], 0.055, 4)

static func _build_deckhouses_and_boats(lm: LandmarkMesh) -> void:
	var deck_y := 4.85
	# Raised forecastle (+X) and poop deck (-X) break bulkheads with teak decks.
	LandmarkFrKit.rect(lm, "Hull", 26.5, 36.0, -4.4, 4.4, deck_y, deck_y + 1.35)
	LandmarkFrKit.rect(lm, "Deck", 26.5, 36.0, -4.3, 4.3, deck_y + 1.35, deck_y + 1.48)
	LandmarkFrKit.rect(lm, "Hull", -38.5, -24.0, -4.8, 4.8, deck_y, deck_y + 1.5)
	LandmarkFrKit.rect(lm, "Deck", -38.5, -24.0, -4.7, 4.7, deck_y + 1.5, deck_y + 1.63)
	# Midship charthouse & navigating bridge with cantilevered bridge wings.
	LandmarkFrKit.rect(lm, "Hull", -7.5, 6.5, -3.7, 3.7, deck_y, deck_y + 2.55)
	LandmarkFrKit.rect(lm, "WoodDark", -7.7, 6.7, -3.9, 3.9, deck_y + 2.55, deck_y + 2.75)
	# Glazed charthouse wheelhouse on top + open bridge wings out to beam edge.
	LandmarkFrKit.rect(lm, "Hull", -2.5, 4.5, -2.5, 2.5, deck_y + 2.75, deck_y + 4.95)
	LandmarkFrKit.rect(lm, "WoodDark", -2.7, 4.7, -2.7, 2.7, deck_y + 4.95, deck_y + 5.15)
	LandmarkFrKit.rect(lm, "Glass", 4.42, 4.58, -2.1, 2.1, deck_y + 3.65, deck_y + 4.65)
	for sz: float in [-1.0, 1.0]:
		LandmarkFrKit.rect(lm, "Glass", -2.0, 4.0, sz * 2.48 - 0.06, sz * 2.48 + 0.06, deck_y + 3.65, deck_y + 4.65)
		LandmarkFrKit.rect(lm, "Hull", 0.5, 3.2, sz * 2.5, sz * 5.8, deck_y + 2.75, deck_y + 3.85)
		LandmarkFrKit.rect(lm, "WoodDark", 0.4, 3.3, sz * 2.5, sz * 5.9, deck_y + 3.85, deck_y + 3.96)
	# Warm bridge glow & aft deckhouse skylight.
	LandmarkFrKit.rect(lm, "Lamp", -1.5, 3.5, -1.5, 1.5, deck_y + 3.75, deck_y + 4.55)
	LandmarkFrKit.rect(lm, "WoodDark", -33.0, -27.5, -2.1, 2.1, deck_y + 1.63, deck_y + 2.35)
	LandmarkFrKit.rect(lm, "Glass", -32.6, -27.9, -1.7, 1.7, deck_y + 2.35, deck_y + 2.65)
	# Cargo hatches forward and aft of midships.
	for hx: float in [13.5, -14.5]:
		LandmarkFrKit.rect(lm, "WoodDark", hx - 2.6, hx + 2.6, -2.2, 2.2, deck_y, deck_y + 0.65)
		LandmarkFrKit.rect(lm, "Sail", hx - 2.4, hx + 2.4, -2.0, 2.0, deck_y + 0.65, deck_y + 0.78)
	# Four lofted white clinker lifeboats suspended on curved steel davits (2 port, 2 starboard).
	var boat_spec := {
		"length": 6.4, "beam": 2.1, "freeboard": 0.65, "draft": 0.35,
		"double_ended": true, "entry": 0.35, "end_width": 0.08, "boot_m": 0.12, "lod": 1,
	}
	for bx: float in [-11.5, 9.5]:
		for s: float in [-1.0, 1.0]:
			var bz := s * 4.95
			var by := deck_y + 2.35
			HullLoft.loft(lm, boat_spec, {"hull": "Hull", "boot": "Hull", "bottom": "Hull", "deck": "Sail"},
				Vector3(bx, by, bz))
			for dx: float in [-2.6, 2.6]:
				var dbase := Vector3(bx + dx, deck_y + 0.2, s * 5.65)
				var dmid := Vector3(bx + dx, by + 1.15, s * 5.65)
				var dtip := Vector3(bx + dx, by + 1.35, bz)
				HullLoft.tube(lm, "Hull", [dbase, dmid, dtip], 0.075, 6)
				HullLoft.tube(lm, "Dark", [dtip, Vector3(bx + dx, by + 0.45, bz)], 0.025, 4)

static func _build_masts_and_rigging(lm: LandmarkMesh) -> void:
	# Three raked steel masts (Fore +22 -> 41.5 m, Main 0 -> 44.0 m, Mizzen -22 -> 39.5 m).
	var deck_y := 4.85
	var specs := [
		[22.0, 41.5, 0.92],
		[0.0, 44.0, 1.00],
		[-22.0, 39.5, 0.85],
	]
	var tops: Array = []
	var crosses: Array = []
	var trucks: Array = []
	var rake := -0.045 # slight aft rake characteristic of clippers
	for mi in specs.size():
		var mx: float = specs[mi][0]
		var mh: float = specs[mi][1]
		var sc: float = specs[mi][2]
		var span_h := mh - deck_y
		var y_top := deck_y + span_h * 0.40
		var y_cross := deck_y + span_h * 0.70
		var p_base := Vector3(mx, deck_y, 0.0)
		var p_top := Vector3(mx + (y_top - deck_y) * rake, y_top, 0.0)
		var p_cross := Vector3(mx + (y_cross - deck_y) * rake, y_cross, 0.0)
		var p_truck := Vector3(mx + span_h * rake, mh - 0.25, 0.0)
		# Stepped steel mast sections: lower mast (white), topmast, topgallant/royal (buff).
		HullLoft.tube(lm, "Hull", [p_base, p_top + Vector3(0, 0.8, 0)], 0.42 * sc, 10)
		HullLoft.tube(lm, "Mast", [p_top - Vector3(0, 0.6, 0), p_cross + Vector3(0, 0.6, 0)], 0.29 * sc, 8)
		HullLoft.tube(lm, "Mast", [p_cross - Vector3(0, 0.4, 0), p_truck], 0.16 * sc, 8)
		# Gilded truck ball & masthead warm beacon.
		lm.lathe("Brass", p_truck, LandmarkFrKit.ball(0.22), 8)
		lm.lathe("Lamp", p_top + Vector3(0.45, 0.25, 0.0), LandmarkFrKit.ball(0.18), 6)
		# Fighting top platform & crosstrees.
		lm.box("WoodDark", p_top, Vector3(2.4 * sc, 0.18, 4.4 * sc))
		lm.beam("WoodDark", p_cross - Vector3(0, 0, 2.2 * sc), p_cross + Vector3(0, 0, 2.2 * sc), 0.12, 0.14)
		# Five tapered square-rig yards per mast with furled canvas sails & lifts.
		var y_fracs := [0.36, 0.50, 0.64, 0.78, 0.90]
		var y_widths := [21.5, 18.6, 15.8, 12.6, 9.2]
		for k in 5:
			var yf: float = y_fracs[k]
			var yy := deck_y + span_h * yf
			var yx := mx + (yy - deck_y) * rake + 0.42
			var hw: float = y_widths[k] * sc * 0.5
			var yr := lerpf(0.20, 0.09, float(k) / 4.0)
			var ctr := Vector3(yx, yy, 0.0)
			HullLoft.tube(lm, "Mast", [ctr - Vector3(0, 0, hw), ctr + Vector3(0, 0, hw)], yr * 0.65, 6)
			HullLoft.tube(lm, "Mast", [ctr - Vector3(0, 0, hw * 0.5), ctr + Vector3(0, 0, hw * 0.5)], yr, 8)
			HullLoft.tube(lm, "Sail", [ctr + Vector3(0.1, yr + 0.12, -hw * 0.88),
				ctr + Vector3(0.14, yr + 0.22, 0.0),
				ctr + Vector3(0.1, yr + 0.12, hw * 0.88)], yr * 1.15, 6)
			var lift_top := Vector3(mx + (yy + 3.4 - deck_y) * rake, minf(yy + 3.4, mh - 0.4), 0.0)
			for s: float in [-1.0, 1.0]:
				HullLoft.tube(lm, "Dark", [ctr + Vector3(0, 0, hw * 0.95 * s), lift_top], 0.025, 4)
		# Standing shrouds from hull sheer to fighting top & crosstrees.
		for s: float in [-1.0, 1.0]:
			var hz := HullLoft.half(HULL_SPEC, mx)
			for j in 4:
				var sx := mx - 2.4 + float(j) * 1.4
				var ch := Vector3(sx, HullLoft.sheer(HULL_SPEC, sx) + 0.85, (hz + 0.15) * s)
				HullLoft.tube(lm, "Dark", [ch, p_top + Vector3(0, -0.2, 0.4 * s)], 0.035, 4)
			HullLoft.tube(lm, "Dark", [p_top + Vector3(0, 0.05, 1.9 * sc * s), p_cross + Vector3(0, -0.1, 0.25 * s)], 0.03, 4)
			HullLoft.tube(lm, "Dark", [p_cross + Vector3(0, 0.05, 1.8 * sc * s), p_truck + Vector3(0, -0.8, 0.1 * s)], 0.025, 4)
			# Backstays sweeping aft to hull quarters.
			var bq := Vector3(mx - 7.5, HullLoft.sheer(HULL_SPEC, mx - 7.5) + 0.9, (HullLoft.half(HULL_SPEC, mx - 7.5) + 0.1) * s)
			HullLoft.tube(lm, "Dark", [bq, p_cross], 0.03, 4)
			HullLoft.tube(lm, "Dark", [bq + Vector3(-1.5, 0, 0), p_truck - Vector3(0, 0.6, 0)], 0.025, 4)
		tops.append(p_top)
		crosses.append(p_cross)
		trucks.append(p_truck)
	# Mizzen spanker boom & gaff extending aft over the poop deck.
	var miz_x := -22.0
	HullLoft.tube(lm, "Mast", [Vector3(miz_x - 0.4, deck_y + 3.2, 0.0), Vector3(-39.5, deck_y + 4.1, 0.0)], 0.16, 8)
	HullLoft.tube(lm, "Sail", [Vector3(miz_x - 1.0, deck_y + 3.55, 0.0), Vector3(-38.5, deck_y + 4.45, 0.0)], 0.22, 6)
	HullLoft.tube(lm, "Mast", [Vector3(miz_x - 0.4, deck_y + 13.8, 0.0), Vector3(-35.5, deck_y + 18.2, 0.0)], 0.13, 8)
	# Fore-and-aft standing stays linking bowsprit, fore, main, and mizzen masts.
	var stem := _side(0.99, 0.0)
	var b_cap := Vector3(stem.x + 7.2, stem.y + 2.9, 0.0)
	var b_tip := Vector3(stem.x + 14.5, stem.y + 4.8, 0.0)
	HullLoft.tube(lm, "Dark", [tops[0], Vector3(stem.x - 1.5, stem.y + 1.0, 0.0)], 0.04, 4)
	HullLoft.tube(lm, "Dark", [crosses[0], b_cap], 0.035, 4)
	HullLoft.tube(lm, "Dark", [trucks[0], b_tip], 0.03, 4)
	for i in 2:
		HullLoft.tube(lm, "Dark", [tops[i + 1], Vector3(specs[i][0], deck_y + 1.2, 0.0)], 0.04, 4)
		HullLoft.tube(lm, "Dark", [crosses[i + 1], tops[i]], 0.035, 4)
		HullLoft.tube(lm, "Dark", [trucks[i + 1], crosses[i]], 0.03, 4)

static func _build_gangway(lm: LandmarkMesh) -> void:
	# Museum visitor boarding gangway from port side (-Z) toward Forum Marinum quay.
	var deck_y := 4.85
	var p0 := Vector3(-6.0, deck_y + 0.1, -6.1)
	var p1 := Vector3(-6.0, 1.9, -12.8)
	lm.beam("Deck", p0, p1, 0.18, 1.9, Vector3.UP)
	for dx: float in [-0.92, 0.92]:
		lm.beam("Hull", p0 + Vector3(dx, 1.05, 0.0), p1 + Vector3(dx, 1.05, 0.0), 0.07, 0.07)
		for k in 5:
			var t := float(k) / 4.0
			var q := p0.lerp(p1, t) + Vector3(dx, 0.0, 0.0)
			lm.beam("Hull", q, q + Vector3(0, 1.08, 0), 0.06, 0.06)

static func _set_night_floods(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(22.0, 6.2, -5.0), Vector3(22.0, 26.0, 0.0), 50.0, 0.85, 44.0, Color(1.0, 0.90, 0.72)],
		[Vector3(0.0, 6.2, -5.0), Vector3(0.0, 28.0, 0.0), 50.0, 0.90, 46.0, Color(1.0, 0.90, 0.72)],
		[Vector3(-22.0, 6.2, -5.0), Vector3(-22.0, 25.0, 0.0), 50.0, 0.80, 42.0, Color(1.0, 0.90, 0.72)],
		[Vector3(0.0, 2.5, -16.0), Vector3(0.0, 4.5, -4.0), 68.0, 0.75, 42.0, Color(1.0, 0.88, 0.70)],
	])
