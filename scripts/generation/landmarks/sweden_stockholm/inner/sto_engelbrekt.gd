class_name StoEngelbrekt
extends RefCounted

## Engelbrektskyrkan (Lars Israel Wahlman, 1914), Östermalm. Origin at the
## centre of OSM way 21572801 (55.4 x 38.4 m, bearing 76.5, registry yaw
## -13.5): +X along the long axis, +Z south, the entrance gable and the
## tower on the south side. 65 m to the cross (OSM tower part 1377989107).
## National-Romantic, dark purple-brown brick with ochre stone dressings,
## huge red tile roofs edged with green copper (photos in
## visual-plan/refs/landmarks/engelbrektskyrkan/):
## - The nave runs north-south (x -8.4..9.3, z -19.4..14): eaves 23 m, a
##   steep tile roof to a ridge at 36 m, a tall brick gable at each end
##   with a stone strip holding a tall window and an arcade of four slits
##   under the apex, green copper on the rakes, a small chimney finial.
## - Lower wings with big hipped tile roofs stand each side of the nave
##   (west x -21.2..-8.4, east x 9.3..21.8, eaves 15 m); the west wing
##   ends in a polygonal apse, the east wing in a low porch (x to 27.7).
## - The entrance arm projects south of the nave (z to 18.9): a gabled
##   front in brick with three tall arched windows, a ring window and a
##   stone cross-slit in the gable, a stone arched portal with a granite
##   stair; a lower cross-gable in front of the nave's tall south gable.
## - The tower (8 m square) stands in the south-west re-entrant corner:
##   a tapered brick shaft to 40.5 m with paired arched windows, a
##   corbelled stone cornice, a narrower belfry stage with open bell
##   louvres and four gold clocks, a stone cornice, a green copper
##   octagonal lantern, a gilt crown and a cross.
## Floodlit tower at night (StoChurchKit.flood).

const NX0 := -8.4
const NX1 := 9.3
const NZ0 := -19.4
const NZ1 := 14.0
const EAVE := 23.0
const RIDGE := 36.0
const WING_EAVE := 15.0
const TOWER := Vector2(-12.1, 12.0)
const TOP := 65.0

static func build(model: Node3D) -> void:
	var mats := StoChurchKit.materials("brick", "#5F3B34", "#B59E7B", "#5F8F7B")
	mats["Tile"] = LandmarkMaterials.pbr("terracotta", "#8F3C2A", 3.0)
	var lm := LandmarkMesh.new()
	StoChurchKit.use_all(lm, mats)
	_nave(lm, mats)
	_wings(lm, mats)
	_entrance(lm, mats)
	_tower(lm, mats)
	lm.commit(model)
	StoChurchKit.flood(model, Vector3(TOWER.x, 0, TOWER.y), TOP, 14.0)

