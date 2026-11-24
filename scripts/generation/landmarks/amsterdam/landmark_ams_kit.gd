class_name LandmarkAmsKit
extends RefCounted

## Shared Dutch architectural primitives for Amsterdam landmarks:
##   - Bentheimer sandstone stringcourses, cornices & quoins
##   - Crow-stepped, neck & bell gables with sandstone coping & finials
##   - Hendrick de Keyser / Dutch Baroque octagonal timber-and-slate lanterns
##   - Gilded & royal-blue Imperial Crown of Maximilian I (Westertoren / Blauwbrug)
##   - Classic arched Dutch Renaissance brick window bays & canal-bridge vaults

## Register standard Amsterdam landmark materials onto `lm`.
static func mats(lm: LandmarkMesh, brick_hex: String = "#7D3729",
		stone_hex: String = "#D6C9AE", roof_hex: String = "#3A4148") -> void:
	lm.use("Brick", LandmarkMaterials.pbr("brick", brick_hex, 2.2))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", stone_hex, 2.8))
	lm.use("Roof", LandmarkMaterials.pbr("slate", roof_hex, 2.5))
	lm.use("Copper", LandmarkMaterials.pbr("copper", "#4F8373", 2.4, 0.45, 0.35))
	lm.use("Glass", LandmarkMaterials.glass("#263542"))
	lm.use("Dark", LandmarkMaterials.pbr("sheet_metal", "#23272B", 2.0, 0.45, 0.7))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("White", LandmarkMaterials.pbr("render", "#EFECE4", 2.5))
	lm.use("Dial", LandmarkMaterials.paint("#1B1E24", 0.35, 0.25))
	lm.use("Lamp", LandmarkMaterials.lit("#FFD588", 2.8))

## Horizontal Bentheimer sandstone stringcourse band wrapping a rectangular block.
static func stone_band(lm: LandmarkMesh, mat: String, cx: float, cz: float,
		w: float, d: float, y: float, h: float = 0.45, out: float = 0.18) -> void:
	lm.box(mat, Vector3(cx, y, cz), Vector3(w + out * 2.0, h, d + out * 2.0))

## Stepped Dutch crow-step gable (`trapgevel`) facing `normal` (+Z or -Z or ±X)
## centered at `base` (bottom-centre of the gable triangle).
static func step_gable(lm: LandmarkMesh, wall_mat: String, trim_mat: String,
		base: Vector3, normal: Vector3, width: float, height: float,
		steps: int = 5, thick: float = 0.85) -> void:
	var n := normal.normalized()
	var yaw := atan2(n.x, n.z)
	var b := Basis(Vector3.UP, yaw)
	var sh := height / float(maxi(steps, 1))
	for i in steps:
		var frac := 1.0 - float(i) / float(steps)
		var sw := maxf(width * frac, 1.4)
		var yc := base.y + (float(i) + 0.5) * sh
		lm.box(wall_mat, Vector3(base.x, yc, base.z), Vector3(sw, sh, thick), b)
		# Sandstone coping slab on top of each step
		lm.box(trim_mat, Vector3(base.x, yc + sh * 0.5 + 0.12, base.z),
			Vector3(sw + 0.35, 0.24, thick + 0.24), b)
	# Apex finial obelisk
	lm.frustum(trim_mat, Vector3(base.x, base.y + height + 0.24, base.z), 0.32, 0.08, 1.4, 6)

