class_name LandmarkCsCentral
extends RefCounted

## Capital termini of central and northern Europe in the station frame
## (+X along the main facade or the through tracks, +Z the forecourt):
## Berlin Hauptbahnhof, Wien Hauptbahnhof, Praha hlavní nádraží, Budapest
## Keleti, Warszawa Centralna, København H, Stockholm Central and Oslo S.

const K = preload("res://scripts/generation/landmarks/capital_stations/landmark_station_kit.gd")

## Berlin Hauptbahnhof (gmp, 2006): the 321 m east-west glass barrel over
## the elevated through tracks, the flat-roofed north-south hall below it,
## and the two 46 m "Bügelbauten" office slabs straddling the barrel
## either side of the crossing; the forecourt is Washingtonplatz (+Z).
static func berlin_hbf(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "concrete", "#9EA3A6", "#BFC3C5", "sheet_metal", "#7D868C", "#8C949A")
	K.shed(lm, "Roof", "Steel", "Glass", Vector3(-160, 0, 0), Vector3.RIGHT, 66.0, 321.0, 14.0, 12.0, 8.0, 0.92, 3)
	# North-south hall: glass walls and a flat glass roof at 26 m.
	lm.box("Glass", Vector3(0, 13.0, 0), Vector3(40.0, 26.0, 160.0), Basis(), 0.0)
	lm.box("Steel", Vector3(0, 26.2, 0), Vector3(41.0, 0.5, 161.0), Basis(), 0.0)
	LandmarkFhParts.ribs(lm, "Steel", Vector3(-20, 0, 80.1), Vector3(20, 0, 80.1), Vector3.BACK, 0.0, 26.0, 2.5, 0.2, 0.3)
	for s in [-1.0, 1.0]:
		var x: float = s * 33.0
		for z in [-56.5, 56.5]:
			K.block(lm, "Glass", "Steel", "Walls", "Roof", x, float(z), 17.0, 47.0, 0.0, 46.0, "flat", 0.0, 3.0, 3.8)
		K.block(lm, "Glass", "Steel", "Walls", "Roof", x, 0.0, 17.0, 66.0, 30.0, 16.0, "flat", 0.0, 3.0, 3.8)
	lm.commit(model)

## Wien Hauptbahnhof (2014): the platform roofs folded into rhombus-shaped
## steel shells (the "diamonds"), the concourse block on Südtiroler Platz
## and its glazed entrance with the station's name band.
static func wien_hbf(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "concrete", "#B8B6B0", "#D2D0CB", "sheet_metal", "#C9CCCE", "#B9BDBF")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 90.0, 26.0, 0.0, 14.0, "flat", 0.0, 3.5, 4.2)
	for s in 5:
		var z := -26.0 - 22.0 * float(s)
		for i in 10:
			var x0 := -150.0 + 30.0 * float(i)
			_diamond(lm, Vector3(x0 + 15.0, 0, z), 30.0, 18.0, 9.5, 16.0)
	K.canopy(lm, "Roof", "Steel", Vector3(-30, 0, 13.0), Vector3(30, 0, 13.0), Vector3.BACK, 6.0, 5.0, 6)
	lm.commit(model)

## One folded roof shell `l` long (X) by `w` wide centred `c`: four
## triangles from the raised centre (`top`) to the edge midpoints at
## `eave`, steel columns under the low points.
static func _diamond(lm: LandmarkMesh, c: Vector3, l: float, w: float, eave: float, top: float) -> void:
	var t := c + Vector3.UP * top
	var e := [c + Vector3(l * 0.5, eave, 0), c + Vector3(0, eave + 2.0, w * 0.5), c + Vector3(-l * 0.5, eave, 0),
		c + Vector3(0, eave + 2.0, -w * 0.5)]
	for i in 4:
		var a: Vector3 = e[i]
		var b: Vector3 = e[(i + 1) % 4]
		lm.tri("Roof", t, a, b, Vector3.UP, Vector3.UP, Vector3.UP, Vector2.ZERO, Vector2(l, 0), Vector2(0, w))
		lm.tri("Roof", t, b, a, Vector3.DOWN, Vector3.DOWN, Vector3.DOWN, Vector2.ZERO, Vector2(l, 0), Vector2(0, w))
		lm.beam("Steel", a, b, 0.4, 0.5)
	lm.box("Steel", c + Vector3(l * 0.5, eave * 0.5, 0), Vector3(0.7, eave, 0.7), Basis(), 0.0)