static func _nave(lm: LandmarkMesh, mats: Dictionary) -> void:
	var cx := (NX0 + NX1) * 0.5
	var cz := (NZ0 + NZ1) * 0.5
	lm.box("Trim", Vector3(cx, 0.6, cz), Vector3(NX1 - NX0 + 0.5, 1.2, NZ1 - NZ0 + 0.5), Basis(), 0.0)
	LandmarkFhUtil.blk(lm, "Wall", cx, 0.0, cz, NX1 - NX0, EAVE, NZ1 - NZ0)
	LandmarkFhUtil.ridge_z(lm, "Tile", "Wall", Vector3(cx, EAVE, cz), NX1 - NX0, NZ1 - NZ0, RIDGE - EAVE, 0.6)
	# Copper edging on the gable rakes and an eave band along the long walls.
	for z in [NZ0 - 0.15, NZ1 + 0.15]:
		for s in [-1.0, 1.0]:
			var sg: float = s
			lm.beam("Copper", Vector3(cx + sg * (NX1 - cx + 0.4), EAVE - 0.2, float(z)),
				Vector3(cx, RIDGE + 0.2, float(z)), 0.5, 0.5, Vector3.BACK)
	for x in [NX0 - 0.1, NX1 + 0.1]:
		lm.box("Copper", Vector3(float(x), EAVE - 0.3, cz), Vector3(0.5, 0.6, NZ1 - NZ0 + 1.0), Basis(), 0.0)
	# The two gable ends: stone strip with a tall window, arcade under the apex.
	var tall := StoChurchKit.round_unit(mats, 1.6, 8.0, 0.3)
	var slit := StoChurchKit.round_unit(mats, 0.7, 2.2, 0.25)
	for g in [[NZ0, Vector3.FORWARD], [NZ1, Vector3.BACK]]:
		var z: float = g[0]
		var out: Vector3 = g[1]
		lm.box("Trim", Vector3(cx, 20.0, z + out.z * 0.12), Vector3(3.4, 17.0, 0.26), Basis(), 0.0)
		StoChurchKit.place(lm, tall, Vector3(cx, 14.0, z + out.z * 0.2), out)
		for k in 4:
			StoChurchKit.place(lm, slit, Vector3(cx - 2.1 + float(k) * 1.4, 27.6, z + out.z * 0.1), out)
		lm.box("Trim", Vector3(cx, RIDGE + 0.9, z), Vector3(1.1, 1.8, 1.1), Basis(), 0.0)
	# Clerestory arches and oculi high on the long walls above the wing roofs.
	var arch := StoChurchKit.round_unit(mats, 1.5, 4.0, 0.3)
	for k in 7:
		var z := lerpf(NZ0 + 4.0, NZ1 - 6.0, float(k) / 6.0)
		StoChurchKit.place(lm, arch, Vector3(NX0, 16.5, z), Vector3.LEFT)
		StoChurchKit.place(lm, arch, Vector3(NX1, 16.5, z), Vector3.RIGHT)
	LandmarkFhParts.band(lm, "Trim", Vector3(NX0, 0, NZ0), Vector3(NX0, 0, NZ1), Vector3.LEFT, 21.0, 0.45, 0.15)
	LandmarkFhParts.band(lm, "Trim", Vector3(NX1, 0, NZ1), Vector3(NX1, 0, NZ0), Vector3.RIGHT, 21.0, 0.45, 0.15)

static func _wings(lm: LandmarkMesh, mats: Dictionary) -> void:
	var win := StoChurchKit.round_unit(mats, 1.3, 3.2, 0.3)
	# West wing and its polygonal apse.
	_wing(lm, -21.2, NX0, -10.5, 8.2)
	_wing(lm, NX1, 21.8, -15.6, 14.9)
	var apse := PackedVector2Array()
	for k in 11:
		var a := PI * 0.5 + PI * float(k) / 10.0
		apse.append(Vector2(-21.2 + cos(a) * 6.5, -1.2 + sin(a) * 7.4))
	lm.poly_prism("Wall", apse, 0.0, 9.0, false)
	LandmarkFhParts.slope_roof(lm, "Tile", apse, Vector2(-21.2, -1.2), 0.12, 9.0, 15.0)
	for k in 10:
		var a := PI * 0.5 + PI * (float(k) + 0.5) / 10.0
		var o := Vector3(cos(a), 0, sin(a))
		StoChurchKit.place(lm, win, Vector3(-21.2 + o.x * 6.5, 3.2, -1.2 + o.z * 7.4), o)
	# East porch under a low gabled roof.
	LandmarkFhUtil.blk(lm, "Wall", 24.7, 0.0, -0.2, 6.0, 7.0, 9.6)
	LandmarkFhUtil.ridge_x(lm, "Tile", "Wall", Vector3(24.7, 7.0, -0.2), 6.0, 9.6, 3.2, 0.4)
	StoChurchKit.place(lm, win, Vector3(27.7, 2.0, -2.0), Vector3.RIGHT)
	StoChurchKit.place(lm, win, Vector3(27.7, 2.0, 2.0), Vector3.RIGHT)
	# Tall arched windows along the wings' outer walls.
	for k in 5:
		var z := lerpf(-8.0, 6.5, float(k) / 4.0)
		StoChurchKit.place(lm, win, Vector3(-21.2, 7.0, z), Vector3.LEFT)
	for k in 7:
		var z := lerpf(-13.0, 12.5, float(k) / 6.0)
		StoChurchKit.place(lm, win, Vector3(21.8, 7.0, z), Vector3.RIGHT)