## Dutch Renaissance octagonal Baroque spire lantern (Westertoren, Oude Kerk,
## Zuiderkerk, Munttoren, Montelbaanstoren): open columned belfry + bulbous
## lead/copper cap + upper lantern + finial needle.
static func dutch_spire(lm: LandmarkMesh, body_mat: String, roof_mat: String,
		trim_mat: String, lamp_mat: String, base: Vector3, radius: float,
		height: float, crown: bool = false) -> void:
	var y := base.y
	# Lower octagonal drum
	var drum_h := height * 0.26
	lm.frustum(body_mat, Vector3(base.x, y, base.z), radius, radius * 0.94, drum_h, 8)
	lm.frustum(trim_mat, Vector3(base.x, y + drum_h, base.z), radius * 1.08, radius * 1.04, 0.55, 8)
	y += drum_h + 0.55
	# Open columned carillon belfry
	var open_h := height * 0.24
	var col_r := radius * 0.80
	for k in 8:
		var ang := float(k) * TAU / 8.0
		var cp := Vector3(base.x + cos(ang) * col_r, y, base.z + sin(ang) * col_r)
		lm.frustum(trim_mat, cp, radius * 0.11, radius * 0.09, open_h, 6)
	# Warm glowing belfry core at night
	lm.frustum(lamp_mat, Vector3(base.x, y + open_h * 0.15, base.z),
		radius * 0.42, radius * 0.38, open_h * 0.72, 8)
	y += open_h
	lm.frustum(trim_mat, Vector3(base.x, y, base.z), radius * 1.02, radius * 0.96, 0.5, 8)
	y += 0.5
	# Bulbous Dutch ogee cap
	var bulb_h := height * 0.22
	lm.lathe(roof_mat, Vector3(base.x, y, base.z), PackedVector2Array([
		Vector2(radius * 0.92, 0.0),
		Vector2(radius * 1.04, bulb_h * 0.28),
		Vector2(radius * 0.86, bulb_h * 0.60),
		Vector2(radius * 0.42, bulb_h * 0.86),
		Vector2(radius * 0.28, bulb_h),
	]), 12)
	y += bulb_h
	# Upper lantern & needle
	var top_h := height * 0.16
	for k in 6:
		var ang := float(k) * TAU / 6.0
		lm.frustum(trim_mat, Vector3(base.x + cos(ang) * radius * 0.28, y,
			base.z + sin(ang) * radius * 0.28), radius * 0.06, radius * 0.05, top_h, 6)
	y += top_h
	if crown:
		imperial_crown(lm, "Gold", "Blue", Vector3(base.x, y, base.z), radius * 0.56, height * 0.14)
	else:
		var tip_h := maxf(height - (y - base.y), 2.0)
		lm.frustum(roof_mat, Vector3(base.x, y, base.z), radius * 0.32, 0.06, tip_h, 8)

## Gilded & royal-blue Imperial Crown of Maximilian I (Westertoren & Blauwbrug).
static func imperial_crown(lm: LandmarkMesh, gold_mat: String, blue_mat: String,
		base: Vector3, r: float, h: float) -> void:
	# Circlet band
	lm.frustum(gold_mat, base, r * 0.78, r * 0.88, h * 0.24, 12)
	# Royal-blue velvet mitre dome
	lm.lathe(blue_mat, base + Vector3.UP * (h * 0.22), PackedVector2Array([
		Vector2(r * 0.80, 0.0), Vector2(r * 1.02, h * 0.26),
		Vector2(r * 0.88, h * 0.54), Vector2(r * 0.35, h * 0.72), Vector2(0.0, h * 0.76),
	]), 12)
	# Gilded arched crown ribs
	for k in 4:
		var ang := float(k) * PI * 0.25
		var dx := cos(ang) * r * 0.98
		var dz := sin(ang) * r * 0.98
		lm.beam(gold_mat, base + Vector3(dx, h * 0.22, dz),
			base + Vector3(0.0, h * 0.98, 0.0), r * 0.12, r * 0.12)
		lm.beam(gold_mat, base + Vector3(-dx, h * 0.22, -dz),
			base + Vector3(0.0, h * 0.98, 0.0), r * 0.12, r * 0.12)
	# Orb & cross finial
	lm.lathe(gold_mat, base + Vector3.UP * (h * 0.95), PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(r * 0.24, h * 0.10), Vector2(0.0, h * 0.22),
	]), 8)
	lm.box(gold_mat, base + Vector3.UP * (h * 1.24), Vector3(r * 0.08, h * 0.24, r * 0.08))
	lm.box(gold_mat, base + Vector3.UP * (h * 1.28), Vector3(r * 0.28, h * 0.07, r * 0.07))

