class_name StoDjurgRosendal
extends RefCounted

## Rosendals slott (Fredrik Blom for Karl XIV Johan, 1823-27), Empire style.
## Origin at the centroid of OSM way 145662484 (33 x 13.6 m, bearing 103),
## +X along the long axis (registry yaw 13), the entrance front facing +Z.
## Outline (OSM, in this frame): two end pavilions x -16.7..-10 and
## 9.5..16.5 (z -6.8..5.6), the recessed centre z -4.7..5.5, a front loggia
## bay x -4.2..3.6 out to z 6.7 and a rear bay x -3.7..3 to z -5.9.
##
## Spec (visual-plan/refs/landmarks/rosendal/: the elevation photo scaled
## by the 33 m front; the OSM tags say peach plaster and a black metal roof,
## so the brief's "yellow plaster, green copper tent roofs" is wrong; the
## pink round building in front.jpg is the garden pavilion, not the
## palace):
## - Two storeys in smooth peach-pink plaster on a low granite plinth, cream
##   rusticated quoins on every corner, a cream string course between the
##   floors and a cream cornice at 8.1 m, wall top 8.6 m.
## - Ground floor: tall round-headed windows with a moulded hood in the
##   wings and end pavilions, the French doors of the loggia; upper floor:
##   rectangular windows with cream hoods, the three centre ones French
##   windows with segmental pediments over an iron balcony.
## - Front loggia: two free columns and an entablature carrying the balcony,
##   three arched doors behind.
## - End pavilions under pedimented gables with a cream roundel garland;
##   the wings and centre under low hipped dark-grey metal roofs; over the
##   centre a small octagonal lantern with a dome (top 11.5 m).

const EAVE := 8.6
const TOP := 11.8

static func build(model: Node3D) -> void:
	var mats := {
		"Wall": LandmarkMaterials.pbr("render", "#EBC3AE", 3.0),
		"Trim": LandmarkMaterials.pbr("render", "#EDE3CF", 3.0),
		"Stone": LandmarkMaterials.pbr("stone", "#8E877D", 2.5),
		"Frame": LandmarkMaterials.paint("#8A5A33"),
		"Glass": LandmarkMaterials.glass("#20282D"),
		"Roof": LandmarkMaterials.pbr("sheet_metal", "#4D5055", 3.0, 0.5, 0.3),
		"Iron": LandmarkMaterials.paint("#26282B", 0.5, 0.5),
	}
	var lm := LandmarkMesh.new()
	StoChurchKit.use_all(lm, mats)
	_walls(lm)
	_windows(lm, mats)
	_loggia(lm, mats)
	_roofs(lm)
	lm.commit(model)

static func _walls(lm: LandmarkMesh) -> void:
	var pts := PackedVector2Array([Vector2(-16.7, 5.4), Vector2(-4.2, 5.5), Vector2(-4.2, 6.6), Vector2(3.6, 6.7),
		Vector2(3.6, 5.6), Vector2(16.4, 5.7), Vector2(16.5, -6.7), Vector2(9.5, -6.8), Vector2(9.5, -4.6),
		Vector2(3.0, -4.6), Vector2(3.0, -5.8), Vector2(-3.7, -5.8), Vector2(-3.7, -4.7), Vector2(-9.9, -4.7),
		Vector2(-9.9, -6.7), Vector2(-16.5, -6.8)])
	lm.poly_prism("Wall", pts, 0.6, EAVE)
	lm.poly_prism("Stone", pts, 0.0, 0.6)
	# String course and cornice around the main rectangles.
	for r in [Rect2(-16.7, -6.8, 33.2, 12.5), Rect2(-4.2, 5.5, 7.8, 1.2), Rect2(-3.7, -5.8, 6.7, 1.2)]:
		var c := (r as Rect2).get_center()
		var sz := (r as Rect2).size
		lm.box("Trim", Vector3(c.x, 4.7, c.y), Vector3(sz.x + 0.16, 0.3, sz.y + 0.16), Basis(), 0.0)
		lm.box("Trim", Vector3(c.x, EAVE - 0.4, c.y), Vector3(sz.x + 0.6, 0.8, sz.y + 0.6), Basis(), 0.0)
	# Rusticated quoins on the pavilion corners: [x, direction into the wall, front too].
	for q in [[-16.7, 1.0, true], [-9.9, -1.0, false], [9.5, 1.0, false], [16.5, -1.0, true]]:
		var zs := [-6.75, 5.5] if bool(q[2]) else [-6.75]
		for cz in zs:
			for i in 8:
				var w := 0.95 if i % 2 == 0 else 0.6
				lm.box("Trim", Vector3(float(q[0]) + float(q[1]) * w * 0.5, 1.1 + float(i) * 0.95, float(cz)),
					Vector3(w, 0.8, 0.16 if i % 2 == 0 else 0.12), Basis(), 0.0)

