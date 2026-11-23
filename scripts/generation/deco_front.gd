class_name DecoFront
extends RefCounted

## Tropical Art Deco & Streamline Moderne street-front 3D relief for Miami Beach
## (`MiamiDecoFronts.row_for` or `look.relief.deco_front`). Zero cost outside
## qualifying buildings. Appends directly into `FacadeRelief`'s `ReliefKit` so
## each building remains a single merged detail mesh:
## - cantilevered horizontal eyebrow sun-shades (`0.42 m` projection, `0.10 m` thick);
## - vertical bay pilasters & fluted upper frieze ribs;
## - stepped, ziggurat, curved, or flat Deco rooftop parapets (`0.9..2.2 m` above `top`);
## - vertical blade fin / sign pylon with dusk-lit neon edge tubes (`ReliefKit.sign`);
## - nautical porthole rings along ground/mezzanine bands;
## - on `kit.ultra`, striped ground canvas awnings & Ocean Drive café umbrellas.

const EYEBROW_PROJ_M := 0.42
const EYEBROW_THICK_M := 0.10
const FIN_PROJ_M := 0.88
const FIN_THICK_M := 0.26

const GENERIC_PALETTES := [
	["#F5EFE4", "#FFFFFF", "#4BA3A6"],
	["#F7E3D8", "#FFFFFF", "#3B8EA5"],
	["#E5F3EC", "#F8F5EA", "#E07A5F"],
	["#F7E9B5", "#FFFFFF", "#2E7D87"],
	["#E6EFF8", "#FFFFFF", "#1F5FA8"],
	["#F6DCE2", "#FFFFFF", "#4AA89C"],
]
const GENERIC_NEONS := ["#38E2FF", "#FF5EA8", "#5AF0D4", "#FFE055", "#FF5247", "#6CE5FF"]
const GENERIC_TERRACES := [
	["#2B7A75", "#F6F3EA"],
	["#1F5699", "#F5F7FA"],
	["#C95244", "#F7F1E3"],
	["#367E62", "#F5F4EC"],
]

static func add(kit: ReliefKit, spans: Array, rows: Array, d: Dictionary) -> void:
	if rows.is_empty() or spans.is_empty():
		return
	var b: Dictionary = d.get("b", {})
	var deco_row := MiamiDecoFronts.row_for(b)
	var relief: Dictionary = (d["look"] as Dictionary).get("relief", {})
	if deco_row.is_empty() and not bool(relief.get("deco_front", false)):
		return
	var seed_v := float(d.get("seed", 0.0))
	var cfg := deco_row if not deco_row.is_empty() else _seeded_spec(seed_v)
	var raised := bool(d.get("raised", false))
	var pal: Array = cfg["palette"]
	var body_mat := ReliefKit.flat(str(pal[0]), 0.68)
	var trim_mat := ReliefKit.flat(str(pal[1]), 0.56)
	var accent_mat := ReliefKit.flat(str(pal[2]), 0.60)
	var sign_mat := ReliefKit.flat(str(cfg["sign_hex"]), 0.52)
	var neon_mat := ReliefKit.sign(str(cfg["neon_hex"]))

	var hero_idx := _pick_hero_span(spans, float(cfg.get("front_w_m", 0.0)))
	if hero_idx < 0:
		return
	var top := float(d.get("top", rows[-1]["y1"]))
	var ground_y := float(d.get("ground_y", rows[0]["y0"]))
	for i in spans.size():
		var sp: Dictionary = spans[i]
		if not bool(sp.get("street", false)) or float(sp.get("len_m", 0.0)) < 3.6:
			continue
		var is_hero := (i == hero_idx)
		if bool(cfg.get("eyebrows", true)):
			_eyebrows(kit, sp, rows, trim_mat, accent_mat, str(cfg.get("corner", "square")) == "round")
		_pilasters_and_frieze(kit, sp, rows, top, accent_mat, trim_mat)
		var para_kind := str(cfg.get("parapet", "stepped")) if is_hero else "flat"
		_parapet(kit, sp, top, para_kind, body_mat, trim_mat, accent_mat, neon_mat if is_hero else null)
		if is_hero and not raised:
			var fin_pos := str(cfg.get("fin_pos", "none"))
			var fin_h := float(cfg.get("fin_h_m", 0.0))
			if fin_pos != "none" and fin_h > 0.25:
				_sign_fin(kit, sp, rows, top, fin_pos, fin_h, str(cfg.get("sign", "")), sign_mat, trim_mat, neon_mat)
			var portholes := int(cfg.get("portholes", 0))
			if portholes > 0:
				_portholes(kit, sp, rows[0], portholes, trim_mat, accent_mat)
		if kit.ultra and not raised and rows[0]["ground"]:
			var terr: Array = cfg.get("terrace", [])
			if terr.size() >= 2:
				_terrace(kit, sp, rows[0], ground_y, str(terr[0]), str(terr[1]), is_hero)

