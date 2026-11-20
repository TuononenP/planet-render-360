class_name StoDjurgLiljevalchs
extends RefCounted

## Liljevalchs konsthall on Djurgårdsvägen (Carl Bergsten, 1913-16). Origin
## at the centroid of OSM way 33114705 (58.6 x 32.6 m, bearing 156.8), +X
## along the long axis (registry yaw 66.8). Footprint: a rectangle with the
## small notch of the OSM outline at the +X/+Z corner.
##
## Spec (visual-plan/refs/landmarks/liljevalchs/front.jpg, an end-on corner
## view scaled by the 32.6 m end width; the OSM tags say darksalmon plaster
## and a copper roof, so the brief's "pale-yellow neoclassical" is wrong):
## - A tall rectangular hall in terracotta-pink plaster on a low stone
##   plinth, wall top 16.8 m.
## - Flat pale-grey pilaster strips (1 m wide, slightly proud) dividing
##   every face into bays: the 24.6 m end faces into a narrow bay and two
##   wide bays, the long sides into five equal bays.
## - Under the cornice in every bay a clerestory band of tall dark-red
##   framed windows (4.2 m high, several panes wide), a cream sill band
##   below them and a cream cornice with a parapet above.
## - On the +X end face a cream portal with a pedimented hood over an arched
##   door, and a five-step flight; the wall below the windows is blank.
## - A low copper hipped roof behind the parapet and two brick chimneys.
## Height: derived (levels tag 5 x 4 m was too high; 16.8 m scaled from the
## photo, unverified).

const X0 := -28.8
const X1 := 29.8
const Z0 := -16.1
const Z1 := 16.1
const NOTCH_X := 25.1
const NOTCH_Z := 8.5
const WALL := 16.8
const TOP := 19.0

static func build(model: Node3D) -> void:
	var mats := {
		"Wall": LandmarkMaterials.pbr("render", "#C98672", 3.0),
		"Trim": LandmarkMaterials.pbr("render", "#D8CDB6", 3.0),
		"Stone": LandmarkMaterials.pbr("stone", "#7E776D", 2.5),
		"Frame": LandmarkMaterials.paint("#6C3A36"),
		"Glass": LandmarkMaterials.glass("#20282D"),
		"Copper": LandmarkMaterials.pbr("copper", "#56776A", 3.0, 0.5, 0.3),
		"Brick": LandmarkMaterials.pbr("brick", "#9C6B55", 2.4),
		"Door": LandmarkMaterials.paint("#5A2F2C"),
	}
	var lm := LandmarkMesh.new()
	StoChurchKit.use_all(lm, mats)
	_mass(lm)
	var win := StoDjurgKit.unit(mats, 2.4, 4.2, false, 0.3)
	_face(lm, win, Vector3(X0, 0, Z0), Vector3(X1, 0, Z0), Vector3(0, 0, -1), 5)
	_face(lm, win, Vector3(NOTCH_X, 0, Z1), Vector3(X0, 0, Z1), Vector3(0, 0, 1), 5)
	_face(lm, win, Vector3(X1, 0, Z0), Vector3(X1, 0, NOTCH_Z), Vector3.RIGHT, 3, true)
	_face(lm, win, Vector3(X0, 0, Z1), Vector3(X0, 0, Z0), Vector3.LEFT, 3)
	_face(lm, win, Vector3(NOTCH_X, 0, NOTCH_Z), Vector3(NOTCH_X, 0, Z1), Vector3.RIGHT, 1)
	_face(lm, win, Vector3(X1, 0, NOTCH_Z), Vector3(NOTCH_X, 0, NOTCH_Z), Vector3(0, 0, 1), 1)
	_roof(lm)
	_portal(lm, mats)
	lm.commit(model)

static func _mass(lm: LandmarkMesh) -> void:
	var pts := PackedVector2Array([Vector2(X0, Z0), Vector2(X1, Z0), Vector2(X1, NOTCH_Z),
		Vector2(NOTCH_X, NOTCH_Z), Vector2(NOTCH_X, Z1), Vector2(X0, Z1)])
	lm.poly_prism("Wall", pts, 1.0, WALL)
	# Plinth, cornice and parapet course: boxes over the two rectangles of the outline.
	for r in [Rect2(X0, Z0, NOTCH_X - X0, Z1 - Z0), Rect2(NOTCH_X, Z0, X1 - NOTCH_X, NOTCH_Z - Z0)]:
		var c := (r as Rect2).get_center()
		var sz := (r as Rect2).size
		lm.box("Stone", Vector3(c.x, 0.5, c.y), Vector3(sz.x + 0.5, 1.0, sz.y + 0.5), Basis(), 0.0)
		lm.box("Trim", Vector3(c.x, WALL - 0.95, c.y), Vector3(sz.x + 1.1, 1.1, sz.y + 1.1), Basis(), 0.0)
		lm.box("Trim", Vector3(c.x, WALL - 0.12, c.y), Vector3(sz.x + 0.5, 0.55, sz.y + 0.5), Basis(), 0.0)

