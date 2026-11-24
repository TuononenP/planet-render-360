class_name LandmarkPaGrandPetitPalais
extends RefCounted

## Grand Palais & Petit Palais (1900 Exposition Universelle; `PA-3`):
## - Grand Palais (45 m): 240 m Beaux-Arts Ionic limestone front, corner bronze quadrigas,
##   and the iconic sea-green steel & glass barrel-vault nave + central domed crossing.
## - Petit Palais (35 m): Charles Girault's gilded entrance arch, Ionic colonnade & ribbed dome.

static func grand_palais(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkPaKit.lutetian("#DFD4BA", 3.5))
	lm.use("Ashlar", LandmarkPaKit.ashlar("#C4B79C", 3.2))
	lm.use("Steel", LandmarkPaKit.verdigris("#58867A"))
	lm.use("Glass", LandmarkMaterials.glass("#8BAAB2"))
	lm.use("Bronze", LandmarkPaKit.verdigris("#4A6E60"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("VaultLamp", LandmarkMaterials.night_lit("#FFE4A8", 1.15, "#2A363C"))
	# Monumental 232 m Beaux-Arts limestone perimeter walls (+X east front faces Avenue Winston-Churchill)
	lm.box("Ashlar", Vector3(0.0, 2.0, 0.0), Vector3(92.0, 4.0, 232.0))
	# East & West long facades + North & South end pavilions (leaving central nave volume for the glass vault)
	for sx in [-1.0, 1.0]:
		lm.box("Stone", Vector3(float(sx) * 39.0, 12.5, 0.0), Vector3(14.0, 17.5, 228.0))
		lm.box("Stone", Vector3(float(sx) * 39.0, 21.8, 0.0), Vector3(15.2, 1.4, 229.6))
	for sz in [-1.0, 1.0]:
		lm.box("Stone", Vector3(0.0, 12.5, float(sz) * 107.0), Vector3(90.0, 17.5, 16.0))
		lm.box("Stone", Vector3(0.0, 22.0, float(sz) * 107.0), Vector3(91.6, 1.6, 17.4))
	# East main colonnade (Avenue Winston-Churchill) with triple central triumphal entrance & mosaic frieze
	LandmarkPaKit.colonnade_z(lm, "Stone", 46.8, 4.0, -96.0, 96.0, 22, 15.0, 0.62)
	lm.box("Gilt", Vector3(46.2, 16.5, 0.0), Vector3(0.24, 2.4, 186.0))
	# Projecting central triple-arch entrance avant-corps on +X
	lm.box("Stone", Vector3(49.5, 13.5, 0.0), Vector3(8.0, 23.0, 42.0))
	for kz in [-12.0, 0.0, 12.0]:
		lm.box("Glass", Vector3(53.6, 9.5, float(kz)), Vector3(0.2, 13.0, 7.5))
	LandmarkPaKit.colonnade_z(lm, "Stone", 54.0, 4.0, -18.0, 18.0, 8, 17.5, 0.68)
	lm.box("Gilt", Vector3(54.2, 23.5, 0.0), Vector3(1.2, 2.4, 16.0))
	# Two iconic monumental bronze Quadriga chariots ("L'Immortalité" & "L'Harmonie") crowning the NE & SE corners
	for sz in [-1.0, 1.0]:
		var qp := Vector3(43.0, 22.8, float(sz) * 106.0)
		lm.box("Stone", qp + Vector3(0.0, 2.0, 0.0), Vector3(11.0, 4.0, 11.0))
		LandmarkPaKit.equestrian(lm, "Bronze", qp + Vector3(0.0, 4.0, -1.8), 1.05, PI * 0.5, true)
		LandmarkPaKit.equestrian(lm, "Bronze", qp + Vector3(0.0, 4.0, 1.8), 1.05, PI * 0.5, true)
	# Iconic arched sea-green steel & glass barrel-vault nave (200 m long, 44 m wide, crest at 35 m)
	_barrel_vault_z(lm, "Glass", "Steel", -98.0, 98.0, 21.5, 22.0, 13.5, 15)
	# Transversal west wing barrel vault (Palais de la Découverte axis)
	_barrel_vault_x(lm, "Glass", "Steel", -62.0, 22.0, 21.5, 18.0, 11.5, 7)
	# Monumental central glazed steel dome & lantern spire rising to 45.0 m
	var dome_prof := LandmarkWestKit.dome_prof(23.0, 15.5, 12, 1.15)
	lm.lathe("Glass", Vector3(0.0, 24.0, 0.0), dome_prof, 24)
	for k in 16:
		var a := TAU * float(k) / 16.0
		var d := Vector3(cos(a), 0.0, sin(a))
		for j in dome_prof.size() - 2:
			lm.beam("Steel", Vector3(0.0, 24.0, 0.0) + d * (dome_prof[j].x + 0.25) + Vector3(0.0, dome_prof[j].y, 0.0),
				Vector3(0.0, 24.0, 0.0) + d * (dome_prof[j + 1].x + 0.25) + Vector3(0.0, dome_prof[j + 1].y, 0.0), 0.5, 0.45)
	lm.frustum("Steel", Vector3(0.0, 39.2, 0.0), 4.2, 3.0, 3.0, 12)
	lm.frustum("Gilt", Vector3(0.0, 42.2, 0.0), 0.8, 0.1, 2.8, 8)
	# Warm glowing inner nave strip so the glass vault glows softly at night
	lm.box("VaultLamp", Vector3(0.0, 24.0, 0.0), Vector3(26.0, 1.2, 176.0))
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(64.0, 2.0, -56.0), Vector3(46.0, 18.0, -56.0), 64.0, 0.95, 72.0],
		[Vector3(64.0, 2.0, 0.0), Vector3(48.0, 22.0, 0.0), 64.0, 1.10, 75.0],
		[Vector3(64.0, 2.0, 56.0), Vector3(46.0, 18.0, 56.0), 64.0, 0.95, 72.0],
		[Vector3(6.0, 26.0, 0.0), Vector3(0.0, 42.0, 0.0), 75.0, 1.0, 60.0],
	])