static func _windows(lm: LandmarkMesh, mats: Dictionary) -> void:
	var arch := StoDjurgKit.unit(mats, 1.25, 3.2, true, 0.22, "Frame")
	var up := StoDjurgKit.unit(mats, 1.15, 2.2, false, 0.22, "Frame")
	for x in [-14.2, -12.0, -7.8, -5.6, 5.0, 7.3, 11.7, 14.2]:
		_bay(lm, arch, up, Vector3(float(x), 0, (5.5 if x < 0.0 else 5.7) if absf(float(x)) > 4.4 else 6.7), Vector3(0, 0, 1))
	for x in [-14.2, -12.0, -7.0, 7.0, 12.0, 14.2]:
		var z := -6.75 if absf(float(x)) > 10.0 else (-4.7 if x < 0.0 else -4.6)
		_bay(lm, arch, up, Vector3(float(x), 0, z), Vector3(0, 0, -1))
	for z in [-3.2, 1.0]:
		_bay(lm, arch, up, Vector3(16.5, 0, float(z)), Vector3.RIGHT)
		_bay(lm, arch, up, Vector3(-16.7, 0, float(z)), Vector3.LEFT)

static func _bay(lm: LandmarkMesh, arch: LandmarkMesh, up: LandmarkMesh, base: Vector3, out: Vector3) -> void:
	StoChurchKit.place(lm, arch, base + Vector3(0, 1.0, 0), out)
	StoChurchKit.place(lm, up, base + Vector3(0, 5.4, 0), out)

## Two free columns, entablature and balcony over the three arched doors.
static func _loggia(lm: LandmarkMesh, mats: Dictionary) -> void:
	var zf := 7.7
	for x in [-1.6, 1.6]:
		lm.frustum("Trim", Vector3(float(x), 0.6, zf), 0.42, 0.34, 4.2, 12)
		lm.box("Trim", Vector3(float(x), 0.7, zf), Vector3(1.0, 0.3, 1.0), Basis(), 0.0)
		lm.box("Trim", Vector3(float(x), 4.95, zf), Vector3(0.95, 0.2, 0.95), Basis(), 0.0)
	lm.box("Trim", Vector3(0, 5.35, 7.2), Vector3(7.8, 0.7, 2.2), Basis(), 0.0)
	var door := StoDjurgKit.unit(mats, 1.3, 3.4, true, 0.2, "Frame")
	var french := StoDjurgKit.unit(mats, 1.2, 2.5, false, 0.2, "Frame")
	for x in [-2.5, 0.0, 2.5]:
		StoChurchKit.place(lm, door, Vector3(float(x), 0.8, 6.7), Vector3(0, 0, 1))
		StoChurchKit.place(lm, french, Vector3(float(x), 5.6, 6.7), Vector3(0, 0, 1))
		lm.gable("Trim", Vector3(float(x), 8.3, 6.8), 1.7, 0.3, 0.4, Basis(Vector3.UP, PI * 0.5), 0.05, "Trim")
	StoDjurgKit.railing(lm, [Vector3(-3.9, 0, 8.3), Vector3(3.9, 0, 8.3), Vector3(3.9, 0, 6.9), Vector3(-3.9, 0, 6.9)],
		5.7, 0.95, 0.5, "Iron")

static func _roofs(lm: LandmarkMesh) -> void:
	# Centre and wings: low hipped dark roofs.
	LandmarkFhUtil.hip(lm, "Roof", Vector3(0, EAVE, -0.1), 20.4, 11.6, 1.2, 0.3)
	# End pavilions: pedimented gables, ridge along Z.
	for cx in [-13.3, 13.0]:
		lm.gable("Roof", Vector3(float(cx), EAVE, -0.6), 6.8, 12.6, 1.7, Basis(), 0.35, "Trim")
		lm.box("Trim", Vector3(float(cx), EAVE + 0.5, 5.9), Vector3(6.8, 0.25, 0.3), Basis(), 0.0)
		lm.disc("Trim", Vector3(float(cx), EAVE + 0.75, 5.95), Vector3.BACK, 0.42, 14)
	# Octagonal lantern with a dome over the centre.
	var y0 := EAVE + 1.2
	lm.frustum("Trim", Vector3(0, y0 - 0.2, 0), 1.75, 1.75, 0.9, 8, PI / 8.0)
	lm.lathe("Roof", Vector3(0, y0 + 0.7, 0), PackedVector2Array([
		Vector2(1.95, 0.0), Vector2(1.7, 0.35), Vector2(1.0, 0.7), Vector2(0.0, 0.9)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.beam("Iron", Vector3(0, y0 + 1.6, 0), Vector3(0, TOP, 0), 0.08, 0.08)
