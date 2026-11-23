extends RefCounted

## Kustaanmiekka shore battery (Kustaanmiekan rantavarustus), Susisaari: the
## angular earth-and-granite bastion line at the south-east tip of the
## fortress. Frame: origin at the centre of the mapped battery (OSM way
## 117478918, 81 x 122 m), seaward face +Z; registry yaw 48 lays +X along
## its long axis.
##
## What the photographs show (visual-plan/refs/landmarks/kustaanmiekka_bastions/):
## a star-shaped trace with sharp salients; the outer faces are battered
## walls of grey ashlar and rubble granite with yellow lichen and a plain
## granite coping; behind the coping a grassed earth rampart rises in a
## gentle mound, with a gravel path along its crest; casemates (store
## rooms) open in the rear with red-brick end walls, arched plank doors
## and turf-covered vaults; cannon stand on wooden carriages behind the
## parapet.
##
## Measured from OSM: the battery's position, long axis and overall size
## (it was registered 250 m away, in the middle of the island). The salient
## layout is a simplified star, not the 44-vertex mapped outline. Estimated:
## wall height (5.6 m), rampart height, gun count and carriage form.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const ENTRY := {"type": "kustaanmiekka_bastions", "name": "Kustaanmiekka Bastions", "lat": 60.138339, "lon": 24.990227,
	"radius_m": 1500.0, "wiki_title": "Kustaanmiekka", "height_m": 9.0, "clear_m": 30.0,
	"yaw_deg": 48.0, "kind": "Fortification",
	"aliases": ["kustaanmiekka bastions", "kustaanmiekka", "gustavssvärd"]}

const WALL := 5.6

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8A857C", 3.0))
	lm.use("Coping", LandmarkMaterials.pbr("limestone", "#A39E92", 2.0))
	lm.use("Grass", LandmarkMaterials.pbr("grass", "#7E8A56", 4.0))
	lm.use("Path", LandmarkMaterials.pbr("gravel", "#B0A590", 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9A4A38", 2.5))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#6B5A48", 1.5))
	lm.use("Iron", LandmarkMaterials.paint("#26292B", 0.5, 0.6))
	var star := _trace()
	var inner := _inset(star, 2.2)
	lm.poly_prism("Granite", _inset(star, -0.45), 0.0, 1.4, false)
	lm.poly_prism("Granite", star, 0.0, WALL)
	lm.poly_prism("Coping", _inset(star, -0.25), WALL - 0.65, WALL - 0.4, false)
	lm.poly_prism("Coping", _inset(star, 0.1), WALL, WALL + 0.3, false)
	# Turf parapet merlons with splayed gun embrasures along seaward faces, plus inner mound.
	_embrasures(lm, star)
	lm.poly_prism("Grass", _inset(star, 8.5), WALL + 0.9, WALL + 2.2)
	lm.poly_prism("Grass", _inset(star, 17.0), WALL + 2.2, WALL + 3.4)
	_path(lm, star)
	_lichen(lm, star)
	_casemates(lm, star)
	_guns(lm, star)
	lm.commit(model)
	var warm := Color(1.0, 0.85, 0.62)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 1.5, 58.0), Vector3(0.0, 5.5, 36.0), 54.0, 0.95, 55.0, warm],
		[Vector3(-56.0, 1.5, 36.0), Vector3(-36.0, 5.5, 22.0), 52.0, 0.9, 55.0, warm],
		[Vector3(56.0, 1.5, 36.0), Vector3(36.0, 5.5, 22.0), 52.0, 0.9, 55.0, warm],
		[Vector3(-34.0, 1.5, -24.0), Vector3(-22.0, 4.5, -10.0), 48.0, 0.8, 45.0, warm],
		[Vector3(34.0, 1.5, -24.0), Vector3(22.0, 4.5, -10.0), 48.0, 0.8, 45.0, warm],
	])

