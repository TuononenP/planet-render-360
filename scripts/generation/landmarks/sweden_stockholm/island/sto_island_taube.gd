class_name StoIslandTaube
extends RefCounted

## Evert Taubes terrass: the granite quay terrace on the west side of
## Riddarholmen by Birger Jarls torg, OSM pedestrian way 26224594 (a long
## strip, 172 x 61 m, running about 164 degrees). Origin at the outline
## centroid, no yaw: +X east, +Z south. From visual-plan/refs/landmarks/
## evert_taubes_terrass/:
## - A granite-paved terrace laid in a grid: bands of pink-grey granite
##   slabs between panels of small-sett cobbles, the quay edge a coping of
##   large granite blocks with bollards, the water-side edge 1.1 m over the
##   water.
## - Broad granite steps climbing along the east side up to the street
##   level of Birger Jarls torg, a dark low guard rail at their foot.
## - Round planters set in rows on the paving, and a row of lamp
##   standards with round opal globes along the east side.
## - The bronze statue of Evert Taube (1890-1976, OSM node at x -27.6,
##   z -31.5 from the centre) on a low granite plinth near the quay edge,
##   built with StatueBuilder's figure and plinth proportions.
## Surfaces (5): Pavers, Setts, Granite, Bronze, Lamp.

const RING := [Vector2(-46.7, 89.1), Vector2(-14.9, -49.6), Vector2(7.9, -64.8), Vector2(15.5, -62.9),
	Vector2(24.6, -60.7), Vector2(26.8, -60.2), Vector2(30.0, -59.1), Vector2(49.6, -52.7), Vector2(40.9, -23.4),
	Vector2(31.4, 9.8), Vector2(13.7, 32.5), Vector2(0.0, 30.5), Vector2(-4.6, 29.5), Vector2(-9.2, 45.2),
	Vector2(-27.0, 83.1), Vector2(-47.3, 98.2)]
const STATUE := Vector2(-27.6, -31.5)
const DECK_Y := 0.5
const TOP_M := 4.6

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Pavers", LandmarkMaterials.pbr("pavement", "#9C8B86", 1.0))
	lm.use("Setts", LandmarkMaterials.pbr("gravel", "#6E6A63", 1.0))
	lm.use("Granite", LandmarkMaterials.pbr("rock", "#8A8782", 2.0))
	lm.use("Bronze", LandmarkMaterials.paint("#4C5A4E", 0.45, 0.5))
	lm.use("Lamp", LandmarkMaterials.lit("#FFF1D6", 0.8))
	var ring := PackedVector2Array()
	for p in RING:
		ring.append(Vector2(p.x, -p.y))
	lm.poly_prism("Setts", ring, 0.0, DECK_Y)
	_coping(lm, ring)
	_grid(lm, ring)
	_steps(lm)
	_planters(lm)
	_lamps(lm)
	_statue(lm)
	lm.commit(model)

## Granite coping round the water-side edges (the first nine ring edges
## are the quay; the east edges are left to the steps).
static func _coping(lm: LandmarkMesh, ring: PackedVector2Array) -> void:
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		if i >= 9 and i <= 11:
			continue
		var d := (b - a)
		var len := d.length()
		var along := Vector3(d.x, 0, d.y) / len
		var basis := Basis(along, Vector3.UP, along.cross(Vector3.UP))
		var mid := (a + b) * 0.5
		lm.box("Granite", Vector3(mid.x, DECK_Y + 0.15, mid.y), Vector3(len, 0.3, 0.9), basis, 0.0)
		var n := int(len / 6.0)
		for k in n + 1:
			var q := a.lerp(b, float(k) / float(maxi(n, 1)))
			lm.frustum("Granite", Vector3(q.x, DECK_Y + 0.3, q.y), 0.22, 0.18, 0.55, 8)

