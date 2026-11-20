extends RefCounted

## Restaurant Kappeli (Hampus Dalstrom, 1867, glass pavilions 1890s), the
## east end of Esplanadi park. Front +Z is the park face, to the north; the
## registry yaw (177.1) turns the model's +X onto the west.
##
## From the Commons photo in visual-plan/refs/landmarks/kappeli/:
## - a central entrance loggia, 10.5 m wide, of four white piers carrying
##   three arches, an entablature and a sculpted pediment with a statue on
##   its apex, in front of a pale-yellow rendered body under a green
##   copper hipped roof;
## - on either side a glazed veranda in a green cast-iron frame with
##   diamond-lattice glazing under a low green lean-to roof;
## - at each end of the front a polygonal glazed pavilion with a green hipped
##   roof and a small dome (the west one at x -23.5, the east one at 9.6);
## - to the east, the later low glass extension;
## - a granite-kerbed terrace in front behind a black iron railing, with
##   a flight of steps on the axis.
##
## Measured: the outline (OSM way 22462839: 57 x 23.5 m, built 1865/1890),
## the axis and the position, which the old registry point missed by 46 m.
## The portico axis (x -7) follows the OSM notch. Estimated: all heights
## (eaves 4.8 m, central body 6.2 m, statue top at 10.8 m), the arch spacing
## and the terrace depth.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const P = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "kappeli", "name": "Restaurant Kappeli", "lat": 60.167388, "lon": 24.950173,
	"radius_m": 1500.0, "wiki_title": "Kappeli", "height_m": 10.0, "clear_m": 34.0,
	"yaw_deg": 177.1, "kind": "Restaurant", "aliases": ["restaurant kappeli", "ravintola kappeli", "esplanadikappeli"]}

## Pavilion outlines (OSM, model frame): west and east, open to the body.
const WEST := [Vector2(-19.7, 6.3), Vector2(-19.7, 10.8), Vector2(-23.0, 11.7), Vector2(-25.6, 11.5),
	Vector2(-27.4, 10.8), Vector2(-27.4, 6.3)]
const EAST := [Vector2(5.9, 6.3), Vector2(5.9, 10.8), Vector2(8.8, 11.7), Vector2(11.6, 11.5),
	Vector2(13.3, 10.8), Vector2(13.3, 6.3)]
const FLOOR := 0.45
const EAVE := 4.8
const BODY_X0 := -28.5
const BODY_X1 := 14.5
const BODY_Z0 := -11.7
const BODY_Z1 := 6.3
const PORTICO_X := -7.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E6D9A4", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F1EEE4", 2.0))
	lm.use("Copper", LandmarkMaterials.paint("#58806F", 0.5, 0.45))
	lm.use("Glass", LandmarkMaterials.glass("#79A097"))
	lm.use("Iron", LandmarkMaterials.paint("#2F4A40", 0.55, 0.5))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#6F6D6B", 2.5))
	lm.use("Red", LandmarkMaterials.pbr("stone", "#7A3B33", 1.5))
	lm.use("Bronze", LandmarkMaterials.paint("#3E4A40", 0.5, 0.6))
	_terrace(lm)
	_body(lm)
	_pavilion(lm, WEST)
	_pavilion(lm, EAST)
	_verandas(lm)
	_extension(lm)
	_portico(lm)
	lm.commit(model)

