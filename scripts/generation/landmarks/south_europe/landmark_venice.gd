class_name SEuVenice
extends RefCounted

## St Mark's Campanile and the Doge's Palace in true metres.

# --- Campanile ----------------------------------------------------------

## Origin at the centre of the 12 m square base. The red-brick shaft
## (50 m, panelled with tall recessed arches) carries the white Istrian
## stone belfry with its four arched openings, the attic with the winged
## lions, the green copper pyramid and the gilded Archangel Gabriel
## weathervane, 98.6 m in all; Sansovino's marble Loggetta leans on the
## base toward the basilica (+Z).
static func campanile(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#B3503A", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#E7E0D0", 2.5))
	lm.use("Shadow", LandmarkMaterials.pbr("brick", "#6B2E22", 2.5))
	lm.use("Copper", LandmarkMaterials.paint("#6E9F8B", 0.5, 0.55))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#D8B9A0", 2.0))
	lm.box("Stone", Vector3(0, -1.5, 0), Vector3(13.0, 3.0, 13.0))
	lm.box("Brick", Vector3(0, 25.0, 0), Vector3(12.0, 50.0, 12.0))
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		SEuUtil.face_row(lm, "Shadow", out * 6.0, right, out, 14.0, 3, 3.6, 2.2, 28.0)
		lm.box("Stone", out * 6.1 + Vector3(0, 4.2, 0), Vector3(12.8, 0.6, 0.4), r)
		lm.box("Stone", out * 6.1 + Vector3(0, 44.0, 0), Vector3(12.8, 0.6, 0.4), r)
		# Belfry: arched opening between corner piers.
		SEuUtil.face_row(lm, "Shadow", out * 5.3, right, out, 52.0, 1, 4.0, 5.2, 7.6)
		lm.box("Stone", out * 5.2 + right * 4.6 + Vector3(0, 56.0, 0), Vector3(1.4, 11.6, 1.4), r)
		lm.box("Stone", out * 5.2 - right * 4.6 + Vector3(0, 56.0, 0), Vector3(1.4, 11.6, 1.4), r)
		# Attic: relief panel and a winged lion on each corner cornice.
		SEuUtil.face_row(lm, "Shadow", out * 4.6, right, out, 64.0, 1, 4.0, 3.0, 3.6)
		lm.box("Gold", out * 5.2 + right * 3.6 + Vector3(0, 63.4, 0), Vector3(1.0, 1.4, 1.6), r)
	lm.box("Stone", Vector3(0, 56.0, 0), Vector3(10.6, 11.6, 10.6))
	lm.box("Stone", Vector3(0, 62.0, 0), Vector3(12.0, 1.0, 12.0))
	lm.box("Stone", Vector3(0, 65.2, 0), Vector3(9.6, 5.4, 9.6))
	lm.box("Stone", Vector3(0, 69.0, 0), Vector3(11.4, 1.4, 11.4))
	lm.spire("Copper", Vector3(0, 69.7, 0), 5.2, 23.8, 0.12)
	lm.frustum("Gold", Vector3(0, 93.5, 0), 0.5, 0.35, 0.8, 8)
	LandmarkKits.statue_figure(lm, "Gold", Vector3(0, 94.3, 0), 4.3, true)
	lm.box("Gold", Vector3(0, 97.0, 0), Vector3(3.2, 0.2, 0.8), Basis(Vector3.UP, 0.6))
	# Loggetta: three arches and a balustrade.
	lm.box("Marble", Vector3(0, 3.4, 10.5), Vector3(17.0, 6.8, 6.0))
	SEuUtil.face_row(lm, "Shadow", Vector3(0, 0, 13.5), Vector3.RIGHT, Vector3(0, 0, 1), 0.2, 3, 4.6, 2.8, 4.6)
	lm.box("Stone", Vector3(0, 7.2, 10.5), Vector3(17.6, 0.8, 6.6))
	lm.commit(model)

# --- Doge's Palace ------------------------------------------------------

const WALL_TOP := 25.5

## Palazzo Ducale around its courtyard, origin at the centre, lagoon
## front (the Molo) facing +Z: the two-tier Gothic arcade of pointed
## arches on the ground and first floor, the great wall of white and
## pink Verona marble diamonds above with its tall windows, the
## pierced crest along the roof edge.
static func doge(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Arcade", LandmarkMaterials.pbr("limestone", "#E9E2D2", 3.0))
	lm.use("Rose", LandmarkMaterials.pbr("limestone", "#E0BDAC", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#F5F0E6", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A433A", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#7B7F80", 2.0))
	var hx := 36.0
	var hz := 33.0
	var t := 15.0
	lm.box("Arcade", Vector3(0, 6.5, hz - t * 0.5), Vector3(hx * 2.0, 13.0, t))
	lm.box("Arcade", Vector3(0, 6.5, -hz + t * 0.5), Vector3(hx * 2.0, 13.0, t))
	lm.box("Arcade", Vector3(hx - t * 0.5, 6.5, 0), Vector3(t, 13.0, (hz - t) * 2.0))
	lm.box("Arcade", Vector3(-hx + t * 0.5, 6.5, 0), Vector3(t, 13.0, (hz - t) * 2.0))
	lm.box("Rose", Vector3(0, 19.25, hz - t * 0.5), Vector3(hx * 2.0 - 0.2, 12.5, t - 0.2))
	lm.box("Rose", Vector3(0, 19.25, -hz + t * 0.5), Vector3(hx * 2.0 - 0.2, 12.5, t - 0.2))
	lm.box("Rose", Vector3(hx - t * 0.5, 19.25, 0), Vector3(t - 0.2, 12.5, (hz - t) * 2.0))
	lm.box("Rose", Vector3(-hx + t * 0.5, 19.25, 0), Vector3(t - 0.2, 12.5, (hz - t) * 2.0))
	lm.box("Roof", Vector3(0, WALL_TOP + 0.3, hz - t * 0.5), Vector3(hx * 2.0 - 1.0, 0.6, t - 1.0))
	lm.box("Roof", Vector3(0, WALL_TOP + 0.3, -hz + t * 0.5), Vector3(hx * 2.0 - 1.0, 0.6, t - 1.0))
	lm.box("Roof", Vector3(hx - t * 0.5, WALL_TOP + 0.3, 0), Vector3(t - 1.0, 0.6, (hz - t) * 2.0))
	lm.box("Roof", Vector3(-hx + t * 0.5, WALL_TOP + 0.3, 0), Vector3(t - 1.0, 0.6, (hz - t) * 2.0))
	for side in 4:
		var out := Vector3(0, 0, 1)
		var length := hx * 2.0
		var dist := hz
		if side == 1:
			out = Vector3(0, 0, -1)
		elif side >= 2:
			out = Vector3(1.0 if side == 2 else -1.0, 0, 0)
			length = hz * 2.0
			dist = hx
		_facade(lm, out, length, dist, side < 2)
	lm.commit(model)

## One outer face: arcade, loggia, diamond lattice, windows, crest.
static func _facade(lm: LandmarkMesh, out: Vector3, length: float, dist: float, long_side: bool) -> void:
	var right := Vector3.UP.cross(out)
	var p := out * dist
	var basis := Basis(Vector3.UP, atan2(out.x, out.z))
	var n1 := 17 if long_side else 15
	SEuUtil.face_row(lm, "Shadow", p, right, out, 0.3, n1, length / float(n1), 2.0, 5.6, true)
	lm.box("Trim", p + Vector3(0, 6.6, 0) + out * 0.35, Vector3(length + 0.6, 0.5, 0.9), basis)
	var n2 := n1 * 2
	SEuUtil.face_row(lm, "Shadow", p, right, out, 7.2, n2, length / float(n2), 1.3, 4.9, true)
	lm.box("Trim", p + Vector3(0, 13.0, 0) + out * 0.4, Vector3(length + 0.8, 0.7, 1.0), basis)
	var cells := int(length / 6.0)
	var step := length / float(cells)
	for i in cells:
		var x0 := -length * 0.5 + step * float(i)
		var a0 := p + right * x0 + Vector3(0, 13.4, 0) + out * 0.02
		var a1 := p + right * (x0 + step) + Vector3(0, 13.4, 0) + out * 0.02
		lm.lattice_panel("Trim", a0, a1, a0 + Vector3(0, 12.0, 0), a1 + Vector3(0, 12.0, 0), 0.35, 2, false)
	SEuUtil.face_row(lm, "Shadow", p, right, out, 16.0, 6 if long_side else 5, length / 6.6, 1.9, 6.0, true)
	lm.box("Trim", p + Vector3(0, WALL_TOP, 0) + out * 0.45, Vector3(length + 1.0, 0.8, 1.2), basis)
	var crest := int(length / 3.0)
	for i in crest:
		var x := -length * 0.5 + length * (float(i) + 0.5) / float(crest)
		lm.box("Trim", p + right * x + Vector3(0, WALL_TOP + 1.1, 0) - out * 0.1, Vector3(1.0, 1.4, 0.8), basis)
