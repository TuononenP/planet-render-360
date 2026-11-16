class_name LandmarkCsCentral
extends RefCounted

## Capital termini of central and northern Europe in the station frame
## (+X along the main facade or the through tracks, +Z the forecourt):
## Berlin Hauptbahnhof, Wien Hauptbahnhof, Praha hlavní nádraží, Budapest
## Keleti, Warszawa Centralna, København H, Stockholm Central and Oslo S.

const K = preload("res://scripts/generation/landmarks/capital_stations/landmark_station_kit.gd")

## Berlin Hauptbahnhof (gmp, 2006): the 321 m east-west glass barrel, a
## light fine-meshed vault over the elevated through tracks that runs on
## unbroken under the two 46 m "Bügelbauten", office bars of pale grey-
## green curtain wall on a fine grid that straddle it, and the lower
## flat-roofed glass north-south halls between them either side of it; the forecourt is
## Washingtonplatz (+Z).
static func berlin_hbf(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "concrete", "#9EA3A6", "#BFC3C5", "sheet_metal", "#7D868C", "#AEB6B9")
	lm.use("Glass", LandmarkMaterials.glass("#9FB3B5"))
	lm.use("Vault", LandmarkMaterials.pbr("concrete", "#C3CED2", 20.0, 0.15, 0.3))
	K.shed(lm, "Vault", "Steel", "Vault", Vector3(-160, 0, 0), Vector3.RIGHT, 66.0, 321.0, 14.0, 12.0, 6.0, 1.0, 3)
	# North-south hall: glass halls with flat glass roofs at 18 m either side
	# of the barrel, which passes over the crossing unbroken.
	for zc in [-56.5, 56.5]:
		lm.box("Glass", Vector3(0, 9.0, zc), Vector3(40.0, 18.0, 47.0), Basis(), 0.0)
		lm.box("Steel", Vector3(0, 18.2, zc), Vector3(41.0, 0.5, 48.0), Basis(), 0.0)
	LandmarkFhParts.ribs(lm, "Steel", Vector3(-20, 0, 80.1), Vector3(20, 0, 80.1), Vector3.BACK, 0.0, 18.0, 2.5, 0.2, 0.3)
	for s in [-1.0, 1.0]:
		var x: float = s * 33.0
		for z in [-56.5, 56.5]:
			_curtain(lm, Vector3(x, 0, float(z)), Vector3(17.0, 46.0, 47.0))
		_curtain(lm, Vector3(x, 30.0, 0.0), Vector3(17.0, 16.0, 66.0))
	lm.commit(model)

## A curtain-walled bar `size` standing on `base`: glass faces with a fine
## grid of mullions and floor bands, a flat roof.
static func _curtain(lm: LandmarkMesh, base: Vector3, size: Vector3) -> void:
	lm.use("Curtain", LandmarkMaterials.pbr("concrete", "#9FB3B5", 20.0, 0.18, 0.35))
	lm.box("Curtain", base + Vector3.UP * size.y * 0.5, size, Basis(), 0.0)
	lm.box("Roof", base + Vector3.UP * (size.y + 0.2), Vector3(size.x + 0.4, 0.4, size.z + 0.4))
	var y := 3.8
	while y < size.y - 0.5:
		lm.box("Steel", base + Vector3.UP * y, Vector3(size.x + 0.2, 0.25, size.z + 0.2), Basis(), 0.0)
		y += 3.8
	for face in LandmarkFhParts.faces(base.x, base.z, size.x, size.z):
		LandmarkFhParts.ribs(lm, "Steel", (face[0] as Vector3) + Vector3.UP * base.y, (face[1] as Vector3) + Vector3.UP * base.y,
			face[2], base.y, base.y + size.y, 2.7, 0.12, 0.15)