static func _seeded_spec(seed_v: float) -> Dictionary:
	var p_idx := int(ArchitectureStyle._h(seed_v, 161) * float(GENERIC_PALETTES.size())) % GENERIC_PALETTES.size()
	var n_idx := int(ArchitectureStyle._h(seed_v, 162) * float(GENERIC_NEONS.size())) % GENERIC_NEONS.size()
	var t_idx := int(ArchitectureStyle._h(seed_v, 163) * float(GENERIC_TERRACES.size())) % GENERIC_TERRACES.size()
	var para_idx := int(ArchitectureStyle._h(seed_v, 164) * float(MiamiDecoFronts.PARAPET_TYPES.size())) % MiamiDecoFronts.PARAPET_TYPES.size()
	var has_fin := ArchitectureStyle._h(seed_v, 165) < 0.68
	var fin_choices := ["center", "left", "right"]
	var fin_pos := str(fin_choices[int(ArchitectureStyle._h(seed_v, 166) * 3.0) % 3]) if has_fin else "none"
	var pal: Array = GENERIC_PALETTES[p_idx]
	return {
		"front_w_m": 0.0,
		"palette": pal,
		"parapet": MiamiDecoFronts.PARAPET_TYPES[para_idx],
		"eyebrows": ArchitectureStyle._h(seed_v, 167) < 0.88,
		"fin_pos": fin_pos,
		"fin_h_m": (4.4 + ArchitectureStyle._h(seed_v, 168) * 3.0) if has_fin else 0.0,
		"corner": "round" if ArchitectureStyle._h(seed_v, 169) < 0.42 else "square",
		"portholes": 3 if ArchitectureStyle._h(seed_v, 170) < 0.45 else 0,
		"sign": "HOTEL",
		"sign_hex": str(pal[2]),
		"neon_hex": str(GENERIC_NEONS[n_idx]),
		"terrace": GENERIC_TERRACES[t_idx] if ArchitectureStyle._h(seed_v, 171) < 0.65 else [],
	}

static func _pick_hero_span(spans: Array, want_w_m: float) -> int:
	var best := -1
	var best_score := -INF
	for i in spans.size():
		var sp: Dictionary = spans[i]
		if not bool(sp.get("street", false)):
			continue
		var len_m := float(sp.get("len_m", 0.0))
		if len_m < 3.6:
			continue
		var score := -absf(len_m - want_w_m) if want_w_m > 1.0 else len_m
		if score > best_score:
			best_score = score
			best = i
	return best