## One wing block between x0 and x1, z0..z1 under a hipped tile roof with copper eaves.
static func _wing(lm: LandmarkMesh, x0: float, x1: float, z0: float, z1: float) -> void:
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	lm.box("Trim", Vector3(cx, 0.5, cz), Vector3(x1 - x0 + 0.4, 1.0, z1 - z0 + 0.4), Basis(), 0.0)
	LandmarkFhUtil.blk(lm, "Wall", cx, 0.0, cz, x1 - x0, WING_EAVE, z1 - z0)
	lm.box("Copper", Vector3(cx, WING_EAVE + 0.1, cz), Vector3(x1 - x0 + 1.0, 0.35, z1 - z0 + 1.0), Basis(), 0.0)
	LandmarkFhUtil.hip(lm, "Tile", Vector3(cx, WING_EAVE + 0.25, cz), x1 - x0 + 1.0, z1 - z0 + 1.0, 9.0, 0.22)

## The entrance arm: a gabled front with its windows, portal and stair, and a
## lower cross-gable in front of the nave's south gable.
static func _entrance(lm: LandmarkMesh, mats: Dictionary) -> void:
	var z0 := 4.0
	var z1 := 18.9
	var hw := 7.4
	var cz := (z0 + z1) * 0.5
	var eave := 14.5
	var rise := 11.0
	LandmarkFhUtil.blk(lm, "Wall", 0.8, 0.0, cz, hw * 2.0, eave, z1 - z0)
	lm.box("Trim", Vector3(0.8, 0.6, cz), Vector3(hw * 2.0 + 0.5, 1.2, z1 - z0 + 0.5), Basis(), 0.0)
	LandmarkFhUtil.ridge_z(lm, "Tile", "Wall", Vector3(0.8, eave, cz), hw * 2.0, z1 - z0, rise, 0.5)
	for s in [-1.0, 1.0]:
		var sg: float = s
		lm.beam("Copper", Vector3(0.8 + sg * (hw + 0.3), eave - 0.2, z1 + 0.15), Vector3(0.8, eave + rise + 0.2, z1 + 0.15),
			0.5, 0.5, Vector3.BACK)
	var out := Vector3.BACK
	var tall := StoChurchKit.round_unit(mats, 2.0, 8.6, 0.35)
	var side := StoChurchKit.round_unit(mats, 1.3, 6.0, 0.3)
	StoChurchKit.place(lm, tall, Vector3(0.8, 6.8, z1), out)
	StoChurchKit.place(lm, side, Vector3(-3.4, 6.8, z1), out)
	StoChurchKit.place(lm, side, Vector3(5.0, 6.8, z1), out)
	lm.box("Trim", Vector3(0.8, 12.0, z1 + 0.1), Vector3(3.6, 10.0, 0.22), Basis(), 0.0)
	# Ring window and the stone cross-slit in the gable.
	LandmarkFhParts.ring(lm, "Trim", Vector3(0.8, 20.0, z1 + 0.1), out, 1.0, 1.7, 0.25, 16)
	lm.disc("Glass", Vector3(0.8, 20.0, z1 + 0.14), out, 1.0, 16)
	lm.box("Trim", Vector3(0.8, 23.8, z1 + 0.1), Vector3(0.4, 2.2, 0.2), Basis(), 0.0)
	lm.box("Trim", Vector3(0.8, 24.2, z1 + 0.1), Vector3(1.4, 0.4, 0.2), Basis(), 0.0)
	# Portal and granite stair.
	var portal := StoChurchKit.round_unit(mats, 2.6, 4.4, 0.6)
	StoChurchKit.place(lm, portal, Vector3(-1.0, 0.4, z1), out)
	StoChurchKit.place(lm, portal, Vector3(2.6, 0.4, z1), out)
	LandmarkFhUtil.steps(lm, "Trim", Vector3(0.8, 0.0, z1 + 0.3), out, 8.0, 0.4, 0.15, 5)

