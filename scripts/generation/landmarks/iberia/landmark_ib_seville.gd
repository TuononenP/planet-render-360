class_name LandmarkIbSeville
extends RefCounted

## The Real Alcazar of Seville in true metres, origin at the Patio de las
## Doncellas, the palace front toward +Z over the Patio de la Monteria
## and the gardens behind it (-Z).

const ALC_TOP := 25.8

## The Mudejar palace of Pedro I (1356-1366) and its courts: ochre
## plastered walls; the palace front on the Monteria (inscribed 1364)
## with its central body of a lintelled door in an alfiz between blind
## lobed arcades, paired twin windows (ajimeces) above, the mocarabe
## frieze and tiled inscription band under the great carved wooden
## eaves on corbels, and upper galleries of lobed arches either side.
## Behind it the Court of the Maidens with its long sunken pool, lobed
## arcades of seven bays on the long sides and five on the short ones
## and Luis de Vega's Renaissance upper gallery (1540-1572); the Hall of
## Ambassadors under its battlemented tiled cupola and lantern; the
## Gothic palace of Alfonso X with buttresses; the Monteria court with
## the Casa de Contratacion arcade and the crenellated wall of the Lion
## Gate; and the gardens: hedged parterres, pools, fountains, palms, the
## Grotesque gallery on the old wall and Charles V's arcaded pavilion.
static func seville_alcazar(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#DCC79E", 3.0))
	lm.use("Red", LandmarkMaterials.pbr("render", "#B5573D", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#EFE6CF", 2.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#B2623E", 2.5))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#6B4A2E", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3E342A", 3.0))
	lm.use("Water", LandmarkMaterials.glass("#2C6670"))
	lm.use("Hedge", LandmarkMaterials.pbr("lawn", "#4E7A3A", 3.0))
	lm.use("Gravel", LandmarkMaterials.pbr("gravel", "#CDB68D", 4.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Pedro I palace: front block, Maidens' court wings, rear range.
	lm.box("Wall", Vector3(0, 5.25, 7.0), Vector3(54.0, 10.5, 30.0))
	lm.box("Red", Vector3(0, 1.5, 22.1), Vector3(54.0, 3.0, 0.3))
	LandmarkCeParts.hip(lm, "Tile", Vector3(0, 10.5, 7.0), 54.0, 30.0, 2.2)
	for s in [-1.0, 1.0]:
		lm.box("Wall", Vector3(s * 19.25, 5.5, -19.0), Vector3(15.5, 11.0, 22.0))
		LandmarkCeParts.hip(lm, "Tile", Vector3(s * 19.25, 11.0, -19.0), 15.5, 22.0, 2.0)
	lm.box("Wall", Vector3(0, 5.5, -35.0), Vector3(54.0, 11.0, 10.0))
	LandmarkCeParts.hip(lm, "Tile", Vector3(0, 11.0, -35.0), 54.0, 10.0, 2.0)
	_front(lm)
	_maidens(lm)
	_ambassadors(lm, Vector3(0, 0, -48.0))
	_monteria(lm)
	_gardens(lm)
	lm.commit(model)

## The palace front on the Monteria (z = 22).
static func _front(lm: LandmarkMesh) -> void:
	var zn := Vector3(0, 0, 1)
	var f := Vector3(0, 0, 22.0)
	# Central body: proud of the wall, 18 m wide and 14 m to the eaves.
	lm.box("Trim", f + Vector3(0, 7.0, 0.3), Vector3(18.0, 14.0, 0.6))
	LandmarkCeParts.hip(lm, "Tile", f + Vector3(0, 14.0, -3.0), 18.0, 7.0, 1.6)
	var ff := f + Vector3(0, 0, 0.6)
	LandmarkIbParts.portal(lm, "Trim", "Wood", ff, Vector3.RIGHT, zn, 3.2, 5.2, 0, 0.35, true)
	# Blind lobed arcades flanking the door, tile dado below them.
	for s in [-1.0, 1.0]:
		for i in 3:
			var x := float(s) * (3.6 + 1.5 * float(i))
			LandmarkIbParts.portal(lm, "Trim", "Shadow", ff + Vector3(x, 2.4, 0), Vector3.RIGHT, zn, 1.1, 3.4, 2, 0.15)
		lm.box("Tile", ff + Vector3(float(s) * 5.1, 1.0, 0.05), Vector3(5.6, 2.0, 0.1), Basis(), 0.0)
		# Twin windows above: two horseshoe lights on a central column.
		for j in 2:
			var wx := float(s) * (2.6 + 3.6 * float(j))
			for k in [-1.0, 1.0]:
				LandmarkIbParts.portal(lm, "Trim", "Shadow", ff + Vector3(wx + float(k) * 0.65, 7.0, 0), Vector3.RIGHT,
					zn, 1.0, 2.4, 2, 0.2)
			LandmarkIbParts.post(lm, "Trim", ff + Vector3(wx, 7.0, 0.25), 0.1, 2.0, 6)
			lm.box("Trim", ff + Vector3(wx, 9.9, 0.15), Vector3(2.9, 0.15, 0.3), Basis(), 0.0)
	# Inscription band, mocarabe frieze and the carved wooden eaves.
	lm.box("Tile", ff + Vector3(0, 10.6, 0.05), Vector3(17.0, 0.7, 0.1), Basis(), 0.0)
	for i in 34:
		var x := -8.25 + 0.5 * float(i)
		lm.box("Trim", ff + Vector3(x, 11.3, 0.12), Vector3(0.36, 0.5, 0.24), Basis(), 0.0)
		lm.box("Trim", ff + Vector3(x + 0.25, 11.75, 0.25), Vector3(0.36, 0.4, 0.5), Basis(), 0.0)
	lm.box("Wood", ff + Vector3(0, 12.4, 0.5), Vector3(18.0, 0.4, 1.0))
	for i in 30:
		var x := -8.7 + 0.6 * float(i)
		lm.beam("Wood", ff + Vector3(x, 12.6, 0.0), ff + Vector3(x, 13.2, 2.4), 0.22, 0.3, Vector3.RIGHT)
		lm.box("Wood", ff + Vector3(x, 12.75, 0.9), Vector3(0.18, 0.5, 1.4), Basis(), 0.0)
	lm.box("Wood", ff + Vector3(0, 13.3, 1.3), Vector3(19.2, 0.3, 2.8))
	lm.box("Wood", ff + Vector3(0, 13.6, 2.6), Vector3(19.4, 0.5, 0.3))
	# Wings either side: upper galleries of three lobed arches on posts,
	# grilled windows below, a smaller eaves.
	for s in [-1.0, 1.0]:
		var wc := f + Vector3(float(s) * 17.0, 0, 0.3)
		for i in 4:
			LandmarkIbParts.post(lm, "Trim", wc + Vector3(float(i - 1.5) * 3.0, 5.6, 0), 0.16, 2.8, 8)
		for i in 3:
			LandmarkIbParts.portal(lm, "Trim", "Shadow", wc + Vector3(float(i - 1) * 3.0, 5.6, -0.1), Vector3.RIGHT, zn,
				2.6, 3.8, 2, 0.25)
			LandmarkIbParts.portal(lm, "Trim", "Shadow", wc + Vector3(float(i - 1) * 3.6, 1.8, -0.1), Vector3.RIGHT, zn,
				1.2, 2.2, 0, 0.2)
		lm.box("Wood", wc + Vector3(0, 10.4, 0.8), Vector3(11.0, 0.3, 1.6))
		for i in 18:
			lm.beam("Wood", wc + Vector3(-5.1 + 0.6 * float(i), 9.9, 0.0), wc + Vector3(-5.1 + 0.6 * float(i), 10.25, 1.5),
				0.16, 0.22, Vector3.RIGHT)

## The Court of the Maidens: pool between sunken beds, lobed arcades on
## paired columns, the Renaissance upper gallery and balustrade.
static func _maidens(lm: LandmarkMesh) -> void:
	lm.box("Gravel", Vector3(0, 0.15, -19.0), Vector3(23.0, 0.3, 22.0))
	lm.box("Trim", Vector3(0, 0.25, -19.0), Vector3(4.4, 0.3, 16.0))
	lm.box("Water", Vector3(0, 0.35, -19.0), Vector3(3.4, 0.2, 15.0))
	for s in [-1.0, 1.0]:
		lm.box("Hedge", Vector3(float(s) * 5.5, 0.4, -19.0), Vector3(5.0, 0.5, 14.0))
	var sides := [[Vector3(-10.6, 0, -19.0), Vector3(1, 0, 0), 7, 2.6], [Vector3(10.6, 0, -19.0), Vector3(-1, 0, 0), 7, 2.6],
		[Vector3(0, 0, -29.1), Vector3(0, 0, 1), 5, 3.6], [Vector3(0, 0, -8.9), Vector3(0, 0, -1), 5, 3.6]]
	for sd in sides:
		var o: Vector3 = sd[0]
		var out: Vector3 = sd[1]
		var n: int = sd[2]
		var pitch: float = sd[3]
		var right := Vector3.UP.cross(out)
		var basis := Basis(right, Vector3.UP, out)
		for i in n + 1:
			var p := o + right * ((float(i) - float(n) * 0.5) * pitch)
			for k in [-1.0, 1.0]:
				LandmarkIbParts.post(lm, "Trim", p + right * (float(k) * 0.22) + Vector3(0, 0.3, 0), 0.13, 3.2, 6)
			LandmarkIbParts.post(lm, "Trim", p + Vector3(0, 6.6, 0), 0.15, 2.6, 6)
		for i in n:
			var c := o + right * ((float(i) - float(n - 1) * 0.5) * pitch)
			LandmarkIbUtil.wedge_arch(lm, "Trim", "Trim", c + Vector3(0, 3.6, 0), right, out, pitch * 0.38, 0.22,
				0.5, -15.0, 195.0, 7)
			LandmarkIbParts.arch_ring(lm, "Trim", c + Vector3(0, 9.2, 0) + out * 0.1, out, pitch - 0.5, 0.2, 0.3, 7)
		lm.box("Trim", o + Vector3(0, 5.3, 0), Vector3(1.0, 1.4, 1.0) + right.abs() * (pitch * float(n) - 1.0), basis)
		lm.box("Trim", o + Vector3(0, 6.2, 0) + out * 0.4, Vector3(pitch * float(n) + 0.6, 0.3, 1.4), basis)
		LandmarkIbParts.rail(lm, "Trim", o - right * (pitch * float(n) * 0.5) + out * 0.5 + Vector3(0, 6.35, 0),
			o + right * (pitch * float(n) * 0.5) + out * 0.5 + Vector3(0, 6.35, 0), 0.9, pitch)
		lm.box("Trim", o + Vector3(0, 10.7, 0), Vector3(pitch * float(n) + 0.6, 0.5, 1.0), basis)
		LandmarkIbParts.window_row(lm, "Trim", "Shadow", o - out * 0.9, right, out, 7.8, n, pitch, 1.0, 2.0)

## The Hall of Ambassadors at c: a square block with tiled walls at the
## foot, grilled windows under the cupola, battlements round a tiled
## pyramid roof, the stepped lantern; a triple horseshoe arcade on
## columns in each wall.
static func _ambassadors(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Wall", c + Vector3(0, 9.5, 0), Vector3(15.0, 19.0, 15.0))
	LandmarkCeParts.hip(lm, "Tile", c + Vector3(0, 19.0, 0), 15.6, 15.6, 3.6)
	lm.box("Wall", c + Vector3(0, 23.0, 0), Vector3(4.6, 2.0, 4.6))
	LandmarkCeParts.hip(lm, "Tile", c + Vector3(0, 24.0, 0), 5.2, 5.3, 1.2)
	lm.box("Gilt", c + Vector3(0, 25.5, 0), Vector3(0.3, 0.6, 0.3))
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		var f := c + out * 7.5
		LandmarkIbParts.stepped_merlons(lm, "Wall", f + right * -7.5 + Vector3(0, 19.0, 0) - out * 0.3,
			f + right * 7.5 + Vector3(0, 19.0, 0) - out * 0.3, 0.9, 1.4, 0.6)
		LandmarkIbParts.stepped_merlons(lm, "Wall", c + out * 2.3 - right * 2.3 + Vector3(0, 24.0, 0),
			c + out * 2.3 + right * 2.3 + Vector3(0, 24.0, 0), 0.6, 0.9, 0.4)
		for i in 4:
			LandmarkIbParts.portal(lm, "Trim", "Shadow", f + right * ((float(i) - 1.5) * 3.2) + Vector3(0, 13.5, 0), right, out,
				1.3, 2.4, 2, 0.2)
		lm.box("Tile", f + out * 0.05 + Vector3(0, 1.2, 0), Vector3(15.0, 2.4, 0.1), r, 0.0)
		for i in 3:
			LandmarkIbParts.portal(lm, "Trim", "Shadow", f + out * 0.22 + right * (float(i - 1) * 2.4) + Vector3(0, 0.3, 0),
				right, out, 1.9, 4.6, 2, 0.3)
		for i in 2:
			LandmarkIbParts.post(lm, "Trim", f + right * ((float(i) - 0.5) * 2.4) + out * 0.55 + Vector3(0, 0.3, 0), 0.14, 3.2, 6)
		lm.box("Trim", f + out * 0.12 + Vector3(0, 3.6, 0), Vector3(8.6, 6.8, 0.2), r, 0.0)

## The Monteria court: its gravel floor, the arcaded Casa de Contratacion
## range on the west, the crenellated walls and towers, the Lion Gate.
static func _monteria(lm: LandmarkMesh) -> void:
	lm.box("Gravel", Vector3(0, 0.15, 47.0), Vector3(68.0, 0.3, 50.0))
	lm.box("Wall", Vector3(-41.0, 5.5, 47.0), Vector3(14.0, 11.0, 46.0))
	lm.box("Red", Vector3(-41.0, 1.5, 47.0), Vector3(14.2, 3.0, 46.2))
	LandmarkCeParts.hip(lm, "Tile", Vector3(-41.0, 11.0, 47.0), 14.0, 46.0, 2.4)
	var xn := Vector3(1, 0, 0)
	for i in 9:
		var z := 27.0 + 5.0 * float(i)
		LandmarkIbParts.portal(lm, "Trim", "Shadow", Vector3(-34.0, 0.3, z), Vector3(0, 0, -1), xn, 3.4, 4.6, 1, 0.4)
		LandmarkDetail.window(lm, "Trim", "Shadow", Vector3(-34.0, 7.8, z), xn, 1.4, 2.6)
	LandmarkIbParts.band(lm, "Trim", Vector3(-34.0, 0, 47.0), Vector3(0, 0, -1), xn, 46.0, 5.6, 0.4, 0.3)
	lm.box("Wall", Vector3(35.0, 4.5, 47.0), Vector3(2.0, 9.0, 50.0))
	LandmarkIbParts.stepped_merlons(lm, "Wall", Vector3(35.0, 9.0, 22.0), Vector3(35.0, 9.0, 72.0), 1.1, 1.4, 1.0)
	for z in [30.0, 50.0, 70.0]:
		lm.box("Wall", Vector3(35.5, 6.5, z), Vector3(4.0, 13.0, 4.0))
		LandmarkIbParts.stepped_merlons(lm, "Wall", Vector3(35.5, 13.0, z - 2.0), Vector3(35.5, 13.0, z + 2.0), 0.8, 1.2, 4.0)
	lm.box("Wall", Vector3(-12.0, 7.0, 71.0), Vector3(26.0, 14.0, 4.0))
	LandmarkIbParts.stepped_merlons(lm, "Wall", Vector3(-25.0, 14.0, 71.0), Vector3(1.0, 14.0, 71.0), 1.1, 1.4, 1.0)
	# Lion Gate: a lintelled gateway under the tiled lion panel.
	var g := Vector3(-12.0, 0, 73.0)
	LandmarkIbParts.portal(lm, "Trim", "Shadow", g, Vector3.RIGHT, Vector3(0, 0, 1), 4.4, 6.0, 0, 0.5, true)
	lm.box("Tile", g + Vector3(0, 8.6, 0.08), Vector3(3.4, 2.2, 0.16), Basis(), 0.0)
	lm.box("Gilt", g + Vector3(0, 8.6, 0.18), Vector3(1.6, 1.1, 0.06), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		lm.disc("Trim", g + Vector3(float(s) * 3.4, 9.6, 0.05), Vector3(0, 0, 1), 0.7, 12)
	# Gothic palace of Alfonso X, south-east of the court.
	lm.box("Wall", Vector3(50.0, 7.0, -20.0), Vector3(40.0, 14.0, 30.0))
	lm.box("Red", Vector3(50.0, 2.5, -4.9), Vector3(40.0, 5.0, 0.3))
	LandmarkCeParts.hip(lm, "Tile", Vector3(50.0, 14.0, -20.0), 40.0, 30.0, 3.0)
	for i in 6:
		var x := 32.0 + 7.2 * float(i)
		LandmarkIbParts.buttress(lm, "Wall", Vector3(x, 0, -5.0), Vector3(0, 0, 1), 1.2, 1.6, 12.0)
		if i < 5:
			LandmarkIbParts.portal(lm, "Trim", "Shadow", Vector3(x + 3.6, 5.0, -5.0), Vector3.RIGHT, Vector3(0, 0, 1),
				2.0, 6.0, 3, 0.3)
	for s in [-1.0, 1.0]:
		var tc := Vector3(50.0 + float(s) * 18.5, 0, -6.5)
		lm.box("Wall", tc + Vector3(0, 8.0, 0), Vector3(5.0, 16.0, 5.0))
		for k in 4:
			var r := Basis(Vector3.UP, PI * 0.5 * float(k))
			LandmarkIbParts.stepped_merlons(lm, "Wall", tc + r * Vector3(-2.5, 16.0, 2.2), tc + r * Vector3(2.5, 16.0, 2.2),
				0.8, 1.2, 0.6)

## The gardens behind the palace: hedged parterres and pools, Mercury's
## pool, fountains and palms, the Grotesque gallery on the old wall and
## Charles V's pavilion with its arcade.
static func _gardens(lm: LandmarkMesh) -> void:
	lm.box("Gravel", Vector3(55.0, 0.15, -88.0), Vector3(150.0, 0.3, 82.0))
	for i in 6:
		for j in 4:
			var bx := 5.0 + 15.0 * float(i)
			var bz := -58.0 - 15.0 * float(j)
			if (i == 4 and j == 1) or (i == 1 and j == 3):
				lm.box("Trim", Vector3(bx, 0.45, bz), Vector3(10.0, 0.3, 10.0))
				lm.box("Water", Vector3(bx, 0.55, bz), Vector3(9.0, 0.2, 9.0))
				lm.frustum("Trim", Vector3(bx, 0.6, bz), 0.6, 0.5, 1.2, 8)
				lm.lathe("Trim", Vector3(bx, 1.8, bz), SEuUtil.dome(1.0, 0.4, 4), 10)
			else:
				lm.box("Hedge", Vector3(bx, 0.65, bz), Vector3(11.0, 0.7, 11.0))
				lm.box("Gravel", Vector3(bx, 0.45, bz), Vector3(3.0, 0.3, 3.0))
				lm.frustum("Trim", Vector3(bx, 0.6, bz), 0.9, 0.9, 0.6, 10)
	for i in 6:
		var p := Vector3(-2.5 + 15.0 * float(i), 0.3, -51.0)
		lm.frustum("Wall", p, 0.25, 0.18, 11.0, 6)
		for k in 7:
			var a := TAU * float(k) / 7.0
			lm.beam("Hedge", p + Vector3(0, 11.0, 0), p + Vector3(cos(a) * 3.0, 10.0, sin(a) * 3.0), 0.9, 0.08)
	# Grotesque gallery: an arcade with a balustraded walk on the wall.
	lm.box("Wall", Vector3(55.0, 3.5, -129.0), Vector3(150.0, 7.0, 3.0))
	for i in 22:
		LandmarkIbParts.portal(lm, "Trim", "Shadow", Vector3(55.0 + (float(i) - 10.5) * 6.4, 0.3, -127.5), Vector3.RIGHT,
			Vector3(0, 0, 1), 3.0, 5.2, 1, 0.35)
	LandmarkIbParts.rail(lm, "Trim", Vector3(-20.0, 7.0, -128.0), Vector3(130.0, 7.0, -128.0), 1.0, 6.4)
	lm.box("Wall", Vector3(130.0, 3.5, -88.0), Vector3(2.0, 7.0, 82.0))
	LandmarkIbParts.stepped_merlons(lm, "Wall", Vector3(130.0, 7.0, -129.0), Vector3(130.0, 7.0, -47.0), 1.2, 1.4, 1.0)
	# Charles V's pavilion: tiled walls, an arcade of columns round it.
	var pv := Vector3(100.0, 0, -62.0)
	lm.box("Trim", pv + Vector3(0, 0.3, 0), Vector3(14.0, 0.6, 14.0))
	lm.box("Wall", pv + Vector3(0, 3.8, 0), Vector3(8.0, 7.0, 8.0))
	LandmarkCeParts.hip(lm, "Tile", pv + Vector3(0, 7.3, 0), 13.4, 13.4, 3.0)
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		LandmarkIbParts.portal(lm, "Trim", "Shadow", pv + out * 4.0 + Vector3(0, 0.6, 0), right, out, 2.0, 4.0, 1, 0.25)
		lm.box("Tile", pv + out * 4.05 + Vector3(0, 1.4, 0), Vector3(8.0, 1.6, 0.1), r, 0.0)
		for i in 4:
			LandmarkIbParts.post(lm, "Trim", pv + out * 6.2 + right * ((float(i) - 1.5) * 4.1) + Vector3(0, 0.6, 0), 0.2, 4.4, 8)
		for i in 3:
			LandmarkIbParts.arch_ring(lm, "Trim", pv + out * 6.2 + right * (float(i - 1) * 4.1) + Vector3(0, 5.0, 0), out,
				3.6, 0.3, 0.4, 7)
		lm.box("Trim", pv + out * 6.2 + Vector3(0, 7.15, 0), Vector3(12.8, 0.3, 0.6), r)