## Cantilevered horizontal `0.42 m` eyebrow shelves over every upper-storey window head.
static func _eyebrows(kit: ReliefKit, sp: Dictionary, rows: Array,
		trim_mat: Material, accent_mat: Material, round_corner: bool) -> void:
	var m := WorldScale.metres_to_units()
	var dir: Vector2 = sp["dir"]
	var n: Vector2 = sp["n"]
	var ax := Vector3(dir.x, 0.0, dir.y)
	var az := Vector3(n.x, 0.0, n.y)
	var proj := EYEBROW_PROJ_M * m
	var thick := EYEBROW_THICK_M * m
	var trim_a := proj if bool(sp.get("a_inside", false)) else 0.04 * m
	var trim_b := proj if bool(sp.get("b_inside", false)) else 0.04 * m
	var run := float(sp["len_m"]) * m - trim_a - trim_b
	if run < 1.2 * m:
		return
	var a2 := (sp["a"] as Vector2) + dir * (trim_a + run * 0.5)
	for r in rows.size():
		var row: Dictionary = rows[r]
		if bool(row["ground"]):
			continue
		var y := minf(float(row["win1"]) + 0.08 * m, float(row["y1"]) - 0.07 * m)
		var c := Vector3(a2.x, y, a2.y) + az * (proj * 0.5)
		kit.box(trim_mat, c, ax, az, Vector3(run, thick, proj))
		kit.box(accent_mat, Vector3(a2.x, y + 0.015 * m, a2.y) + az * (proj + 0.015 * m),
			ax, az, Vector3(run - 0.04 * m, thick * 0.45, 0.03 * m))
		if round_corner:
			for end_cfg: Array in [[bool(sp["first"]) and not bool(sp.get("a_inside", false)), -1.0],
					[bool(sp["last"]) and not bool(sp.get("b_inside", false)), 1.0]]:
				if not bool(end_cfg[0]):
					continue
				var sgn := float(end_cfg[1])
				var tip := Vector3(a2.x, y, a2.y) + ax * (sgn * (run * 0.5 + 0.09 * m)) + az * (proj * 0.34)
				var diag := (ax * sgn + az).normalized()
				var diag_n := Vector3(diag.z, 0.0, -diag.x) if sgn < 0.0 else Vector3(-diag.z, 0.0, diag.x)
				kit.box(trim_mat, tip, diag, diag_n.normalized(), Vector3(0.28 * m, thick, proj * 0.55))

## Vertical Deco pilasters between bays + fluted upper parapet frieze ribs.
static func _pilasters_and_frieze(kit: ReliefKit, sp: Dictionary, rows: Array, top: float,
		accent_mat: Material, trim_mat: Material) -> void:
	var m := WorldScale.metres_to_units()
	var bays := maxi(int(sp.get("bays", 1)), 1)
	var len := float(sp["len_m"]) * m
	var step := len / float(bays)
	var dir: Vector2 = sp["dir"]
	var n: Vector2 = sp["n"]
	var ax := Vector3(dir.x, 0.0, dir.y)
	var az := Vector3(n.x, 0.0, n.y)
	var y0 := float(rows[0]["y1"]) if bool(rows[0]["ground"]) and rows.size() > 1 else float(rows[0]["y0"]) + 0.4 * m
	var y1 := top - 0.04 * m
	if y1 - y0 < 1.2 * m:
		return
	var a: Vector2 = sp["a"]
	for j in bays + 1:
		if (j == 0 and bool(sp.get("a_inside", false))) or (j == bays and bool(sp.get("b_inside", false))):
			continue
		var off := clampf(float(j) * step, 0.14 * m, len - 0.14 * m)
		var p2 := a + dir * off
		kit.box(accent_mat, Vector3(p2.x, (y0 + y1) * 0.5, p2.y) + az * 0.065 * m,
			ax, az, Vector3(0.16 * m, y1 - y0, 0.13 * m))
	# Three horizontal speed-stripes along the upper frieze just below `top`
	var frieze_len := len - (0.28 * m if bool(sp.get("b_inside", false)) else 0.08 * m)
	if frieze_len > 1.5 * m:
		var mid2 := a + dir * (frieze_len * 0.5 + 0.04 * m)
		for k: int in [0, 1]:
			var fy := top - (0.22 + float(k) * 0.18) * m
			kit.box(trim_mat, Vector3(mid2.x, fy, mid2.y) + az * 0.055 * m,
				ax, az, Vector3(frieze_len, 0.07 * m, 0.11 * m))

