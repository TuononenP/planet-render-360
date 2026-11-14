class_name LandmarkFhHeroHarbour
extends RefCounted

## Helsinki harbour and Esplanadi landmarks, true metres.
## Havis Amanda (5 m including fountain, bronze and pink granite):
## https://tpr.hel.fi/TPRalusta/notification/info/3229/
## SkyWheel (40 m): https://skywheel.fi/en/home/
## Kappeli glass verandas: https://tpr.hel.fi/TPRalusta/notification/info/605/
## Allas layout: https://allasseapool.fi/en/

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

static func _materials() -> LandmarkMesh:
	var lm := LandmarkMesh.new()
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#A28A66", 2.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#B8A898", 2.0))
	lm.use("Trim", LandmarkMaterials.paint("#DADDD8"))
	lm.use("Metal", LandmarkMaterials.paint("#29483D"))
	lm.use("Glass", LandmarkMaterials.glass("#5A7881"))
	return lm

## The green cast-iron framework and glazed verandas, with polygonal
## end pavilions and the high central roof lantern.
static func kappeli(model: Node3D) -> void:
	var lm := _materials()
	U.blk(lm, "Stone", 0, 0, 0, 47.0, 0.55, 20.0)
	U.blk(lm, "Wood", 0, 0.55, 0, 31.0, 5.1, 14.0)
	U.hip(lm, "Metal", Vector3(0, 5.65, 0), 32.0, 15.0, 3.2, 0.3)
	for s in [-1.0, 1.0]:
		# The verandas are actual glazed surfaces with a fine iron grid.
		U.blk(lm, "Glass", 0, 0.8, s * 8.2, 32.0, 3.9, 3.0)
		U.blk(lm, "Metal", 0, 4.7, s * 8.2, 32.5, 0.25, 3.4)
		for i in 17:
			U.blk(lm, "Metal", (float(i) - 8.0) * 1.9, 0.55, s * 9.73, 0.10, 4.2, 0.10)
		for y in [1.4, 3.7, 4.6]:
			U.blk(lm, "Metal", 0, y, s * 9.74, 32.0, 0.10, 0.10)
		var c := Vector3(s * 19.0, 0.55, 0)
		lm.frustum("Glass", c, 7.0, 7.0, 4.8, 8, PI / 8)
		lm.lathe("Metal", c + Vector3.UP * 4.8, PackedVector2Array([Vector2(7.3, 0),
			Vector2(4.8, 2.2), Vector2(0, 3.2)]), 8, 1.0, 1.0, PI / 8, false)
		for i in 8:
			var a := TAU * float(i) / 8.0 + PI / 8
			var p := c + Vector3(cos(a), 0, sin(a)) * 7.0
			U.blk(lm, "Metal", p.x, p.y, p.z, 0.14, 4.8, 0.14)
		lm.frustum("Metal", c + Vector3.UP * 8.0, 0.13, 0.06, 0.8, 12)
	U.blk(lm, "Glass", 0, 7.4, 0, 8.0, 1.9, 5.0)
	U.hip(lm, "Metal", Vector3(0, 9.3, 0), 9.0, 6.0, 1.5, 0.1)
	# Esplanade terrace: entrance steps, lamp posts and the low stone
	# kerb that separates the restaurant terrace from the park path.
	U.steps(lm, "Stone", Vector3(0, 0, 10.2), Vector3.BACK, 10.0, 0.45, 0.18, 3)
	for x in [-16.0, -5.5, 5.5, 16.0]:
		U.blk(lm, "Metal", x, 0, 11.4, 0.14, 3.1, 0.14)
		lm.lathe("Glass", Vector3(x, 3.1, 11.4), U.ball(0.28), 10)
	U.blk(lm, "Stone", 0, 0, 12.3, 44.0, 0.28, 0.5)
	lm.commit(model)

