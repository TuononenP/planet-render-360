extends RefCounted

## Grand Hôtel (Södra Blasieholmshamnen 8, Blasieholmen), with the adjoining
## Bolinder palace as a separate mass. Origin at the OSM footprint centre
## (relation 18489276, outer ring 80.5 x 79.1 m), the long quay front along
## local X. The registry yaw 37.5 turns local +X onto bearing 127.5 deg
## (the quay runs NW-SE) and the quay FRONT, facing the Royal Palace across
## Strömmen to the south-west, is +Z (bearing 217.5). The Bolinder palace
## stands at the +X (south-east) end, toward the Nationalmuseum. The sources
## doc's yaw -51.7 was an x-long reading of the 38.3 deg inner ranges; the
## aerial photo and the quay show the front runs along 127.5 deg instead.
##
## From the photos (front, quarter, aerial in visual-plan/refs/landmarks/
## grand_hotel_stockholm/):
## - 80 x 79 m block, salmon-orange render. Six floors of 28 windows a
##   row above the ground floor, the top storey a white band under the
##   cornice (24.5 m eave).
## - The quay front carries a long green-copper canopy at first-floor level
##   with striped awnings under it and a flower-box railing on top; a
##   narrow central oriel with a copper cap; quoined corner pavilions.
## - Steep green copper mansard (6 m rise) with a dormer over every bay and
##   hipped corner pavilions; a raised central roof block in white with six
##   round windows and the gilt name, a glazed lantern with a copper cap,
##   and a row of flagpoles along the front ridge.
## - Bolinder palace (cream render, dark mansard, two round corner turrets
##   with domes, green shop awnings) beside it on the quay.
## Registry height is the centre flagpole tip. Window counts follow the
## front photo; the inner courtyards are hidden under the roof.

const K = preload("res://scripts/generation/landmarks/sweden_stockholm/palaces/sto_pal_kit.gd")

const HX := 40.0
const HZ := 39.5
const EAVE := 24.5
const MANSARD := 6.0
const RIDGE := 30.5
const COLS := 28
const BX1 := 68.0
const BZ0 := 4.0
const B_EAVE := 21.5
const TOP := 42.5

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#C98C72", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E9E4D6", 2.5))
	lm.use("Copper", LandmarkMaterials.pbr("copper", "#6A927E", 2.0, 0.55, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#2B3338"))
	lm.use("Awning", LandmarkMaterials.pbr("render", "#E6E1D3", 2.0))
	lm.use("Iron", LandmarkMaterials.paint("#2B2C2D", 0.5, 0.5))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Pole", LandmarkMaterials.paint("#E8E8E4", 0.5, 0.3))
	lm.use("FlagRed", LandmarkMaterials.paint("#C2272D", 0.8, 0.0))
	lm.use("FlagBlue", LandmarkMaterials.paint("#1F5FA8", 0.8, 0.0))
	lm.use("BWall", LandmarkMaterials.pbr("render", "#E4DFD2", 3.0))
	lm.use("Slate", LandmarkMaterials.pbr("slate", "#4A4E54", 2.5))
	_block(lm)
	_quay_front(lm)
	_mansard(lm)
	_attic(lm)
	_bolinder(lm)
	lm.commit(model)
	var warm := Color(1.0, 0.88, 0.7)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-22.0, 1.5, 64.0), Vector3(-20.0, 14.0, HZ), 45.0, 0.9, 62.0, warm],
		[Vector3(22.0, 1.5, 64.0), Vector3(20.0, 14.0, HZ), 45.0, 0.9, 62.0, warm],
		[Vector3(0.0, 1.5, 66.0), Vector3(0.0, 24.0, HZ), 40.0, 0.7, 70.0, warm],
		[Vector3(56.0, 1.5, 62.0), Vector3(55.0, 12.0, HZ), 45.0, 0.8, 55.0, warm],
	])

# --- Block -------------------------------------------------------------

