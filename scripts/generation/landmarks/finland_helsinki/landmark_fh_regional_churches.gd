class_name LandmarkFhRegionalChurches
extends RefCounted

## Two medieval cathedrals of the Uusimaa coast in true metres: Espoo
## Cathedral (grey fieldstone church with its free-standing campanile) and
## Porvoo Cathedral (whitewashed hall church with the red brick gables and
## the separate belfry). Footprints follow OpenStreetMap.

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

# --- Espoo Cathedral -------------------------------------------------------

## The grey-stone church of the 1480s, the only Finnish stone church of
## that decade (origin at the OSM footprint centre), parts after the OSM
## 3D outline: the 15.7 x 37 m nave and chancel (eaves 7.6 m, ridge
## 14.1 m) and the 30 m transept under its taller roof (ridge 21.6 m),
## limewashed fieldstone walls with buttresses, gables with blind niches
## and the medieval roof trusses under dark metal; the free-standing
## campanile 24 m west and 23 m south of the centre: stone base, red
## timber stages and a shingled spire.
static func espoo(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#CDBFB2", 4.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#E2D8CA", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#3A3F43", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#8E3F2C", 2.5))
	lm.use("Shingle", LandmarkMaterials.pbr("wood", "#4A3E36", 2.0))
	var eave := 7.6
	# Nave and chancel (15.7 x 37 m) and the transept (30.4 x 17.8 m).
	FhU.blk(lm, "Stone", -0.15, 0.0, 1.2, 15.7, eave, 37.0)
	FhU.ridge_z(lm, "Roof", "Plaster", Vector3(-0.15, eave, 1.2), 15.7, 37.0, 6.5, 0.45)
	FhU.blk(lm, "Stone", -0.1, 0.0, 3.35, 30.4, eave, 17.8)
	FhU.ridge_x(lm, "Roof", "Plaster", Vector3(-0.1, eave, 3.35), 30.4, 17.8, 14.0, 0.45)
	FhP.box_band(lm, "Plaster", -0.15, 1.2, 15.7, 37.0, eave - 0.4, 0.4, 0.15)
	FhP.box_band(lm, "Plaster", -0.1, 3.35, 30.4, 17.8, eave - 0.4, 0.4, 0.15)
	# Gables: blind-niche arcades in the plaster, a cross and pinnacles.
	for g in [[Vector3(-0.15, 0, 19.7), Vector3(0, 0, 1), 15.7, 6.5], [Vector3(-0.15, 0, -17.3), Vector3(0, 0, -1), 15.7, 6.5],
			[Vector3(15.1, 0, 3.35), Vector3(1, 0, 0), 17.8, 14.0], [Vector3(-15.3, 0, 3.35), Vector3(-1, 0, 0), 17.8, 14.0]]:
		var c: Vector3 = g[0]
		var o: Vector3 = g[1]
		var gw: float = g[2]
		var rise: float = g[3]
		var r := Vector3.UP.cross(o).normalized()
		var bands := 3 if rise > 10.0 else 2
		for k in bands:
			var y := eave + 0.6 + rise * 0.28 * float(k)
			var half := gw * 0.5 * (1.0 - (y - eave + 1.6) / rise)
			var nn := maxi(int(half * 2.0 / 1.6), 1)
			FhP.arcade(lm, "Plaster", c - r * half + Vector3(0, 0, 0) + o * 0.02, c + r * half + o * 0.02, o, y,
				rise * 0.22, nn, 0.12)
		FhP.latin_cross(lm, "Plaster", c + Vector3(0, eave + rise, 0) + o * 0.1, 1.4, o)
		for s in [-1.0, 1.0]:
			lm.box("Stone", c + r * (gw * 0.5 - 0.5) * float(s) + o * 0.6 + Vector3(0, 3.0, 0), Vector3(1.0, 6.0, 1.2),
				Basis(Vector3.UP, atan2(o.x, o.z)))
	# Pointed windows down the nave and in the transept, the west portal.
	for s in [-1.0, 1.0]:
		var x: float = -0.15 + s * 7.85
		FhP.lancet_row(lm, "Plaster", "Glass", Vector3(x, 0, -16.0), Vector3(x, 0, -6.0), Vector3(s, 0, 0), 2.6, 2, 1.1,
			3.6, 0.3)
		FhP.lancet_row(lm, "Plaster", "Glass", Vector3(x, 0, 12.6), Vector3(x, 0, 19.0), Vector3(s, 0, 0), 2.6, 1, 1.1,
			3.6, 0.3)
		FhP.lancet_row(lm, "Plaster", "Glass", Vector3(-0.1 + s * 15.2, 0, -3.0), Vector3(-0.1 + s * 15.2, 0, 10.0),
			Vector3(s, 0, 0), 2.4, 2, 1.3, 4.4, 0.3)
		for z in [-12.0, -7.0, 14.5]:
			lm.box("Stone", Vector3(x + s * 0.6, 2.4, float(z)), Vector3(1.2, 4.8, 1.0))
	FhP.lancet(lm, "Plaster", "Glass", Vector3(-0.15, 0.2, 19.75), Vector3(0, 0, 1), 2.2, 4.0, 0.4, false)
	FhP.lancet(lm, "Plaster", "Glass", Vector3(-0.15, 2.6, -17.35), Vector3(0, 0, -1), 1.3, 3.8, 0.3)
	# The campanile: stone base, two red timber stages, shingled spire.
	var tx := -23.95
	var tz := 22.95
	FhU.blk(lm, "Stone", tx, 0.0, tz, 8.4, 9.0, 8.3)
	FhU.blk(lm, "Plaster", tx, 8.8, tz, 8.8, 0.4, 8.7)
	FhU.blk(lm, "Wood", tx, 9.0, tz, 7.2, 6.5, 7.2)
	FhU.blk(lm, "Wood", tx, 15.5, tz, 6.0, 4.5, 6.0)
	for face in FhP.faces(tx, tz, 7.2, 7.2):
		FhP.ribs(lm, "Wood", face[0], face[1], face[2], 9.0, 15.5, 0.5, 0.12, 0.05)
		FhP.band(lm, "Plaster", face[0], face[1], face[2], 15.3, 0.25, 0.2)
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(f))
		var out := r * Vector3(0, 0, 1)
		FhU.opening(lm, "Glass", Vector3(tx, 16.3, tz) + out * 3.05, out, 1.6, 2.8)
		FhU.opening(lm, "Glass", Vector3(tx, 3.0, tz) + out * (4.17 if f % 2 == 0 else 4.22), out, 1.0, 3.0, false)
	lm.lathe("Shingle", Vector3(tx, 20.0, tz), PackedVector2Array([Vector2(4.6, 0), Vector2(3.4, 1.0),
		Vector2(0.5, 3.6), Vector2(0.0, 4.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.commit(model)

# --- Porvoo Cathedral ----------------------------------------------------------

## The cathedral of Porvoo (stone church of c. 1410-20, widened about 1450,
## origin at the OSM footprint centre, turned square to its axis by the
## registry yaw): the whitewashed 33 x 18.5 m hall church under its steep
## roof, the red-brick east and west gables with their blind niches and
## pinnacles, the sacristy on the north, the south porch and the west
## porch with their own brick gables, buttresses and pointed windows; and
## the separate belfry to the south-east: whitewashed stone base, red
## timber stages and pyramid roof.
static func porvoo(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#D9D3C2", 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9A4B38", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("wood", "#5A4A3C", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Red", LandmarkMaterials.pbr("wood", "#8E3328", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#7E7B74", 4.0))
	var x0 := -13.7
	var x1 := 19.6
	var z0 := -8.3
	var z1 := 10.2
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	var w := x1 - x0
	var d := z1 - z0
	var eave := 8.5
	FhU.blk(lm, "Stone", cx, 0.0, cz, w + 0.6, 1.0, d + 0.6)
	FhU.blk(lm, "Wall", cx, 1.0, cz, w, eave - 1.0, d)
	FhU.ridge_x(lm, "Roof", "Brick", Vector3(cx, eave, cz), w, d, 9.0, 0.5)
	# Brick gables at both ends: blind niches stepping up, pinnacles.
	for s in [-1.0, 1.0]:
		var gx: float = x1 if s > 0.0 else x0
		var o := Vector3(s, 0, 0)
		var c := Vector3(gx + s * 0.05, 0, cz)
		var nn := 7
		for k in nn:
			var t := (float(k) + 0.5) / float(nn)
			var zz := lerpf(z0 + 1.2, z1 - 1.2, t)
			var hgt := 9.0 * (1.0 - absf(t - 0.5) * 2.0) * 0.82
			lm.box("Brick", Vector3(gx + s * 0.25, eave + 0.3 + hgt * 0.5, zz), Vector3(0.4, hgt, 1.3), Basis(), 0.0)
			lm.box("Wall", Vector3(gx + s * 0.32, eave + 0.8 + hgt * 0.4, zz), Vector3(0.3, hgt * 0.6, 0.8), Basis(), 0.0)
		for k in 5:
			var t := float(k) / 4.0
			var zz := lerpf(z0 + 0.3, z1 - 0.3, t)
			var hh := eave + 9.0 * (1.0 - absf(t - 0.5) * 2.0)
			lm.box("Brick", Vector3(gx + s * 0.25, hh + 0.6, zz), Vector3(0.6, 1.6, 0.8))
			lm.spire("Brick", Vector3(gx + s * 0.25, hh + 1.4, zz), 0.45, 1.4, 0.0, 4)
		# Buttresses and pointed windows in the gable wall.
		for zz in [z0 + 0.6, z1 - 0.6]:
			lm.box("Wall", Vector3(gx + s * 0.8, 3.5, float(zz)), Vector3(1.6, 7.0, 1.2))
		FhP.lancet_row(lm, "Wall", "Glass", c + Vector3(0, 0, -5.0), c + Vector3(0, 0, 5.0), o, 2.0, 2, 1.2, 4.6, 0.3)
	# Long walls: buttresses between pointed windows.
	for s in [-1.0, 1.0]:
		var z: float = z1 if s > 0.0 else z0
		var o := Vector3(0, 0, s)
		FhP.lancet_row(lm, "Wall", "Glass", Vector3(x0 + 1.0, 0, z), Vector3(x1 - 1.0, 0, z), o, 2.4, 5, 1.3, 4.6, 0.3)
		for k in 6:
			var x := lerpf(x0 + 1.0, x1 - 1.0, float(k) / 5.0)
			lm.box("Wall", Vector3(x, 2.8, z + s * 0.6), Vector3(1.1, 5.6, 1.2))
	# Sacristy north, south porch and west porch, each with a brick gable.
	FhU.blk(lm, "Wall", 5.75, 0.0, -13.0, 11.9, 6.5, 9.4)
	FhU.ridge_z(lm, "Roof", "Brick", Vector3(5.75, 6.5, -13.0), 11.9, 9.4, 4.2, 0.4)
	FhU.blk(lm, "Wall", 1.35, 0.0, 13.8, 9.1, 6.0, 7.2)
	FhU.ridge_z(lm, "Roof", "Brick", Vector3(1.35, 6.0, 13.8), 9.1, 7.2, 4.4, 0.4)
	FhU.blk(lm, "Wall", -16.75, 0.0, -0.55, 6.1, 5.5, 6.1)
	FhU.ridge_x(lm, "Roof", "Brick", Vector3(-16.75, 5.5, -0.55), 6.1, 6.1, 3.4, 0.3)
	FhP.lancet(lm, "Brick", "Glass", Vector3(1.35, 0.3, 17.42), Vector3(0, 0, 1), 1.8, 3.4, 0.35, false)
	FhP.arcade(lm, "Brick", Vector3(-1.6, 0, 17.42), Vector3(4.3, 0, 17.42), Vector3(0, 0, 1), 6.3, 2.6, 3, 0.12)
	FhP.lancet(lm, "Brick", "Glass", Vector3(-19.82, 0.3, -0.55), Vector3(-1, 0, 0), 1.6, 3.2, 0.35, false)
	FhP.lancet_row(lm, "Wall", "Glass", Vector3(2.0, 0, -17.72), Vector3(9.5, 0, -17.72), Vector3(0, 0, -1), 2.0, 2, 1.0,
		2.6, 0.25)
	# The belfry south-east of the church.
	var bx := 31.6
	var bz := 23.1
	var bb := Basis(Vector3.UP, -0.1)
	lm.box("Wall", Vector3(bx, 3.0, bz), Vector3(10.6, 6.0, 10.2), bb)
	lm.box("Stone", Vector3(bx, 0.3, bz), Vector3(11.0, 0.6, 10.6), bb)
	lm.box("Red", Vector3(bx, 9.0, bz), Vector3(9.2, 6.0, 9.2), bb)
	lm.box("Red", Vector3(bx, 13.2, bz), Vector3(7.6, 2.4, 7.6), bb)
	for f in 4:
		var r := bb * Basis(Vector3.UP, PI * 0.5 * float(f))
		var out: Vector3 = r * Vector3(0, 0, 1)
		var rt: Vector3 = r * Vector3(1, 0, 0)
		var fc := Vector3(bx, 0, bz) + out * 4.6
		FhP.ribs(lm, "Red", fc - rt * 4.5, fc + rt * 4.5, out, 6.0, 12.0, 0.45, 0.1, 0.05)
		FhU.opening(lm, "Glass", Vector3(bx, 7.5, bz) + out * 4.65, out, 1.6, 3.6)
		FhU.opening(lm, "Glass", Vector3(bx, 12.4, bz) + out * 3.85, out, 1.2, 1.6, false)
		FhU.opening(lm, "Glass", Vector3(bx, 0.0, bz) + out * 5.32, out, 1.4, 2.4)
	lm.lathe("Roof", Vector3(bx, 14.4, bz), PackedVector2Array([Vector2(6.2, 0), Vector2(0.0, 5.6)]), 4, 1.0, 1.0,
		PI * 0.25 - 0.1, false)
	lm.box("Red", Vector3(bx, 20.25, bz), Vector3(0.25, 0.5, 0.25))
	lm.commit(model)