## Josef Fanta's station building (1909) on Wilsonova: the Art Nouveau
## central hall with its great semicircular glazed arch and dome, the two
## 45 m towers with their glass-and-metal globes, the wings either side,
## and the two arched train sheds behind.
static func praha_hln(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#D8CDB0", "#E3DAC4", "copper", "#5E8C7A")
	for s in [-1.0, 1.0]:
		K.shed(lm, "Roof", "Steel", "Glass", Vector3(s * 17.0, 0, -20), Vector3.FORWARD, 33.0, 230.0, 8.0, 12.0, 9.0,
			0.5, 1)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 52.0, -4.0, 50.0, 18.0, 0.0, 15.0, "mansard", 4.0, 4.5, 5.0, true)
		var tx: float = s * 25.0
		K.block(lm, "Walls", "Trim", "Glass", "Roof", tx, 1.0, 9.0, 9.0, 0.0, 36.0, "flat", 0.0, 3.0, 6.0)
		lm.lathe("Roof", Vector3(tx, 36.0, 1.0), LandmarkFhUtil.dome_prof(4.2, 4.5), 16)
		lm.lathe("Gilt", Vector3(tx, 40.5, 1.0), LandmarkFhUtil.ball(1.6), 12)
		lm.box("Gilt", Vector3(tx, 43.8, 1.0), Vector3(0.3, 1.2, 0.3))
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, -2.0, 40.0, 26.0, 0.0, 20.0, "flat", 0.0, 4.0, 5.0)
	K.arch_window(lm, "Trim", "Glass", Vector3(0, 2.0, 11.05), Vector3.BACK, 26.0, 26.0, 7, 1.4)
	lm.lathe("Roof", Vector3(0, 20.0, -2.0), LandmarkFhUtil.dome_prof(15.0, 9.0), 20, 1.0, 1.0)
	K.clock(lm, "Dial", "Trim", Vector3(0, 22.0, 11.6), Vector3.BACK, 1.6)
	for x in [-14.0, -8.0, 8.0, 14.0]:
		K.statue(lm, "Trim", Vector3(x, 20.0, 10.6), 3.5)
	lm.commit(model)

## Budapest Keleti (Rochlitz and Feketeházy, 1884): the stone front whose
## great glazed arch closes the 42 m iron shed, the statues of Watt and
## Stephenson either side and the allegorical group on the crown, the
## corner pavilions and the office wings along the shed.
static func keleti(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "limestone", "#CFC3A9", "#DED4C0", "slate", "#4F575E")
	K.shed(lm, "Roof", "Steel", "Glass", Vector3(0, 0, -2), Vector3.FORWARD, 42.0, 185.0, 18.0, 12.0, 9.0, 0.5, 1)
	lm.box("Walls", Vector3(0, 15.0, 0.5), Vector3(48.0, 30.0, 4.0))
	K.arch_window(lm, "Trim", "Glass", Vector3(0, 1.0, 2.55), Vector3.BACK, 32.0, 27.0, 8, 1.4)
	lm.box("Trim", Vector3(0, 30.6, 0.5), Vector3(49.0, 1.2, 5.0))
	lm.box("Trim", Vector3(0, 31.8, 1.0), Vector3(14.0, 1.2, 3.0))
	K.statue(lm, "Trim", Vector3(0, 33.0, 1.0), 2.0)
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 31.0, -1.0, 14.0, 14.0, 0.0, 22.0, "flat", 0.0, 3.4, 5.5, true)
		lm.lathe("Roof", Vector3(s * 31.0, 22.0, -1.0), LandmarkFhUtil.dome_prof(6.0, 5.0), 4, 1.0, 1.0, PI * 0.25, false)
		K.statue(lm, "Trim", Vector3(s * 19.0, 18.0, 3.0), 4.0)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 31.0, -98.0, 14.0, 180.0, 0.0, 16.0, "hip", 3.0, 4.5, 5.0, true)
	lm.commit(model)

