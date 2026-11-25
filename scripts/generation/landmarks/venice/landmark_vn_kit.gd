class_name LandmarkVnKit
extends RefCounted

## Shared Venetian architectural building kit for `LandmarkSetVenice`:
## - Authentic PBR material helpers (weathered Istrian limestone, sun-washed
##   Venetian lime-stucco, terracotta brick, Verona pink marble, patinated lead
##   and copper domes, Murano mosaic gold, wet canal algae plinths).
## - Venetian Gothic *polifore* / *quadrifore* arcaded window bands with
##   slender colonnettes, pointed arches, quatrefoil tracery and projecting
##   Istrian-stone balconies (*poggioli*).
## - Palladian / Renaissance temple fronts & colonnades.
## - Venetian brick campanile builder (tapered shaft, *lesene*, arched Istrian
##   belfry with bronze bells, octagonal drum or copper/terracotta spire).
## - Ribbed Venetian lead/copper domes, bell-topped chimneys (*camini a
##   campana*), wooden *altane*, and Grand Canal *paline* mooring poles.

static func istrian(hex: String = "#ECE7DA", tile_m: float = 2.8) -> StandardMaterial3D:
	return LandmarkMaterials.pbr("limestone", hex, tile_m)

static func istrian_trim(hex: String = "#F4F0E6", tile_m: float = 2.2) -> StandardMaterial3D:
	return LandmarkMaterials.pbr("limestone", hex, tile_m)

static func brick(hex: String = "#AD533D", tile_m: float = 2.6) -> StandardMaterial3D:
	return LandmarkMaterials.pbr("brick", hex, tile_m)

static func stucco(hex: String = "#DFB595", tile_m: float = 3.2) -> StandardMaterial3D:
	return LandmarkMaterials.pbr("render", hex, tile_m)

static func verona_rose(hex: String = "#D9B0A0", tile_m: float = 2.5) -> StandardMaterial3D:
	return LandmarkMaterials.pbr("limestone", hex, tile_m)

static func terracotta(hex: String = "#9B5F49", tile_m: float = 2.4) -> StandardMaterial3D:
	return LandmarkMaterials.pbr("terracotta", hex, tile_m)

static func lead_dome(hex: String = "#8E9499", tile_m: float = 2.2) -> StandardMaterial3D:
	return LandmarkMaterials.pbr("slate", hex, tile_m, 0.42, 0.38)

static func copper_patina(hex: String = "#5E907C", tile_m: float = 2.2) -> StandardMaterial3D:
	return LandmarkMaterials.pbr("slate", hex, tile_m, 0.44, 0.48)

static func algae_plinth(hex: String = "#465242", tile_m: float = 2.0) -> StandardMaterial3D:
	return LandmarkMaterials.pbr("stone", hex, tile_m, 0.85, 0.04)

static func shadow_glass(hex: String = "#272F35") -> StandardMaterial3D:
	return LandmarkMaterials.glass(hex)

static func dark_wood(hex: String = "#5C402C", tile_m: float = 2.0) -> StandardMaterial3D:
	return LandmarkMaterials.pbr("wood", hex, tile_m)

static func warm_lamp(hex: String = "#FFE1A4", energy: float = 2.0) -> StandardMaterial3D:
	return LandmarkMaterials.lit(hex, energy)

## Raised ribbed dome profile (radius, y) closed at apex.
static func dome_profile(r: float, h: float, onion: bool = false) -> PackedVector2Array:
	var pr := PackedVector2Array()
	for k in 13:
		var t := float(k) / 12.0
		var a := PI * 0.5 * t
		var rad := cos(a) * r
		if onion:
			rad *= (1.0 + 0.14 * sin(PI * t) - 0.12 * t * t)
		pr.append(Vector2(maxf(rad, 0.0), sin(a) * h))
	pr[pr.size() - 1] = Vector2(0.0, h)
	return pr

