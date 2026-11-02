class_name SEuIberia
extends RefCounted

## The Giralda, the Belém Tower and the Guggenheim Museum Bilbao in true
## metres.

# --- Giralda --------------------------------------------------------------

## Seville's bell tower, origin at the centre of its 13.6 m base. The
## Almohad minaret shaft (70 m of ochre brick with sebka recesses and
## horseshoe windows), the Renaissance belfry of three stages, the
## lantern dome and the bronze Giraldillo weathervane (104.1 m); the
## cathedral nave spreads to the south-west.
static func giralda(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#CFA97E", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D6C29C", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("brick", "#6E4B36", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#8B8D88", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	var w := 13.6
	lm.box("Brick", Vector3(0, 35.2, 0), Vector3(w, 70.4, w))
	var stages := [[70.4, 80.5, 11.4, 72.2, 3.4, 6.6], [80.5, 90.0, 9.6, 82.0, 2.8, 6.0],
		[90.0, 96.5, 6.2, 91.2, 1.4, 3.8]]
	for st in stages:
		lm.box("Stone", Vector3(0, (float(st[0]) + float(st[1])) * 0.5, 0),
			Vector3(float(st[2]), float(st[1]) - float(st[0]), float(st[2])))
		lm.box("Stone", Vector3(0, float(st[0]) + 0.4, 0), Vector3(float(st[2]) + 1.2, 0.8, float(st[2]) + 1.2))
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		# Sebka panels, bands and windows up the shaft.
		for band in [[8.0, 14.0], [26.0, 14.0], [44.0, 14.0]]:
			SEuUtil.face_row(lm, "Shadow", out * (w * 0.5), right, out, float(band[0]), 2, 4.6, 3.4, float(band[1]), true)
		SEuUtil.face_row(lm, "Shadow", out * (w * 0.5), right, out, 60.0, 3, 3.6, 1.2, 3.6, true)
		lm.box("Stone", out * (w * 0.5 + 0.1) + Vector3(0, 23.0, 0), Vector3(w, 0.5, 0.3), r)
		lm.box("Stone", out * (w * 0.5 + 0.1) + Vector3(0, 41.0, 0), Vector3(w, 0.5, 0.3), r)
		lm.box("Stone", out * (w * 0.5 + 0.1) + Vector3(0, 69.0, 0), Vector3(w, 1.0, 0.3), r)
		for st in stages:
			SEuUtil.face_row(lm, "Shadow", out * (float(st[2]) * 0.5), right, out, float(st[3]), 1, 1.0,
				float(st[4]), float(st[5]), true)
	lm.lathe("Roof", Vector3(0, 96.5, 0), SEuUtil.dome(3.4, 3.7, 6), 12, 1.0, 1.0, PI / 12.0)
	lm.frustum("Gold", Vector3(0, 100.0, 0), 0.5, 0.3, 0.2, 8)
	LandmarkKits.statue_figure(lm, "Gold", Vector3(0, 100.2, 0), 3.9, true)
	# Cathedral: nave under a gabled roof, crossing lantern, buttresses.
	lm.box("Stone", Vector3(-68.4, 17.0, 34.0), Vector3(123.2, 34.0, 82.0))
	lm.box("Stone", Vector3(-68.4, 21.0, 34.0), Vector3(123.2, 42.0, 26.0))
	lm.gable("Roof", Vector3(-68.4, 42.0, 34.0), 26.0, 123.2, 7.0, Basis(Vector3.UP, PI * 0.5), 0.3)
	lm.frustum("Stone", Vector3(-68.4, 40.0, 34.0), 11.0, 11.0, 14.0, 8, PI / 8.0)
	lm.lathe("Roof", Vector3(-68.4, 54.0, 34.0), SEuUtil.dome(11.4, 7.0, 6), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 14:
		var x := -126.0 + 8.8 * float(k)
		lm.box("Stone", Vector3(x, 14.0, 76.0), Vector3(2.0, 28.0, 3.2))
		lm.spire("Stone", Vector3(x, 28.0, 76.0), 0.9, 6.0, 0.0)
	for k in 9:
		var z := 6.0 + 8.6 * float(k)
		lm.box("Stone", Vector3(-132.0, 14.0, z), Vector3(3.2, 28.0, 2.0))
	SEuUtil.face_row(lm, "Shadow", Vector3(-68.4, 0, 75.05), Vector3.RIGHT, Vector3(0, 0, 1), 8.0, 14, 8.8, 2.4, 14.0, true)
	lm.commit(model)

# --- Belem Tower ---------------------------------------------------------

## Torre de Belém: Lioz limestone Manueline fortress on the Tagus, origin
## at the tower's axis, river front facing +Z. A pentagonal bulwark with
## battlements, cannon ports and corner watch-turrets carries the
## four-storey tower with its arcaded loggia, shields, corner turrets
## and crowning merlons, 30 m above the terrace.
static func belem(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Lioz", LandmarkMaterials.pbr("limestone", "#E1D3B2", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#EDE2C6", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#51493D", 2.5))
	lm.use("Dome", LandmarkMaterials.pbr("limestone", "#D2C3A0", 2.0))
	var poly := PackedVector2Array([Vector2(-13.0, -8.0), Vector2(13.0, -8.0), Vector2(15.0, 3.0),
		Vector2(10.5, 11.5), Vector2(0.0, 14.5), Vector2(-10.5, 11.5), Vector2(-15.0, 3.0)])
	lm.poly_prism("Lioz", poly, -4.0, 6.5)
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		SEuUtil.crenels(lm, "Trim", Vector3(p.x, 6.5, p.y), Vector3(q.x, 6.5, q.y), 0.9, 1.3, 1.0)
		var mid := (p + q) * 0.5
		var d := (q - p).normalized()
		var out := Vector3(d.y, 0, -d.x)
		if q.distance_to(p) > 8.0 and (mid.y > 0.0):
			SEuUtil.face_row(lm, "Shadow", Vector3(mid.x, 0, mid.y), Vector3(d.x, 0, d.y), out, 1.8,
				int(q.distance_to(p) / 3.5), 3.5, 1.2, 1.6)
		var a := Vector3(p.x, 6.5, p.y)
		lm.frustum("Lioz", a, 1.2, 1.2, 3.4, 10)
		lm.lathe("Dome", a + Vector3(0, 3.4, 0), SEuUtil.dome(1.5, 1.7, 5), 10)
	lm.box("Lioz", Vector3(0, 16.7, 0), Vector3(11.4, 20.4, 11.4))
	lm.box("Trim", Vector3(0, 27.4, 0), Vector3(12.6, 1.2, 12.6))
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		SEuUtil.face_row(lm, "Shadow", out * 5.7, right, out, 10.5, 3, 3.2, 1.9, 4.6, true)
		SEuUtil.face_row(lm, "Shadow", out * 5.7, right, out, 18.0, 2, 4.4, 1.5, 4.0, true)
		SEuUtil.face_row(lm, "Shadow", out * 5.7, right, out, 23.0, 1, 1.0, 1.2, 2.8, true)
		lm.disc("Trim", out * 5.76 + Vector3(0, 14.8, 0), out, 1.0, 16)
		lm.box("Trim", out * 5.9 + Vector3(0, 9.0, 0), Vector3(11.8, 0.6, 0.5), r)
		lm.box("Trim", out * 5.9 + Vector3(0, 16.5, 0), Vector3(11.8, 0.6, 0.5), r)
		SEuUtil.crenels(lm, "Trim", out * 6.0 - right * 6.0 + Vector3(0, 28.0, 0),
			out * 6.0 + right * 6.0 + Vector3(0, 28.0, 0), 0.8, 1.0, 0.8)
		var corner := (out + right) * 5.9
		lm.frustum("Lioz", corner + Vector3(0, 20.0, 0), 1.3, 1.1, 8.2, 12)
		lm.lathe("Dome", corner + Vector3(0, 28.2, 0), SEuUtil.dome(1.5, 1.8, 5), 12)
	lm.commit(model)

# --- Guggenheim Bilbao ---------------------------------------------------

## Gehry's titanium museum along the Nervión, origin at the centre of
## the atrium, river to the north (-Z). A cluster of five leaning
## titanium towers (the tallest 50 m) over the glazed atrium, the long
## curved gallery wings east and west, limestone-clad rectilinear
## galleries to the south and La Salve bridge with its red portal over
## the west wing.
static func guggenheim(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Ti", LandmarkMaterials.pbr("concrete", "#BDB8A8", 3.0, 0.28, 0.85))
	lm.use("Ti2", LandmarkMaterials.pbr("concrete", "#A9A596", 3.0, 0.3, 0.8))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D9CCB2", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2E3A40"))
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#55565A", 4.0))
	lm.use("Red", LandmarkMaterials.paint("#B8342A", 0.5, 0.4))
	# Atrium towers: (centre, radii, lean).
	var petals := [[Vector3(0, 0, -6), 13.0, 50.0, 17.0, Vector3(0.0, 0, -0.14)],
		[Vector3(12, 0, 8), 10.0, 37.0, 13.0, Vector3(0.22, 0, 0.1)],
		[Vector3(-13, 0, 4), 11.0, 31.0, 12.0, Vector3(-0.2, 0, 0.12)],
		[Vector3(2, 0, -24), 9.0, 27.0, 12.0, Vector3(0.1, 0, -0.2)],
		[Vector3(-4, 0, 24), 12.0, 24.0, 10.0, Vector3(0.1, 0, 0.25)]]
	for i in petals.size():
		var pt: Array = petals[i]
		SEuUtil.blob(lm, "Ti" if i % 2 == 0 else "Ti2", pt[0], float(pt[1]), float(pt[2]),
			float(pt[3]), pt[4], true, 12, 24)
	# Curved gallery wings (west under the bridge, east the "fish").
	_loaf(lm, "Ti", -118.0, -14.0, -2.0, 10.0, 15.0, 13.0, -10.0)
	_loaf(lm, "Ti2", 14.0, 132.0, 6.0, -8.0, 13.0, 17.0, 12.0)
	_loaf(lm, "Ti", -70.0, 70.0, -34.0, -34.0, 12.0, 14.0, 6.0)
	lm.box("Stone", Vector3(30.0, 11.0, 42.0), Vector3(48.0, 22.0, 26.0))
	lm.box("Stone", Vector3(-34.0, 9.0, 52.0), Vector3(36.0, 18.0, 22.0))
	lm.box("Glass", Vector3(0, 12.0, 14.0), Vector3(24.0, 24.0, 2.0))
	SEuUtil.face_row(lm, "Glass", Vector3(30.0, 0, 55.05), Vector3.RIGHT, Vector3(0, 0, 1), 4.0, 4, 11.0, 4.0, 12.0)
	# La Salve bridge over the west wing, red portal at its north end.
	lm.box("Deck", Vector3(-62.0, 16.5, -30.0), Vector3(22.0, 1.2, 120.0))
	for s in [-1.0, 1.0]:
		lm.box("Red", Vector3(-62.0 + s * 11.0, 14.0, -80.0), Vector3(1.4, 28.0, 1.4))
		lm.box("Red", Vector3(-62.0 + s * 11.0, 8.0, 25.0), Vector3(1.4, 16.0, 1.4))
	lm.box("Red", Vector3(-62.0, 27.0, -80.0), Vector3(24.0, 1.6, 1.6))
	lm.box("Red", Vector3(-62.0 + 5.0, 22.0, -80.0), Vector3(1.0, 11.0, 1.0), Basis(Vector3.BACK, 0.5))
	lm.box("Red", Vector3(-62.0 - 5.0, 22.0, -80.0), Vector3(1.0, 11.0, 1.0), Basis(Vector3.BACK, -0.5))
	lm.commit(model)

## A rounded titanium gallery loaf along X: from x0 to x1, its axis
## moving from z0 to z1 with a sideways `bend`, half-width w, height h.
static func _loaf(lm: LandmarkMesh, key: String, x0: float, x1: float, z0: float, z1: float,
		w: float, h: float, bend: float) -> void:
	var rows: Array = []
	var nx := 24
	var nu := 16
	for j in nx + 1:
		var t := float(j) / nx
		var env := pow(sin(PI * t), 0.4)
		var zc := lerpf(z0, z1, t) + bend * sin(PI * t)
		var ww := w * env * (1.0 + 0.18 * sin(t * 7.0))
		var hh := h * env * (1.0 + 0.3 * sin(t * 5.0 + 1.0))
		var row := PackedVector3Array()
		for i in nu + 1:
			var a := PI * float(i) / nu
			var cz := cos(a)
			var sy := sin(a)
			row.append(Vector3(lerpf(x0, x1, t), hh * pow(sy, 0.6), zc + ww * signf(cz) * pow(absf(cz), 0.7)))
		rows.append(row)
	SEuUtil.grid_facing(lm, key, rows, Vector3.UP)
