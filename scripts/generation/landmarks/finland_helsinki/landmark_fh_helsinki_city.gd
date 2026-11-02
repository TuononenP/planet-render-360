class_name LandmarkFhHelsinkiCity
extends RefCounted

## Four landmarks of the Helsinki city centre in true metres: the Central
## Station (Saarinen's granite National Romantic hall, 48.5 m clock
## tower), the 1931 Hotel Torni, the Old Market Hall by the South Harbour
## and the National Library (Engel's rotunda). Footprints and part
## heights follow OpenStreetMap.

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

# --- Helsinki Central Station ----------------------------------------

## Eliel Saarinen's station (1919), origin at the centre of the arched
## entrance, front +Z toward Rautatientori (registry yaw -2): the 36 m
## entrance block with its parabolic arch and the four lantern-bearing
## granite giants, the barrel-roofed wings, the hall behind and the 48.5 m
## clock tower at the east end with its stepped copper top.
static func station(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#9AA09A", 4.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#B9BDB5", 3.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#7A9A88", 2.0, 0.5, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE8B0", 0.9))
	lm.use("Dial", LandmarkMaterials.lit("#F2EEE0", 0.35))
	# Entrance block, wings and the hall behind (barrel roofs as low gables).
	FhU.blk(lm, "Granite", 0.0, 0.0, 0.0, 36.0, 18.0, 18.0)
	FhU.ridge_x(lm, "Copper", "Granite", Vector3(0, 18.0, 0), 36.0, 18.0, 2.6, 0.5)
	FhU.blk(lm, "Granite", -30.0, 0.0, -7.0, 44.0, 14.0, 19.0)
	FhU.ridge_x(lm, "Copper", "Granite", Vector3(-30.0, 14.0, -7.0), 44.0, 19.0, 2.4, 0.5)
	FhU.blk(lm, "Granite", 37.0, 0.0, -7.0, 47.0, 14.0, 11.0)
	FhU.ridge_x(lm, "Copper", "Granite", Vector3(37.0, 14.0, -7.0), 47.0, 11.0, 2.0, 0.5)
	FhU.blk(lm, "Granite", 4.0, 0.0, -27.0, 60.0, 16.0, 36.0)
	FhU.ridge_z(lm, "Copper", "Granite", Vector3(4.0, 16.0, -27.0), 60.0, 36.0, 4.5, 0.5)
	FhU.blk(lm, "Trim", 0.0, 17.0, 0.0, 36.8, 1.0, 18.8)
	# The parabolic entrance arch (11 m wide, 13 m tall), glazed, with its frame.
	var fz := 9.05
	var aw := 5.6
	var ah := 13.2
	for k in 12:
		var y0 := ah * float(k) / 12.0
		var y1 := ah * float(k + 1) / 12.0
		var w0 := aw * sqrt(1.0 - y0 / ah)
		var w1 := aw * sqrt(1.0 - y1 / ah)
		lm.quad("Glass", Vector3(-w0, y0, fz), Vector3(w0, y0, fz), Vector3(w1, y1, fz), Vector3(-w1, y1, fz),
			Vector3(0, 0, 1))
		for s in [-1.0, 1.0]:
			lm.beam("Trim", Vector3(s * (w0 + 0.7), y0, fz + 0.15), Vector3(s * (w1 + 0.7), y1 + 0.001, fz + 0.15),
				1.4, 0.9, Vector3.RIGHT)
	lm.box("Trim", Vector3(0, ah + 0.1, fz + 0.15), Vector3(1.8, 1.8, 0.9))
	FhU.steps(lm, "Trim", Vector3(0, 0, 9.0), Vector3(0, 0, 1), 14.0, 0.7, 0.18, 4)
	# The four giants with their spherical lamps flank the arch.
	for gx in [-9.8, -7.4, 7.4, 9.8]:
		var gb := Vector3(gx, 0.0, 10.4)
		lm.box("Trim", gb + Vector3(0, 0.5, 0), Vector3(1.8, 1.0, 1.8))
		LandmarkKits.statue_figure(lm, "Granite", gb + Vector3(0, 1.0, 0), 4.4, true)
		lm.lathe("Lamp", gb + Vector3(0.9, 5.0, 0), FhU.ball(0.55), 10)
	# Arched windows along the wings and tall slits beside the arch.
	FhU.openings(lm, "Glass", Vector3(-50.0, 0, 2.5), Vector3(-10.0, 0, 2.5), Vector3(0, 0, 1), 2.5, 7, 3.2, 8.0)
	FhU.openings(lm, "Glass", Vector3(15.0, 0, -1.5), Vector3(59.0, 0, -1.5), Vector3(0, 0, 1), 2.5, 7, 3.2, 8.0)
	for s in [-1.0, 1.0]:
		FhU.openings(lm, "Glass", Vector3(s * 13.5, 0, 9.0), Vector3(s * 16.5, 0, 9.0), Vector3(0, 0, 1), 6.0,
				1, 1.6, 7.0)
	# Clock tower: granite shaft, slits, four dials and the stepped copper top.
	var tx := 50.0
	var tz := -16.0
	FhU.blk(lm, "Granite", tx, 0.0, tz, 10.0, 36.2, 10.0)
	FhU.blk(lm, "Trim", tx, 36.0, tz, 10.8, 0.8, 10.8)
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(f))
		var out := r * Vector3(0, 0, 1)
		FhU.opening(lm, "Glass", Vector3(tx, 10.0, tz) + out * 5.05, out, 1.4, 7.0, false)
		FhU.opening(lm, "Glass", Vector3(tx, 20.0, tz) + out * 5.05, out, 1.4, 5.0, false)
		lm.disc("Dial", Vector3(tx, 30.0, tz) + out * 5.08, out, 2.2, 24)
	var s2 := 1.4142
	lm.lathe("Copper", Vector3(tx, 36.8, tz), PackedVector2Array([Vector2(5.4 * s2, 0), Vector2(4.4 * s2, 3.2),
		Vector2(4.4 * s2, 3.9), Vector2(3.3 * s2, 6.8), Vector2(3.3 * s2, 7.5), Vector2(2.0 * s2, 9.6),
		Vector2(2.0 * s2, 10.1), Vector2(0.7 * s2, 11.7)]), 4, 1.0, 1.0, PI * 0.25, false)
	lm.commit(model)