## The 80 x 79 m block: wall skins with a real window grid on all four
## faces (six salmon floors and the white top storey), cornice and quoins.
static func _block(lm: LandmarkMesh) -> void:
	K.rb(lm, "Wall", -HX, HX, 0.0, EAVE, -HZ, HZ)
	var faces := [[Vector3(-HX, 0, HZ), Vector3(HX, 0, HZ), Vector3(0, 0, 1), COLS],
		[Vector3(HX, 0, -HZ), Vector3(-HX, 0, -HZ), Vector3(0, 0, -1), COLS],
		[Vector3(HX, 0, HZ), Vector3(HX, 0, -HZ), Vector3(1, 0, 0), 27],
		[Vector3(-HX, 0, -HZ), Vector3(-HX, 0, HZ), Vector3(-1, 0, 0), 27]]
	for f in faces:
		var a: Vector3 = f[0]
		var b: Vector3 = f[1]
		var out: Vector3 = f[2]
		var cols: int = f[3]
		LandmarkFhParts.pierce(lm, "Wall", "Glass", a, b, out, 0.0, 21.2, cols, 6, Vector2(1.2, 2.0), 1.0, 3.5, 0.3)
		LandmarkFhParts.pierce(lm, "Trim", "Glass", a, b, out, 21.2, 3.3, cols, 1, Vector2(1.2, 1.8), 0.7, 3.3, 0.3)
		LandmarkDetail.cornice(lm, "Trim", a + Vector3(0, EAVE - 1.0, 0) + out * 0.3, b + Vector3(0, EAVE - 1.0, 0) + out * 0.3,
			out, 1.0, true)
	# String courses between the salmon floors.
	for y in [4.6, 11.6, 18.6]:
		K.rb(lm, "Trim", -HX - 0.25, HX + 0.25, float(y), float(y) + 0.25, -HZ - 0.25, HZ + 0.25, 0.0)
	# Quoined corner pavilions.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var cx: float = float(sx) * (HX - 0.6)
			var cz: float = float(sz) * (HZ - 0.6)
			K.rb(lm, "Trim", cx - 1.5, cx + 1.5, 4.6, 21.2, cz - 1.5, cz + 1.5, 0.0)

## The quay front: copper canopy with its flower railing, awnings below,
## the central oriel.
static func _quay_front(lm: LandmarkMesh) -> void:
	var out := Vector3(0, 0, 1)
	var z1 := HZ + 5.0
	var a := Vector3(-HX + 1.0, 5.4, HZ + 0.3)
	var b := Vector3(HX - 1.0, 5.4, HZ + 0.3)
	var da := Vector3(0, -0.8, 4.7)
	var nrm := Vector3(0, 4.7, 0.8).normalized()
	lm.quad("Copper", a, b, b + da, a + da, nrm)
	lm.quad("Copper", a + da, b + da, b, a, -nrm)
	K.rb(lm, "Copper", -HX + 1.0, HX - 1.0, 4.35, 4.85, z1 - 0.2, z1 + 0.05, 0.0)
	# Flower railing on the canopy edge.
	K.rb(lm, "Iron", -HX + 1.0, HX - 1.0, 4.9, 5.0, z1 - 0.25, z1 - 0.15, 0.0)
	K.rb(lm, "Iron", -HX + 1.0, HX - 1.0, 5.75, 5.85, z1 - 0.25, z1 - 0.15, 0.0)
	var x := -HX + 1.5
	while x < HX - 1.0:
		lm.beam("Iron", Vector3(x, 4.9, z1 - 0.2), Vector3(x, 5.85, z1 - 0.2), 0.08, 0.08)
		x += 1.6
	# Striped awnings under the canopy.
	for t in K.evenly(19, 4.1):
		K.awning(lm, "Awning", Vector3(float(t), 4.3, HZ + 0.4), out, 3.8, 3.6, 1.7)
	# Central oriel with copper cap.
	K.rb(lm, "Trim", -3.0, 3.0, 5.2, 21.4, HZ + 0.3, HZ + 1.3)
	for row in 5:
		for c in K.evenly(3, 1.7):
			LandmarkFhUtil.opening(lm, "Glass", Vector3(float(c), 6.0 + float(row) * 3.3, HZ + 1.33), out, 1.0, 2.0, false)
	LandmarkFhUtil.hip(lm, "Copper", Vector3(0, 21.4, HZ + 0.8), 6.4, 1.8, 1.6, 0.2)
	# Balconies on a few upper windows.
	for t in [-26.0, -10.0, 10.0, 26.0]:
		for y in [8.0, 11.5]:
			K.rb(lm, "Iron", float(t) - 1.4, float(t) + 1.4, float(y) - 0.1, float(y) + 0.9, HZ + 0.3, HZ + 0.95, 0.0)

# --- Roofs -------------------------------------------------------------