static func _barrel_vault_z(lm: LandmarkMesh, glass_mat: String, steel_mat: String,
		z0: float, z1: float, y0: float, rx: float, ry: float, ribs: int) -> void:
	var segs := 12
	var grid: Array[PackedVector3Array] = []
	for iz in [z1, z0]:
		var row := PackedVector3Array()
		for i in segs + 1:
			var a := PI * float(i) / float(segs)
			row.append(Vector3(-cos(a) * rx, y0 + sin(a) * ry, float(iz)))
		grid.append(row)
	lm.grid(glass_mat, grid)
	for r in ribs:
		var z := lerpf(z0, z1, float(r) / float(maxi(ribs - 1, 1)))
		LandmarkPaKit.arch_rib(lm, steel_mat, -rx, rx, y0, y0 + ry + 0.25, z, segs, 0.65, 0.55)

static func _barrel_vault_x(lm: LandmarkMesh, glass_mat: String, steel_mat: String,
		x0: float, x1: float, y0: float, rz: float, ry: float, ribs: int) -> void:
	var segs := 10
	var grid: Array[PackedVector3Array] = []
	for ix in [x0, x1]:
		var row := PackedVector3Array()
		for i in segs + 1:
			var a := PI * float(i) / float(segs)
			row.append(Vector3(float(ix), y0 + sin(a) * ry, -cos(a) * rz))
		grid.append(row)
	lm.grid(glass_mat, grid)
	for r in ribs:
		var x := lerpf(x0, x1, float(r) / float(maxi(ribs - 1, 1)))
		for i in segs:
			var a0 := PI * float(i) / float(segs)
			var a1 := PI * float(i + 1) / float(segs)
			lm.beam(steel_mat, Vector3(x, y0 + sin(a0) * ry, -cos(a0) * rz),
				Vector3(x, y0 + sin(a1) * ry, -cos(a1) * rz), 0.55, 0.45)