## Wien Hauptbahnhof (2014), here with the tracks along Z and the city
## end (Südtiroler Platz) at +Z: five white roof ribbons over the island
## platforms that, toward the city, fold into rhombus-shaped shells
## braided across the five ribbons, each with a glazed slit along its
## fold; behind them the plain ribbons with their skylight strips run on
## over the tracks. The BahnhofCity concourse stands along the -X side and
## a lower canopy building on the +X side.
static func wien_hbf(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "concrete", "#B8B6B0", "#D2D0CB", "sheet_metal", "#E4E6E7", "#C9CCCE")
	for i in 5:
		var x := (float(i) - 2.0) * WIEN_PITCH
		var odd := i % 2 == 1
		var z_end := 0.0
		for k in 4:
			var zc := -WIEN_DIAMOND * (0.5 + float(k) + (0.5 if odd else 0.0))
			_rhombus(lm, Vector3(x, 0, zc), WIEN_DIAMOND, WIEN_PITCH * 2.0, 17.0)
			z_end = zc - WIEN_DIAMOND * 0.5
		_ribbon(lm, x, z_end, -420.0)
	# BahnhofCity along the -X side and the lower building on the +X side.
	K.block(lm, "Walls", "Trim", "Glass", "Roof", -110.0, -120.0, 26.0, 250.0, 0.0, 16.0, "flat", 0.0, 4.0, 4.5)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 112.0, -95.0, 22.0, 100.0, 0.0, 8.0, "flat", 0.0, 4.0, 4.0)
	lm.box("Roof", Vector3(112.0, 8.6, -95.0), Vector3(30.0, 0.8, 108.0))
	# The entrance hall on Südtiroler Platz: a glazed hall under the dark
	# wedge roof that cantilevers out over the square, thickest at its tip.
	lm.use("Dark", LandmarkMaterials.pbr("sheet_metal", "#3A3D40", 2.0))
	lm.box("Glass", Vector3(0, 7.0, 12.0), Vector3(56.0, 14.0, 24.0))
	LandmarkFhParts.strips(lm, "Steel", Vector3(-27.5, 0, 24.05), Vector3(27.5, 0, 24.05), Vector3.BACK, 0.0, 14.0, 15,
		0.25, 0.2)
	var w0 := Vector3(-34.0, 14.0, -2.0)
	var w1 := Vector3(34.0, 14.0, -2.0)
	var t0 := Vector3(-34.0, 17.5, 40.0)
	var t1 := Vector3(34.0, 17.5, 40.0)
	var drop := Vector3.DOWN * 4.5
	lm.quad("Dark", w0, w1, t1, t0, Vector3(0, 1, -0.08).normalized())
	lm.quad("Dark", w1 + drop * 0.3, w0 + drop * 0.3, t0 + drop, t1 + drop, Vector3.DOWN)
	lm.quad("Dark", t0 + drop, t0, t1, t1 + drop, Vector3.BACK)
	for e in [[w0, t0, -1.0], [w1, t1, 1.0]]:
		var a: Vector3 = e[0]
		var b: Vector3 = e[1]
		var nx := Vector3(float(e[2]), 0, 0)
		lm.quad("Dark", a + drop * 0.3, b + drop, b, a, nx)
		lm.quad("Dark", a, b, b + drop, a + drop * 0.3, -nx)
	lm.commit(model)

const WIEN_PITCH := 30.0
const WIEN_DIAMOND := 60.0