## Granite-kerbed terrace in front, the iron railing and the steps.
static func _terrace(lm: LandmarkMesh) -> void:
	U.blk(lm, "Granite", 0.0, 0.0, 9.6, 60.0, FLOOR, 6.0 + 7.0)
	U.blk(lm, "Granite", 0.0, FLOOR, 15.6, 59.0, 0.5, 0.4)
	U.steps(lm, "Granite", Vector3(PORTICO_X, 0, 16.0), Vector3.BACK, 4.0, 0.4, 0.15, 3)
	var x0 := -29.0
	var x1 := 29.0
	for side in 2:
		var gap := 2.4
		var a := Vector3(x0, FLOOR + 0.5, 15.8)
		var m0 := Vector3(PORTICO_X - gap, FLOOR + 0.5, 15.8)
		var m1 := Vector3(PORTICO_X + gap, FLOOR + 0.5, 15.8)
		var b := Vector3(x1, FLOOR + 0.5, 15.8)
		var run := [a, m0] if side == 0 else [m1, b]
		var p: Vector3 = run[0]
		var q: Vector3 = run[1]
		lm.beam("Iron", p + Vector3(0, 0.95, 0), q + Vector3(0, 0.95, 0), 0.06, 0.06, Vector3.UP)
		lm.beam("Iron", p + Vector3(0, 0.35, 0), q + Vector3(0, 0.35, 0), 0.05, 0.05, Vector3.UP)
		var n := int(p.distance_to(q) / 1.6)
		for k in n + 1:
			var r := p.lerp(q, float(k) / float(n))
			lm.beam("Iron", r, r + Vector3(0, 1.0, 0), 0.05, 0.05, Vector3.BACK)

## The rear block, its hipped green roof and the taller central body.
static func _body(lm: LandmarkMesh) -> void:
	var w := BODY_X1 - BODY_X0
	var d := BODY_Z1 - BODY_Z0
	var cx := (BODY_X0 + BODY_X1) * 0.5
	var cz := (BODY_Z0 + BODY_Z1) * 0.5
	U.blk(lm, "Wall", cx, FLOOR, cz, w, EAVE - FLOOR, d)
	U.blk(lm, "Trim", cx, EAVE - 0.35, cz, w + 0.5, 0.35, d + 0.5)
	U.hip(lm, "Copper", Vector3(cx, EAVE, cz), w + 1.0, d + 1.0, 2.0, 0.55)
	# Central body, a storey taller, with its own roof over the loggia.
	U.blk(lm, "Wall", PORTICO_X, FLOOR, cz, 10.5, 6.2 - FLOOR, d + 1.2)
	U.blk(lm, "Trim", PORTICO_X, 5.85, cz, 11.1, 0.35, d + 1.8)
	U.hip(lm, "Copper", Vector3(PORTICO_X, 6.2, cz), 11.2, d + 1.8, 2.6, 0.25)
	lm.frustum("Copper", Vector3(PORTICO_X, 8.6, cz - 2.0), 0.7, 0.7, 0.8, 8)
	# Windows high on the rear and ends of the body.
	P.win_row(lm, "Iron", "Glass", Vector3(-26.0, 0, BODY_Z0), Vector3(12.0, 0, BODY_Z0), Vector3(0, 0, -1), 1.4, 14, 1.4, 2.4, true, 0.15)

## A polygonal glazed pavilion: glass walls with iron mullions and a
## transom, a green hipped roof and a small dome.
static func _pavilion(lm: LandmarkMesh, pts: Array) -> void:
	var poly := PackedVector2Array(pts)
	lm.poly_prism("Glass", poly, FLOOR, EAVE - 0.8)
	lm.poly_prism("Trim", poly, EAVE - 0.8, EAVE)
	var c := P.centre(poly)
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		if a.y < 7.0 and b.y < 7.0:
			continue
		var ln := a.distance_to(b)
		var out := P.edge_out(poly, i)
		var a3 := Vector3(a.x, 0, a.y)
		var b3 := Vector3(b.x, 0, b.y)
		P.ribs(lm, "Iron", a3, b3, out, FLOOR, EAVE - 0.8, 0.9, 0.1, 0.1)
		P.band(lm, "Iron", a3, b3, out, 2.4, 0.1, 0.1)
		P.band(lm, "Iron", a3, b3, out, FLOOR, 0.15, 0.12)
		if ln < 0.5:
			continue
	var base := Vector3(c.x, EAVE, c.y)
	lm.lathe("Copper", base, PackedVector2Array([Vector2(5.6, 0), Vector2(5.0, 0.5), Vector2(1.0, 2.3), Vector2(0.8, 2.4)]), 6, 0.72, 0.55, PI / 6.0, false)
	lm.lathe("Copper", base + Vector3(0, 2.4, 0), U.dome_prof(0.9, 0.8, 6), 12)
	lm.frustum("Copper", base + Vector3(0, 3.2, 0), 0.05, 0.03, 1.0, 6)