## Mansard on a four-face dormer ring, corner pavilion hips.
static func _mansard(lm: LandmarkMesh) -> void:
	var w := 2.0 * HX + 0.6
	var d := 2.0 * HZ + 0.6
	LandmarkFhUtil.hip(lm, "Copper", Vector3(0, EAVE, 0), w, d, MANSARD, (w - 6.0) / w)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			LandmarkFhUtil.hip(lm, "Copper", Vector3(float(sx) * (HX - 6.2), EAVE, float(sz) * (HZ - 6.2)), 13.2, 13.2, MANSARD + 1.3, 0.52)
	# Dormers over every bay on all four slopes.
	var front: Array = K.evenly(COLS, 2.0 * HX / float(COLS))
	var side: Array = K.evenly(27, 2.0 * HZ / 27.0)
	_dormers(lm, Vector3(0, 0, HZ + 0.3), Vector3(0, 0, 1), front)
	_dormers(lm, Vector3(0, 0, -HZ - 0.3), Vector3(0, 0, -1), front)
	_dormers(lm, Vector3(HX + 0.3, 0, 0), Vector3(1, 0, 0), side)
	_dormers(lm, Vector3(-HX - 0.3, 0, 0), Vector3(-1, 0, 0), side)

static func _dormers(lm: LandmarkMesh, p: Vector3, out: Vector3, offs: Array) -> void:
	var along := K.right(out)
	var basis := Basis(along, Vector3.UP, out)
	for t in offs:
		var c: Vector3 = p + along * float(t) - out * 1.2 + Vector3(0, 27.3, 0)
		lm.box("Copper", c, Vector3(1.7, 2.0, 1.5), basis, 0.0)
		lm.quad("Glass", c + out * 0.76 - along * 0.55 - Vector3(0, 0.75, 0), c + out * 0.76 + along * 0.55 - Vector3(0, 0.75, 0),
			c + out * 0.76 + along * 0.55 + Vector3(0, 0.75, 0), c + out * 0.76 - along * 0.55 + Vector3(0, 0.75, 0), out)
		lm.gable("Copper", c + Vector3(0, 1.0, 0), 1.9, 1.7, 0.6, basis, 0.1)

## The raised white central roof block with its six round windows and the
## gilt name, the lantern and the flagpoles along the front ridge.
static func _attic(lm: LandmarkMesh) -> void:
	var zf := HZ - 3.0
	K.rb(lm, "Trim", -16.0, 16.0, RIDGE - 0.1, RIDGE + 3.8, -22.0, zf)
	LandmarkFhUtil.hip(lm, "Copper", Vector3(0, RIDGE + 3.8, (-22.0 + zf) * 0.5), 33.0, zf + 22.0 + 0.6, 1.0, 0.8)
	for t in K.evenly(6, 4.8):
		var c := Vector3(float(t), RIDGE + 1.9, zf + 0.05)
		LandmarkFhParts.ring(lm, "Copper", c, Vector3(0, 0, 1), 0.85, 1.2, 0.25, 12)
		lm.disc("Glass", c + Vector3(0, 0, 0.05), Vector3(0, 0, 1), 0.85, 12)
	K.rb(lm, "Gilt", -9.0, 9.0, RIDGE + 3.9, RIDGE + 4.9, zf - 1.5, zf - 1.3, 0.0)
	# Lantern: glazed stage and a copper cap with its flagpole.
	var ly := RIDGE + 4.8
	K.rb(lm, "Copper", -1.8, 1.8, ly, ly + 0.6, -1.8, 1.8)
	K.rb(lm, "Glass", -1.2, 1.2, ly + 0.6, ly + 3.2, -1.2, 1.2, 0.0)
	for s in [-1.0, 1.0]:
		for t in [-1.0, 1.0]:
			lm.beam("Copper", Vector3(float(s) * 1.2, ly + 0.6, float(t) * 1.2), Vector3(float(s) * 1.2, ly + 3.2, float(t) * 1.2), 0.2, 0.2)
	K.rb(lm, "Copper", -1.7, 1.7, ly + 3.2, ly + 3.6, -1.7, 1.7)
	LandmarkFhUtil.hip(lm, "Copper", Vector3(0, ly + 3.6, 0), 3.4, 3.4, 2.4, 0.0)
	K.flag(lm, "Pole", "FlagBlue", Vector3(0, ly + 6.0, 0), TOP - (ly + 6.0), Vector3(1, 0, 0), 2.6, 1.7)
	# Flagpoles along the front ridge.
	var poles := [[-36.0, 7.5, "FlagRed"], [-28.0, 8.5, "FlagBlue"], [-20.0, 7.5, "FlagRed"],
		[20.0, 7.5, "FlagBlue"], [28.0, 8.5, "FlagRed"], [36.0, 7.5, "FlagBlue"]]
	for p in poles:
		K.flag(lm, "Pole", p[2], Vector3(float(p[0]), RIDGE, HZ - 3.5), float(p[1]), Vector3(1, 0, 0), 2.4, 1.5)