## One folded rhombus shell centred `c`, `l` long (Z) and `w` wide (X):
## its apex `top` high over the centre and its four corners 6 m lower.
## Shells `w` / 2 apart and offset by `l` / 2 tile the roof edge to edge
## (a shell's side corner is its neighbours' tip); a glazed slit along the fold, steel columns under the
## tips, and the underside drawn for the platforms below.
static func _rhombus(lm: LandmarkMesh, c: Vector3, l: float, w: float, top: float) -> void:
	var apex := c + Vector3.UP * top
	var tips := [c + Vector3(0, top - 6.0, l * 0.5), c + Vector3(w * 0.5, top - 6.0, 0),
		c + Vector3(0, top - 6.0, -l * 0.5), c + Vector3(-w * 0.5, top - 6.0, 0)]
	for i in 4:
		var a: Vector3 = tips[i]
		var b: Vector3 = tips[(i + 1) % 4]
		var n := (a - apex).cross(b - apex).normalized()
		if n.y < 0.0:
			n = -n
		lm.tri("Roof", apex, a, b, n, n, n, Vector2.ZERO, Vector2(l, 0), Vector2(0, w))
		lm.tri("Roof", apex, b, a, -n, -n, -n, Vector2.ZERO, Vector2(l, 0), Vector2(0, w))
		lm.beam("Roof", a, b, 0.5, 0.6)
	var up := Vector3.UP * 0.08
	var f := apex.lerp(tips[0], 0.75) + up
	var r := apex.lerp(tips[1], 0.1) + up
	var bk := apex.lerp(tips[2], 0.75) + up
	var lf := apex.lerp(tips[3], 0.1) + up
	lm.tri("Glass", f, r, apex + up, Vector3.UP, Vector3.UP, Vector3.UP, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
	lm.tri("Glass", apex + up, r, bk, Vector3.UP, Vector3.UP, Vector3.UP, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
	lm.tri("Glass", bk, lf, apex + up, Vector3.UP, Vector3.UP, Vector3.UP, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
	lm.tri("Glass", apex + up, lf, f, Vector3.UP, Vector3.UP, Vector3.UP, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
	for t in [tips[0], tips[2]]:
		var foot := Vector3((t as Vector3).x, 0, (t as Vector3).z)
		lm.box("Steel", foot + Vector3.UP * (t as Vector3).y * 0.5, Vector3(0.8, (t as Vector3).y, 0.8), Basis(), 0.0)

## A plain roof ribbon over one island platform from z0 back to z1: an
## 18 m wide slab 11 m up with two skylight strips, on columns every 20 m.
static func _ribbon(lm: LandmarkMesh, x: float, z0: float, z1: float) -> void:
	var l := z0 - z1
	if l < 1.0:
		return
	var zc := (z0 + z1) * 0.5
	lm.box("Roof", Vector3(x, 11.0, zc), Vector3(18.0, 1.2, l))
	for s in [-1.0, 1.0]:
		lm.box("Glass", Vector3(x + s * 3.5, 11.63, zc), Vector3(1.6, 0.05, l - 4.0), Basis(), 0.0)
	for k in int(l / 20.0) + 1:
		var z := z0 - 20.0 * float(k)
		lm.box("Steel", Vector3(x, 5.2, z), Vector3(0.7, 10.4, 0.7), Basis(), 0.0)

## Josef Fanta's station building (1909) on Wilsonova (cream render, red
## tile roofs, pale grey sheds, copper only on the domes): the Art Nouveau
## central hall with its great semicircular glazed arch and dome, the two
## 45 m towers with their glass-and-metal globes, the wings either side,
## and the two arched train sheds behind.
static func praha_hln(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#E3DCCB", "#ECE6D8", "terracotta", "#A8503A")
	lm.use("Copper", LandmarkMaterials.pbr("copper", "#5E8C7A", 2.0))
	lm.use("Shed", LandmarkMaterials.pbr("sheet_metal", "#C9CDD0", 2.0))
	for s in [-1.0, 1.0]:
		K.shed(lm, "Shed", "Steel", "Glass", Vector3(s * 17.0, 0, -20), Vector3.FORWARD, 33.0, 230.0, 8.0, 12.0, 9.0,
			0.5, 1)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 52.0, -4.0, 50.0, 18.0, 0.0, 15.0, "mansard", 4.0, 4.5, 5.0, true)
		var tx: float = s * 25.0
		K.block(lm, "Walls", "Trim", "Glass", "Roof", tx, 1.0, 9.0, 9.0, 0.0, 36.0, "flat", 0.0, 3.0, 6.0)
		lm.lathe("Copper", Vector3(tx, 36.0, 1.0), LandmarkFhUtil.dome_prof(4.2, 4.5), 16)
		lm.lathe("Gilt", Vector3(tx, 40.5, 1.0), LandmarkFhUtil.ball(1.6), 12)
		lm.box("Gilt", Vector3(tx, 43.8, 1.0), Vector3(0.3, 1.2, 0.3))
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, -2.0, 40.0, 26.0, 0.0, 20.0, "flat", 0.0, 4.0, 5.0)
	K.arch_window(lm, "Trim", "Glass", Vector3(0, 2.0, 11.05), Vector3.BACK, 26.0, 26.0, 7, 1.4)
	lm.lathe("Copper", Vector3(0, 20.0, -2.0), LandmarkFhUtil.dome_prof(15.0, 9.0), 20, 1.0, 1.0)
	K.clock(lm, "Dial", "Trim", Vector3(0, 22.0, 11.6), Vector3.BACK, 1.6)
	for x in [-14.0, -8.0, 8.0, 14.0]:
		K.statue(lm, "Trim", Vector3(x, 20.0, 10.6), 3.5)
	lm.commit(model)

## Budapest Keleti (Rochlitz and Feketeházy, 1884): the light stone
## frame whose great glazed arch closes the 42 m iron shed, its two tall
## piers holding the statues of Watt and Stephenson in their niches under
## the sculpted crest group and flag; the ochre-yellow corner pavilions
## and side ranges with white trim under dark grey mansard roofs.
static func keleti(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "limestone", "#D9CFB8", "#F2EEE4", "slate", "#4F575E")
	lm.use("Ochre", LandmarkMaterials.pbr("render", "#E3C25F", 3.0))
	K.shed(lm, "Roof", "Steel", "Glass", Vector3(0, 0, -2), Vector3.FORWARD, 42.0, 185.0, 18.0, 12.0, 9.0, 0.5, 1)
	lm.box("Walls", Vector3(0, 15.0, 0.5), Vector3(48.0, 30.0, 4.0))
	K.arch_window(lm, "Trim", "Glass", Vector3(0, 1.0, 2.55), Vector3.BACK, 32.0, 27.0, 8, 1.4)
	lm.box("Trim", Vector3(0, 30.6, 0.5), Vector3(49.0, 1.2, 5.0))
	for s in [-1.0, 1.0]:
		var x: float = s * 21.0
		lm.box("Walls", Vector3(x, 16.0, 2.6), Vector3(5.0, 32.0, 1.6))
		lm.box("Glass", Vector3(x, 15.0, 3.45), Vector3(2.6, 6.0, 0.1), Basis(), 0.0)
		K.statue(lm, "Trim", Vector3(x, 12.2, 3.6), 5.0)
		K.block(lm, "Ochre", "Trim", "Glass", "Roof", s * 31.0, -1.0, 14.0, 14.0, 0.0, 22.0, "mansard", 5.0, 3.4, 5.5, true)
		K.block(lm, "Ochre", "Trim", "Glass", "Roof", s * 31.0, -98.0, 14.0, 180.0, 0.0, 16.0, "mansard", 3.5, 4.5, 5.0, true)
	# The crest: a sculpted group and its flag about 6 m over the arch.
	lm.box("Trim", Vector3(0, 32.2, 1.0), Vector3(14.0, 2.0, 3.0))
	for x in [-3.5, 0.0, 3.5]:
		K.statue(lm, "Trim", Vector3(x, 33.2, 1.0), 3.6 if absf(x) > 1.0 else 4.2)
	lm.box("Steel", Vector3(0, 38.0, 0.6), Vector3(0.15, 3.0, 0.15), Basis(), 0.0)
	lm.commit(model)

## Warszawa Centralna (Arseniusz Romanowicz, 1975) on Aleje Jerozolimskie
## (+Z): the dark glazed main hall with its name band, under the great
## thin roof slab that oversails it far on every side, a shallow saddle
## whose middle dips and whose corners lift, carried on tall round
## columns; a lower wing beside it. The platforms lie beneath the street.
static func warszawa_centralna(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "concrete", "#3A4146", "#C3C5C4", "sheet_metal", "#AEB3B5", "#C8C9C6")
	# The hall: glass walls under a dark band carrying the name.
	lm.box("Glass", Vector3(0, 5.0, 0), Vector3(104.0, 10.0, 56.0), Basis(), 0.0)
	lm.box("Walls", Vector3(0, 11.2, 0), Vector3(105.0, 2.4, 57.0))
	lm.box("Walls", Vector3(0, 13.4, 0), Vector3(96.0, 2.0, 50.0))
	LandmarkFhParts.ribs(lm, "Walls", Vector3(-52, 0, 28.05), Vector3(52, 0, 28.05), Vector3.BACK, 0.0, 10.0, 6.5, 0.3, 0.3)
	LandmarkFhParts.ribs(lm, "Walls", Vector3(-52, 0, -28.05), Vector3(52, 0, -28.05), Vector3.FORWARD, 0.0, 10.0, 6.5,
		0.3, 0.3)
	lm.box("Trim", Vector3(0, 11.2, 28.7), Vector3(38.0, 1.1, 0.2), Basis(), 0.0)
	# The saddle slab: top y(x, z), 1.4 m thick, drawn as a grid with its
	# soffit and fascia.
	var hx := 66.0
	var hz := 42.0
	var nx := 16
	var nz := 10
	var top := func(x: float, z: float) -> Vector3:
		return Vector3(x, WARSAW_ROOF_Y + 4.2 * pow(x / hx, 2.0) + 1.6 * pow(z / hz, 2.0), z)
	for i in nx:
		for j in nz:
			var x0 := -hx + 2.0 * hx * float(i) / float(nx)
			var x1 := -hx + 2.0 * hx * float(i + 1) / float(nx)
			var z0 := -hz + 2.0 * hz * float(j) / float(nz)
			var z1 := -hz + 2.0 * hz * float(j + 1) / float(nz)
			var a: Vector3 = top.call(x0, z0)
			var b: Vector3 = top.call(x1, z0)
			var c: Vector3 = top.call(x1, z1)
			var d: Vector3 = top.call(x0, z1)
			var down := Vector3.DOWN * WARSAW_SLAB
			lm.quad("Roof", a, b, c, d, Vector3.UP)
			lm.quad("Trim", b + down, a + down, d + down, c + down, Vector3.DOWN)
	var edge := func(p: Vector3, q: Vector3, n: Vector3) -> void:
		lm.quad("Roof", p, q, q + Vector3.DOWN * WARSAW_SLAB, p + Vector3.DOWN * WARSAW_SLAB, n)
	for i in nx:
		var x0 := -hx + 2.0 * hx * float(i) / float(nx)
		var x1 := -hx + 2.0 * hx * float(i + 1) / float(nx)
		edge.call(top.call(x1, hz), top.call(x0, hz), Vector3.BACK)
		edge.call(top.call(x0, -hz), top.call(x1, -hz), Vector3.FORWARD)
	for j in nz:
		var z0 := -hz + 2.0 * hz * float(j) / float(nz)
		var z1 := -hz + 2.0 * hz * float(j + 1) / float(nz)
		edge.call(top.call(hx, z0), top.call(hx, z1), Vector3.RIGHT)
		edge.call(top.call(-hx, z1), top.call(-hx, z0), Vector3.LEFT)
	# Tall round columns in two rows, before and behind the hall.
	for x in [-44.0, 0.0, 44.0]:
		for z in [-32.0, 32.0]:
			var under: float = (top.call(x, z) as Vector3).y - WARSAW_SLAB
			lm.frustum("Trim", Vector3(x, 0, z), 0.85, 0.75, under, 16)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 76.0, -6.0, 30.0, 40.0, 0.0, 6.0, "flat", 0.0, 4.0, 4.0)
	lm.commit(model)

const WARSAW_ROOF_Y := 16.0
const WARSAW_SLAB := 1.4

## Heinrich Wenck's København H (1911): the national-romantic deep red
## brick and granite station on Bernstorffsgade, its front a run of steep
## gables, the main gable with its great round-arched window over the
## arcaded porch along the street, the steep dark roof of the hall behind
## them (its arched timber trusses are inside), and the clock tower at the
## corner with its tall slender spire.
static func kobenhavn_h(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "brick", "#8A3A28", "#C9BFAE", "slate", "#3D4651")
	lm.use("Spire", LandmarkMaterials.pbr("copper", "#4F6B63", 2.0))
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, -14.0, 74.0, 44.0, 0.0, 13.0, "gable_x", 14.0, 5.0, 5.0)
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 62.0, -6.0, 50.0, 26.0, 0.0, 12.0, "gable_x", 8.0, 4.0, 4.5, true)
	for i in 5:
		var x := -32.0 + 16.0 * float(i)
		var big := i == 2
		K.block(lm, "Walls", "Trim", "Glass", "Roof", x, 10.0, 14.0 if big else 12.0, 8.0, 0.0, 14.0 if big else 12.0,
			"gable_z", 10.0 if big else 7.0, 3.2, 4.5, not big)
	K.arch_window(lm, "Trim", "Glass", Vector3(0, 4.0, 14.05), Vector3.BACK, 9.0, 15.0, 3, 0.7)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 16.5, 70.0, 5.0, 0.0, 4.5, "flat", 0.0, 3.5, 4.5, true)
	K.clock_tower(lm, "Walls", "Trim", "Spire", "Dial", "Glass", Vector3(-41.0, 0, 9.0), 7.0, 30.0, "spire", 16.0)
	lm.commit(model)