## Glazed verandas between the loggia and the pavilions, under low green
## lean-to roofs.
static func _verandas(lm: LandmarkMesh) -> void:
	for run in [[-19.7, -12.2], [-1.7, 5.9]]:
		var x0: float = run[0]
		var x1: float = run[1]
		var xm := (x0 + x1) * 0.5
		lm.box("Glass", Vector3(xm, (FLOOR + EAVE - 1.0) * 0.5, 7.0), Vector3(x1 - x0, EAVE - 1.0 - FLOOR, 0.2))
		P.ribs(lm, "Iron", Vector3(x0, 0, 7.15), Vector3(x1, 0, 7.15), Vector3(0, 0, 1), FLOOR, EAVE - 1.0, 1.0, 0.1, 0.08)
		P.band(lm, "Iron", Vector3(x0, 0, 7.15), Vector3(x1, 0, 7.15), Vector3(0, 0, 1), 2.4, 0.1, 0.1)
		U.wedge(lm, "Copper", "Copper", x0 - 0.2, x1 + 0.2, 6.3, 8.2, EAVE - 1.0, 1.0, 0.1)

## The later glass extension east of the body.
static func _extension(lm: LandmarkMesh) -> void:
	var x0 := 13.1
	var x1 := 28.5
	var z0 := -10.1
	var z1 := 0.3
	U.blk(lm, "Glass", (x0 + x1) * 0.5, FLOOR, (z0 + z1) * 0.5, x1 - x0, 3.6, z1 - z0)
	U.blk(lm, "Copper", (x0 + x1) * 0.5, 4.05, (z0 + z1) * 0.5, x1 - x0 + 0.6, 0.25, z1 - z0 + 0.6)
	var out := Vector3(0, 0, 1)
	P.ribs(lm, "Iron", Vector3(x0, 0, z1), Vector3(x1, 0, z1), out, FLOOR, 4.05, 1.5, 0.1, 0.1)
	P.ribs(lm, "Iron", Vector3(x1, 0, z1), Vector3(x1, 0, z0), Vector3(1, 0, 0), FLOOR, 4.05, 1.5, 0.1, 0.1)

## The entrance loggia: four piers, three arches, entablature, pediment
## and the statue on its apex.
static func _portico(lm: LandmarkMesh) -> void:
	var z := 7.0
	var h := 4.6
	for k in 4:
		var x := PORTICO_X - 5.0 + float(k) * 3.33
		U.blk(lm, "Trim", x, FLOOR, z, 0.9, h, 0.9)
		U.blk(lm, "Red", x, FLOOR, z + 0.0, 0.5, 1.5, 1.0)
	for k in 3:
		var x := PORTICO_X - 3.33 + float(k) * 3.33
		U.opening(lm, "Glass", Vector3(x, FLOOR + 0.1, z - 0.5), Vector3(0, 0, 1), 2.1, h - 0.1, true)
		lm.beam("Trim", Vector3(x - 1.05, FLOOR + h - 1.0, z + 0.45), Vector3(x + 1.05, FLOOR + h - 1.0, z + 0.45), 0.25, 0.25, Vector3.UP)
	U.blk(lm, "Trim", PORTICO_X, FLOOR + h, z, 11.0, 0.9, 1.6)
	U.blk(lm, "Trim", PORTICO_X, FLOOR + h + 0.9, z, 11.4, 0.25, 2.0)
	U.ridge_z(lm, "Trim", "Trim", Vector3(PORTICO_X, FLOOR + h + 1.15, z), 11.0, 1.9, 1.6, 0.2)
	lm.frustum("Bronze", Vector3(PORTICO_X, FLOOR + h + 2.7, z), 0.28, 0.2, 1.1, 8)
	lm.lathe("Bronze", Vector3(PORTICO_X, FLOOR + h + 3.8, z), U.ball(0.2), 8)
	lm.box("Granite", Vector3(PORTICO_X, FLOOR + h + 2.45, z), Vector3(0.7, 0.3, 0.7))
