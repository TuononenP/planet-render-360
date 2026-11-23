class_name LandmarkMiWynwoodWalls
extends RefCounted

## Wynwood Walls - Wynwood, Miami (MI-6.5).
## Site: way:435845377 (25.801132, -80.195325), yaw_deg 88.0, footprint 53.5 x 35.6 m, 11.0 m.
##   - Three low concrete-block warehouse galleries (y = 0..7.5 m) around a paved courtyard.
##   - Bold procedural colour-block mural panels (rectangles, chevrons, discs) - original
##     geometric patterns only, no copied artwork.
##   - Concrete entry portals, courtyard royal palms, water-tank frame reaching 11.0 m.

const HEIGHT_M := 11.0
const MURAL_KEYS := ["MuralRed", "MuralYellow", "MuralBlue", "MuralTeal", "MuralPink", "MuralWhite"]

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Block", LandmarkMaterials.pbr("concrete", "#B9B7B0", 3.0))
	lm.use("Paving", LandmarkMaterials.pbr("gravel", "#9C9A94", 3.0))
	lm.use("MuralRed", LandmarkMaterials.paint("#E0352B", 0.7, 0.0))
	lm.use("MuralYellow", LandmarkMaterials.paint("#F7C920", 0.7, 0.0))
	lm.use("MuralBlue", LandmarkMaterials.paint("#1F5FD0", 0.7, 0.0))
	lm.use("MuralTeal", LandmarkMaterials.paint("#12B5A5", 0.7, 0.0))
	lm.use("MuralPink", LandmarkMaterials.paint("#F2539A", 0.7, 0.0))
	lm.use("MuralWhite", LandmarkMaterials.paint("#F4F2EA", 0.7, 0.0))
	lm.use("Steel", LandmarkMaterials.paint("#5B6168", 0.5, 0.6))
	lm.use("PalmTrunk", LandmarkMaterials.paint("#8D8A82", 0.80, 0.0))
	lm.use("PalmFrond", LandmarkMaterials.paint("#3C7A36", 0.75, 0.0))
	lm.use("SignLamp", LandmarkMaterials.lit("#FFB347", 1.8))

	lm.box("Paving", Vector3(0.0, -0.05, 0.0), Vector3(53.5, 0.3, 35.6))
	# Galleries: north (back), west and east wings
	lm.box("Block", Vector3(0.0, 3.75, -14.0), Vector3(53.5, 7.5, 7.6))
	lm.box("Block", Vector3(-23.0, 3.75, 4.0), Vector3(7.5, 7.5, 28.0))
	lm.box("Block", Vector3(23.0, 3.75, 4.0), Vector3(7.5, 7.5, 28.0))
	# Mural panels on courtyard-facing walls
	for i: int in 8:
		var x := -22.0 + 6.2 * float(i)
		_mural(lm, Vector3(x, 3.8, -10.1), Vector3(1.0, 0.0, 0.0), i)
	for i: int in 4:
		var z := -6.0 + 6.5 * float(i)
		_mural(lm, Vector3(-19.2, 3.8, z), Vector3(0.0, 0.0, 1.0), i + 1)
		_mural(lm, Vector3(19.2, 3.8, z), Vector3(0.0, 0.0, -1.0), i + 3)
	# Entry portals (south side)
	for px: float in [-4.0, 4.0]:
		lm.box("Block", Vector3(px, 3.0, 17.0), Vector3(1.4, 6.0, 1.4))
	lm.box("Block", Vector3(0.0, 6.3, 17.0), Vector3(10.0, 0.9, 1.6))
	lm.box("SignLamp", Vector3(0.0, 6.3, 17.85), Vector3(7.0, 0.35, 0.1))
	# Water-tank frame on the north gallery
	for tx: float in [-2.5, 2.5]:
		for tz: float in [-16.5, -11.5]:
			lm.beam("Steel", Vector3(tx - 20.0, 7.5, tz), Vector3(tx - 20.0, 8.4, tz), 0.4, 0.4)
	lm.box("Steel", Vector3(-20.0, 8.3, -14.0), Vector3(6.0, 0.3, 6.0))
	lm.frustum("MuralBlue", Vector3(-20.0, 8.45, -14.0), 2.4, 2.4, 2.55, 12)
	for pp: Vector2 in [Vector2(-8.0, 0.0), Vector2(9.0, 6.0), Vector2(-9.0, 10.0), Vector2(10.0, -4.0)]:
		LandmarkMiKit.royal_palm(lm, "PalmTrunk", "PalmFrond", Vector3(pp.x, 0.1, pp.y), 8.0, pp.x)
	lm.commit(model)

	var warm := Color(1.0, 0.82, 0.55)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-10.0, 9.0, 4.0), Vector3(0.0, 3.0, -12.0), 40.0, 1.2, 75.0, warm],
		[Vector3(10.0, 9.0, 4.0), Vector3(0.0, 3.0, -12.0), 40.0, 1.2, 75.0, warm],
	])

## One procedural mural: backing block with a chevron, disc and stripes. `along` is the wall tangent.
static func _mural(lm: LandmarkMesh, c: Vector3, along: Vector3, seed_i: int) -> void:
	var n := Vector3(-along.z, 0.0, along.x)
	if c.z < -9.0:
		n = Vector3(0, 0, 1)
	elif c.x < 0.0:
		n = Vector3(1, 0, 0)
	else:
		n = Vector3(-1, 0, 0)
	var basis := Basis(along, Vector3.UP, n)
	var k0: String = MURAL_KEYS[seed_i % 6]
	var k1: String = MURAL_KEYS[(seed_i + 2) % 6]
	var k2: String = MURAL_KEYS[(seed_i + 4) % 6]
	lm.box(k0, c + n * 0.05, Vector3(5.6, 6.2, 0.1), basis, 0.0)
	lm.box(k1, c + n * 0.12 + Vector3(0, -1.7, 0), Vector3(5.6, 1.6, 0.1), basis, 0.0)
	lm.disc(k2, c + n * 0.14 + Vector3(0, 1.4, 0), n, 1.3, 16)
	for s: float in [-1.0, 1.0]:
		var a := c + n * 0.15 + along * (s * 2.2) + Vector3(0, -0.2, 0)
		var b := c + n * 0.15 + Vector3(0, 1.0, 0)
		lm.beam(k2 if s > 0.0 else k1, a, b, 0.5, 0.05, n)