# --- Bolinder palace -----------------------------------------------------

## The separate mass at the south-east end: cream render, dark mansard,
## two round corner turrets with domes, green shop awnings on the quay.
static func _bolinder(lm: LandmarkMesh) -> void:
	var cx := (HX + BX1) * 0.5
	var cz := (BZ0 + HZ) * 0.5
	var w := BX1 - HX
	var d := HZ - BZ0
	K.rb(lm, "BWall", HX, BX1, 0.0, B_EAVE, BZ0, HZ)
	var front_a := Vector3(HX, 0, HZ)
	var front_b := Vector3(BX1, 0, HZ)
	LandmarkFhParts.pierce(lm, "BWall", "Glass", front_a, front_b, Vector3(0, 0, 1), 0.0, B_EAVE - 0.3, 9, 5,
		Vector2(1.3, 2.3), 1.0, 3.8, 0.3)
	LandmarkFhParts.pierce(lm, "BWall", "Glass", Vector3(BX1, 0, HZ), Vector3(BX1, 0, BZ0), Vector3(1, 0, 0), 0.0,
		B_EAVE - 0.3, 11, 5, Vector2(1.3, 2.3), 1.0, 3.8, 0.3)
	LandmarkDetail.cornice(lm, "Trim", Vector3(HX, B_EAVE - 1.3, HZ + 0.3), Vector3(BX1, B_EAVE - 1.3, HZ + 0.3), Vector3(0, 0, 1), 1.3, true)
	LandmarkDetail.cornice(lm, "Trim", Vector3(BX1 + 0.3, B_EAVE - 1.3, HZ), Vector3(BX1 + 0.3, B_EAVE - 1.3, BZ0), Vector3(1, 0, 0), 1.3, true)
	for y in [4.8, 12.4]:
		K.rb(lm, "Trim", HX, BX1 + 0.3, float(y), float(y) + 0.3, BZ0, HZ + 0.3, 0.0)
	LandmarkFhUtil.hip(lm, "Slate", Vector3(cx, B_EAVE, cz), w + 0.6, d + 0.6, 4.2, 0.72)
	for t in K.evenly(9, w / 9.0):
		K.rb(lm, "Slate", cx + float(t) - 0.7, cx + float(t) + 0.7, B_EAVE + 0.3, B_EAVE + 2.3, HZ - 1.0, HZ + 0.1, 0.0)
		lm.quad("Glass", Vector3(cx + float(t) - 0.5, B_EAVE + 0.5, HZ + 0.12), Vector3(cx + float(t) + 0.5, B_EAVE + 0.5, HZ + 0.12),
			Vector3(cx + float(t) + 0.5, B_EAVE + 1.9, HZ + 0.12), Vector3(cx + float(t) - 0.5, B_EAVE + 1.9, HZ + 0.12), Vector3(0, 0, 1))
	# Round corner turrets with domes.
	for tx in [HX + 1.6, BX1 - 1.6]:
		var base := Vector3(float(tx), 6.0, HZ - 1.6)
		lm.frustum("BWall", base, 2.4, 2.4, B_EAVE + 3.4 - 6.0, 14)
		lm.frustum("Trim", base + Vector3(0, 7.5, 0), 2.55, 2.55, 0.4, 14)
		lm.frustum("Trim", base + Vector3(0, B_EAVE - 3.0 - 6.0 + 3.4, 0), 2.6, 2.6, 0.4, 14)
		for k in 8:
			var ang := TAU * float(k) / 8.0
			K.rb(lm, "Glass", base.x + cos(ang) * 2.42 - 0.35, base.x + cos(ang) * 2.42 + 0.35, 14.0, 16.0,
				base.z + sin(ang) * 2.42 - 0.35, base.z + sin(ang) * 2.42 + 0.35, 0.0)
		lm.lathe("Slate", Vector3(base.x, B_EAVE + 3.4, base.z), LandmarkFhUtil.dome_prof(2.5, 2.8), 14)
		lm.beam("Iron", Vector3(base.x, B_EAVE + 6.0, base.z), Vector3(base.x, B_EAVE + 7.6, base.z), 0.12, 0.12)
	# Shop awnings along the quay front (green, in the photos).
	for t in K.evenly(7, 3.4):
		K.awning(lm, "Copper", Vector3(cx + float(t), 4.4, HZ + 0.3), Vector3(0, 0, 1), 2.6, 1.6, 1.0)