## Stepped, ziggurat, curved, or flat Deco parapet rising `0.9..2.1 m` above `top`.
static func _parapet(kit: ReliefKit, sp: Dictionary, top: float, kind: String,
		body_mat: Material, trim_mat: Material, accent_mat: Material, neon_mat: Material) -> void:
	var m := WorldScale.metres_to_units()
	var dir: Vector2 = sp["dir"]
	var n: Vector2 = sp["n"]
	var ax := Vector3(dir.x, 0.0, dir.y)
	var az := Vector3(n.x, 0.0, n.y)
	var trim_a := 0.28 * m if bool(sp.get("a_inside", false)) else 0.03 * m
	var trim_b := 0.28 * m if bool(sp.get("b_inside", false)) else 0.03 * m
	var len := float(sp["len_m"]) * m - trim_a - trim_b
	if len < 1.8 * m:
		return
	var mid2 := (sp["a"] as Vector2) + dir * (trim_a + len * 0.5)
	var thick := 0.28 * m
	var z_off := az * (-0.08 * m)
	var base_h := 0.92 * m
	var base_c := Vector3(mid2.x, top + base_h * 0.5, mid2.y) + z_off
	kit.box(body_mat, base_c, ax, az, Vector3(len, base_h, thick))
	kit.box(accent_mat, Vector3(mid2.x, top + base_h + 0.045 * m, mid2.y) + z_off + az * 0.03 * m,
		ax, az, Vector3(len + 0.04 * m, 0.09 * m, thick + 0.08 * m))

	var crest_y := top + base_h + 0.09 * m
	var crest_w := len * 0.56
	match kind:
		"ziggurat":
			var tiers: Array = [[0.62, 0.44], [0.42, 0.42], [0.24, 0.36]]
			var y_cur := top + base_h
			for tier: Array in tiers:
				var tw := maxf(len * float(tier[0]), 1.3 * m)
				var th := float(tier[1]) * m
				kit.box(body_mat, Vector3(mid2.x, y_cur + th * 0.5, mid2.y) + z_off + az * 0.02 * m,
					ax, az, Vector3(tw, th, thick + 0.04 * m))
				kit.box(trim_mat, Vector3(mid2.x, y_cur + th + 0.04 * m, mid2.y) + z_off + az * 0.05 * m,
					ax, az, Vector3(tw + 0.14 * m, 0.08 * m, thick + 0.12 * m))
				y_cur += th + 0.08 * m
			crest_y = y_cur
			crest_w = maxf(len * 0.42, 1.5 * m)
		"stepped":
			var w1 := maxf(len * 0.54, 1.8 * m)
			var h1 := 0.58 * m
			var y1 := top + base_h
			kit.box(body_mat, Vector3(mid2.x, y1 + h1 * 0.5, mid2.y) + z_off + az * 0.02 * m,
				ax, az, Vector3(w1, h1, thick + 0.04 * m))
			kit.box(accent_mat, Vector3(mid2.x, y1 + h1 + 0.045 * m, mid2.y) + z_off + az * 0.05 * m,
				ax, az, Vector3(w1 + 0.14 * m, 0.09 * m, thick + 0.12 * m))
			crest_y = y1 + h1 + 0.09 * m
			crest_w = w1
		"curved":
			var segs := 5
			var span_w := maxf(len * 0.58, 2.0 * m)
			var seg_w := span_w / float(segs)
			for s in segs:
				var u := (float(s) + 0.5) / float(segs) * 2.0 - 1.0
				var arch_h := (0.22 + 0.58 * maxf(0.0, 1.0 - u * u)) * m
				var sx := (float(s) + 0.5 - float(segs) * 0.5) * seg_w
				var sc := Vector3(mid2.x, top + base_h + arch_h * 0.5, mid2.y) + ax * sx + z_off + az * 0.02 * m
				kit.box(body_mat, sc, ax, az, Vector3(seg_w - 0.02 * m, arch_h, thick + 0.04 * m))
				kit.box(trim_mat, sc + Vector3.UP * (arch_h * 0.5 + 0.035 * m) + az * 0.03 * m,
					ax, az, Vector3(seg_w, 0.07 * m, thick + 0.10 * m))
			crest_y = top + base_h + 0.84 * m
			crest_w = span_w * 0.65
	if neon_mat != null:
		kit.box(neon_mat, Vector3(mid2.x, crest_y - 0.16 * m, mid2.y) + az * 0.13 * m,
			ax, az, Vector3(minf(crest_w, len * 0.85), 0.07 * m, 0.07 * m))

