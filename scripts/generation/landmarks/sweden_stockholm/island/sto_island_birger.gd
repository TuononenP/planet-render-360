class_name StoIslandBirger
extends RefCounted

## Birger Jarls torn on Riddarholmen (a 1530s cannon tower, round, 14.4 m
## across, OSM way 34590001: 19.5 m, four levels, dome roof). Origin at its
## centre. From visual-plan/refs/landmarks/birger_jarls_torn/:
## - A rubble granite foot 2.4 m high, then a whitewashed (pale pink-white)
##   plastered drum, slightly battered, up to a rounded cornice.
## - Three tiers of small rectangular windows in stone-grey reveals on the
##   cardinal faces (one larger window with two slits beside it) and shallow
##   blind rectangular panels between them; a barred window low down.
## - Under the cornice a frieze of twelve round portholes, each with a
##   brown-gold shutter swung open beside it.
## - A shallow verdigris copper dome with a ball and a thin vane.
## Surfaces (5): Render, Granite, Copper, Windows, Shutter.

const R := 7.2
const CORNICE_Y := 14.4
const TOP_M := 19.5

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Render", LandmarkMaterials.pbr("render", "#E2D3C6", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("rock", "#837E78", 3.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#5F8573", 2.0, 0.55, 0.3))
	lm.use("Windows", LandmarkMaterials.glass("#1E2427"))
	lm.use("Shutter", LandmarkMaterials.paint("#8C6A36", 0.7, 0.2))
	_drum(lm)
	_windows(lm)
	_frieze(lm)
	_dome(lm)
	lm.commit(model)

static func _drum(lm: LandmarkMesh) -> void:
	# Rubble foot: a rough lathe with a ring of boulders.
	lm.lathe("Granite", Vector3.ZERO, PackedVector2Array([Vector2(8.0, 0.0), Vector2(7.9, 1.0), Vector2(7.5, 2.4)]), 24,
		1.0, 1.0, 0.0, true, false)
	for k in 22:
		var a := TAU * float(k) / 22.0
		var s := 0.9 + 0.5 * absf(sin(float(k) * 2.3))
		lm.box("Granite", Vector3(cos(a) * 7.7, 0.55 * s, sin(a) * 7.7), Vector3(1.9 * s, 1.1 * s, 1.6 * s),
			Basis(Vector3.UP, -a + PI * 0.5), 0.0)
	lm.lathe("Render", Vector3(0, 2.2, 0), PackedVector2Array([Vector2(7.4, 0.0), Vector2(7.2, 12.2)]), 28)
	# Two plain string courses on the drum, then the rounded cornice.
	for y in [10.6, 13.0]:
		lm.lathe("Render", Vector3(0, y, 0), PackedVector2Array([Vector2(7.2, 0.0), Vector2(7.45, 0.1), Vector2(7.45, 0.3),
			Vector2(7.2, 0.4)]), 28, 1.0, 1.0, 0.0, true, false)
	lm.lathe("Render", Vector3(0, CORNICE_Y, 0), PackedVector2Array([Vector2(7.2, 0.0), Vector2(8.2, 0.2), Vector2(8.3, 0.7),
		Vector2(8.0, 1.2), Vector2(7.6, 1.4)]), 28)

## Three tiers of windows and blind panels on the four faces, the barred one low down.
static func _windows(lm: LandmarkMesh) -> void:
	var tiers := [[4.2, 0.9], [8.2, 1.0], [11.9, 1.0]]
	for t in tiers:
		var y: float = t[0]
		for q in 4:
			var a := TAU * float(q) / 4.0 + 0.35
			_pane(lm, a, y, 1.0, 1.7, "Windows")
			for s in [-1.0, 1.0]:
				_pane(lm, a + float(s) * 0.72, y - 0.2, 0.45, 1.5, "Windows")
				_pane(lm, a + float(s) * 0.33, y + 0.1, 1.1, 1.9, "Render")
	_pane(lm, 0.35, 2.9, 1.5, 1.0, "Windows")

## A flat rectangular opening (or blind panel) on the drum at azimuth `a`.
static func _pane(lm: LandmarkMesh, a: float, y: float, w: float, h: float, key: String) -> void:
	var r := 7.3 - 0.2 * (y - 2.2) / 12.0
	var b := Basis(Vector3.UP, -a + PI * 0.5)
	var c := Vector3(cos(a) * r, y + h * 0.5, sin(a) * r)
	if key == "Render":
		lm.box("Granite", c + b * Vector3(0, 0, 0.03), Vector3(w + 0.16, h + 0.16, 0.04), b, 0.0)
		lm.box("Render", c + b * Vector3(0, 0, 0.06), Vector3(w, h, 0.05), b, 0.0)
		return
	lm.box("Granite", c + b * Vector3(0, 0, 0.04), Vector3(w + 0.3, h + 0.3, 0.06), b, 0.0)
	lm.box("Windows", c + b * Vector3(0, 0, 0.09), Vector3(w, h, 0.05), b, 0.0)

## Twelve portholes under the cornice, each with its open shutter.
static func _frieze(lm: LandmarkMesh) -> void:
	for k in 12:
		var a := TAU * (float(k) + 0.5) / 12.0
		var b := Basis(Vector3.UP, -a + PI * 0.5)
		var c := Vector3(cos(a) * 7.25, 13.75, sin(a) * 7.25)
		lm.disc("Windows", c + b * Vector3(0, 0, 0.08), b * Vector3.BACK, 0.38, 12)
		var sc := c + b * Vector3(0.9, 0, 0.12)
		lm.disc("Shutter", sc, b * Vector3.BACK, 0.42, 12)

static func _dome(lm: LandmarkMesh) -> void:
	var y := CORNICE_Y + 1.4
	lm.lathe("Copper", Vector3(0, y, 0), LandmarkCoreBArchKit.dome(7.7, 3.2, 10), 28, 1.0, 1.0, 0.0, true, false)
	lm.lathe("Copper", Vector3(0, y + 3.1, 0), PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.35, 0.12),
		Vector2(0.3, 0.3), Vector2(0.0, 0.4)]), 10)
	lm.frustum("Copper", Vector3(0, y + 3.5, 0), 0.05, 0.02, TOP_M - (y + 3.5), 4)
