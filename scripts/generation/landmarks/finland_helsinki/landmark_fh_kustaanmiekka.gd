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
	lm.poly_prism("Granite", star, 0.0, WALL)
	lm.poly_prism("Coping", _inset(star, 0.1), WALL, WALL + 0.3, false)
	# Rampart: a stepped earth mound within the coping.
	lm.poly_prism("Grass", inner, WALL + 0.3, WALL + 0.9)
	lm.poly_prism("Grass", _inset(star, 9.0), WALL + 0.9, WALL + 2.2)
	lm.poly_prism("Grass", _inset(star, 17.0), WALL + 2.2, WALL + 3.4)
	_path(lm, star)
	_lichen(lm, star)
	_casemates(lm, star)
	_guns(lm, star)
	lm.commit(model)

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

## Casemate doors: brick surrounds with arched plank doors set into the
## longer granite faces, the vaults behind them under the turf.
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
		var basis := Basis(Vector3.UP, atan2(d.x, d.y))
		var out := Vector3(n.x, 0, n.y)
		for t in [0.3, 0.7]:
			var p := a.lerp(b, t)
			lm.box("Brick", Vector3(p.x, 2.1, p.y) + out * 0.12, Vector3(0.5, 4.2, 4.4), basis)
			U.opening(lm, "Wood", Vector3(p.x, 0.0, p.y) + out * 0.42, out, 1.9, 3.0, true)

## Guns on wooden carriages behind the parapet.
static func _guns(lm: LandmarkMesh, star: PackedVector2Array) -> void:
	for i in star.size():
		if i % 2 != 0:
			continue
		var tip := star[i]
		if tip.y < 0.0:
			continue
		var dir := Vector2(tip.x, tip.y).normalized()
		var base2 := tip - dir * 5.0
		var ang := atan2(dir.x, dir.y)
		var b := Basis(Vector3.UP, ang)
		var y := WALL + 0.95
		lm.box("Wood", Vector3(base2.x, y + 0.35, base2.y), Vector3(1.5, 0.6, 2.4), b)
		for s in [-1.0, 1.0]:
			lm.frustum("Wood", Vector3(base2.x + cos(ang) * s * 0.85, y, base2.y - sin(ang) * s * 0.85), 0.5, 0.5, 0.18, 8)
		var p0 := Vector3(base2.x, y + 1.0, base2.y)
		var p1 := p0 + b * Vector3(0, 0.25, 3.3)
		lm.beam("Iron", p0, p1, 0.5, 0.5)
		lm.frustum("Iron", Vector3(p1.x, p1.y - 0.25, p1.z), 0.3, 0.3, 0.5, 8)