## Adolf W. Edelsvärd's Stockholm Central (1871) on Vasagatan: the long
## rendered range of three storeys with its central pavilion and corner
## pavilions under mansard roofs, the tracks along its back.
static func stockholm_central(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#D9C79F", "#E6DAC2", "slate", "#3E464D")
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 52.0, 0.0, 64.0, 22.0, 0.0, 16.0, "hip", 5.0, 4.2, 5.0, true)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 92.0, 1.0, 16.0, 25.0, 0.0, 18.0, "mansard", 6.0, 3.6, 5.5, true)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 1.5, 40.0, 27.0, 0.0, 20.0, "mansard", 6.5, 3.8, 6.0, true)
	K.clock(lm, "Dial", "Trim", Vector3(0, 17.0, 15.2), Vector3.BACK, 1.4)
	K.canopy(lm, "Steel", "Steel", Vector3(-16, 0, 15.0), Vector3(16, 0, 15.0), Vector3.BACK, 4.0, 4.5, 5)
	for i in 4:
		K.shed(lm, "Roof", "Steel", "Glass", Vector3(-100, 0, -24.0 - 13.0 * float(i)), Vector3.RIGHT, 11.0, 200.0, 5.0,
			1.5, 12.0, 0.3, 0)
	lm.commit(model)