## Ribbed Venetian dome on cylindrical or octagonal drum with colonnaded lantern and finial.
static func venetian_dome(lm: LandmarkMesh, stone_mat: String, trim_mat: String, dome_mat: String,
		glass_mat: String, gold_mat: String, c: Vector3, drum_r: float, drum_h: float,
		dome_h: float, lantern_h: float, finial_h: float, onion: bool = false) -> void:
	lm.frustum(stone_mat, c, drum_r, drum_r, drum_h, 24)
	lm.frustum(trim_mat, c, drum_r + 0.3, drum_r + 0.25, 0.6, 24)
	lm.frustum(trim_mat, c + Vector3(0, drum_h - 0.5, 0), drum_r + 0.45, drum_r + 0.5, 0.55, 24)
	var nw := 12 if drum_r >= 5.5 else 8
	for k in nw:
		var a := TAU * (float(k) + 0.5) / float(nw)
		var dir := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.window(lm, trim_mat, glass_mat, c + dir * drum_r + Vector3(0, drum_h * 0.5, 0),
			dir, minf(1.5, drum_r * 0.22), minf(3.6, drum_h * 0.58), true, 0.16)
	var dy := c.y + drum_h
	var pts := dome_profile(drum_r * 1.02, dome_h, onion)
	lm.lathe(dome_mat, Vector3(c.x, dy, c.z), pts, 28)
	# Raised lead/copper ribs
	var ribs := 12 if drum_r >= 5.5 else 8
	for k in ribs:
		var a := TAU * float(k) / float(ribs)
		for j in range(0, pts.size() - 2, 2):
			var p0 := Vector3(c.x + cos(a) * pts[j].x, dy + pts[j].y, c.z + sin(a) * pts[j].x)
			var p1 := Vector3(c.x + cos(a) * pts[j + 2].x, dy + pts[j + 2].y, c.z + sin(a) * pts[j + 2].x)
			lm.beam(dome_mat, p0, p1, 0.24, 0.20)
	if lantern_h > 0.5:
		var ly := dy + dome_h - 0.2
		var lr := maxf(drum_r * 0.24, 1.1)
		lm.frustum(trim_mat, Vector3(c.x, ly, c.z), lr * 1.15, lr * 1.1, 0.4, 12)
		lm.frustum(glass_mat, Vector3(c.x, ly + 0.4, c.z), lr * 0.65, lr * 0.65, lantern_h * 0.55, 8)
		for k in 6:
			var a := TAU * float(k) / 6.0
			lm.frustum(trim_mat, Vector3(c.x + cos(a) * lr * 0.9, ly + 0.4, c.z + sin(a) * lr * 0.9),
				0.14, 0.12, lantern_h * 0.55, 6)
		var cap_y := ly + 0.4 + lantern_h * 0.55
		lm.frustum(trim_mat, Vector3(c.x, cap_y, c.z), lr * 1.15, lr * 1.15, 0.35, 12)
		lm.lathe(dome_mat, Vector3(c.x, cap_y + 0.35, c.z), dome_profile(lr * 0.95, lantern_h * 0.42), 12)
		if finial_h > 0.2:
			lm.frustum(gold_mat, Vector3(c.x, cap_y + 0.35 + lantern_h * 0.42, c.z), 0.22, 0.06, finial_h, 6)