## Pink-granite basin, bronze pedestal, seaweed, four sea lions and the
## slender standing figure. Small sculpture is articulated rather than
## represented by a block; the casting's exact anatomy is approximated.
static func havis(model: Node3D) -> void:
	var lm := _materials()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#B48E83", 1.2))
	lm.use("Bronze", LandmarkMaterials.paint("#436457", 0.5, 0.65))
	lm.use("Water", LandmarkMaterials.glass("#55796B"))
	lm.lathe("Granite", Vector3.ZERO, PackedVector2Array([Vector2(4.5, 0), Vector2(4.5, 0.25),
		Vector2(4.2, 0.40), Vector2(3.95, 0.42), Vector2(3.95, 0.25)]), 64)
	lm.disc("Water", Vector3(0, 0.28, 0), Vector3.UP, 3.95, 64)
	lm.lathe("Bronze", Vector3(0, 0.3, 0), PackedVector2Array([Vector2(1.5, 0), Vector2(1.2, 0.35),
		Vector2(0.55, 1.3), Vector2(0.75, 1.8), Vector2(0.45, 2.0)]), 32)
	for i in 4:
		var a := TAU * float(i) / 4.0
		var d := Vector3(cos(a), 0, sin(a))
		var p := d * 3.4
		lm.lathe("Bronze", p + Vector3.UP * 0.42, U.ball(0.36), 16, 1.3, 2.0)
		lm.beam("Bronze", p + Vector3(0, 0.7, 0), p + d * 0.5 + Vector3(0, 1.2, 0), 0.38, 0.5)
		lm.lathe("Bronze", p + d * 0.5 + Vector3(0, 1.0, 0), U.ball(0.27), 16)
		# Fish heads around the pedestal, mouths facing the basin.
		lm.beam("Bronze", d * 0.8 + Vector3(0, 1.1, 0), d * 1.4 + Vector3(0, 1.2, 0), 0.3)
	var hip := Vector3(0.12, 3.3, 0)
	lm.beam("Bronze", Vector3(-0.12, 2.25, 0), hip + Vector3(-0.14, 0, 0), 0.18, 0.2)
	lm.beam("Bronze", Vector3(0.22, 2.25, 0), hip + Vector3(0.14, 0, 0), 0.17, 0.2)
	lm.lathe("Bronze", hip - Vector3.UP * 0.15, PackedVector2Array([Vector2(0.22, 0),
		Vector2(0.20, 0.3), Vector2(0.15, 0.55), Vector2(0.29, 0.9), Vector2(0.22, 1.05)]), 24)
	lm.frustum("Bronze", hip + Vector3(0, 0.95, 0), 0.10, 0.10, 0.25, 16)
	lm.lathe("Bronze", Vector3(0.12, 4.50, 0), U.ball(0.25), 24, 0.85, 1.0)
	lm.beam("Bronze", hip + Vector3(-0.25, 0.85, 0), hip + Vector3(-0.38, 0.12, 0.08), 0.12)
	lm.beam("Bronze", hip + Vector3(0.25, 0.85, 0), hip + Vector3(0.38, 0.15, -0.08), 0.12)
	lm.commit(model)