## Projecting vertical Deco blade sign pylon with glowing neon edge & letter strokes.
static func _sign_fin(kit: ReliefKit, sp: Dictionary, rows: Array, top: float,
		fin_pos: String, fin_h_m: float, sign_text: String,
		sign_mat: Material, trim_mat: Material, neon_mat: Material) -> void:
	var m := WorldScale.metres_to_units()
	var len := float(sp["len_m"]) * m
	var dir: Vector2 = sp["dir"]
	var n: Vector2 = sp["n"]
	var ax := Vector3(dir.x, 0.0, dir.y)
	var az := Vector3(n.x, 0.0, n.y)
	var frac := 0.5
	if fin_pos == "left":
		frac = clampf(1.8 * m / len, 0.16, 0.32)
	elif fin_pos == "right":
		frac = 1.0 - clampf(1.8 * m / len, 0.16, 0.32)
	var p2 := (sp["a"] as Vector2) + dir * (len * frac)

	var above := clampf(fin_h_m * 0.36, 1.1, 3.0) * m
	var y1 := top + above
	var min_y0 := float(rows[0]["y1"]) + 0.25 * m
	var y0 := maxf(min_y0, y1 - fin_h_m * m)
	if y1 - y0 < 1.8 * m:
		y0 = maxf(float(rows[0]["y0"]) + 2.6 * m, y1 - 2.4 * m)
	var h := y1 - y0
	if h < 1.2 * m:
		return
	var proj := FIN_PROJ_M * m
	var thick := FIN_THICK_M * m
	var c := Vector3(p2.x, y0 + h * 0.5, p2.y)
	# Backing pilaster spine + projecting blade fin + stepped cap
	kit.box(trim_mat, c + az * 0.11 * m, ax, az, Vector3(thick * 2.1, h + 0.16 * m, 0.22 * m))
	kit.box(sign_mat, c + az * (proj * 0.5 + 0.06 * m), ax, az, Vector3(thick, h, proj))
	kit.box(trim_mat, Vector3(p2.x, y1 + 0.06 * m, p2.y) + az * (proj * 0.45 + 0.05 * m),
		ax, az, Vector3(thick + 0.08 * m, 0.12 * m, proj * 0.92))
	# Vertical neon leading-edge tube + top neon bar + stacked letter-glyph bars
	kit.box(neon_mat, c + az * (proj + 0.095 * m), ax, az, Vector3(0.075 * m, h - 0.14 * m, 0.075 * m))
	var glyphs := clampi(sign_text.replace(" ", "").length(), 4, 10)
	var span_h := h - 0.48 * m
	var step_y := span_h / float(glyphs)
	for g in glyphs:
		var gy := y1 - 0.28 * m - (float(g) + 0.5) * step_y
		kit.box(neon_mat, Vector3(p2.x, gy, p2.y) + az * (proj * 0.60 + 0.06 * m),
			ax, az, Vector3(thick + 0.05 * m, minf(step_y * 0.46, 0.24 * m), proj * 0.46))

## Nautical Streamline Moderne porthole rings along the ground/mezzanine frieze.
static func _portholes(kit: ReliefKit, sp: Dictionary, ground_row: Dictionary,
		count: int, trim_mat: Material, accent_mat: Material) -> void:
	var m := WorldScale.metres_to_units()
	var len := float(sp["len_m"]) * m
	var n_holes := mini(count, maxi(1, int(len / (2.2 * m))))
	if n_holes <= 0:
		return
	var dir: Vector2 = sp["dir"]
	var n: Vector2 = sp["n"]
	var ax := Vector3(dir.x, 0.0, dir.y)
	var az := Vector3(n.x, 0.0, n.y)
	var gy0 := float(ground_row["y0"])
	var gy1 := float(ground_row["y1"])
	var py := clampf(gy1 - 0.58 * m, gy0 + 1.8 * m, gy1 - 0.32 * m)
	var r := 0.28 * m
	var glass := kit.pane()
	for i in n_holes:
		var t := (float(i) + 0.5) / float(n_holes)
		var p2 := (sp["a"] as Vector2) + dir * (len * t)
		var pc := Vector3(p2.x, py, p2.y)
		kit.box(glass, pc + az * 0.025 * m, ax, az, Vector3(r * 1.45, r * 1.45, 0.04 * m))
		for s in 8:
			var ang := (float(s) + 0.5) * TAU / 8.0
			var tang_x := cos(ang)
			var tang_y := sin(ang)
			var seg_c := pc + ax * (tang_x * r) + Vector3.UP * (tang_y * r) + az * 0.055 * m
			kit.box(trim_mat, seg_c, ax, az, Vector3(r * 0.72, r * 0.28, 0.09 * m))
		kit.box(accent_mat, pc + az * 0.065 * m, ax, az, Vector3(r * 1.65, 0.045 * m, 0.05 * m))

