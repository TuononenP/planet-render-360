extends RefCounted

## national_museum_of_finland. Registry entry and model in one file.

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "national_museum_of_finland", "skyline": true, "name": "National Museum of Finland", "lat": 60.17497, "lon": 24.93177,
	"radius_m": 5000.0, "wiki_title": "National Museum of Finland", "height_m": 64.7, "clear_m": 78.0,
	"yaw_deg": -115.0, "kind": "Museum", "aliases": ["national museum of finland", "kansallismuseo",
		"finlands nationalmuseum"]}

## Top of the granite tower shaft; brick belfry, skirt, upper belfry and spire above.
const SHAFT := 40.5

## From the Commons photos (visual-plan/refs/landmarks/national_museum_of_finland/):
## the roofs are dark brown tile (not green); the tower's granite shaft is
## topped by a red brick belfry, a flared verdigris skirt, a small brick
## stage with two arches and a tall verdigris spire; upper walls of the
## wings are cream render over granite. Measured: the 64.7 m tower top
## (LoD2); the OSM footprint. Estimated: the stage heights (scaled from one
## photo: shaft 40.5 m, brick 5.2 m, skirt 4.6 m, belfry 4.6 m, spire 9.2 m).
##
## Gesellius-Lindgren-Saarinen (1910), origin at the OSM footprint centre,
## front +Z (the registry yaw turns it onto Mannerheimintie): grey
## Uusikaupunki granite and render round two courts, steep hipped roofs
## with gabled dormers, the round stair tower at the rear corner, the
## church-like rear hall, the entrance with Wikström's bear beside its
## steps, and the 58 m tower (7.5 x 9 m) at the front corner: granite
## shaft, arched belfry, and the copper spire with its lucarnes.
static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#6F6F69", 4.0))
	lm.use("Soap", LandmarkMaterials.pbr("limestone", "#9A9380", 3.0))
	lm.use("Copper", LandmarkMaterials.pbr("slate", "#463C37", 2.0))
	lm.use("Verdigris", LandmarkMaterials.pbr("concrete", "#6B9A85", 2.0, 0.5, 0.3))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A8442F", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	# Blocks [x0, x1, z0, z1, eave height, roof rise].
	var blocks := [[2.0, 43.0, -20.0, 15.5, 15.0, 9.0], [-13.3, 2.0, -37.7, 20.0, 15.0, 10.0],
		[-34.2, -13.3, -29.0, 3.3, 13.0, 8.0], [-13.6, 0.0, -46.9, -37.7, 11.0, 5.0]]
	for b in blocks:
		var bx0: float = b[0]
		var bx1: float = b[1]
		var bz0: float = b[2]
		var bz1: float = b[3]
		var eave: float = b[4]
		var w := bx1 - bx0
		var d := bz1 - bz0
		var cx := (bx0 + bx1) * 0.5
		var cz := (bz0 + bz1) * 0.5
		FhU.blk(lm, "Granite", cx, 0.0, cz, w + 0.5, 3.0, d + 0.5)
		FhU.blk(lm, "Soap", cx, 3.0, cz, w, eave - 3.0, d)
		FhU.blk(lm, "Granite", cx, eave - 0.6, cz, w + 0.6, 0.7, d + 0.6)
		FhU.hip(lm, "Copper", Vector3(cx, eave + 0.1, cz), w + 1.0, d + 1.0, float(b[5]), 0.12)
		for face in FhP.faces(cx, cz, w, d):
			var l := (face[0] as Vector3).distance_to(face[1])
			var n := maxi(int(l / 4.6), 1)
			FhP.pierce(lm, "Soap", "Glass", face[0], face[1], face[2], 3.0, eave - 3.6, n, 2,
				Vector2(1.4, 2.4), 1.0, (eave - 3.0) * 0.5, 0.3)
			FhU.openings(lm, "Glass", face[0], face[1], face[2], 1.0, n, 1.0, 1.2, false, 0.03)
			# Gabled dormers on the long roof slopes.
			if l > 14.0:
				var o: Vector3 = face[2]
				var rb := Basis(Vector3.UP, atan2(o.x, o.z))
				for k in maxi(int(l / 9.0), 1):
					var p := (face[0] as Vector3).lerp(face[1], (float(k) + 0.5) / float(maxi(int(l / 9.0), 1)))
					var dc := p - o * 1.6 + Vector3(0, eave + 1.0, 0)
					lm.box("Soap", dc + Vector3(0, 0.9, 0), Vector3(2.2, 1.8, 2.4), rb)
					lm.gable("Copper", dc + Vector3(0, 1.8, 0), 2.2, 2.4, 1.3, rb, 0.2, "Soap")
					lm.quad("Glass", dc + o * 1.22 + rb.x * -0.6 + Vector3(0, 0.3, 0), dc + o * 1.22 + rb.x * 0.6 + Vector3(0, 0.3, 0),
						dc + o * 1.22 + rb.x * 0.6 + Vector3(0, 1.5, 0), dc + o * 1.22 + rb.x * -0.6 + Vector3(0, 1.5, 0), o)
	# Gabled ends of the main block and the west wing toward the street.
	FhU.ridge_z(lm, "Copper", "Soap", Vector3(23.0, 15.0, 15.5), 12.0, 3.0, 5.0, 0.3)
	FhU.ridge_z(lm, "Copper", "Soap", Vector3(-24.0, 13.0, 3.3), 10.0, 3.0, 4.5, 0.3)
	FhP.win_row(lm, "Granite", "Glass", Vector3(19.0, 0, 17.05), Vector3(27.0, 0, 17.05), Vector3(0, 0, 1), 15.6, 3,
		1.0, 2.6, true, 0.2)
	# Round stair tower at the rear corner of the west wing, conical roof.
	var rt := Vector3(-31.0, 0.0, -29.7)
	lm.frustum("Granite", rt, 5.4, 5.3, 3.0, 20)
	lm.frustum("Soap", rt + Vector3(0, 3.0, 0), 5.2, 5.2, 13.0, 20)
	lm.frustum("Granite", rt + Vector3(0, 15.6, 0), 5.5, 5.5, 0.6, 20)
	lm.lathe("Copper", rt + Vector3(0, 16.2, 0), PackedVector2Array([Vector2(5.7, 0), Vector2(3.0, 3.6),
		Vector2(0.15, 7.6)]), 20)
	for k in 5:
		var a := PI * 0.5 + PI * 0.25 * float(k)
		FhU.opening(lm, "Glass", rt + Vector3(cos(a), 0, sin(a)) * 5.25 + Vector3(0, 6.0 + 2.0 * float(k % 2), 0),
			Vector3(cos(a), 0, sin(a)), 1.0, 2.2, false)
	# Rear hall: a church-like gable with a rose window.
	FhU.ridge_z(lm, "Copper", "Soap", Vector3(-6.8, 11.0, -42.3), 13.6, 9.2, 6.0, 0.4)
	lm.disc("Glass", Vector3(-6.8, 13.5, -46.98), Vector3(0, 0, -1), 1.6, 16)
	FhP.ring(lm, "Granite", Vector3(-6.8, 13.5, -46.95), Vector3(0, 0, -1), 1.6, 2.1, 0.25, 16)
	# Entrance: granite portal, steps and the bear on its pedestal.
	FhU.blk(lm, "Granite", -5.6, 0.0, 20.7, 7.6, 8.0, 1.4)
	LandmarkDetail.arch(lm, "Granite", Vector3(-5.6, 4.6, 21.4), Vector3(0, 0, 1), 3.4, 0.6, 0.4)
	lm.quad("Glass", Vector3(-7.3, 0.6, 21.42), Vector3(-3.9, 0.6, 21.42), Vector3(-3.9, 4.6, 21.42),
		Vector3(-7.3, 4.6, 21.42), Vector3(0, 0, 1))
	FhU.steps(lm, "Granite", Vector3(-5.6, 0.0, 21.4), Vector3(0, 0, 1), 8.0, 0.6, 0.15, 4)
	lm.box("Granite", Vector3(-0.6, 0.6, 23.5), Vector3(1.6, 1.2, 2.6))
	_bear(lm, "Granite", Vector3(-0.6, 1.2, 23.5), 2.4)
	# The tower: granite shaft with corner buttresses, slit windows, the
	# arched belfry, cornice and the copper spire with four lucarnes.
	var tx := -11.55
	var tz := 7.2
	FhU.blk(lm, "Granite", tx, 0.0, tz, 7.5, SHAFT, 9.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Granite", Vector3(tx + sx * 3.5, 10.0, tz + sz * 4.25), Vector3(1.3, 20.0, 1.3))
	for y in [12.0, 24.0]:
		FhP.box_band(lm, "Soap", tx, tz, 7.5, 9.0, y, 0.4, 0.15)
	# Brick belfry (arched louvres between dentil friezes), a flared
	# verdigris skirt, a small brick stage with two arches and the spire.
	FhU.blk(lm, "Soap", tx, SHAFT, tz, 8.3, 0.6, 9.8)
	FhU.blk(lm, "Brick", tx, SHAFT + 0.6, tz, 7.6, 4.8, 9.1)
	FhU.blk(lm, "Soap", tx, SHAFT + 5.4, tz, 8.3, 0.5, 9.8)
	lm.frustum("Verdigris", Vector3(tx, SHAFT + 5.9, tz), 6.4, 4.6, 4.4, 4, PI * 0.25)
	FhU.blk(lm, "Brick", tx, SHAFT + 10.3, tz, 5.2, 4.6, 6.0)
	for face in FhP.faces(tx, tz, 5.2, 6.0):
		var fa: Vector3 = face[0]
		var fb: Vector3 = face[1]
		var fo: Vector3 = face[2]
		FhU.openings(lm, "Glass", fa.lerp(fb, 0.22), fa.lerp(fb, 0.78), fo, SHAFT + 11.5, 2, 1.0, 2.2, true, 0.03)
	for face in FhP.faces(tx, tz, 7.6, 9.1):
		var fa: Vector3 = face[0]
		var fb: Vector3 = face[1]
		var fo: Vector3 = face[2]
		FhU.openings(lm, "Glass", fa.lerp(fb, 0.3), fa.lerp(fb, 0.7), fo, SHAFT + 1.4, 2, 1.0, 2.4, true, 0.03)
	lm.frustum("Verdigris", Vector3(tx, SHAFT + 14.9, tz), 4.4, 0.0, 9.2, 4, PI * 0.25)
	lm.frustum("Verdigris", Vector3(tx, SHAFT + 24.1, tz), 0.1, 0.04, 0.6, 6)
	lm.commit(model)

## Emil Wikström's granite bear, `l` long, lying on a pedestal at `base`.
static func _bear(lm: LandmarkMesh, key: String, base: Vector3, l: float) -> void:
	lm.lathe(key, base, PackedVector2Array([Vector2(0.0, 0.0), Vector2(l * 0.2, l * 0.02), Vector2(l * 0.24, l * 0.12),
		Vector2(l * 0.2, l * 0.26), Vector2(l * 0.1, l * 0.32), Vector2(0.0, l * 0.33)]), 12, 0.8, 2.0)
	lm.lathe(key, base + Vector3(0, l * 0.14, l * 0.46), FhU.ball(l * 0.1), 10, 1.0, 1.3)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box(key, base + Vector3(sx * l * 0.14, l * 0.05, sz * l * 0.3), Vector3(l * 0.1, l * 0.1, l * 0.16))
