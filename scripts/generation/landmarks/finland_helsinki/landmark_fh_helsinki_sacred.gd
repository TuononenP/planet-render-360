class_name LandmarkFhHelsinkiSacred
extends RefCounted

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

## Four Helsinki churches in true metres: Uspenski Cathedral (red-brick
## Orthodox, gilded onions), Temppeliaukio (the copper dome in its rock),
## St John's (twin 74 m neo-Gothic spires) and Kallio Church (granite Art
## Nouveau tower). Footprints and part heights follow OpenStreetMap.

# --- Uspenski Cathedral ---------------------------------------------

## Gornostayev's cathedral (1868) on its Katajanokka rock, origin at the
## OSM footprint centre, entrance and bell tower south: the cross-in-square
## core with four gabled arms, the octagonal drum under a copper tent and
## a gilded onion (44 m, cross 48 m above the church floor), six corner
## turrets, small domes on the arm gables, apse and porch (13 gilded onions in
## all, as on the real church) and the bell tower with its own dome.
static func uspenski(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8A4638", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#DAD3C3", 2.5))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#5F8F78", 2.0, 0.5, 0.3))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Rock", LandmarkMaterials.pbr("stone", "#827D74", 4.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	var y0 := 1.1
	# Katajanokka rock the church stands on.
	lm.frustum("Rock", Vector3(0, -3.0, 0), 31.0, 27.0, y0 + 3.0, 14, 0.0, 0.9, 1.15)
	# Lower body round the crossing and the four gabled arms (kokoshniks).
	FhU.blk(lm, "Brick", 1.0, y0, -7.5, 33.0, 12.0, 27.0)
	FhU.blk(lm, "Trim", 1.0, y0 + 12.0, -7.5, 33.8, 0.6, 27.8)
	FhU.blk(lm, "Brick", -1.0, y0, -7.0, 15.0, 18.0, 15.0)
	for arm in [[Vector2(-1.0, -17.5), false], [Vector2(-1.0, 3.5), false],
			[Vector2(-11.5, -7.0), true], [Vector2(9.5, -7.0), true]]:
		var c: Vector2 = arm[0]
		if bool(arm[1]):
			FhU.blk(lm, "Brick", c.x, y0, c.y, 5.0, 15.0, 15.0)
			FhU.ridge_x(lm, "Copper", "Brick", Vector3(c.x, y0 + 15.0, c.y), 5.0, 15.0, 6.0, 0.3)
			FhU.opening(lm, "Glass", Vector3(c.x + signf(c.x + 1.0) * 2.55, y0 + 5.0, c.y),
				Vector3(signf(c.x + 1.0), 0, 0), 2.0, 6.0)
		else:
			FhU.blk(lm, "Brick", c.x, y0, c.y, 15.0, 15.0, 5.0)
			FhU.ridge_z(lm, "Copper", "Brick", Vector3(c.x, y0 + 15.0, c.y), 15.0, 5.0, 6.0, 0.3)
			FhU.opening(lm, "Glass", Vector3(c.x, y0 + 5.0, c.y + signf(c.y + 7.0) * 2.55),
				Vector3(0, 0, signf(c.y + 7.0)), 2.0, 6.0)
		# Small gilded dome on each arm gable.
		var t := Vector3(c.x, y0 + 21.0, c.y)
		lm.frustum("Brick", t, 1.5, 1.5, 3.0, 8)
		FhU.onion(lm, "Gold", t + Vector3(0, 3.0, 0), 1.9, 3.2)
		FhU.cross(lm, "Gold", t + Vector3(0, 6.1, 0), 1.6)
	# Windows along the lower walls.
	FhU.openings(lm, "Glass", Vector3(-15.6, y0, -20.0), Vector3(-15.6, y0, 5.0), Vector3(-1, 0, 0), 3.0, 5, 1.6, 6.0)
	FhU.openings(lm, "Glass", Vector3(17.6, y0, -20.0), Vector3(17.6, y0, 5.0), Vector3(1, 0, 0), 3.0, 5, 1.6, 6.0)
	FhU.openings(lm, "Glass", Vector3(-14.0, y0, -21.1), Vector3(16.0, y0, -21.1), Vector3(0, 0, -1), 3.0, 6,
			1.6, 6.0)
	# Apse of the sanctuary.
	lm.frustum("Brick", Vector3(-1.0, y0, -20.0), 5.5, 5.5, 13.0, 10)
	lm.lathe("Copper", Vector3(-1.0, y0 + 13.0, -20.0), PackedVector2Array([Vector2(6.0, 0), Vector2(0, 5.0)]), 10)
	FhU.onion(lm, "Gold", Vector3(-1.0, y0 + 18.0, -20.0), 1.5, 2.6)
	FhU.cross(lm, "Gold", Vector3(-1.0, y0 + 20.5, -20.0), 1.5)
	# The thirteenth dome of the body, over the south porch roof.
	lm.frustum("Brick", Vector3(-1.0, y0 + 12.0, 6.5), 1.3, 1.3, 2.4, 8)
	FhU.onion(lm, "Gold", Vector3(-1.0, y0 + 14.4, 6.5), 1.7, 3.0)
	FhU.cross(lm, "Gold", Vector3(-1.0, y0 + 17.3, 6.5), 1.5)
	# Drum, copper tent, gilded onion and cross over the crossing.
	var cp := Vector3(-1.0, y0 + 18.0, -7.0)
	lm.frustum("Brick", cp, 6.4, 6.4, 11.0, 8, PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0 + PI / 8.0
		FhU.opening(lm, "Glass", cp + Vector3(cos(a) * 6.0, 6.0, sin(a) * 6.0),
			Vector3(cos(a), 0, sin(a)), 1.4, 3.6)
	lm.frustum("Trim", cp + Vector3(0, 11.0, 0), 6.9, 6.9, 0.7, 8, PI / 8.0)
	lm.lathe("Copper", cp + Vector3(0, 11.7, 0), PackedVector2Array([Vector2(7.0, 0), Vector2(3.4, 5.0),
		Vector2(1.6, 9.0), Vector2(0.9, 10.3)]), 8, 1.0, 1.0, PI / 8.0, false)
	FhU.onion(lm, "Gold", cp + Vector3(0, 21.8, 0), 2.7, 5.0)
	FhU.cross(lm, "Gold", cp + Vector3(0, 26.7, 0), 4.2)
	# Six corner turrets with cone roofs and small onions.
	for p in [Vector2(5, -20), Vector2(-9, -19), Vector2(11, -15), Vector2(-15, -13), Vector2(12, -1),
			Vector2(-14, 1)]:
		var base := Vector3(p.x, y0 + 12.0, p.y)
		lm.frustum("Brick", base, 1.8, 1.8, 7.0, 8)
		lm.lathe("Copper", base + Vector3(0, 7.0, 0), PackedVector2Array([Vector2(2.3, 0), Vector2(0.5, 4.0)]), 8)
		FhU.onion(lm, "Gold", base + Vector3(0, 11.0, 0), 1.3, 2.2)
		FhU.cross(lm, "Gold", base + Vector3(0, 13.1, 0), 1.3)
	# Bell tower over the south porch: brick shaft, open belfry, copper tent.
	var bt := Vector3(0.0, y0, 15.5)
	FhU.blk(lm, "Brick", bt.x, y0, bt.z, 7.0, 20.0, 7.0)
	FhU.openings(lm, "Glass", bt + Vector3(-1.5, 0, 3.55), bt + Vector3(1.5, 0, 3.55), Vector3(0, 0, 1), 3.0, 2,
			1.4, 5.0)
	lm.box("Trim", bt + Vector3(0, 20.3, 0), Vector3(7.8, 0.6, 7.8))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Brick", bt + Vector3(sx * 3.0, 24.0, sz * 3.0), Vector3(1.0, 7.4, 1.0))
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(f))
		lm.box("Glass", bt + r * Vector3(0, 24.0, 3.2), Vector3(3.6, 5.5, 0.3), r)
	lm.box("Trim", bt + Vector3(0, 27.9, 0), Vector3(7.8, 0.6, 7.8))
	lm.lathe("Copper", bt + Vector3(0, 28.2, 0), PackedVector2Array([Vector2(4.6, 0), Vector2(2.4, 4.5),
		Vector2(1.0, 8.0), Vector2(0.7, 9.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	FhU.onion(lm, "Gold", bt + Vector3(0, 37.2, 0), 1.7, 3.0)
	FhU.cross(lm, "Gold", bt + Vector3(0, 40.2, 0), 2.4)
	lm.commit(model)

# --- Temppeliaukio Church -------------------------------------------

## The Rock Church (Suomalainen, 1969): a 24 m copper-lined dome on a
## glazed ring, set into a blasted granite outcrop; from outside only the
## shallow copper disc and the rough rock rim show. Origin at the OSM
## footprint centre, the dome axis at (-1, -5.5), entrance block south.
static func temppeliaukio(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Rock", LandmarkMaterials.pbr("cliff", "#8C8780", 4.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#7C9A86", 2.0, 0.45, 0.4))
	lm.use("Glass", LandmarkMaterials.glass("#3A4A52"))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#7E7B76", 3.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#9A9892", 3.0))
	var c := Vector3(-1.0, 0, -5.5)
	# Rock outcrop, steep faces ringed round the pit of the church.
	lm.lathe("Rock", c + Vector3(0, -2.0, 0), PackedVector2Array([Vector2(24.0, 0), Vector2(22.0, 3.0),
		Vector2(20.0, 5.2), Vector2(17.5, 6.6), Vector2(15.0, 7.0), Vector2(14.0,
				7.0)]), 22, 0.95, 1.1, 0.3, false, false)
	# Concrete ring beam, the glazed band (about 180 windows) and the dome.
	lm.frustum("Concrete", c + Vector3(0, 4.9, 0), 14.0, 13.6, 0.9, 32)
	lm.frustum("Glass", c + Vector3(0, 5.8, 0), 13.4, 13.4, 0.7, 32)
	lm.lathe("Copper", c + Vector3(0, 6.4, 0), PackedVector2Array([Vector2(13.6, 0), Vector2(11.5, 0.7),
		Vector2(7.5, 1.3), Vector2(3.5, 1.55), Vector2(0, 1.6)]), 32)
	# Granite entrance block and the tunnel mouth to the south.
	FhU.blk(lm, "Granite", 6.0, 0.0, 21.0, 12.0, 4.5, 8.0)
	FhU.blk(lm, "Concrete", 6.0, 4.5, 21.0, 12.6, 0.5, 8.6)
	FhU.opening(lm, "Glass", Vector3(6.0, 0.0, 25.08), Vector3(0, 0, 1), 3.0, 3.0, false)
	lm.commit(model)

# --- St John's Church ------------------------------------------------

## Melander's neo-Gothic church (1891), origin at the OSM footprint centre,
## front +Z (turned onto the north-east by the registry yaw): the 29 m
## wide hall with its 28.8 m steep roof, transept and chancel, the entrance
## gable and the twin 8 m square towers whose spires reach 74 m.
static func stjohns(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8E4B3B", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#C9C1B0", 2.5))
	lm.use("Slate", LandmarkMaterials.pbr("slate", "#454C52", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#7A7771", 4.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	var eave := 11.6
	# Plinth, nave hall, transept and chancel walls.
	FhU.blk(lm, "Granite", 0.25, -0.5, 11.75, 30.5, 2.0, 33.5)
	FhU.blk(lm, "Brick", 0.25, 0.0, 11.75, 29.5, eave, 32.5)
	FhU.blk(lm, "Brick", 1.4, 0.0, -10.85, 45.8, eave, 13.7)
	FhU.blk(lm, "Brick", 1.4, 0.0, -26.5, 28.0, eave - 1.0, 18.0)
	# Roofs: steep nave ridge at 28.8 m, lower transept and hipped chancel.
	FhU.ridge_z(lm, "Slate", "Brick", Vector3(0.25, eave, 11.75), 29.5, 32.5, 17.2, 0.5)
	FhU.ridge_x(lm, "Slate", "Brick", Vector3(1.4, eave, -10.85), 45.8, 13.7, 9.0, 0.5)
	FhU.hip(lm, "Slate", Vector3(1.4, eave - 1.0, -26.5), 28.5, 18.5, 9.0, 0.1)
	# Tall lancet windows down the walls and in the transept ends.
	for sx in [-1.0, 1.0]:
		FhU.openings(lm, "Glass", Vector3(0.25 + sx * 14.8, 0, -2.0), Vector3(0.25 + sx * 14.8, 0, 22.0),
			Vector3(sx, 0, 0), 2.5, 7, 1.5, 7.5)
		FhU.openings(lm, "Glass", Vector3(1.4 + sx * 22.95, 0, -15.0), Vector3(1.4 + sx * 22.95, 0, -6.0),
			Vector3(sx, 0, 0), 2.5, 3, 1.5, 7.5)
	# Entrance front: portal, rose window and the stepped gable between the towers.
	var fz := 28.0
	FhU.blk(lm, "Trim", 0.25, 0.0, fz - 0.6, 5.6, 7.0, 1.6)
	FhU.opening(lm, "Glass", Vector3(0.25, 0.0, fz + 0.25), Vector3(0, 0, 1), 3.0, 5.5)
	lm.disc("Glass", Vector3(0.25, 17.5, fz + 0.15), Vector3(0, 0, 1), 2.6, 16)
	lm.disc("Trim", Vector3(0.25, 17.5, fz + 0.1), Vector3(0, 0, 1), 3.2, 16)
	for sx in [-1.0, 1.0]:
		var tx: float = sx * 9.3
		var tz := 22.5
		FhU.blk(lm, "Brick", tx, 0.0, tz, 8.0, 37.0, 8.0)
		FhU.blk(lm, "Trim", tx, 21.0, tz, 8.6, 0.6, 8.6)
		FhU.blk(lm, "Trim", tx, 36.4, tz, 8.8, 1.0, 8.8)
		for f in 4:
			var r := Basis(Vector3.UP, PI * 0.5 * float(f))
			var out := r * Vector3(0, 0, 1)
			FhU.opening(lm, "Glass", Vector3(tx, 24.0, tz) + out * 4.05, out, 1.6, 8.5)
			FhU.opening(lm, "Glass", Vector3(tx, 6.0, tz) + out * 4.05, out, 1.4, 5.0)
			lm.box("Brick", Vector3(tx, 38.4, tz) + r * Vector3(3.4, 0, 3.4), Vector3(1.0, 1.8, 1.0))
		# Octagonal 37 m spire between four corner pinnacles.
		lm.spire("Slate", Vector3(tx, 37.0, tz), 3.7, 37.0, 0.0, 8)
		for qx in [-1.0, 1.0]:
			for qz in [-1.0, 1.0]:
				lm.spire("Slate", Vector3(tx + qx * 3.4, 37.4, tz + qz * 3.4), 0.7, 5.0, 0.0, 4)
	lm.commit(model)

# --- Kallio Church ---------------------------------------------------

## Lars Sonck's granite church on the Kallio hill (1912), origin at the
## OSM footprint centre, entrance and tower south: the tall 16 m wide nave
## (eaves 22.5 m, ridge 30.8 m), the wide transept, the rounded porch and
## the 65 m tower with its belfry, corner pinnacles and copper spire.
static func kallio(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8E8F8D", 4.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#5E605F", 4.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E9D89", 2.0, 0.5, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	# Nave, chancel apse and transept with their copper roofs.
	FhU.blk(lm, "Granite", 0.0, -2.0, -4.5, 16.0, 24.5, 33.0)
	FhU.ridge_z(lm, "Copper", "Granite", Vector3(0, 22.5, -4.5), 16.0, 33.0, 8.3, 0.5)
	FhU.blk(lm, "Granite", 0.0, 0.0, -21.3, 11.0, 17.0, 4.6)
	FhU.ridge_z(lm, "Copper", "Granite", Vector3(0, 17.0, -21.3), 11.0, 4.6, 4.0, 0.3)
	FhU.blk(lm, "Granite", 0.0, -2.0, 18.4, 49.0, 20.0, 12.8)
	FhU.ridge_x(lm, "Copper", "Granite", Vector3(0, 18.0, 18.4), 49.0, 12.8, 7.0, 0.5)
	for sx in [-1.0, 1.0]:
		FhU.openings(lm, "Glass", Vector3(sx * 8.05, 0, -18.0), Vector3(sx * 8.05, 0, 9.0), Vector3(sx, 0, 0),
				5.0, 6, 1.5, 10.0)
		FhU.openings(lm, "Glass", Vector3(sx * 24.55, 0, 14.0), Vector3(sx * 24.55, 0, 23.0), Vector3(sx, 0, 0),
				4.0, 2, 1.8, 9.0)
	# Rounded entrance porch under its low copper dome.
	lm.frustum("Granite", Vector3(1.0, -2.0, 28.0), 6.4, 6.0, 24.0, 12)
	lm.lathe("Copper", Vector3(1.0, 22.0, 28.0), FhU.dome_prof(6.2, 6.0), 12)
	# Tower on the south face of the transept.
	var tz := 22.0
	FhU.blk(lm, "Granite", 0.0, -2.0, tz, 10.0, 58.0, 12.0)
	FhU.blk(lm, "Dark", 0.0, 17.0, tz, 10.6, 0.8, 12.6)
	FhU.blk(lm, "Dark", 0.0, 55.2, tz, 10.8, 1.2, 12.8)
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(f))
		var out := r * Vector3(0, 0, 1)
		var half := 6.05 if f % 2 == 0 else 5.05
		FhU.opening(lm, "Glass", Vector3(0, 40.0, tz) + out * half, out, 2.0, 13.0)
		FhU.opening(lm, "Glass", Vector3(0, 8.0, tz) + out * half, out, 1.8, 6.0)
		for k in [-1.0, 1.0]:
			var corner: Vector3 = r * Vector3(k * 4.4, 0, 5.4)
			lm.frustum("Granite", Vector3(corner.x, 56.2, tz + corner.z), 1.0, 0.7, 2.6, 6)
	lm.spire("Copper", Vector3(0, 56.4, tz), 4.2, 8.0, 0.0, 8)
	lm.box("Dark", Vector3(0, 64.7, tz), Vector3(0.3, 0.6, 0.3))
	lm.commit(model)