static func _tower(lm: LandmarkMesh, mats: Dictionary) -> void:
	var at := TOWER
	var hw0 := 3.9
	var hw1 := 3.5
	var shaft := 40.5
	StoChurchKit.tapered_shaft(lm, "Wall", at.x, at.y, 0.0, shaft, hw0, hw1)
	lm.box("Trim", Vector3(at.x, 0.7, at.y), Vector3(hw0 * 2.0 + 0.5, 1.4, hw0 * 2.0 + 0.5), Basis(), 0.0)
	StoChurchKit.tower_band(lm, "Trim", at.x, at.y, lerpf(hw0, hw1, 8.0 / shaft), 8.0, 0.5, 0.2)
	StoChurchKit.tower_band(lm, "Trim", at.x, at.y, lerpf(hw0, hw1, 30.0 / shaft), 30.0, 0.4, 0.15)
	var tilt := atan((hw0 - hw1) / shaft)
	var pair := StoChurchKit.round_unit(mats, 0.8, 1.7, 0.25)
	var slit := StoChurchKit.round_unit(mats, 0.95, 4.6, 0.3)
	for d in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
		var out: Vector3 = d
		var side := Vector3.UP.cross(out)
		for y in [11.0, 15.5, 20.0, 24.5, 28.0]:
			for s in [-1.0, 1.0]:
				StoChurchKit.place(lm, pair, Vector3(at.x, y, at.y) + out * lerpf(hw0, hw1, y / shaft) + side * float(s) * 1.3, out, tilt)
		StoChurchKit.place(lm, slit, Vector3(at.x, 3.0, at.y) + out * hw0, out)
		StoChurchKit.place(lm, slit, Vector3(at.x, 33.0, at.y) + out * lerpf(hw0, hw1, 33.0 / shaft), out, tilt)
	# Corbelled stone cornice, then the narrower belfry stage.
	lm.box("Trim", Vector3(at.x, shaft + 0.4, at.y), Vector3(hw1 * 2.0 + 1.5, 0.8, hw1 * 2.0 + 1.5), Basis(), 0.0)
	for d in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
		var out: Vector3 = d
		var side := Vector3.UP.cross(out)
		for k in 5:
			var off := (float(k) - 2.0) * 1.3
			lm.box("Trim", Vector3(at.x, shaft - 0.5, at.y) + out * (hw1 + 0.35) + side * off, Vector3(0.7, 1.0, 0.7), Basis(), 0.0)
	var bhw := 3.1
	var b0 := shaft + 0.8
	var b1 := 53.5
	LandmarkFhUtil.blk(lm, "Wall", at.x, b0, at.y, bhw * 2.0, b1 - b0, bhw * 2.0)
	var louvre := StoChurchKit.round_unit(mats, 1.1, 3.6, 0.3)
	var hole := StoChurchKit.round_unit(mats, 0.6, 1.3, 0.2)
	for d in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
		var out: Vector3 = d
		var side := Vector3.UP.cross(out)
		for s in [-1.0, 1.0]:
			StoChurchKit.place(lm, louvre, Vector3(at.x, 43.0, at.y) + out * bhw + side * float(s) * 1.5, out)
			StoChurchKit.place(lm, hole, Vector3(at.x, 48.3, at.y) + out * bhw + side * float(s) * 1.5, out)
		StoChurchKit.clock(lm, Vector3(at.x, 51.2, at.y) + out * (bhw + 0.15), out, 1.2)
		lm.box("Trim", Vector3(at.x, 46.5, at.y) + out * bhw + side * 0.0, Vector3(0.5, 0.5, 0.5), Basis(), 0.0)
	lm.box("Trim", Vector3(at.x, b1 + 0.4, at.y), Vector3(bhw * 2.0 + 1.0, 0.8, bhw * 2.0 + 1.0), Basis(), 0.0)
	# Green copper lantern, gilt crown and cross.
	var lc := Vector3(at.x, b1 + 0.8, at.y)
	lm.frustum("Copper", lc, 2.9, 2.5, 3.6, 8, PI / 8.0)
	var glaze := StoChurchKit.round_unit(mats, 1.0, 2.2, 0.2)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var o := Vector3(cos(a), 0, sin(a))
		StoChurchKit.place(lm, glaze, lc + Vector3(0, 0.7, 0) + o * 2.55, o)
	lm.frustum("Copper", lc + Vector3(0, 3.6, 0), 3.0, 2.6, 0.4, 8, PI / 8.0)
	var crown := lc + Vector3(0, 4.0, 0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var o := Vector3(cos(a), 0, sin(a))
		lm.beam("Gilt", crown + o * 2.3, crown + o * 1.3 + Vector3(0, 1.4, 0), 0.14, 0.14)
		lm.beam("Gilt", crown + o * 1.3 + Vector3(0, 1.4, 0), crown + o * 0.2 + Vector3(0, 2.6, 0), 0.14, 0.14)
	lm.lathe("Copper", crown, PackedVector2Array([Vector2(1.9, 0), Vector2(1.4, 0.8), Vector2(0.3, 1.9), Vector2(0.0, 2.2)]), 8, 1.0, 1.0, PI / 8.0, false)
	var tip := crown + Vector3(0, 2.2, 0)
	StoChurchKit.finial(lm, tip, 0.3, TOP - tip.y)