## Paving bands in a grid over the sett field (axes along the terrace),
## laid in 4 m pieces kept only where they lie inside the strip.
static func _grid(lm: LandmarkMesh, ring: PackedVector2Array) -> void:
	var ax := Vector2(sin(deg_to_rad(164.0)), -cos(deg_to_rad(164.0)))
	var cross := Vector2(-ax.y, ax.x)
	var bax := Basis(Vector3(ax.x, 0, ax.y), Vector3.UP, Vector3(ax.x, 0, ax.y).cross(Vector3.UP))
	var bcr := Basis(Vector3(cross.x, 0, cross.y), Vector3.UP, Vector3(cross.x, 0, cross.y).cross(Vector3.UP))
	for k in 5:
		var off := -24.0 + 12.0 * float(k)
		for j in 45:
			var c := cross * off + ax * (-90.0 + 4.0 * float(j)) + Vector2(4.0, 0.0)
			if _inside(ring, c, 2.5):
				lm.box("Pavers", Vector3(c.x, DECK_Y + 0.02, c.y), Vector3(4.0, 0.05, 1.6), bax, 0.0)
	for k in 16:
		var along := -70.0 + 9.0 * float(k)
		for j in 14:
			var c := ax * along + cross * (-28.0 + 4.0 * float(j)) + Vector2(4.0, 0.0)
			if _inside(ring, c, 2.5):
				lm.box("Pavers", Vector3(c.x, DECK_Y + 0.02, c.y), Vector3(4.0, 0.05, 1.6), bcr, 0.0)

## True when `c` and the four points 2.5 m around it lie inside `ring`.
static func _inside(ring: PackedVector2Array, c: Vector2, m: float) -> bool:
	for o in [Vector2.ZERO, Vector2(m, 0), Vector2(-m, 0), Vector2(0, m), Vector2(0, -m)]:
		if not Geometry2D.is_point_in_polygon(c + o, ring):
			return false
	return true

## Wide granite steps along the east side.
static func _steps(lm: LandmarkMesh) -> void:
	var a := Vector2(31.4, -9.8)
	var b := Vector2(13.7, -32.5)
	var d := b - a
	var len := d.length()
	var dir := Vector3(d.x, 0, d.y) / len
	var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP))
	var out := dir.cross(Vector3.UP)
	if out.dot(Vector3(1, 0, -0.2)) < 0.0:
		out = -out
		basis = Basis(dir, Vector3.UP, out)
	var mid := Vector3((a.x + b.x) * 0.5, 0, (a.y + b.y) * 0.5)
	for k in 7:
		var h := 0.5 + 0.17 * float(7 - k)
		lm.box("Granite", mid + out * (0.4 * float(k) + 0.5) + Vector3(0, h * 0.5, 0), Vector3(len, h, 0.4), basis, 0.0)

static func _planters(lm: LandmarkMesh) -> void:
	for row in 3:
		for k in 5:
			var p := Vector3(-6.0 + 5.0 * float(k) + 2.0 * float(row), DECK_Y, 12.0 - 5.0 * float(row) - 4.0 * float(k))
			lm.lathe("Granite", p, PackedVector2Array([Vector2(0.6, 0.0), Vector2(0.7, 0.2), Vector2(0.7, 0.8),
				Vector2(0.55, 0.8)]), 12, 1.0, 1.0, 0.0, true, false)

## A row of lamp standards with round globes inside the east edge.
static func _lamps(lm: LandmarkMesh) -> void:
	for k in 8:
		var p := Vector2(44.0, 46.0).lerp(Vector2(25.0, -8.0), float(k) / 7.0)
		lm.frustum("Bronze", Vector3(p.x, DECK_Y, p.y), 0.09, 0.06, 3.6, 8)
		lm.lathe("Lamp", Vector3(p.x, DECK_Y + 3.6, p.y), PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.28, 0.12),
			Vector2(0.32, 0.35), Vector2(0.2, 0.6), Vector2(0.0, 0.65)]), 10)

## Evert Taube's bronze figure on a low granite plinth by the quay.
static func _statue(lm: LandmarkMesh) -> void:
	var p := Vector3(STATUE.x, DECK_Y, STATUE.y)
	lm.box("Granite", p + Vector3(0, 0.15, 0), Vector3(2.2, 0.3, 2.2), Basis(), 0.0)
	lm.box("Granite", p + Vector3(0, 0.95, 0), Vector3(1.5, 1.3, 1.1))
	LandmarkKits.statue_figure(lm, "Bronze", p + Vector3(0, 1.6, 0), 2.4)