## Venetian Gothic polifora (multi-bay arcade of slender colonnettes + pointed arches + quatrefoils + balcony)
## centred at `c` on a facade facing `out` (local +Z when basis is identity).
static func polifora(lm: LandmarkMesh, trim_mat: String, glass_mat: String, c: Vector3,
		rt: Vector3, out: Vector3, bays: int, bay_w: float, h: float, balcony: bool = true) -> void:
	var basis := Basis(rt, Vector3.UP, out)
	var total_w := float(bays) * bay_w
	# Dark recessed glazing behind the marble arcade
	lm.box(glass_mat, c + Vector3(0, h * 0.48, 0) + out * 0.04, Vector3(total_w - 0.2, h * 0.92, 0.14), basis)
	# Frame surround (jambs, sill, upper lintel)
	lm.box(trim_mat, c + Vector3(0, -0.14, 0) + out * 0.24, Vector3(total_w + 0.7, 0.28, 0.48), basis)
	lm.box(trim_mat, c + Vector3(0, h + 0.16, 0) + out * 0.22, Vector3(total_w + 0.7, 0.32, 0.42), basis)
	var col_h := h * 0.64
	for i in bays + 1:
		var x := -total_w * 0.5 + float(i) * bay_w
		var p := c + rt * x + out * 0.22
		if i == 0 or i == bays:
			lm.box(trim_mat, p + Vector3(0, h * 0.5, 0), Vector3(0.32, h, 0.38), basis)
		else:
			lm.frustum(trim_mat, p, 0.12, 0.10, col_h, 8)
			lm.box(trim_mat, p + Vector3(0, col_h + 0.12, 0), Vector3(0.34, 0.24, 0.34), basis)
	# Pointed Gothic arches and pierced quatrefoil spandrels
	for i in bays:
		var x0 := -total_w * 0.5 + float(i) * bay_w
		var xm := x0 + bay_w * 0.5
		var p_l := c + rt * (x0 + 0.08) + Vector3(0, col_h + 0.15, 0) + out * 0.24
		var p_r := c + rt * (x0 + bay_w - 0.08) + Vector3(0, col_h + 0.15, 0) + out * 0.24
		var p_top := c + rt * xm + Vector3(0, h - 0.28, 0) + out * 0.24
		lm.beam(trim_mat, p_l, p_top, 0.18, 0.22, out)
		lm.beam(trim_mat, p_r, p_top, 0.18, 0.22, out)
		if i < bays - 1:
			var q := c + rt * (x0 + bay_w) + Vector3(0, h - 0.46, 0) + out * 0.22
			lm.disc(trim_mat, q, out, minf(0.28, bay_w * 0.22), 8)
	if balcony:
		var bd := 0.95
		lm.box(trim_mat, c + Vector3(0, -0.22, 0) + out * (bd * 0.5), Vector3(total_w + 0.9, 0.24, bd), basis)
		LandmarkDetail.balustrade(lm, trim_mat,
			c - rt * (total_w * 0.5 + 0.35) + out * (bd - 0.10),
			c + rt * (total_w * 0.5 + 0.35) + out * (bd - 0.10), 0.92, maxf(1.5, total_w * 0.5))

## Palladian / Renaissance interlocking temple facade centred at `c` facing `out` (local +Z).
static func palladian_front(lm: LandmarkMesh, stone_mat: String, trim_mat: String, glass_mat: String,
		c: Vector3, rt: Vector3, out: Vector3, total_w: float, main_w: float,
		main_h: float, side_h: float, ped_h: float, cols: int = 4) -> void:
	var basis := Basis(rt, Vector3.UP, out)
	# Side wings + half-pediments
	var wing_w := (total_w - main_w) * 0.5
	if wing_w > 1.0:
		for s: float in [-1.0, 1.0]:
			var wc := c + rt * (s * (main_w * 0.5 + wing_w * 0.5))
			lm.box(stone_mat, wc + Vector3(0, side_h * 0.5, 0) - out * 0.6, Vector3(wing_w, side_h, 1.4), basis)
			# Half-pediment raking beam
			var p_in := c + rt * (s * main_w * 0.5) + Vector3(0, side_h + ped_h * 0.68, 0) + out * 0.15
			var p_out := c + rt * (s * total_w * 0.5) + Vector3(0, side_h, 0) + out * 0.15
			lm.beam(trim_mat, p_in, p_out, 0.55, 0.6, out)
			# Niche on each wing
			LandmarkDetail.window(lm, trim_mat, glass_mat, wc + Vector3(0, side_h * 0.45, 0) + out * 0.12,
				out, minf(2.0, wing_w * 0.35), minf(4.6, side_h * 0.35), true, 0.18)
	# Main central temple front with giant columns on plinths
	lm.box(stone_mat, c + Vector3(0, main_h * 0.5, 0) - out * 0.5, Vector3(main_w, main_h, 1.6), basis)
	var pl_h := maxf(2.4, main_h * 0.16)
	var ent_y := main_h - 1.8
	for i in cols:
		var t := float(i) / float(maxi(cols - 1, 1)) - 0.5
		var x := t * (main_w - 2.2)
		var cp := c + rt * x + out * 0.75
		lm.box(trim_mat, cp + Vector3(0, pl_h * 0.5, 0), Vector3(1.5, pl_h, 1.5), basis)
		LandmarkDetail.column(lm, trim_mat, cp + Vector3(0, pl_h, 0), 0.58, ent_y - pl_h, "corinthian", 10)
	# Central portal
	LandmarkDetail.window(lm, trim_mat, glass_mat, c + Vector3(0, 4.4, 0) + out * 0.35, out, 3.6, 7.6, true, 0.25)
	# Entablature + main triangular pediment + apex statue
	lm.box(trim_mat, c + Vector3(0, ent_y + 0.9, 0) + out * 0.55, Vector3(main_w + 1.2, 1.8, 1.8), basis)
	lm.gable(trim_mat, c + Vector3(0, main_h, 0) + out * 0.45, main_w + 1.2, 1.6, ped_h, basis, 0.25, stone_mat)
	LandmarkKits.statue_figure(lm, trim_mat, c + Vector3(0, main_h + ped_h, 0) + out * 0.55, 2.4, true)
	for s in [-1.0, 1.0]:
		LandmarkKits.statue_figure(lm, trim_mat, c + rt * (s * main_w * 0.5) + Vector3(0, main_h, 0) + out * 0.55, 2.0)