## Pilaster strips, window band, sill band along a face a..b facing `out`.
static func _face(lm: LandmarkMesh, win: LandmarkMesh, a: Vector3, b: Vector3, out: Vector3, bays: int,
		wide_centre: bool = false) -> void:
	var len := a.distance_to(b)
	var dir := (b - a) / len
	var basis := Basis(dir, Vector3.UP, out)
	var widths := []
	if wide_centre:
		widths = [0.22, 0.39, 0.39]
	else:
		for i in bays:
			widths.append(1.0 / float(bays))
	var t := 0.0
	var edges := [0.0]
	for w in widths:
		t += float(w)
		edges.append(t)
	for e in edges:
		var p := a + dir * len * float(e)
		if float(e) < 0.001:
			p += dir * 0.5
		elif float(e) > 0.999:
			p -= dir * 0.5
		lm.box("Trim", p + out * 0.12 + Vector3(0, (1.0 + WALL - 0.5) * 0.5, 0),
			Vector3(1.0, WALL - 1.5, 0.28), basis, 0.0)
	lm.box("Trim", a.lerp(b, 0.5) + out * 0.08 + Vector3(0, 9.55, 0), Vector3(len, 0.45, 0.2), basis, 0.0)
	for k in bays:
		var bw := float(widths[k]) * len
		var p0 := a + dir * len * float(edges[k])
		var p1 := a + dir * len * float(edges[k + 1])
		var n := maxi(int((bw - 1.4) / 2.9), 1)
		for i in n:
			var p := p0.lerp(p1, (float(i) + 0.5) / float(n))
			StoChurchKit.place(lm, win, Vector3(p.x, 10.0, p.z), out)

static func _roof(lm: LandmarkMesh) -> void:
	var cx := (X0 + X1) * 0.5
	LandmarkFhUtil.hip(lm, "Copper", Vector3(cx, WALL, 0), X1 - X0 + 0.2, Z1 - Z0 + 0.2, 1.2, 0.4)
	for p in [Vector2(X0 + 2.0, Z0 + 2.0), Vector2(X1 - 2.5, Z0 + 2.0)]:
		lm.box("Brick", Vector3(p.x, WALL + 1.1, p.y), Vector3(1.4, 2.2, 1.4), Basis(), 0.0)
		lm.box("Trim", Vector3(p.x, WALL + 2.3, p.y), Vector3(1.7, 0.2, 1.7), Basis(), 0.0)

## The cream portal on the +X end: pilasters, pedimented hood, arched door, steps.
static func _portal(lm: LandmarkMesh, mats: Dictionary) -> void:
	var zc := Z0 + (NOTCH_Z - Z0) * 0.61
	var x := X1
	for s in [-1.0, 1.0]:
		lm.box("Trim", Vector3(x + 0.25, 3.2, zc + float(s) * 1.7), Vector3(0.5, 6.0, 0.7), Basis(), 0.0)
	lm.box("Trim", Vector3(x + 0.3, 6.4, zc), Vector3(0.6, 0.8, 4.2), Basis(), 0.0)
	lm.gable("Trim", Vector3(x + 0.3, 6.8, zc), 3.6, 0.8, 0.9, Basis(Vector3.UP, PI * 0.5), 0.2, "Trim")
	var door := LandmarkMesh.new()
	StoChurchKit.use_all(door, mats)
	LandmarkDetail.window(door, "Door", "Glass", Vector3(0, 2.6, 0), Vector3.BACK, 2.0, 5.0, true, 0.3)
	StoChurchKit.place(lm, door, Vector3(x + 0.08, 0.6, zc), Vector3.RIGHT)
	LandmarkFhUtil.steps(lm, "Stone", Vector3(x + 0.5, 0.0, zc), Vector3.RIGHT, 4.2, 0.45, 0.14, 4)