## Petit Palais (35 m; 126 x 84 m):
## Charles Girault's Beaux-Arts museum opposite Grand Palais: sweeping Ionic colonnade,
## gilded wrought-iron monumental arch portal, corner pavilions and central ribbed dome.
static func petit_palais(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkPaKit.lutetian("#E1D6BC", 3.4))
	lm.use("Ashlar", LandmarkPaKit.ashlar("#C5B89E", 3.2))
	lm.use("Zinc", LandmarkPaKit.zinc("#5A6672", 2.4))
	lm.use("Glass", LandmarkMaterials.glass("#2A353E"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Lamp", LandmarkMaterials.lit("#FFE4AA", 1.35))
	# Main U/trapezoidal museum body around its semicircular garden courtyard
	lm.box("Ashlar", Vector3(0.0, 2.0, 0.0), Vector3(124.0, 4.0, 76.0))
	lm.box("Stone", Vector3(0.0, 10.5, 22.0), Vector3(122.0, 13.5, 28.0))
	lm.box("Stone", Vector3(0.0, 10.5, -24.0), Vector3(106.0, 13.5, 24.0))
	for sx in [-1.0, 1.0]:
		lm.box("Stone", Vector3(float(sx) * 50.0, 10.5, -2.0), Vector3(22.0, 13.5, 64.0))
		# Corner pavilions with steep slate/zinc mansards
		lm.box("Stone", Vector3(float(sx) * 54.0, 12.0, 26.0), Vector3(18.0, 18.0, 22.0))
		LandmarkPaKit.mansard(lm, "Zinc", "Stone", "Glass",
			Vector3(float(sx) * 54.0, 21.0, 26.0), 18.4, 22.4, 5.5, 2)
	LandmarkPaKit.mansard(lm, "Zinc", "Stone", "Glass", Vector3(0.0, 17.2, 22.0), 92.0, 27.0, 4.6, 10)
	# Sweeping front Ionic colonnade facing Grand Palais (+Z)
	LandmarkPaKit.colonnade_x(lm, "Stone", -44.0, 44.0, 4.0, 37.2, 16, 12.2, 0.52)
	# Signature monumental gilded-iron entrance arch pavilion & central ribbed zinc dome (35.0 m)
	lm.box("Stone", Vector3(0.0, 12.0, 30.0), Vector3(24.0, 20.0, 20.0))
	lm.box("Gilt", Vector3(0.0, 10.0, 40.2), Vector3(10.0, 13.0, 0.45))
	lm.box("Glass", Vector3(0.0, 10.0, 39.9), Vector3(9.0, 12.0, 0.25))
	lm.frustum("Stone", Vector3(0.0, 21.8, 30.0), 9.2, 9.0, 4.0, 20)
	lm.lathe("Zinc", Vector3(0.0, 25.8, 30.0), LandmarkWestKit.dome_prof(9.0, 6.8, 10, 1.1), 20)
	lm.frustum("Gilt", Vector3(0.0, 32.5, 30.0), 1.6, 0.12, 2.5, 8)
	for lx in [-36.0, -16.0, 16.0, 36.0]:
		LandmarkPaKit.paris_lamp(lm, "Zinc", "Lamp", Vector3(float(lx), 0.0, 43.0), 4.0)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-34.0, 2.0, 52.0), Vector3(-34.0, 14.0, 36.0), 62.0, 0.9, 55.0],
		[Vector3(0.0, 2.0, 54.0), Vector3(0.0, 22.0, 34.0), 60.0, 1.1, 62.0],
		[Vector3(34.0, 2.0, 52.0), Vector3(34.0, 14.0, 36.0), 62.0, 0.9, 55.0],
	])