## White structural rim in two planes, tension spokes and thirty blue
## cabins. The frame is vertical in XY and its axle runs along Z.
static func skywheel(model: Node3D) -> void:
	var lm := _materials()
	lm.use("Cabin", LandmarkMaterials.glass("#4D8FB0"))
	var centre := Vector3(0, 22.5, 0)
	var radius := 17.5
	for s in [-1.0, 1.0]:
		for i in 120:
			var a := TAU * float(i) / 120.0
			var b := TAU * float(i + 1) / 120.0
			lm.beam("Trim", centre + Vector3(cos(a) * radius, sin(a) * radius, s * 1.0),
				centre + Vector3(cos(b) * radius, sin(b) * radius, s * 1.0), 0.30)
		for i in 30:
			var a := TAU * float(i) / 30.0
			var rim := centre + Vector3(cos(a) * radius, sin(a) * radius, s * 1.0)
			lm.beam("Trim", centre + Vector3(0, 0, s * 1.8), rim, 0.065)
		for x in [-7.0, 7.0]:
			lm.beam("Trim", Vector3(x, 0.5, s * 5.0), centre + Vector3(0, 0, s * 1.8), 0.85)
	lm.beam("Metal", centre + Vector3(0, 0, -2.0), centre + Vector3(0, 0, 2.0), 1.0)
	for i in 30:
		var a := TAU * float(i) / 30.0
		var p := centre + Vector3(cos(a) * radius, sin(a) * radius, 0)
		lm.beam("Trim", p + Vector3(0, 0, -1), p + Vector3(0, 0, 1), 0.20)
		# Gondolas hang below the pivot and stay upright.
		U.blk(lm, "Cabin", p.x, p.y - 1.75, 0, 1.65, 1.65, 2.0)
		U.blk(lm, "Trim", p.x, p.y - 1.80, 0, 1.7, 0.18, 2.05)
		U.blk(lm, "Trim", p.x, p.y - 0.1, 0, 1.7, 0.18, 2.05)
	U.blk(lm, "Wood", 0, 0, 0, 22.0, 0.6, 12.0)
	lm.commit(model)

## Timber terraces, three sea-level pools and sauna pavilion. Pool
## surfaces sit below the raised boardwalk so they read as openings.
static func allas(model: Node3D) -> void:
	var lm := _materials()
	lm.use("Pool", LandmarkMaterials.glass("#398D9B"))
	# Boardwalk strips leave the pool areas uncovered.
	for x in [-27.0, 0.0, 27.0]:
		U.blk(lm, "Wood", x, 0, 10.0, 5.0, 0.8, 40.0)
	for z in [-11.0, 31.0]:
		U.blk(lm, "Wood", 0, 0, z, 59.0, 0.8, 4.0)
	for pool in [[-13.5, 8.0, 22.0, 25.0], [13.5, 8.0, 22.0, 25.0]]:
		var x := float(pool[0])
		var z := float(pool[1])
		U.blk(lm, "Pool", x, 0.35, z, float(pool[2]), 0.05, float(pool[3]))
		for side in [-1.0, 1.0]:
			U.blk(lm, "Trim", x + side * 11.1, 0.4, z, 0.18, 0.45, 25.2)
	# Lane ropes across both main pools and benches along the boardwalk.
	for pool_x in [-13.5, 13.5]:
		for lane in 5:
			U.blk(lm, "Trim", pool_x - 8.0 + float(lane) * 4.0, 0.42, 8.0, 0.14, 0.07, 24.0)
	for bx in [-22.0, -6.0, 10.0, 24.0]:
		U.blk(lm, "Wood", bx, 1.25, -9.0, 3.2, 0.14, 0.7)
		U.blk(lm, "Metal", bx - 1.3, 0.8, -9.0, 0.12, 0.45, 0.6)
		U.blk(lm, "Metal", bx + 1.3, 0.8, -9.0, 0.12, 0.45, 0.6)
	U.blk(lm, "Pool", 14, 0.35, 25.0, 12.0, 0.05, 6.0)
	U.blk(lm, "Wood", -4.0, 0, -23.0, 48.0, 5.8, 18.0)
	U.blk(lm, "Metal", -4.0, 5.8, -23.0, 49.0, 0.25, 19.0)
	U.window_grid(lm, "Glass", Vector3(-26, 0, -13.9), Vector3(18, 0, -13.9), Vector3.BACK,
		0.9, 1, 1.0, 17, 2.2, 3.7)
	# Roof terrace rail, stairs and sauna ventilation stacks.
	for x in [-27.0, 19.0]:
		lm.beam("Metal", Vector3(x, 7.0, -31), Vector3(x, 7.0, -15), 0.06)
	for x in [-15.0, -5.0, 5.0]:
		U.blk(lm, "Metal", x, 6.05, -27.0, 0.45, 1.0, 0.45)
	U.steps(lm, "Wood", Vector3(20, 0, -15), Vector3.BACK, 5.0, 0.3, 0.2, 29)
	lm.commit(model)