## Warszawa Centralna (Arseniusz Romanowicz, 1975): the glazed hall under
## its roof of concrete hyperbolic-paraboloid shells, the low pavilions
## round it, the platforms beneath the street.
static func warszawa_centralna(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "concrete", "#B1AEA7", "#C9C6BF", "roof_concrete", "#8F8C85")
	lm.box("Glass", Vector3(0, 8.5, 0), Vector3(120.0, 17.0, 64.0), Basis(), 0.0)
	LandmarkFhParts.ribs(lm, "Steel", Vector3(-60, 0, 32.05), Vector3(60, 0, 32.05), Vector3.BACK, 0.0, 17.0, 3.0, 0.2, 0.2)
	LandmarkFhParts.ribs(lm, "Steel", Vector3(-60, 0, -32.05), Vector3(60, 0, -32.05), Vector3.FORWARD, 0.0, 17.0, 3.0,
		0.2, 0.2)
	# Six hypar shells, 40 by 32 m, their corners alternately high and low.
	for i in 3:
		for j in 2:
			var c := Vector3(-40.0 + 40.0 * float(i), 17.0, -16.0 + 32.0 * float(j))
			var p := [c + Vector3(-20, 3.0, -16), c + Vector3(20, 0.0, -16), c + Vector3(20, 3.0, 16),
				c + Vector3(-20, 0.0, 16)]
			for k in 4:
				for m in 4:
					var u0 := float(k) / 4.0
					var u1 := float(k + 1) / 4.0
					var v0 := float(m) / 4.0
					var v1 := float(m + 1) / 4.0
					var q := func(u: float, v: float) -> Vector3:
						return ((p[0] as Vector3).lerp(p[1], u)).lerp((p[3] as Vector3).lerp(p[2], u), v)
					lm.quad("Roof", q.call(u0, v0), q.call(u1, v0), q.call(u1, v1), q.call(u0, v1), Vector3.UP)
					lm.quad("Roof", q.call(u1, v0), q.call(u0, v0), q.call(u0, v1), q.call(u1, v1), Vector3.DOWN)
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 72.0, 0.0, 24.0, 40.0, 0.0, 7.0, "flat", 0.0, 4.0, 4.0)
	lm.commit(model)

## Heinrich Wenck's København H (1911): the national-romantic red brick
## and granite station with its great arched hall roof of copper, the
## gabled front on Bernstorffsgade and the clock tower at the corner.
static func kobenhavn_h(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "brick", "#9A4C38", "#C9BFAE", "copper", "#5C8D7B")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, -14.0, 74.0, 44.0, 0.0, 13.0, "barrel", 14.0, 5.0, 5.0)
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 62.0, -6.0, 50.0, 26.0, 0.0, 12.0, "gable_x", 8.0, 4.0, 4.5, true)
	for i in 3:
		var x := -24.0 + 24.0 * float(i)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", x, 10.0, 14.0, 8.0, 0.0, 12.0, "gable_z", 7.0, 3.2, 4.5, true)
	LandmarkStationKit.lunette(lm, "Trim", "Glass", Vector3(0, 13.0, 8.1), Vector3.BACK, 40.0, 12.0, 12, 7)
	K.clock_tower(lm, "Walls", "Trim", "Roof", "Dial", "Glass", Vector3(-41.0, 0, 9.0), 8.0, 32.0, "spire", 9.0)
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

## Oslo S: the 1882 Østbanehallen on Jernbanetorget, rendered brick with
## its pedimented centre and hipped roofs, beside the 1980 concourse of
## glass and concrete, and the platform canopies behind.
static func oslo_s(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#C9B48E", "#DCCFB5", "slate", "#454C52")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", -40.0, 0.0, 90.0, 24.0, 0.0, 13.0, "hip", 5.0, 4.0, 5.0, true)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", -40.0, 2.0, 22.0, 26.0, 0.0, 15.0, "gable_z", 5.0, 3.6, 5.0, true)
	K.clock(lm, "Dial", "Trim", Vector3(-40.0, 17.2, 15.2), Vector3.BACK, 1.2)
	K.block(lm, "Glass", "Steel", "Walls", "Roof", 50.0, -6.0, 80.0, 36.0, 0.0, 20.0, "flat", 0.0, 3.0, 4.0)
	for i in 6:
		K.shed(lm, "Roof", "Steel", "Glass", Vector3(-90, 0, -30.0 - 12.0 * float(i)), Vector3.RIGHT, 10.0, 230.0, 5.0,
			1.2, 12.0, 0.3, 0)
	lm.commit(model)
