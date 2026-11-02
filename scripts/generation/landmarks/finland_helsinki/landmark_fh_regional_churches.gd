class_name LandmarkFhRegionalChurches
extends RefCounted

## Two medieval cathedrals of the Uusimaa coast in true metres: Espoo
## Cathedral (grey fieldstone church with its free-standing campanile) and
## Porvoo Cathedral (whitewashed hall church with the red brick gables and
## the separate belfry). Footprints follow OpenStreetMap.

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

# --- Espoo Cathedral -------------------------------------------------------

## The grey-stone church of c. 1485 (origin at the OSM footprint centre):
## the 15 m nave and chancel under a roof ridge at 14.1 m, the 30 m
## transept under its taller crossing roof (21.6 m, the star vault of
## 1929-31), stepped plastered gables, and 100 m beyond its south-west
## corner the free-standing campanile of 1767 (24 m west, 23 m south of the centre: (stone base, timber stages,
## conical roof).
static func espoo(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8F8F8A", 4.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#D8D4C8", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#5C5A58", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#8E3F2C", 2.5))
	lm.use("Shingle", LandmarkMaterials.pbr("wood", "#4A3E36", 2.0))
	var eave := 7.6
	# Nave and chancel (15 x 37 m), the transept (30 x 17 m) and the roofs.
	FhU.blk(lm, "Stone", 0.0, -0.5, 1.15, 15.4, eave + 0.5, 37.3)
	FhU.ridge_z(lm, "Roof", "Plaster", Vector3(0.0, eave, 1.15), 15.4, 37.3, 6.5, 0.4)
	FhU.blk(lm, "Stone", -0.1, -0.5, 3.5, 30.6, eave + 0.5, 17.4)
	FhU.ridge_x(lm, "Roof", "Plaster", Vector3(-0.1, eave, 3.5), 30.6, 17.4, 14.0, 0.4)
	# Stepped plaster gables: blind-niche bands on the south front and the transept ends.
	for k in 4:
		var w := 13.0 - 2.4 * float(k)
		FhU.blk(lm, "Plaster", 0.0, 7.6 + 2.0 * float(k), 19.8, w, 2.0, 0.5)
		FhU.blk(lm, "Plaster", 0.0, 7.6 + 2.0 * float(k), -17.4, w, 2.0, 0.5)
	for s in [-1.0, 1.0]:
		for k in 3:
			FhU.blk(lm, "Plaster", s * 15.4, 7.6 + 3.2 * float(k), 3.5, 0.5, 3.4, 11.0 - 3.6 * float(k))
	# Lancet windows and the west door.
	FhU.openings(lm, "Glass", Vector3(-7.75, 0, -14.0), Vector3(-7.75, 0, 4.0), Vector3(-1, 0, 0), 2.5, 5, 1.1, 3.6)
	FhU.openings(lm, "Glass", Vector3(7.75, 0, -14.0), Vector3(7.75, 0, 4.0), Vector3(1, 0, 0), 2.5, 5, 1.1, 3.6)
	FhU.opening(lm, "Glass", Vector3(0.0, 0.0, 19.9), Vector3(0, 0, 1), 2.4, 4.4)
	for s in [-1.0, 1.0]:
		FhU.openings(lm, "Glass", Vector3(s * 15.5, 0, 0.0), Vector3(s * 15.5, 0, 8.0), Vector3(s, 0, 0), 2.5,
				2, 1.2, 4.2)
	# The campanile: stone base, two timber stages, conical shingle roof.
	var tx := -23.95
	var tz := 22.85
	FhU.blk(lm, "Stone", tx, -0.5, tz, 8.4, 9.5, 8.3)
	FhU.blk(lm, "Wood", tx, 9.0, tz, 7.2, 6.5, 7.2)
	FhU.blk(lm, "Wood", tx, 15.5, tz, 6.0, 4.5, 6.0)
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(f))
		var out := r * Vector3(0, 0, 1)
		FhU.opening(lm, "Glass", Vector3(tx, 16.3, tz) + out * 3.05, out, 1.6, 2.8)
		FhU.opening(lm, "Glass", Vector3(tx, 3.0, tz) + out * (4.17 if f % 2 == 0 else 4.22), out, 1.0, 3.0, false)
	lm.lathe("Shingle", Vector3(tx, 20.0, tz), PackedVector2Array([Vector2(4.6, 0), Vector2(3.4, 1.0),
		Vector2(0.5, 3.6), Vector2(0.0, 4.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.commit(model)

# --- Porvoo Cathedral ----------------------------------------------------------

## The cathedral of Porvoo (consecrated 1418, origin at the OSM footprint
## centre): the whitewashed hall church with its steep shingle roof, the
## unplastered red-brick stepped gables at both ends, the sacristy and
## south porch, and the red timber belfry standing 35 m to the east-south-east.
static func porvoo(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#D9D3C2", 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9A4B38", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("wood", "#5A4A3C", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Red", LandmarkMaterials.pbr("wood", "#8E3328", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#7E7B74", 4.0))
	# Hall church 34 x 21 m, ridge along the east-west axis at 17.5 m.
	var cx := 3.0
	var cz := -1.5
	FhU.blk(lm, "Stone", cx, -1.0, cz, 34.6, 1.8, 21.6)
	FhU.blk(lm, "Wall", cx, 0.0, cz, 34.0, 8.5, 21.0)
	FhU.ridge_x(lm, "Roof", "Brick", Vector3(cx, 8.5, cz), 34.0, 21.0, 9.0, 0.5)
	# Stepped brick gable fronts with their pinnacles at both ends.
	for s in [-1.0, 1.0]:
		var gx: float = cx + s * 17.0
		for k in 5:
			var w := 18.0 - 3.4 * float(k)
			lm.box("Brick", Vector3(gx + s * 0.25, 8.5 + 1.8 * float(k) + 0.9, cz), Vector3(0.6, 1.8, w))
		lm.box("Brick", Vector3(gx + s * 0.25, 18.6, cz), Vector3(0.6, 1.2, 1.6))
		for k in 4:
			FhU.opening(lm, "Glass", Vector3(gx + s * 0.12, 1.5, cz + (float(k) - 1.5) * 4.6), Vector3(s, 0, 0),
					1.2, 5.0)
	# Sacristy to the north and the south porch, each under its own gable.
	FhU.blk(lm, "Wall", 4.0, 0.0, -14.0, 12.0, 6.5, 9.0)
	FhU.ridge_x(lm, "Roof", "Wall", Vector3(4.0, 6.5, -14.0), 12.0, 9.0, 4.2, 0.4)
	FhU.blk(lm, "Wall", -2.0, 0.0, 12.0, 20.0, 6.5, 7.0)
	FhU.ridge_x(lm, "Roof", "Wall", Vector3(-2.0, 6.5, 12.0), 20.0, 7.0, 4.0, 0.4)
	FhU.openings(lm, "Glass", Vector3(-9.0, 0, 9.0), Vector3(14.0, 0, 9.0), Vector3(0, 0, 1), 2.8, 5, 1.4, 4.2)
	FhU.opening(lm, "Glass", Vector3(-2.0, 0.0, 15.55), Vector3(0, 0, 1), 2.4, 3.8)
	FhU.openings(lm, "Glass", Vector3(-12.0, 0, -12.0), Vector3(18.0, 0, -12.0), Vector3(0, 0, -1), 2.8, 5, 1.4, 4.2)
	# The belfry: stone base, timber stages and a pyramidal shingle roof.
	var bx := 34.2
	var bz := 19.0
	FhU.blk(lm, "Stone", bx, -0.5, bz, 11.8, 6.5, 11.4)
	FhU.blk(lm, "Red", bx, 6.0, bz, 9.4, 6.0, 9.4)
	FhU.blk(lm, "Red", bx, 12.0, bz, 7.6, 2.4, 7.6)
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(f))
		var out := r * Vector3(0, 0, 1)
		FhU.opening(lm, "Glass", Vector3(bx, 7.5, bz) + out * 4.75, out, 1.6, 3.6)
		FhU.opening(lm, "Glass", Vector3(bx, 12.4, bz) + out * 3.85, out, 1.2, 1.6, false)
	FhU.hip(lm, "Roof", Vector3(bx, 14.4, bz), 8.4, 8.4, 5.6)
	lm.box("Red", Vector3(bx, 20.25, bz), Vector3(0.25, 0.5, 0.25))
	lm.commit(model)
