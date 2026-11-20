extends RefCounted

## Behind the Vasagatan front: the lower rear mass on the mapped outline (the
## same plaster, punched window rows, a flat slate roof), the annex toward
## the Klarabergsviadukten end, the barrel vault of the central hall rising
## out of the rear roof (steel ribs, glazed crown, glazed end screen toward
## the tracks) and the long low platform canopies over the tracks at -Z
## (corrugated rust-brown roofs on slim iron posts, seen in side.jpg).

const P = preload("res://scripts/generation/landmarks/sweden_stockholm/stations/sto_cs_plan.gd")
const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")
const K = preload("res://scripts/generation/landmarks/capital_stations/landmark_station_kit.gd")

const VAULT_SPAN := 30.0
const VAULT_RISE := 7.0
const CANOPY_Z0 := -31.0
const CANOPY_LEN := 62.0
const CANOPY_W := 5.6
const CANOPY_H := 5.4

static func build(lm: LandmarkMesh) -> void:
	_mass(lm, PackedVector2Array(P.REAR), P.REAR_H, true)
	_mass(lm, PackedVector2Array(P.TAIL), P.TAIL_H, false)
	_vault(lm)
	_canopies(lm)

## A rear mass: walls with window rows on every exposed edge, a cornice band
## and a flat slate roof set just inside the parapet.
static func _mass(lm: LandmarkMesh, poly: PackedVector2Array, h: float, is_rear: bool) -> void:
	lm.poly_prism("Wall", poly, 0.0, h, false)
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		if _internal(p, q, is_rear) or p.distance_to(q) < 5.0:
			continue
		var out := FhP.edge_out(poly, i)
		var a := Vector3(p.x, 0, p.y)
		var b := Vector3(q.x, 0, q.y)
		var n := maxi(int(a.distance_to(b) / 4.5), 1)
		FhP.band(lm, "Trim", a, b, out, h - 0.9, 0.9, 0.3)
		FhP.band(lm, "Rustic", a, b, out, 0.0, P.RUST, 0.12)
		var rows := 3 if h > 12.0 else 2
		FhU.window_grid(lm, "Glass", a, b, out, 5.8 if h > 12.0 else 4.4, rows - 1, 4.4, n, 1.5, 2.3)
		FhU.openings(lm, "Glass", a, b, out, 1.4, n, 1.4, 2.8, true)
	var inner := Geometry2D.offset_polygon(poly, -0.5)
	for ring in inner:
		lm.poly_prism("Roof", ring, h - 0.02, h + 0.5, true)

## Edges buried against the front range or the tail's shared line.
static func _internal(p: Vector2, q: Vector2, is_rear: bool) -> bool:
	if is_rear:
		return absf(p.y - P.ZB) < 0.01 and absf(q.y - P.ZB) < 0.01 and p.x > -68.5 and q.x > -68.5 \
			and p.x < 63.5 and q.x < 63.5
	return (p == Vector2(65, -15) and q == Vector2(42, -29)) or (q == Vector2(65, -15) and p == Vector2(42, -29)) \
		or (p == Vector2(42, -29) and q == Vector2(65, -15))

## The central hall's vault along -Z from the back of the central block.
static func _vault(lm: LandmarkMesh) -> void:
	K.shed(lm, "Roof", "Steel", "Glass", Vector3(P.CX, 0.0, 1.0), Vector3(0, 0, -1), VAULT_SPAN, 23.5,
		P.REAR_H, VAULT_RISE, 7.8, 0.6, 1)

## Platform canopies: one built once, set side by side over the tracks.
static func _canopies(lm: LandmarkMesh) -> void:
	var t := LandmarkMesh.new()
	P.materials(t)
	t.box("Canopy", Vector3(0, CANOPY_H + 0.15, CANOPY_Z0 - CANOPY_LEN * 0.5), Vector3(CANOPY_W, 0.3, CANOPY_LEN), Basis(), 0.0)
	t.box("Steel", Vector3(0, CANOPY_H - 0.1, CANOPY_Z0 - CANOPY_LEN * 0.5), Vector3(0.5, 0.4, CANOPY_LEN), Basis(), 0.0)
	for k in 7:
		var z := CANOPY_Z0 - 2.0 - float(k) * (CANOPY_LEN - 4.0) / 6.0
		for s in [-1.0, 1.0]:
			t.box("Steel", Vector3(float(s) * CANOPY_W * 0.4, CANOPY_H * 0.5, z), Vector3(0.28, CANOPY_H, 0.28), Basis(), 0.0)
	for i in 9:
		lm.merge(t, Transform3D(Basis(), Vector3(-78.0 + 13.0 * float(i), 0.0, 0.0)))