# --- Hotel Torni --------------------------------------------------------

## Jung & Jung's Torni (1931), origin at the OSM footprint centre
## (registry yaw -35, the block turned onto Yrjönkatu): a 30 m square base,
## three setback tiers, the glazed lantern and the copper spire, 69.5 m, the
## tallest building in Finland until 1976.
static func torni(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#D8D0BC", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#EDE6D2", 2.5))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#8A8780", 4.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E9C88", 2.0, 0.5, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Sign", LandmarkMaterials.lit("#D8322A", 0.6))
	# Tiers [size, y0, y1]: base, two setbacks, the tower head and the lantern.
	var tiers := [[30.0, 0.0, 18.8], [26.0, 18.8, 30.0], [20.0, 30.0, 45.0], [12.0, 45.0, 53.0]]
	FhU.blk(lm, "Plinth", 0.0, 0.0, 0.0, 30.8, 3.0, 30.8)
	for t in tiers:
		var sz: float = float(t[0])
		FhU.blk(lm, "Wall", 0.0, float(t[1]), 0.0, sz, float(t[2]) - float(t[1]), sz)
		FhU.blk(lm, "Trim", 0.0, float(t[2]) - 0.5, 0.0, sz + 0.8, 0.5, sz + 0.8)
	var rows := [[30.0, 3.4, 4, 3.6], [26.0, 20.0, 3, 3.5], [20.0, 31.5, 3, 4.5], [12.0, 46.0, 2, 3.4]]
	for r in rows:
		var sz: float = float(r[0])
		var n := int(sz / 3.2)
		FhU.box_windows(lm, "Glass", 0.0, 0.0, sz, sz, float(r[1]), int(r[2]), float(r[3]), n, n, 1.4, 2.2)
	# Lantern, copper spire and the red sign band below the head.
	FhU.blk(lm, "Glass", 0.0, 53.0, 0.0, 6.0, 8.5, 6.0)
	FhU.blk(lm, "Trim", 0.0, 61.3, 0.0, 6.8, 0.3, 6.8)
	FhU.hip(lm, "Copper", Vector3(0, 61.5, 0), 6.6, 6.6, 7.5)
	lm.box("Copper", Vector3(0, 69.25, 0), Vector3(0.3, 0.5, 0.3))
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(f))
		lm.box("Sign", r * Vector3(0, 50.5, 6.1), Vector3(9.0, 1.4, 0.2), r)
	lm.commit(model)

# --- Old Market Hall -----------------------------------------------------

## Gustaf Nyström's Vanha kauppahalli (1889), origin at the OSM footprint
## centre, front +Z toward the Market Square (registry yaw -93): the 85 m
## brick hall under its low copper roof, round-headed windows, the
## gabled entrance bays on both long sides and the four corner turrets
## with pyramidal copper caps.
static func markethall(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8F4A38", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#D9D0BC", 2.5))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E9C88", 2.0, 0.5, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#8A8780", 4.0))
	var cz := -0.65
	FhU.blk(lm, "Plinth", 0.2, 0.0, cz, 85.4, 1.2, 17.2)
	FhU.blk(lm, "Brick", 0.2, 1.2, cz, 85.0, 6.8, 16.7)
	FhU.blk(lm, "Trim", 0.2, 7.6, cz, 86.0, 0.5, 17.7)
	FhU.ridge_x(lm, "Copper", "Brick", Vector3(0.2, 8.1, cz), 85.0, 16.7, 5.0, 0.6)
	for s in [-1.0, 1.0]:
		var ez := 8.95 if s > 0.0 else -9.6
		FhU.blk(lm, "Brick", 0.5, 0.0, ez, 12.1, 11.5, 2.6)
		FhU.ridge_z(lm, "Copper", "Brick", Vector3(0.5, 11.5, ez), 12.1, 2.6, 4.2, 0.3)
		FhU.opening(lm, "Glass", Vector3(0.5, 1.2, ez + s * 1.35), Vector3(0, 0, s), 5.0, 8.5)
		FhU.steps(lm, "Plinth", Vector3(0.5, 0.0, ez + s * 1.3), Vector3(0, 0, s), 6.0, 0.5, 0.2, 3)
		FhU.openings(lm, "Glass", Vector3(-39.0, 1.2, cz + s * 8.4), Vector3(39.0, 1.2, cz + s * 8.4),
			Vector3(0, 0, s), 0.0, 14, 2.4, 5.6)
	# Corner turrets with pyramidal copper caps.
	for tx in [-40.6, 41.0]:
		for tz in [-7.4, 6.1]:
			FhU.blk(lm, "Brick", tx, 0.0, tz, 3.6, 13.6, 3.6)
			FhU.blk(lm, "Trim", tx, 13.4, tz, 4.2, 0.4, 4.2)
			FhU.hip(lm, "Copper", Vector3(tx, 13.8, tz), 4.4, 4.4, 5.2)
			FhU.opening(lm, "Glass", Vector3(tx, 9.0, tz + signf(tz) * 1.85), Vector3(0, 0, signf(tz)), 1.0, 2.6)
	# Gable ends with a round window.
	for s in [-1.0, 1.0]:
		lm.disc("Glass", Vector3(0.2 + s * 42.6, 10.5, cz), Vector3(s, 0, 0), 1.3, 14)
	lm.commit(model)

