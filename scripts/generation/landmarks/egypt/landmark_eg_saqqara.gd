class_name LandmarkEgSaqqara
extends RefCounted

## The early pyramids of the Memphite necropolis in true metres: Djoser's
## Step Pyramid at Saqqara with its enclosure wall and entrance
## colonnade, Sneferu's Bent and Red Pyramids at Dahshur and the
## collapsed tower of Meidum. Faces to the compass, +X east, -Z north.

# --- Step Pyramid of Djoser ---

## Six battered tiers 62.5 m high on a 125 x 109 m base, each laid in
## inward-leaning courses, inside the 544 x 277 m panelled enclosure wall
## (10.5 m, the long side north-south, pyramid 300 m from the north
## wall) with its bastions and 14 false gates. The true gate is at the
## south end of the east wall, opening on the roofed colonnade of 40
## ribbed columns engaged to spur walls; north of it the Heb-Sed court of
## dummy chapels and the Houses of the South and North, the great south
## court with its B-shaped markers and the South Tomb behind its cobra
## frieze, and the mortuary temple and serdab on the north face.
static func djoser(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#CDBA94", 3.2))
	lm.use("Wall", LandmarkMaterials.pbr("stone", "#DDD0AE", 3.4))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A2E22", 2.0))
	lm.use("Sand", LandmarkMaterials.pbr("sand", "#D6BE8C", 8.0))
	lm.box("Sand", Vector3(0, 0.1, -28.0), Vector3(300.0, 0.2, 566.0), Basis(), 0.0)
	var heights: Array[float] = [12.0, 11.3, 10.6, 10.1, 9.5, 9.0]
	var w := 125.0
	var d := 109.0
	var y := 0.0
	for h in heights:
		var lean := h * 0.3
		_tier(lm, "Stone", Vector3(0, y, 0), w, d, lean, h)
		y += h
		w -= 2.0 * (lean + 2.8)
		d -= 2.0 * (lean + 2.8)
	_djoser_enclosure(lm)
	_djoser_colonnade(lm)
	_heb_sed(lm)
	# Mortuary temple and the serdab with its two eye holes on the north face.
	lm.box("Wall", Vector3(-8.0, 3.5, -72.0), Vector3(36.0, 7.0, 34.0))
	for s in [-1.0, 1.0]:
		lm.box("Wall", Vector3(-8.0 + s * 9.0, 2.5, -61.0), Vector3(12.0, 5.0, 8.0))
	lm.box("Dark", Vector3(-8.0, 2.4, -89.1), Vector3(3.0, 4.8, 0.3), Basis(), 0.0)
	LandmarkEgParts.taper(lm, "Wall", Vector3(18.0, 0, -58.0), 4.4, 3.6, 3.6, 2.8, 4.2)
	for s in [-1.0, 1.0]:
		lm.box("Dark", Vector3(18.0 + s * 0.4, 2.9, -59.65), Vector3(0.2, 0.2, 0.2), Basis(), 0.0)
	# Great south court: the paired B-shaped markers of the jubilee run.
	for z in [86.0, 150.0]:
		lm.poly_prism("Wall", PackedVector2Array([Vector2(-6, z - 3), Vector2(2, z - 3), Vector2(5, z - 1.5),
			Vector2(3.5, z), Vector2(5, z + 1.5), Vector2(2, z + 3), Vector2(-6, z + 3)]), 0.0, 1.6)
	# South Tomb along the south wall: a mastaba under a frieze of cobras.
	lm.box("Wall", Vector3(-20.0, 4.5, 226.0), Vector3(84.0, 9.0, 12.0))
	for i in 36:
		var cx := -60.0 + 2.3 * float(i)
		lm.lathe("Wall", Vector3(cx, 9.0, 219.8), PackedVector2Array([Vector2(0.5, 0), Vector2(0.45, 0.8),
			Vector2(0.6, 1.2), Vector2(0.3, 1.5), Vector2(0.0, 1.6)]), 6, 1.0, 0.5)
	lm.commit(model)

## One battered tier w x d at its foot, `lean` in on every side over `h`,
## laid in courses of small blocks about 0.6 m high, a small ledge each.
static func _tier(lm: LandmarkMesh, key: String, c: Vector3, w: float, d: float, lean: float,
		h: float) -> void:
	var n := maxi(int(round(h / 0.6)), 2)
	var k := sqrt(2.0)
	var prof := PackedVector2Array()
	var sz := d / w
	for i in n:
		var t0 := float(i) / float(n)
		var t1 := float(i + 1) / float(n)
		var r0 := (w * 0.5 - lean * t0) * k
		var r1 := (w * 0.5 - lean * t1) * k
		prof.append(Vector2(r0, h * t0))
		prof.append(Vector2(r1 + 0.15 * k, h * t1))
	prof.append(Vector2((w * 0.5 - lean) * k, h))
	lm.lathe(key, c, prof, 4, 1.0, sz, PI * 0.25, false, true)

## The enclosure: a 10.5 m wall with bastions every ~7.6 m (211 in
## all), each a panelled projection, and 14 larger false gates.
static func _djoser_enclosure(lm: LandmarkMesh) -> void:
	var x0 := -138.5
	var x1 := 138.5
	var z0 := -300.0
	var z1 := 244.0
	var hw := 10.5
	for e in [[Vector2(x0, z0), Vector2(x1, z0)], [Vector2(x0, z1), Vector2(x1, z1)],
			[Vector2(x0, z0), Vector2(x0, z1)], [Vector2(x1, z0), Vector2(x1, z1)]]:
		var a: Vector2 = e[0]
		var b: Vector2 = e[1]
		LandmarkEgParts.wall(lm, "Wall", a, b, hw, 3.2)
		var dir := (b - a).normalized()
		var out := Vector2(-dir.y, dir.x)
		if out.dot((a + b) * 0.5 - Vector2(0, -28.0)) < 0.0:
			out = -out
		var ln := a.distance_to(b)
		var n := int(ln / 7.6)
		var basis := Basis(Vector3(dir.x, 0, dir.y), Vector3.UP, Vector3(out.x, 0, out.y))
		for i in n:
			var p := a + dir * (ln * (float(i) + 0.5) / float(n)) + out * 2.1
			var gate := i % 4 == 2 and (i / 4) % 2 == 0
			var bw := 9.0 if gate else 3.6
			var pc := Vector3(p.x, hw * 0.5, p.y)
			lm.box("Wall", pc, Vector3(bw, hw, 1.0), basis)
			# Recessed panel lines down the bastion face.
			var o3 := Vector3(out.x, 0, out.y)
			for k in (3 if gate else 1):
				var off := Vector3(dir.x, 0, dir.y) * (float(k) - 1.0) * 2.6 * (1.0 if gate else 0.0)
				lm.box("Dark", pc + off + o3 * 0.48 - Vector3(0, hw * 0.05, 0), Vector3(0.5, hw * 0.8, 0.1),
					basis, 0.0)
		LandmarkEgParts.wall(lm, "Wall", a - dir * 1.6, b + dir * 1.6, 0.6, 4.4, hw)

## Entrance gate in the east wall and the 54 m roofed colonnade running
## west from it: 20 pairs of 6.6 m ribbed (reeded) columns, each engaged
## to a short spur wall, under the restored stone roof.
static func _djoser_colonnade(lm: LandmarkMesh) -> void:
	var zc := 200.0
	lm.box("Dark", Vector3(140.2, 3.0, zc), Vector3(0.4, 6.0, 1.4), Basis(), 0.0)
	lm.box("Wall", Vector3(141.0, 5.25, zc), Vector3(1.6, 10.5, 9.0))
	for s in [-1.0, 1.0]:
		LandmarkEgParts.wall(lm, "Wall", Vector2(138.0, zc + s * 7.6), Vector2(84.0, zc + s * 7.6), 7.0, 1.8)
	lm.box("Wall", Vector3(111.0, 7.6, zc), Vector3(54.0, 1.2, 14.2))
	for i in 20:
		var x := 135.0 - 2.6 * float(i)
		for s in [-1.0, 1.0]:
			var z: float = zc + s * 2.4
			lm.box("Wall", Vector3(x, 3.3, z + s * 2.2), Vector3(1.2, 6.6, 4.0))
			lm.lathe("Wall", Vector3(x, 0, z), PackedVector2Array([Vector2(0.55, 0), Vector2(0.5, 6.2),
				Vector2(0.62, 6.25), Vector2(0.62, 6.6)]), 14, 1.0, 1.0, 0.0, false, false)
	lm.box("Wall", Vector3(80.0, 3.5, zc), Vector3(8.0, 7.0, 15.0))
	lm.box("Dark", Vector3(75.9, 2.4, zc), Vector3(0.3, 4.8, 2.4), Basis(), 0.0)

## Heb-Sed court: two facing rows of solid dummy chapels with curved
## (arched) roofs and engaged fluted columns on their fronts; north of
## it the Houses of the South and North with their papyrus half-columns.
static func _heb_sed(lm: LandmarkMesh) -> void:
	for i in 12:
		var z := 100.0 + 7.0 * float(i)
		for s in [-1.0, 1.0]:
			var x: float = 95.0 + s * 12.0
			lm.box("Wall", Vector3(x, 2.4, z), Vector3(6.0, 4.8, 5.4))
			# Curved roof: a half-cylinder running across the chapel front.
			var rows: Array = []
			for k in 7:
				var a := PI * float(k) / 6.0
				var off := Vector3(cos(a) * 3.0, 4.8 + sin(a) * 1.4, 0)
				rows.append(PackedVector3Array([Vector3(x, 0, z - 2.7) + off, Vector3(x, 0, z + 2.7) + off]))
			lm.grid("Wall", rows, Vector3(x, 4.8, z), true)
			for k in [-1.0, 1.0]:
				lm.lathe("Wall", Vector3(x - s * 3.1, 0, z + k * 1.4), PackedVector2Array([Vector2(0.3, 0),
					Vector2(0.28, 4.6)]), 8, 1.0, 1.0, 0.0, false, false)
			lm.box("Dark", Vector3(x - s * 3.05, 1.6, z), Vector3(0.1, 2.2, 1.0), Basis(), 0.0)
	for z in [10.0, -40.0]:
		lm.box("Wall", Vector3(96.0, 4.0, z), Vector3(18.0, 8.0, 14.0))
		lm.lathe("Wall", Vector3(96.0, 8.0, z), PackedVector2Array([Vector2(9.0, 0), Vector2(8.5, 0.8),
			Vector2(0.0, 1.6)]), 4, 1.0, 14.0 / 18.0, PI * 0.25, false)
		for k in 4:
			LandmarkEgParts.column(lm, "Wall", Vector3(86.6, 0, z - 4.5 + 3.0 * k), 0.4, 7.2,
				LandmarkEgParts.PLAIN)
		lm.box("Dark", Vector3(86.9, 2.0, z), Vector3(0.2, 4.0, 1.4), Basis(), 0.0)

# --- Bent Pyramid ---

## 188.6 m square, 104.7 m: the 54.5 degree lower slope turns at 47 m to
## 43.5 degrees, most of the Tura casing still on; the entrances 11.8 m
## up the north face and 33 m up the west face, casing blocks fallen
## from the worn corners, the mortuary chapel with
## its two round-topped stelae and offering table on the east face, the
## low enclosure wall, the 26 m satellite pyramid 55 m south with its own
## chapel, and the causeway leaving north-east toward the valley temple.
static func bent(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Casing", LandmarkMaterials.pbr("stone", "#DDD0AB", 4.2))
	lm.use("Core", LandmarkMaterials.pbr("stone", "#C4AE86", 3.6))
	lm.use("Sand", LandmarkMaterials.pbr("sand", "#D6BE8C", 8.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A2E22", 2.0))
	var hb := 94.3
	var kink := 47.0
	var hw_kink := 60.7
	var apex_lower := kink / (1.0 - hw_kink / hb)
	var apex_top := 104.7
	var hb_upper := hw_kink / (1.0 - kink / apex_top)
	lm.box("Sand", Vector3(0, 0.1, 30.0), Vector3(hb * 2.0 + 60.0, 0.2, hb * 2.0 + 140.0), Basis(), 0.0)
	# Foundation platform course and the two slopes; the lower casing in
	# its bands of fine courses, the corners worn back to the core.
	lm.box("Casing", Vector3(0, 0.35, 0), Vector3(hb * 2.0 + 3.0, 0.5, hb * 2.0 + 3.0))
	LandmarkEgParts.smooth(lm, "Casing", Vector3.ZERO, hb, apex_lower, 0.0, kink)
	LandmarkEgParts.smooth(lm, "Casing", Vector3.ZERO, hb_upper, apex_top, kink, apex_top)
	_band(lm, "Casing", hb, apex_lower, kink - 0.6, 0.6, 0.25)
	for k in 6:
		_band(lm, "Core", hb, apex_lower, 4.0 + 6.0 * float(k), 1.2, 0.05, 0.32 - 0.04 * float(k))
	# Casing blocks fallen from the worn corners, lying at the foot.
	for f in 4:
		var out := Vector3(sin(PI * 0.5 * f), 0, cos(PI * 0.5 * f))
		var rt := Vector3.UP.cross(out)
		for i in 10:
			var side := -1.0 if i < 5 else 1.0
			var x := side * (hb - 2.0 - 3.5 * float(i % 5))
			lm.box("Casing", out * (hb + 2.5 + 1.2 * sin(float(i * 5 + f))) + rt * x + Vector3(0, 0.6, 0),
				Vector3(1.5, 1.1, 1.3), Basis(Vector3.UP, float(i) * 0.7 + float(f)))
	_slope_door(lm, "Dark", hb, apex_lower, 11.8, 1.1, 1.1, Vector3(0, 0, -1))
	_slope_door(lm, "Dark", hb, apex_lower, 33.3, 1.1, 1.1, Vector3(-1, 0, 0))
	# Mortuary chapel against the east face: walls, stelae, offering table.
	lm.box("Core", Vector3(hb + 6.0, 1.5, 0), Vector3(8.0, 3.0, 2.0))
	for s in [-1.0, 1.0]:
		lm.box("Core", Vector3(hb + 6.0, 1.5, s * 6.0), Vector3(8.0, 3.0, 1.2))
		var st := Vector3(hb + 3.0, 0, s * 3.2)
		lm.box("Casing", st + Vector3(0, 3.5, 0), Vector3(1.0, 7.0, 2.4))
		lm.lathe("Casing", st + Vector3(0, 7.0, 0), PackedVector2Array([Vector2(1.2, 0), Vector2(0.9, 0.7),
			Vector2(0.0, 1.0)]), 8, 0.42, 1.0)
	lm.box("Casing", Vector3(hb + 5.0, 0.4, 0), Vector3(1.6, 0.8, 2.6))
	# Enclosure wall, now a low ridge, and the causeway start.
	var ew := hb + 26.0
	var zs := ew + 100.0
	LandmarkEgParts.wall(lm, "Core", Vector2(-ew, -ew), Vector2(ew, -ew), 1.4, 4.0)
	LandmarkEgParts.wall(lm, "Core", Vector2(-ew, zs), Vector2(ew, zs), 1.4, 4.0)
	for s in [-1.0, 1.0]:
		LandmarkEgParts.wall(lm, "Core", Vector2(s * ew, -ew), Vector2(s * ew, zs), 1.4, 4.0)
	lm.beam("Core", Vector3(ew, 0.9, -ew + 20.0), Vector3(ew + 30.0, 0.9, -ew - 10.0), 6.0, 1.8,
		Vector3.ZERO, true)
	# Satellite pyramid (52.8 m base, 26 m today) and its chapel.
	var sat := Vector3(0, 0, 165.0)
	LandmarkEgParts.smooth(lm, "Casing", sat, 26.2, 37.0, 0.0, 10.0)
	LandmarkEgParts.courses(lm, "Core", sat, 26.2, 37.0, 10.0, 26.0, 1.0, true)
	lm.box("Core", sat + Vector3(30.0, 1.4, 0), Vector3(5.0, 2.8, 7.0))
	_slope_door(lm, "Dark", 26.2, 37.0, 1.0, 1.0, 1.0, Vector3(0, 0, -1), sat)
	lm.commit(model)

## Projecting band round all four faces of a square pyramid (half-base
## hb, apex height `apex`) from y to y + h, `proud` m out; `span` < 1
## limits it to the corner stretches (casing worn back to the core).
static func _band(lm: LandmarkMesh, key: String, hb: float, apex: float, y: float, h: float,
		proud: float, span: float = 1.0) -> void:
	for f in 4:
		var out := Vector3(sin(PI * 0.5 * f), 0, cos(PI * 0.5 * f))
		var rt := Vector3.UP.cross(out)
		var fn := (out * apex + Vector3.UP * hb).normalized()
		var at := func(x: float, yy: float) -> Vector3:
			var half := hb * (1.0 - yy / apex)
			return out * half + rt * x * half + fn * proud + Vector3(0, yy, 0)
		var spans: Array = [[-1.0, 1.0]] if span >= 1.0 else [[-1.0, -1.0 + span], [1.0 - span, 1.0]]
		for sp in spans:
			var x0: float = sp[0]
			var x1: float = sp[1]
			lm.quad(key, at.call(x0, y), at.call(x1, y), at.call(x1, y + h), at.call(x0, y + h), fn)

## Dark passage mouth `w` x `h` at height y on the face looking along
## `out` (a unit compass axis) of a pyramid of half-base hb.
static func _slope_door(lm: LandmarkMesh, key: String, hb: float, apex: float, y: float, w: float,
		h: float, out: Vector3, c: Vector3 = Vector3.ZERO) -> void:
	var rt := Vector3.UP.cross(out)
	var fn := (out * apex + Vector3.UP * hb).normalized()
	var p := func(x: float, yy: float) -> Vector3:
		return c + out * hb * (1.0 - yy / apex) + rt * x + Vector3(0, yy, 0) + fn * 0.1
	lm.quad(key, p.call(-w * 0.5, y), p.call(w * 0.5, y), p.call(w * 0.5, y + h), p.call(-w * 0.5, y + h), fn)

# --- Red Pyramid ---

## 220 m square, 104 m (43.4 degrees): the first true smooth-sided
## pyramid, today stripped to its red-weathered core courses with a ring
## of the white casing left at the foot; the entrance 28 m up the north
## face reached by the visitors' stair, the restored limestone
## pyramidion set up on a plinth by the east face, and the ruined
## mortuary temple east.
static func red_pyramid(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Core", LandmarkMaterials.pbr("stone", "#C47A55", 3.8))
	lm.use("Casing", LandmarkMaterials.pbr("stone", "#DCCFAC", 4.0))
	lm.use("Sand", LandmarkMaterials.pbr("sand", "#D6BE8C", 8.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A2E22", 2.0))
	var hb := 110.0
	var apex := 104.0
	lm.box("Sand", Vector3(0, 0.1, 0), Vector3(hb * 2.0 + 60.0, 0.2, hb * 2.0 + 40.0), Basis(), 0.0)
	LandmarkEgParts.smooth(lm, "Casing", Vector3.ZERO, hb, apex, 0.0, 4.5)
	LandmarkEgParts.courses(lm, "Core", Vector3.ZERO, hb, apex, 4.5, apex, 0.9)
	# Casing blocks still lying along the foot.
	for f in 4:
		var out := Vector3(sin(PI * 0.5 * f), 0, cos(PI * 0.5 * f))
		var rt := Vector3.UP.cross(out)
		for i in 9:
			var x := -90.0 + 22.5 * float(i) + 4.0 * sin(float(i * 3 + f))
			lm.box("Casing", out * (hb + 3.0 + 1.5 * sin(float(i + f))) + rt * x + Vector3(0, 0.6, 0),
				Vector3(1.6, 1.2, 1.6), Basis(Vector3.UP, float(i) * 0.4))
	# Entrance passage mouth 28 m up the north face and the visitors' stair.
	var n := Vector3(0, hb, -apex).normalized()
	var zc := -hb * (1.0 - 28.0 / apex)
	lm.quad("Dark", Vector3(-0.6, 28.0, zc) + n * 0.4, Vector3(0.6, 28.0, zc) + n * 0.4,
		Vector3(0.6, 29.2, zc + 1.2 * hb / apex) + n * 0.4, Vector3(-0.6, 29.2, zc + 1.2 * hb / apex) + n * 0.4, n)
	lm.beam("Casing", Vector3(0, 0.4, -hb - 2.0), Vector3(0, 27.8, zc - 0.6), 1.6, 0.4, Vector3.RIGHT, true)
	for i in 28:
		var t := float(i) / 28.0
		var p := Vector3(0, 0.4, -hb - 2.0).lerp(Vector3(0, 27.8, zc - 0.6), t)
		for s in [-1.0, 1.0]:
			lm.box("Dark", p + Vector3(s * 0.8, 0.5, 0), Vector3(0.06, 1.0, 0.06), Basis(), 0.0)
	lm.box("Casing", Vector3(0, 28.0, zc - 0.8), Vector3(3.0, 0.3, 2.0))
	# The pyramidion, re-erected on a plinth east of the pyramid.
	lm.box("Casing", Vector3(hb + 14.0, 0.4, 20.0), Vector3(4.0, 0.8, 4.0))
	lm.spire("Casing", Vector3(hb + 14.0, 0.8, 20.0), 1.6, 1.6)
	# Mortuary temple ruin: low walls of a court and offering hall.
	lm.box("Core", Vector3(hb + 10.0, 1.2, 0), Vector3(4.0, 2.4, 30.0))
	for s in [-1.0, 1.0]:
		lm.box("Core", Vector3(hb + 20.0, 1.2, s * 15.0), Vector3(24.0, 2.4, 2.0))
		lm.box("Core", Vector3(hb + 20.0, 0.8, s * 6.0), Vector3(14.0, 1.6, 1.4))
	lm.box("Core", Vector3(hb + 32.0, 1.2, 0), Vector3(2.0, 2.4, 30.0))
	lm.commit(model)

# --- Pyramid of Meidum ---

## The collapsed pyramid of Huni and Sneferu: the steep (75 degree)
## three-stage tower of core masonry 65 m high, smooth-dressed faces
## between the rough bands left where the outer layers tore away,
## standing out of a 185 m wide mound of its own casing debris; the
## entrance passage 18.5 m up the north side with its stair, and the
## small intact mortuary chapel with two stelae on the east.
static func meidum(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Tower", LandmarkMaterials.pbr("stone", "#C2AB82", 3.6))
	lm.use("Rubble", LandmarkMaterials.pbr("gravel", "#B09A74", 5.0))
	lm.use("Sand", LandmarkMaterials.pbr("sand", "#D6BE8C", 8.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A2E22", 2.0))
	lm.box("Sand", Vector3(0, 0.1, 0), Vector3(220.0, 0.2, 220.0), Basis(), 0.0)
	# Debris mound: an irregular cone of scree, ridges down each corner.
	var rows: Array = []
	var levels := [[96.0, 0.0], [84.0, 5.0], [70.0, 12.0], [56.0, 20.0], [44.0, 28.0], [35.0, 34.0]]
	var seg := 40
	for lv in levels:
		var ring := PackedVector3Array()
		for i in seg + 1:
			var a := TAU * float(i) / float(seg)
			var rr: float = float(lv[0]) * (1.0 + 0.06 * sin(a * 3.0 + float(lv[1])) + 0.08 * absf(sin(a * 2.0)))
			ring.append(Vector3(cos(a) * rr, float(lv[1]), sin(a) * rr))
		rows.append(ring)
	lm.grid("Rubble", rows, Vector3(0, 10.0, 0), true)
	lm.box("Rubble", Vector3(0, 33.0, 0), Vector3(66.0, 2.0, 66.0))
	_meidum_stage(lm, Vector3(0, 30.0, 0), 66.0, 60.0, 15.0)
	_meidum_stage(lm, Vector3(0, 45.0, 0), 52.0, 47.0, 11.0)
	_meidum_stage(lm, Vector3(0, 56.0, 0), 39.0, 34.0, 9.0)
	for k in 6:
		var ang := float(k) * 1.1
		var r := 30.0 + 2.0 * float(k)
		lm.box("Tower", Vector3(cos(ang) * r, 64.2, sin(ang) * r) * Vector3(0.45, 1.0, 0.45),
			Vector3(3.0, 1.6, 2.2), Basis(Vector3.UP, ang))
	# North entrance and its stair up the mound.
	lm.box("Dark", Vector3(0, 19.6, -60.0), Vector3(1.0, 1.2, 0.3), Basis(), 0.0)
	lm.box("Tower", Vector3(0, 21.0, -60.0), Vector3(3.0, 0.8, 1.8))
	for i in 18:
		var t := float(i) / 18.0
		lm.box("Tower", Vector3(0, 19.0 * t + 0.5, -92.0 + 31.0 * t), Vector3(2.0, 0.3, 1.0))
	# Mortuary chapel: the offering court between two stelae against the east face.
	lm.box("Tower", Vector3(98.0, 1.4, 0), Vector3(9.0, 2.8, 9.0))
	for s in [-1.0, 1.0]:
		lm.box("Tower", Vector3(98.0, 1.4, s * 7.0), Vector3(9.0, 2.8, 4.0))
		lm.box("Tower", Vector3(91.0, 2.1, s * 2.0), Vector3(0.8, 4.2, 1.6))
		lm.lathe("Tower", Vector3(91.0, 4.2, s * 2.0), PackedVector2Array([Vector2(0.8, 0),
			Vector2(0.6, 0.4), Vector2(0.0, 0.6)]), 8, 0.5, 1.0)
	lm.box("Dark", Vector3(102.6, 1.2, 0), Vector3(0.3, 2.0, 1.0), Basis(), 0.0)
	lm.box("Rubble", Vector3(130.0, 0.6, 0), Vector3(50.0, 1.2, 6.0))
	lm.commit(model)

## One stage of the Meidum tower: steep smooth faces (w0 at the foot,
## w1 at the top over `h`) with a rough projecting ledge band at the
## foot and a weathered tread on top.
static func _meidum_stage(lm: LandmarkMesh, c: Vector3, w0: float, w1: float, h: float) -> void:
	LandmarkEgParts.taper(lm, "Tower", c, w0, w0, w1, w1, h)
	LandmarkEgParts.taper(lm, "Tower", c, w0 + 1.6, w0 + 1.6, w0 + 0.6, w0 + 0.6, 1.4)
	for k in 3:
		var y := h * (0.3 + 0.25 * float(k))
		var wy := lerpf(w0, w1, y / h)
		LandmarkEgParts.taper(lm, "Tower", c + Vector3(0, y, 0), wy + 0.12, wy + 0.12, wy + 0.1, wy + 0.1, 0.25,
			false)
	for k in 4:
		var a := PI * 0.5 * float(k)
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Rubble", c + Vector3(0, h + 0.2, 0) + d * (w1 * 0.5 - 1.0), Vector3(2.0, 0.4, 2.0) +
			Vector3(absf(d.z), 0, absf(d.x)) * (w1 - 6.0))