## Venetian red-brick square campanile with shallow lesene, arched Istrian belfry,
## optional octagonal drum and conical/pyramidal spire (`tilt_x` supports leaning towers
## such as Santo Stefano and San Pietro di Castello).
static func campanile(lm: LandmarkMesh, shaft_mat: String, trim_mat: String, roof_mat: String,
		shadow_mat: String, gold_mat: String, base: Vector3, width: float, total_h: float,
		tilt_x: float = 0.0, octagonal_drum: bool = false) -> void:
	var shaft_h := total_h * 0.62
	var belfry_h := total_h * 0.12
	var drum_h := total_h * 0.08 if octagonal_drum else 0.0
	var spire_h := total_h - shaft_h - belfry_h - drum_h - 1.6
	var lean_b := Basis()
	if absf(tilt_x) > 0.001:
		lean_b = Basis(Vector3.BACK, atan2(tilt_x, shaft_h))
	var top_off := Vector3(tilt_x, 0, 0)
	# Stone plinth + tapered brick shaft with corner lesene
	lm.box(trim_mat, base + Vector3(0, 1.0, 0), Vector3(width + 0.8, 2.0, width + 0.8))
	lm.box(shaft_mat, base + top_off * 0.5 + Vector3(0, 2.0 + (shaft_h - 2.0) * 0.5, 0),
		Vector3(width, shaft_h - 2.0, width), lean_b)
	for k in 4:
		var r := lean_b * Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var rt := r * Vector3(1, 0, 0)
		for s in [-0.42, 0.0, 0.42]:
			lm.box(shaft_mat, base + top_off * 0.5 + Vector3(0, 2.0 + (shaft_h - 2.0) * 0.5, 0)
				+ out * (width * 0.5 + 0.08) + rt * (width * float(s)),
				Vector3(width * 0.13, shaft_h - 2.5, 0.28), r)
	# Belfry cell in white Istrian stone
	var by := base.y + shaft_h
	var bc := Vector3(base.x + tilt_x, by, base.z)
	lm.box(trim_mat, bc + Vector3(0, 0.45, 0), Vector3(width + 0.9, 0.9, width + 0.9))
	lm.box(shadow_mat, bc + Vector3(0, 0.9 + belfry_h * 0.5, 0), Vector3(width * 0.72, belfry_h, width * 0.72))
	var bw := width * 0.48
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box(trim_mat, bc + Vector3(sx * bw, 0.9 + belfry_h * 0.5, sz * bw),
				Vector3(width * 0.22, belfry_h, width * 0.22))
	# Central belfry colonnettes on all four faces
	for k in 4:
		var a := PI * 0.5 * float(k)
		var d := Vector3(cos(a), 0, sin(a))
		lm.frustum(trim_mat, bc + d * (width * 0.46) + Vector3(0, 0.9, 0), 0.22, 0.20, belfry_h, 8)
	var cy := by + 0.9 + belfry_h
	lm.box(trim_mat, Vector3(bc.x, cy + 0.35, bc.z), Vector3(width + 1.0, 0.7, width + 1.0))
	var py := cy + 0.7
	if octagonal_drum:
		lm.frustum(trim_mat, Vector3(bc.x, py, bc.z), width * 0.44, width * 0.42, drum_h, 8, PI / 8.0)
		py += drum_h
	lm.spire(roof_mat, Vector3(bc.x, py, bc.z), width * 0.44, maxf(spire_h, 3.0), 0.10, 8 if octagonal_drum else 4)
	lm.frustum(gold_mat, Vector3(bc.x, py + maxf(spire_h, 3.0), bc.z), 0.26, 0.08, 1.6, 6)