# --- National Library of Finland --------------------------------------

## Engel's university library (1845), origin at the OSM footprint centre
## (registry yaw -3): the plastered four-storey block with its
## semicircular west bay and the rotunda, a drum under a copper dome and
## lantern in the middle of the east wing.
static func natlibrary(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E3DCC4", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#F0EBDD", 2.5))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E9C88", 2.0, 0.5, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#5A6068", 3.0))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#8A8780", 4.0))
	# Main block x -8.6..21.3, z -23.1..23.9; semicircular bay to the west.
	FhU.blk(lm, "Plinth", 6.35, 0.0, 0.4, 30.6, 2.0, 47.6)
	FhU.blk(lm, "Wall", 6.35, 2.0, 0.4, 29.9, 12.0, 47.0)
	FhU.blk(lm, "Trim", 6.35, 13.6, 0.4, 31.0, 0.8, 48.1)
	FhU.hip(lm, "Roof", Vector3(6.35, 14.4, 0.4), 30.5, 47.6, 2.4, 0.3)
	lm.frustum("Plinth", Vector3(-8.6, 0.0, 0.0), 14.6, 14.6, 2.0, 16)
	lm.frustum("Wall", Vector3(-8.6, 2.0, 0.0), 14.3, 14.3, 10.0, 16)
	lm.frustum("Trim", Vector3(-8.6, 11.6, 0.0), 14.9, 14.9, 0.7, 16)
	lm.lathe("Roof", Vector3(-8.6, 12.3, 0.0), PackedVector2Array([Vector2(14.9, 0), Vector2(0, 2.6)]), 16)
	# Tall round-headed windows round the bay and on the long faces.
	for i in 9:
		var a := PI * (0.55 + 0.9 * float(i) / 8.0)
		var out := Vector3(cos(a), 0, sin(a))
		FhU.opening(lm, "Glass", Vector3(-8.6, 3.5, 0.0) + out * 14.4, out, 1.8, 6.5)
	FhU.openings(lm, "Glass", Vector3(-6.0, 3.0, 24.0), Vector3(19.0, 3.0, 24.0), Vector3(0, 0, 1), 0.0, 6, 2.0, 7.0)
	FhU.openings(lm, "Glass", Vector3(-6.0, 3.0, -23.3), Vector3(19.0, 3.0, -23.3), Vector3(0, 0, -1), 0.0, 6,
			2.0, 7.0)
	FhU.openings(lm, "Glass", Vector3(21.5, 3.0, -20.0), Vector3(21.5, 3.0, 21.0), Vector3(1, 0, 0), 0.0, 8, 2.0, 7.0)
	# Rotunda: plastered drum, windows, copper dome and lantern.
	var rc := Vector3(7.2, 0.0, 0.4)
	lm.frustum("Wall", rc + Vector3(0, 14.4, 0), 7.0, 7.0, 6.0, 20)
	lm.frustum("Trim", rc + Vector3(0, 20.4, 0), 7.4, 7.4, 0.6, 20)
	for i in 10:
		var a := TAU * float(i) / 10.0
		FhU.opening(lm, "Glass", rc + Vector3(cos(a) * 7.02, 16.4, sin(a) * 7.02), Vector3(cos(a), 0, sin(a)),
				1.4, 3.2)
	lm.lathe("Copper", rc + Vector3(0, 21.0, 0), FhU.dome_prof(5.8, 5.2, 10), 20)
	lm.frustum("Trim", rc + Vector3(0, 26.2, 0), 1.3, 1.1, 1.3, 10)
	lm.lathe("Copper", rc + Vector3(0, 27.5, 0), PackedVector2Array([Vector2(1.2, 0), Vector2(0, 0.5)]), 10)
	lm.commit(model)