## Striped ground-storey canvas awning & sidewalk café umbrellas (desktop Ultra).
static func _terrace(kit: ReliefKit, sp: Dictionary, ground_row: Dictionary, ground_y: float,
		awning_hex: String, umbrella_hex: String, with_umbrellas: bool) -> void:
	var m := WorldScale.metres_to_units()
	var len := float(sp["len_m"]) * m
	if len < 4.2 * m:
		return
	var dir: Vector2 = sp["dir"]
	var n: Vector2 = sp["n"]
	var ax := Vector3(dir.x, 0.0, dir.y)
	var az := Vector3(n.x, 0.0, n.y)
	var awn_mat := ReliefKit.canvas(awning_hex, true)
	var bays := maxi(int(sp.get("bays", 1)), 1)
	var step := len / float(bays)
	var ay := clampf(float(ground_row["y1"]) - 0.34 * m, ground_y + 2.75 * m, ground_y + 3.55 * m)
	var out := 1.35 * m
	var drop := 0.58 * m
	var val := Vector3.DOWN * 0.22 * m
	var slope_n := (az * drop + Vector3.UP * out).normalized()
	for j in bays:
		var c2 := (sp["a"] as Vector2) + dir * (step * (float(j) + 0.5))
		var w := step * 0.88
		var l := Vector3(c2.x, ay, c2.y) - ax * (w * 0.5) + az * 0.025 * m
		var r := l + ax * w
		var lf := l + az * out + Vector3.DOWN * drop
		var rf := r + az * out + Vector3.DOWN * drop
		kit.quad(awn_mat, lf, rf, r, l, slope_n, Vector2.ZERO, Vector2(w / m, 1.0))
		kit.quad(awn_mat, lf + val, rf + val, rf, lf, az, Vector2.ZERO, Vector2(w / m, 0.22))

	if not with_umbrellas or len < 6.0 * m:
		return
	var umb_mat := ReliefKit.canvas(umbrella_hex, false)
	var pole_mat := ReliefKit.flat("#2C3034", 0.5, 0.55)
	var n_umb := clampi(int(len / (4.2 * m)), 2, 6)
	var usable := len - 2.4 * m
	for k in n_umb:
		var u := (float(k) + 0.5) / float(n_umb)
		var p2 := (sp["a"] as Vector2) + dir * (1.2 * m + usable * u) + n * (2.25 * m)
		var base := Vector3(p2.x, ground_y, p2.y)
		var hub := base + Vector3.UP * (2.22 * m)
		var apex := base + Vector3.UP * (2.68 * m)
		kit.box(pole_mat, base + Vector3.UP * (1.18 * m), ax, az, Vector3(0.055 * m, 2.36 * m, 0.055 * m))
		var hw := 1.05 * m
		var corners := [
			hub - ax * hw + az * hw,
			hub + ax * hw + az * hw,
			hub + ax * hw - az * hw,
			hub - ax * hw - az * hw,
		]
		for s in 4:
			var c0: Vector3 = corners[s]
			var c1: Vector3 = corners[(s + 1) % 4]
			var fn := (c1 - c0).cross(apex - c0).normalized()
			if fn.y < 0.0:
				fn = -fn
			kit.tri(umb_mat, c0, c1, apex, fn)
