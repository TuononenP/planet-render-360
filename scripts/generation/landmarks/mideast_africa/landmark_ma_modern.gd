class_name LandmarkMaModern
extends RefCounted

## Two modern icons in true metres: Tehran's Azadi Tower and the
## Museum of the Future in Dubai.

# --- Azadi Tower ---

## Leg centre offset and half-width at height y: four marble legs lean
## together from a 63 m base to the capstone.
static func _azadi_leg(y: float) -> Vector2:
	var t := clampf(y / 33.0, 0.0, 1.0)
	return Vector2(lerpf(21.0, 7.0, t), lerpf(7.5, 5.5, t))

## 45 m white-marble gateway: four inclined legs joined by pointed arch
## infill on every side (the arch opens 22 m at the base and closes at
## 26 m), a capstone and a turquoise-tiled crown, on its plinth.
static func azadi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EDEBE4", 5.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#2E8C98", 3.0))
	lm.use("Plaza", LandmarkMaterials.pbr("pavement", "#CFC6B2", 6.0))
	lm.box("Plaza", Vector3(0, -1.0, 0), Vector3(110, 2, 110))
	lm.box("Marble", Vector3(0, 0.75, 0), Vector3(66, 1.5, 66))
	var slices := 11
	for k in slices:
		var y0 := 33.0 * k / slices
		var y1 := 33.0 * (k + 1) / slices
		var ym := (y0 + y1) * 0.5
		var leg := _azadi_leg(ym)
		var inner := leg.x - leg.y
		var arch := 11.0 * pow(maxf(1.0 - ym / 26.0, 0.0), 0.65)
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				lm.box("Marble", Vector3(sx * leg.x, ym, sz * leg.x),
					Vector3(leg.y * 2.0, y1 - y0, leg.y * 2.0))
			if inner > arch:
				var w := inner - arch
				for side in [-1.0, 1.0]:
					var o: float = side * (arch + w * 0.5)
					lm.box("Marble", Vector3(o, ym, sx * leg.x), Vector3(w, y1 - y0, leg.y * 2.0))
					lm.box("Marble", Vector3(sx * leg.x, ym, o), Vector3(leg.y * 2.0, y1 - y0, w))
	lm.box("Marble", Vector3(0, 37, 0), Vector3(24, 8, 24))
	lm.box("Tile", Vector3(0, 41.5, 0), Vector3(21, 1, 21))
	lm.spire("Tile", Vector3(0, 42, 0), 9.0, 3.0, 0.0)
	lm.commit(model)

# --- Museum of the Future ---

const MOF_OUTER := Vector2(39.0, 37.0)
const MOF_INNER := Vector2(17.0, 21.0)
const MOF_CENTER_Y := 40.0
const MOF_HALF_DEPTH := 24.0

## Point of the torus at ring angle th and tube angle phi: between the
## outer and inner ellipse, with a rounded (super-elliptic) tube
## cross-section MOF_HALF_DEPTH deep either side of the mid-plane.
static func _mof_point(th: float, phi: float) -> Vector3:
	var o := Vector2(MOF_OUTER.x * cos(th), MOF_OUTER.y * sin(th))
	var i := Vector2(MOF_INNER.x * cos(th), MOF_INNER.y * sin(th))
	var c := (o + i) * 0.5
	var d := (o - i) * 0.5
	var cp := cos(phi)
	var sp := sin(phi)
	var cq := signf(cp) * pow(absf(cp), 0.7)
	var sq := signf(sp) * pow(absf(sp), 0.7)
	return Vector3(c.x + d.x * cq, MOF_CENTER_Y + c.y + d.y * cq, MOF_HALF_DEPTH * sq)

## 77 m torus of stainless steel standing on its landscaped mound: an
## elliptical ring (78 m wide) round a vertical oval void, its facade
## ribboned with Arabic-calligraphy windows.
static func museum_of_the_future(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Steel", LandmarkMaterials.paint("#C8CDD0", 0.28, 0.85))
	lm.use("Glass", LandmarkMaterials.lit("#BFD3DC", 0.25))
	lm.use("Mound", LandmarkMaterials.pbr("grass", "#6E8A4E", 8.0))
	lm.use("Plaza", LandmarkMaterials.pbr("pavement", "#CFC6B2", 6.0))
	lm.box("Plaza", Vector3(0, -1.0, 0), Vector3(150, 2, 110))
	lm.lathe("Mound", Vector3(0, -4, 0), PackedVector2Array([Vector2(62, 0), Vector2(55, 4),
		Vector2(40, 9), Vector2(25, 13), Vector2(0, 16)]), 28)
	var n_th := 64
	var n_ph := 20
	var rows: Array = []
	for j in n_th + 1:
		var row := PackedVector3Array()
		for k in n_ph + 1:
			row.append(_mof_point(TAU * j / n_th, -TAU * k / n_ph))
		rows.append(row)
	lm.grid("Steel", rows)
	# Calligraphy windows: bands of glass on both broad faces.
	for b in 14:
		var th0 := TAU * b / 14.0 + 0.05
		for face in [1.0, -1.0]:
			var wrows: Array = []
			for j in 7:
				var wrow := PackedVector3Array()
				for k in 5:
					var phi := deg_to_rad(120.0 - 15.0 * k) if face > 0.0 \
						else deg_to_rad(300.0 - 15.0 * k)
					var p := _mof_point(th0 + 0.22 * j / 6.0, phi)
					wrow.append(p + Vector3(0, 0, 0.35 * signf(p.z)))
				wrows.append(wrow)
			lm.grid("Glass", wrows, Vector3(0, 0, face))
	lm.commit(model)