## Oslo S: the 1882 Østbanehallen on Jernbanetorget, pale buff render
## with its pedimented centre and hipped roofs, beside the lower 1980s
## concourse of glass and concrete with its big glazed hall toward the
## square, and the low flat canopies over the island platforms behind.
static func oslo_s(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#E2D3B0", "#ECE2CC", "slate", "#454C52")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", -40.0, 0.0, 90.0, 24.0, 0.0, 13.0, "hip", 5.0, 4.0, 5.0, true)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", -40.0, 2.0, 22.0, 26.0, 0.0, 15.0, "gable_z", 5.0, 3.6, 5.0, true)
	K.clock(lm, "Dial", "Trim", Vector3(-40.0, 17.2, 15.2), Vector3.BACK, 1.2)
	K.block(lm, "Trim", "Steel", "Glass", "Roof", 50.0, -6.0, 80.0, 36.0, 0.0, 12.0, "flat", 0.0, 4.0, 4.0)
	lm.box("Glass", Vector3(50.0, 8.0, 12.2), Vector3(40.0, 15.0, 0.3), Basis(), 0.0)
	lm.box("Roof", Vector3(50.0, 15.6, 6.0), Vector3(44.0, 0.8, 12.6))
	for i in 6:
		var z := -30.0 - 12.0 * float(i)
		lm.box("Roof", Vector3(25.0, 6.0, z), Vector3(230.0, 0.5, 8.0))
		for k in 12:
			lm.box("Steel", Vector3(-88.0 + 20.0 * float(k), 3.0, z), Vector3(0.4, 6.0, 0.4), Basis(), 0.0)
	lm.commit(model)