## Turf parapet ring behind the coping with embrasure gaps at each salient gun.
static func _embrasures(lm: LandmarkMesh, star: PackedVector2Array) -> void:
	var outer := _inset(star, 1.6)
	var inner := _inset(star, 6.0)
	lm.poly_prism("Grass", inner, WALL + 0.3, WALL + 0.95)
	for i in outer.size():
		var a := outer[i]
		var b := outer[(i + 1) % outer.size()]
		var ia := inner[i]
		var ib := inner[(i + 1) % inner.size()]
		var gun_at_a := (i % 2 == 0 and star[i].y >= 0.0)
		var gun_at_b := (((i + 1) % outer.size()) % 2 == 0 and star[(i + 1) % star.size()].y >= 0.0)
		var t0 := 0.14 if gun_at_a else 0.0
		var t1 := 0.86 if gun_at_b else 1.0
		var merlon := PackedVector2Array([a.lerp(b, t0), a.lerp(b, t1), ib.lerp(ia, 1.0 - t1), ib.lerp(ia, 1.0 - t0)])
		lm.poly_prism("Grass", merlon, WALL + 0.3, WALL + 1.95)
		if gun_at_a:
			var cheek_b := Basis(Vector3.UP, atan2((b - a).x, (b - a).y))
			var cp := a.lerp(ia, 0.5) + (b - a).normalized() * 1.4
			lm.box("Wood", Vector3(cp.x, WALL + 1.15, cp.y), Vector3(0.2, 1.4, 3.4), cheek_b, 0.0)

## The star trace: five salients and re-entrants round the battery,
## 35 m radius, seaward side to +Z.
static func _trace() -> PackedVector2Array:
	var p := PackedVector2Array()
	var k := 5
	for i in k * 2:
		var a2 := TAU * float(i) / float(k * 2)
		var r := 44.0 if i % 2 == 0 else 28.0
		# Flatten the inland (-Z) side: it is the gorge.
		var q := Vector2(cos(a2) * r * 1.25, sin(a2) * r)
		if q.y < -10.0:
			q.y = -10.0 - (q.y + 10.0) * 0.1
		p.append(q)
	return p

## Offset a convex-ish ring toward its centroid by d (uniform scale about it).
static func _inset(poly: PackedVector2Array, d: float) -> PackedVector2Array:
	var c := Vector2.ZERO
	for q in poly:
		c += q
	c /= float(poly.size())
	var out := PackedVector2Array()
	for q in poly:
		var v := q - c
		out.append(c + v * maxf(1.0 - d / maxf(v.length(), 1.0), 0.05))
	return out

static func _path(lm: LandmarkMesh, star: PackedVector2Array) -> void:
	var inner := _inset(star, 4.0)
	var y := WALL + 0.95
	for i in inner.size():
		var a := inner[i]
		var b := inner[(i + 1) % inner.size()]
		var d := b - a
		var m := (a + b) * 0.5
		lm.box("Path", Vector3(m.x, y, m.y), Vector3(1.6, 0.05, d.length()), Basis(Vector3.UP, atan2(d.x, d.y)))

## Yellow lichen patches and loophole slits down the granite faces.
static func _lichen(lm: LandmarkMesh, star: PackedVector2Array) -> void:
	for i in star.size():
		var a := star[i]
		var b := star[(i + 1) % star.size()]
		var d := b - a
		var n := Vector2(d.y, -d.x).normalized()
		if n.dot((a + b) * 0.5) < 0.0:
			n = -n
		var basis := Basis(Vector3.UP, atan2(d.x, d.y))
		for k in int(d.length() / 6.0):
			var p := a.lerp(b, (float(k) + 0.5) * 6.0 / d.length()) + n * 0.05
			lm.box("Iron", Vector3(p.x, WALL - 1.6, p.y), Vector3(0.12, 0.6, 0.1), basis)