## Clock dial with gilded rim facing `normal`.
static func clock_dial(lm: LandmarkMesh, dial_mat: String, rim_mat: String,
		at: Vector3, normal: Vector3, radius: float) -> void:
	var n := normal.normalized()
	var b := Basis(Vector3.UP, atan2(n.x, n.z))
	lm.box(rim_mat, at, Vector3(radius * 2.18, radius * 2.18, 0.22), b)
	lm.box(dial_mat, at + n * 0.08, Vector3(radius * 1.85, radius * 1.85, 0.14), b)
	lm.box(rim_mat, at + n * 0.16, Vector3(radius * 0.14, radius * 0.78, 0.08), b)
	lm.box(rim_mat, at + n * 0.16 + b * Vector3(radius * 0.25, 0.0, 0.0),
		Vector3(radius * 0.56, radius * 0.12, 0.08), b)

## Pitched gable roof along X (`axis_x = true`) or Z (`axis_x = false`).
static func pitched_roof(lm: LandmarkMesh, mat: String, centre: Vector3,
		w: float, d: float, rise: float, axis_x: bool = true) -> void:
	var hw := w * 0.5
	var hd := d * 0.5
	var y0 := centre.y
	var y1 := centre.y + rise
	if axis_x:
		var n1 := Vector3(0.0, hd, rise).normalized()
		var n2 := Vector3(0.0, hd, -rise).normalized()
		lm.quad(mat, Vector3(centre.x - hw, y0, centre.z + hd), Vector3(centre.x + hw, y0, centre.z + hd),
			Vector3(centre.x + hw, y1, centre.z), Vector3(centre.x - hw, y1, centre.z), n1)
		lm.quad(mat, Vector3(centre.x + hw, y0, centre.z - hd), Vector3(centre.x - hw, y0, centre.z - hd),
			Vector3(centre.x - hw, y1, centre.z), Vector3(centre.x + hw, y1, centre.z), n2)
	else:
		var n1 := Vector3(rise, hw, 0.0).normalized()
		var n2 := Vector3(-rise, hw, 0.0).normalized()
		lm.quad(mat, Vector3(centre.x + hw, y0, centre.z - hd), Vector3(centre.x + hw, y0, centre.z + hd),
			Vector3(centre.x, y1, centre.z + hd), Vector3(centre.x, y1, centre.z - hd), n1)
		lm.quad(mat, Vector3(centre.x - hw, y0, centre.z + hd), Vector3(centre.x - hw, y0, centre.z - hd),
			Vector3(centre.x, y1, centre.z - hd), Vector3(centre.x, y1, centre.z + hd), n2)

## Row of recessed arched or rectangular windows along a wall face.
static func window_row(lm: LandmarkMesh, mat: String, a: Vector3, b: Vector3,
		normal: Vector3, y0: float, count: int, w: float, h: float) -> void:
	var n := normal.normalized()
	var yaw := atan2(n.x, n.z)
	var rot := Basis(Vector3.UP, yaw)
	for i in count:
		var t := (float(i) + 0.5) / float(maxi(count, 1))
		var p := a.lerp(b, t) + n * 0.08
		p.y = y0 + h * 0.5
		lm.box(mat, p, Vector3(w, h, 0.16), rot)

## Classical triangular pediment facing `normal`.
static func pediment(lm: LandmarkMesh, trim_mat: String, fill_mat: String,
		base: Vector3, normal: Vector3, width: float, height: float, depth: float = 1.2) -> void:
	var n := normal.normalized()
	var rot := Basis(Vector3.UP, atan2(n.x, n.z))
	var steps := 6
	for i in steps:
		var frac := 1.0 - float(i) / float(steps)
		var sh := height / float(steps)
		lm.box(fill_mat, Vector3(base.x, base.y + (float(i) + 0.5) * sh, base.z),
			Vector3(width * frac, sh, depth), rot)
	# Raking cornice beams
	var left := base + rot * Vector3(-width * 0.52, 0.0, depth * 0.4)
	var right := base + rot * Vector3(width * 0.52, 0.0, depth * 0.4)
	var apex := base + rot * Vector3(0.0, height + 0.2, depth * 0.4)
	lm.beam(trim_mat, left, apex, 0.45, 0.55)
	lm.beam(trim_mat, right, apex, 0.45, 0.55)
	lm.box(trim_mat, Vector3(base.x, base.y - 0.25, base.z) + n * (depth * 0.2),
		Vector3(width + 0.8, 0.5, depth + 0.5), rot)