## Venetian funnel / bell-shaped chimney pot (*camino a campana*) on a roof at `p`.
static func bell_chimney(lm: LandmarkMesh, mat: String, p: Vector3, h: float = 2.4,
		stem_down: float = 0.0) -> void:
	var shaft_h := h * 0.76 + stem_down
	lm.box(mat, p + Vector3(0, h * 0.76 - shaft_h * 0.5, 0), Vector3(0.55, shaft_h, 0.55))
	lm.frustum(mat, p + Vector3(0, h * 0.76, 0), 0.30, 0.58, h * 0.24, 8)

## Venetian spiral-striped mooring pole (*palina*) standing out of the water at `p`.
static func palina(lm: LandmarkMesh, pole_mat: String, stripe_mat: String, p: Vector3, h: float = 3.4) -> void:
	lm.frustum(pole_mat, p + Vector3(0, -0.4, 0), 0.14, 0.12, h + 0.4, 8)
	lm.frustum(stripe_mat, p + Vector3(0, h * 0.45, 0), 0.145, 0.138, h * 0.24, 8)
	lm.frustum(stripe_mat, p + Vector3(0, h - 0.15, 0), 0.15, 0.04, 0.26, 8)

## Generic Venetian palazzo facade block with rusticated water-gate plinth,
## wet algae waterline, ground porta d'acqua, piano nobile polifora, flanking
## windows and hipped terracotta roof with bell chimneys.
static func palazzo_block(lm: LandmarkMesh, wall_mat: String, stone_mat: String, roof_mat: String,
		glass_mat: String, algae_mat: String, c: Vector3, w: float, d: float, h: float,
		polifora_bays: int = 5, stories: int = 4, roof_rise: float = 2.6) -> void:
	var eave := h - roof_rise
	lm.box(algae_mat, c + Vector3(0, 0.20, 0), Vector3(w + 0.18, 0.55, d + 0.18))
	lm.box(stone_mat, c + Vector3(0, 1.9, 0), Vector3(w + 0.12, 3.0, d + 0.12))
	lm.box(wall_mat, c + Vector3(0, 3.4 + (eave - 3.4) * 0.5, 0), Vector3(w, eave - 3.4, d))
	# Horizontal string courses & top cornice
	for s in range(1, stories):
		var sy := eave * float(s) / float(stories)
		lm.box(stone_mat, c + Vector3(0, sy, 0), Vector3(w + 0.36, 0.34, d + 0.36))
	LandmarkDetail.cornice(lm, stone_mat, c + Vector3(-w * 0.52, eave - 0.2, d * 0.5),
		c + Vector3(w * 0.52, eave - 0.2, d * 0.5), Vector3(0, 0, 1), 0.65, true)
	# Ground floor arched porta d'acqua (+Z)
	LandmarkDetail.window(lm, stone_mat, glass_mat, c + Vector3(0, 2.0, d * 0.5 + 0.06),
		Vector3(0, 0, 1), minf(3.0, w * 0.16), 3.6, true, 0.22)
	# Piano nobile polifore on upper stories (+Z front)
	var floor_h := eave / float(stories)
	for s in range(1, stories):
		var wy := floor_h * float(s) + 0.45
		var wh := minf(floor_h - 1.1, 3.6)
		var bay_w := minf(1.85, (w * 0.46) / float(maxi(polifora_bays, 1)))
		polifora(lm, stone_mat, glass_mat, c + Vector3(0, wy, d * 0.5), Vector3.RIGHT, Vector3(0, 0, 1),
			polifora_bays, bay_w, wh, s == 1 or s == 2)
		# Flanking side windows on both wings
		var half_poly := float(polifora_bays) * bay_w * 0.5
		var wing_avail := w * 0.5 - half_poly - 1.2
		if wing_avail > 1.6:
			var n_side := maxi(1, int(wing_avail / 3.4))
			for side: float in [-1.0, 1.0]:
				for j in n_side:
					var wx := side * (half_poly + 1.4 + (float(j) + 0.5) * (wing_avail / float(n_side)))
					LandmarkDetail.window(lm, stone_mat, glass_mat,
						c + Vector3(wx, wy + wh * 0.5, d * 0.5 + 0.04), Vector3(0, 0, 1), 1.35, wh * 0.86, true, 0.16)
	# Hipped terracotta roof + bell chimneys
	# Add arched Venetian windows on side (-X / +X) and rear (-Z) facades so oblique canal & aerial views never show blank flanks
	var n_flank := clampi(int((d - 3.0) / 4.2), 2, 7)
	var n_rear := clampi(int((w - 3.0) / 4.4), 2, 7)
	for s in range(1, stories):
		var wy_f := floor_h * float(s) + 0.45
		var wh_f := minf(floor_h - 1.1, 3.4)
		for sx_f: float in [-1.0, 1.0]:
			for j in n_flank:
				var wz := lerpf(-d * 0.5 + 2.4, d * 0.5 - 2.4, float(j) / float(maxi(n_flank - 1, 1)))
				LandmarkDetail.window(lm, stone_mat, glass_mat,
					c + Vector3(sx_f * (w * 0.5 + 0.04), wy_f + wh_f * 0.5, wz), Vector3(sx_f, 0, 0), 1.35, wh_f * 0.84, true, 0.14)
		for j in n_rear:
			var wx_r := lerpf(-w * 0.5 + 2.4, w * 0.5 - 2.4, float(j) / float(maxi(n_rear - 1, 1)))
			LandmarkDetail.window(lm, stone_mat, glass_mat,
				c + Vector3(wx_r, wy_f + wh_f * 0.5, -d * 0.5 - 0.04), Vector3(0, 0, -1), 1.35, wh_f * 0.84, true, 0.14)
	var rot_r := Basis(Vector3.UP, PI * 0.5) if w > d else Basis()
	lm.gable(roof_mat, c + Vector3(0, eave, 0), minf(w, d) + 0.6, maxf(w, d) + 0.6, roof_rise, rot_r, 0.35, wall_mat)
	for sx in [-0.34, 0.34]:
		bell_chimney(lm, wall_mat, c + Vector3(sx * w, eave + roof_rise * 0.52, -d * 0.15), 2.1, roof_rise * 0.52)

## Warm architectural night floodlights along +Z front (and optional crown).
static func set_warm_floods(model: Node3D, width: float, depth: float, height: float,
		energy: float = 0.85, both_sides: bool = false) -> void:
	var spots: Array = []
	var n := clampi(int(ceil(width / 24.0)), 2, 5)
	for i in n:
		var x := lerpf(-width * 0.42, width * 0.42, float(i) / float(maxi(n - 1, 1)))
		spots.append([Vector3(x, 1.4, depth * 0.5 + 7.0), Vector3(x, height * 0.52, depth * 0.5), 48.0, energy])
		if both_sides:
			spots.append([Vector3(x, 1.4, -depth * 0.5 - 7.0), Vector3(x, height * 0.52, -depth * 0.5), 48.0, energy * 0.75])
	model.set_meta(LandmarkLights.FLOOD_META, spots)