## Casemate portals: brick-vaulted surrounds with stone keystones, arched plank
## doors and turf-covered barrel vaults rising behind the parapet.
static func _casemates(lm: LandmarkMesh, star: PackedVector2Array) -> void:
	for i in star.size():
		var a := star[i]
		var b := star[(i + 1) % star.size()]
		var d := b - a
		if d.length() < 14.0:
			continue
		var n := Vector2(d.y, -d.x).normalized()
		if n.dot((a + b) * 0.5) < 0.0:
			n = -n
		var right := Vector3(-n.y, 0.0, n.x)
		var out := Vector3(n.x, 0.0, n.y)
		var basis := Basis(right, Vector3.UP, out)
		for t in [0.3, 0.7]:
			var p := a.lerp(b, t)
			var cen := Vector3(p.x, 0.0, p.y)
			# Brick surround and granite jamb quoins.
			lm.box("Brick", cen + Vector3(0, 2.15, 0) + out * 0.14, Vector3(4.6, 4.3, 0.45), basis)
			for s in [-1.0, 1.0]:
				for qk in 3:
					lm.box("Coping", cen + right * (s * 1.35) + Vector3(0, 0.45 + float(qk) * 0.85, 0) + out * 0.34,
						Vector3(0.45, 0.45, 0.25), basis, 0.0)
			# Recessed arched oak plank door and semicircular brick voussoir arch.
			U.opening(lm, "Wood", cen + out * 0.38, out, 2.0, 3.1, true)
			var arch_c := cen + Vector3(0, 2.1, 0) + out * 0.36
			var prev := arch_c + right * 1.15
			for k in range(1, 9):
				var ang := PI * float(k) / 8.0
				var pt := arch_c + right * (1.15 * cos(ang)) + Vector3(0, 1.15 * sin(ang), 0)
				lm.beam("Brick", prev, pt, 0.35, 0.28, out)
				prev = pt
			lm.box("Coping", arch_c + Vector3(0, 1.2, 0) + out * 0.06, Vector3(0.4, 0.5, 0.3), basis, 0.0)
			# Turf-covered casemate vault hood behind the portal.
			lm.frustum("Grass", cen - out * 3.2 + Vector3(0, WALL + 0.5, 0), 2.4, 1.6, 1.4, 8)

## Coastal artillery barrels on stepped wooden carriages behind each embrasure.
static func _guns(lm: LandmarkMesh, star: PackedVector2Array) -> void:
	for i in star.size():
		if i % 2 != 0:
			continue
		var tip := star[i]
		if tip.y < 0.0:
			continue
		var dir := Vector2(tip.x, tip.y).normalized()
		var base2 := tip - dir * 4.4
		var ang := atan2(dir.x, dir.y)
		var b := Basis(Vector3.UP, ang)
		var y := WALL + 0.95
		# Stepped wooden carriage cheeks and four truck wheels.
		lm.box("Wood", Vector3(base2.x, y + 0.35, base2.y), Vector3(1.4, 0.55, 2.4), b)
		lm.box("Wood", Vector3(base2.x, y + 0.72, base2.y) + b * Vector3(0, 0, 0.2), Vector3(1.05, 0.32, 1.7), b)
		for sz in [-0.75, 0.75]:
			for sx in [-0.82, 0.82]:
				var wp := Vector3(base2.x, y, base2.y) + b * Vector3(sx, 0.26, sz)
				lm.box("Wood", wp, Vector3(0.22, 0.52, 0.52), b, 0.0)
				lm.box("Iron", wp, Vector3(0.25, 0.2, 0.2), b, 0.0)
		# Tapered cast-iron artillery barrel with cascabel, reinforcing bands and muzzle swell.
		var p0 := Vector3(base2.x, y + 0.98, base2.y) - b * Vector3(0, 0, 0.35)
		var p_mid := p0 + b * Vector3(0, 0.14, 1.8)
		var p1 := p0 + b * Vector3(0, 0.26, 3.6)
		lm.beam("Iron", p0, p_mid, 0.56, 0.56)
		lm.beam("Iron", p_mid, p1, 0.42, 0.42)
		lm.frustum("Iron", p0 - Vector3(0, 0.15, 0) - b * Vector3(0, 0, 0.22), 0.18, 0.18, 0.3, 8)
		lm.frustum("Iron", p1 - Vector3(0, 0.24, 0), 0.32, 0.28, 0.48, 8)
