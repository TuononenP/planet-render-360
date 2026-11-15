class_name LandmarkCsWest
extends RefCounted

## Capital termini of western Europe in true metres, built in the station
## frame (+X along the main facade, +Z out to the forecourt, the tracks
## and train sheds toward -Z), origin at the head building's centre:
## Paris Gare du Nord, Amsterdam Centraal, Brussels-Central, Dublin
## Heuston, Bern, Madrid Atocha, Lisbon Rossio and Roma Termini.

const K = preload("res://scripts/generation/landmarks/capital_stations/landmark_station_kit.gd")

## Hittorff's Gare du Nord (1865): the 180 m limestone front on Place
## Napoléon III, its central pavilion of three great arched bays between
## giant pilasters under an attic of the cities' statues with Paris on the
## crown (38 m), the lower arcaded ranges and end pavilions, and the
## three-nave iron and glass train shed behind.
static func gare_du_nord(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "limestone", "#D6CBB4", "#E2D9C6", "slate", "#5B636B")
	K.shed(lm, "Roof", "Steel", "Glass", Vector3(0, 0, -8), Vector3.FORWARD, 70.0, 190.0, 22.0, 13.0, 10.0, 0.5, 1)
	for s in [-1.0, 1.0]:
		K.shed(lm, "Roof", "Steel", "Glass", Vector3(s * 56.0, 0, -8), Vector3.FORWARD, 42.0, 190.0, 15.0, 8.0,
			10.0, 0.5, 1)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 59.0, 0.0, 58.0, 16.0, 0.0, 17.0, "mansard", 3.5, 5.0, 6.0, true)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 81.0, 0.5, 18.0, 17.0, 0.0, 22.0, "mansard", 5.0, 4.5, 6.5, true)
	lm.box("Walls", Vector3(0, 14.5, 0.5), Vector3(60.0, 29.0, 17.0))
	for i in [-1.0, 0.0, 1.0]:
		K.arch_window(lm, "Trim", "Glass", Vector3(i * 17.0, 1.2, 9.05), Vector3.BACK, 11.5, 22.0, 4, 0.9)
	LandmarkFhParts.strips(lm, "Trim", Vector3(-25.5, 0, 9.0), Vector3(25.5, 0, 9.0), Vector3.BACK, 0.0, 26.0, 4, 2.0, 0.9)
	LandmarkFhParts.strips(lm, "Trim", Vector3(-29.0, 0, 9.0), Vector3(29.0, 0, 9.0), Vector3.BACK, 0.0, 26.0, 2, 1.4, 0.6)
	lm.box("Trim", Vector3(0, 26.6, 9.3), Vector3(61.0, 1.4, 1.6))
	lm.box("Walls", Vector3(0, 28.4, 8.6), Vector3(60.0, 2.2, 1.2))
	lm.box("Trim", Vector3(0, 29.3, 1.0), Vector3(61.0, 0.6, 18.0))
	for k in 9:
		var x := -26.0 + 6.5 * float(k)
		if absf(x) > 1.0:
			K.statue(lm, "Trim", Vector3(x, 29.6, 8.7), 4.2)
	lm.box("Trim", Vector3(0, 30.8, 8.0), Vector3(12.0, 2.4, 3.0))
	K.statue(lm, "Trim", Vector3(0, 32.0, 8.0), 6.0)
	K.clock(lm, "Dial", "Trim", Vector3(0, 24.6, 9.2), Vector3.BACK, 1.6)
	lm.commit(model)

## Cuypers' Amsterdam Centraal (1889) on its islands in the IJ: the red
## brick neo-Renaissance range with stone bands, steep slate roofs and
## dormered pavilions, the central block between its two towers (the west
## with the clock, the east with the wind dial) and the two arched train
## sheds behind, the tracks running along the building.
static func amsterdam_centraal(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "brick", "#8E4A36", "#D8CDB6", "slate", "#3F474F")
	K.shed(lm, "Roof", "Steel", "Glass", Vector3(-135, 0, -38), Vector3.RIGHT, 40.0, 270.0, 9.0, 14.0, 9.0, 0.5, 3)
	K.shed(lm, "Roof", "Steel", "Glass", Vector3(-110, 0, -75), Vector3.RIGHT, 32.0, 220.0, 8.0, 10.0, 9.0, 0.5, 3)
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 47.0, 0.0, 58.0, 24.0, 0.0, 16.0, "hip", 7.0, 4.2, 5.0, true)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 83.0, 0.0, 14.0, 27.0, 0.0, 19.0, "hip", 8.0, 3.5, 5.5, true)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 105.0, 0.0, 30.0, 24.0, 0.0, 15.0, "hip", 6.5, 4.2, 5.0, true)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 124.0, 0.0, 10.0, 26.0, 0.0, 17.0, "hip", 7.0, 3.5, 5.5, true)
		var tx: float = s * 13.0
		K.clock_tower(lm, "Walls", "Trim", "Roof", "Dial", "Glass", Vector3(tx, 0, 6.0), 9.0, 31.0, "pavilion", 9.5)
		lm.box("Gilt", Vector3(tx, 40.75, 6.0), Vector3(0.3, 0.5, 0.3))
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 1.5, 17.0, 27.0, 0.0, 21.0, "gable_z", 9.0, 4.0, 5.5, false)
	K.arch_row(lm, "Trim", "Glass", Vector3(-7.5, 0, 15.05), Vector3(7.5, 0, 15.05), Vector3.BACK, 0.6, 3, 4.0, 8.5, 2)
	K.arch_window(lm, "Trim", "Glass", Vector3(0, 11.0, 15.05), Vector3.BACK, 9.0, 8.5, 3)
	for y in [5.0, 10.5]:
		LandmarkFhParts.band(lm, "Trim", Vector3(-128, 0, 12.05), Vector3(128, 0, 12.05), Vector3.BACK, y, 0.5, 0.25)
	lm.commit(model)

## Brussels-Central (Horta and Brunfaut, 1952): the long, low sandstone
## block on the Carrefour de l'Europe and its tall central booking hall
## lit by narrow vertical windows, the tracks in the tunnel beneath.
static func brussels_central(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "stone", "#B5A585", "#CFC3A8", "roof_concrete", "#6E6A63")
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 62.0, -4.0, 70.0, 34.0, 0.0, 15.0, "flat", 0.0, 3.4, 4.2)
	lm.box("Walls", Vector3(0, 13.0, -2.0), Vector3(54.0, 26.0, 40.0))
	lm.box("Trim", Vector3(0, 25.7, -2.0), Vector3(55.0, 0.6, 41.0))
	LandmarkFhParts.ribs(lm, "Trim", Vector3(-25, 0, 18.0), Vector3(25, 0, 18.0), Vector3.BACK, 4.0, 24.0, 2.6, 0.7, 0.5)
	LandmarkFhUtil.openings(lm, "Glass", Vector3(-24, 0, 18.05), Vector3(24, 0, 18.05), Vector3.BACK, 5.0, 19, 1.3,
		18.0, false)
	K.canopy(lm, "Trim", "Steel", Vector3(-22, 0, 18.0), Vector3(22, 0, 18.0), Vector3.BACK, 5.0, 4.4, 6)
	K.clock(lm, "Dial", "Trim", Vector3(0, 22.5, 18.4), Vector3.BACK, 1.4)
	lm.commit(model)

## Sancton Wood's Heuston (1846): the granite palazzo front of two storeys
## and attic with its balustrade and the corner turrets with their domed
## cupolas, and the train shed of iron spans behind.
static func heuston(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "stone", "#A7A096", "#C9C2B5", "slate", "#454C53")
	for i in 3:
		K.shed(lm, "Roof", "Steel", "Glass", Vector3(-26.0 + 26.0 * float(i), 0, -10), Vector3.FORWARD, 26.0, 180.0,
			7.0, 6.5, 8.0, 0.55, 1)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 64.0, 18.0, 0.0, 17.0, "flat", 0.0, 4.6, 6.0, true)
	LandmarkFhUtil.merlons(lm, "Trim", Vector3(-31.5, 17.0, 9.2), Vector3(31.5, 17.0, 9.2), 1.1, 0.4, 1.0, 0.4)
	for s in [-1.0, 1.0]:
		var c := Vector3(s * 28.5, 17.0, 6.5)
		lm.box("Walls", c + Vector3.UP * 2.5, Vector3(6.0, 5.0, 6.0))
		lm.lathe("Roof", c + Vector3.UP * 5.0, LandmarkFhUtil.dome_prof(3.2, 1.8), 12)
		lm.frustum("Trim", c + Vector3.UP * 6.8, 0.8, 0.5, 1.2, 8)
		lm.lathe("Roof", c + Vector3.UP * 8.0, LandmarkFhUtil.dome_prof(0.8, 0.0 + 1.0), 8)
	K.clock(lm, "Dial", "Trim", Vector3(0, 14.5, 9.3), Vector3.BACK, 1.2)
	lm.commit(model)

## Bern's station (1974 hall, the 2008 Baldachin): the long concourse block
## on the Bahnhofplatz under the great glass canopy that leans out over the
## square on its slender columns.
static func bern(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "concrete", "#A9A59E", "#C8C3BA", "roof_concrete", "#6B6862")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, -10.0, 150.0, 34.0, 0.0, 18.0, "flat", 0.0, 3.5, 4.0)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", -40.0, -14.0, 30.0, 24.0, 18.0, 4.0, "flat", 0.0, 3.5, 4.0)
	for i in 5:
		K.shed(lm, "Roof", "Steel", "Glass", Vector3(-70.0 + 35.0 * float(i), 0, -30), Vector3.FORWARD, 12.0, 160.0,
			6.0, 1.5, 12.0, 0.3, 0)
	# The Baldachin: a glass roof rising from 11 m at the hall to 22 m out
	# over the square, on six raking steel columns.
	var a := Vector3(-34, 11.0, 7.5)
	var b := Vector3(34, 11.0, 7.5)
	var c := Vector3(30, 22.0, 34.0)
	var d := Vector3(-30, 22.0, 34.0)
	var up := (b - a).cross(d - a).normalized()
	if up.y < 0.0:
		up = -up
	lm.quad("Glass", a, b, c, d, up)
	lm.quad("Glass", b, a, d, c, -up)
	for e in [[a, b], [b, c], [c, d], [d, a]]:
		lm.beam("Steel", e[0], e[1], 0.5, 0.8)
	for k in 6:
		var t := float(k) / 5.0
		var top := d.lerp(c, t).lerp(a.lerp(b, t), 0.25)
		lm.beam("Steel", Vector3(top.x * 0.9, 0, top.z - 2.0), top, 0.6, 0.6)
	lm.commit(model)

## The old Atocha (Alberto de Palacio, 1892): the iron and glass shed of
## 48 m span and 27 m rise whose glazed gable faces the Glorieta del
## Emperador Carlos V between the two brick pavilions with their tiled
## cupolas, and the side ranges along the shed.
static func atocha(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "brick", "#A0603F", "#D9CCB2", "terracotta", "#8C5A3C")
	K.shed(lm, "Roof", "Steel", "Glass", Vector3(0, 0, 0), Vector3.FORWARD, 48.0, 152.0, 12.0, 15.0, 8.0, 0.55, 3)
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 30.5, -76.0, 13.0, 152.0, 0.0, 11.0, "gable_z", 3.0, 4.5, 5.0, true)
		var c := Vector3(s * 31.0, 0, 3.5)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", c.x, c.z, 13.0, 13.0, 0.0, 22.0, "flat", 0.0, 3.2, 5.5, true)
		lm.lathe("Roof", c + Vector3.UP * 22.0, LandmarkFhUtil.dome_prof(6.0, 5.0), 16)
		lm.frustum("Trim", c + Vector3.UP * 27.0, 0.6, 0.2, 1.0, 8)
	K.clock(lm, "Dial", "Trim", Vector3(0, 21.0, 0.6), Vector3.BACK, 2.0)
	lm.commit(model)

## José Luís Monteiro's Rossio (1890) on the Praça D. João da Câmara: the
## neo-Manueline limestone front of five storeys with its two great
## horseshoe portals, twisted rope mouldings, a crenellated skyline and the
## clock turret over the centre (the platforms lie at the top floor).
static func rossio(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "limestone", "#DDD3BF", "#E8E0CF", "slate", "#5A6168")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 58.0, 20.0, 0.0, 24.0, "flat", 0.0, 3.0, 4.6, false)
	for x in [-6.5, 6.5]:
		var foot := Vector3(x, 0.3, 10.05)
		K.arch_window(lm, "Trim", "Glass", foot, Vector3.BACK, 8.0, 13.5, 3, 1.0)
		lm.box("Trim", foot + Vector3(-4.6, 6.5, 0.4), Vector3(0.8, 13.0, 0.8))
		lm.box("Trim", foot + Vector3(4.6, 6.5, 0.4), Vector3(0.8, 13.0, 0.8))
	LandmarkFhUtil.merlons(lm, "Trim", Vector3(-28.5, 24.0, 10.0), Vector3(28.5, 24.0, 10.0), 2.0, 1.0, 1.4, 0.5)
	for x in [-28.0, -14.0, 14.0, 28.0]:
		lm.frustum("Trim", Vector3(x, 24.0, 9.5), 0.6, 0.15, 3.5, 8)
	K.clock_tower(lm, "Walls", "Trim", "Roof", "Dial", "Glass", Vector3(0, 24.0, 7.0), 7.0, 8.5, "spire", 4.0)
	K.shed(lm, "Roof", "Steel", "Glass", Vector3(0, 18.0, -10), Vector3.FORWARD, 40.0, 90.0, 4.0, 5.0, 9.0, 0.5, 0)
	lm.commit(model)

## Roma Termini (Montuori and Calini, 1950): the glass-fronted atrium under
## its "dinosaur", the wave of cantilevered concrete ribs rising from the
## Piazza dei Cinquecento, against the long travertine block with its
## ribbon windows behind it.
static func termini(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "limestone", "#D6CBB0", "#E3DAC6", "roof_concrete", "#A8A399")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, -24.0, 232.0, 16.0, 0.0, 25.0, "flat", 0.0, 3.2, 3.4)
	for y in range(3, 25, 3):
		LandmarkFhParts.band(lm, "Glass", Vector3(-115, 0, -15.95), Vector3(115, 0, -15.95), Vector3.BACK,
			float(y) - 0.4, 1.4, 0.06)
	# The atrium: glass walls, then the wave roof as a profile (z, y) swept
	# along X, front cantilever low over the square, rising to the block.
	var prof := [Vector2(26.0, 11.0), Vector2(18.0, 13.6), Vector2(12.0, 13.2), Vector2(6.0, 15.4),
		Vector2(0.0, 15.0), Vector2(-6.0, 17.4), Vector2(-12.0, 17.0), Vector2(-16.0, 19.0)]
	var hx := 64.0
	for i in prof.size() - 1:
		var p0: Vector2 = prof[i]
		var p1: Vector2 = prof[i + 1]
		var a := Vector3(-hx, p0.y, p0.x)
		var b := Vector3(hx, p0.y, p0.x)
		var c := Vector3(hx, p1.y, p1.x)
		var d := Vector3(-hx, p1.y, p1.x)
		lm.quad("Roof", a, b, c, d, Vector3.UP)
		lm.quad("Roof", b, a, d, c, Vector3.DOWN)
	for k in 17:
		var x := -hx + 2.0 * hx * float(k) / 16.0
		for i in prof.size() - 1:
			var p0: Vector2 = prof[i]
			var p1: Vector2 = prof[i + 1]
			lm.beam("Roof", Vector3(x, p0.y - 0.6, p0.x), Vector3(x, p1.y - 0.6, p1.x), 0.5, 1.2)
	lm.box("Glass", Vector3(0, 6.0, 16.0), Vector3(hx * 2.0, 12.0, 0.2), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		lm.quad("Glass", Vector3(s * hx, 0, 16.0), Vector3(s * hx, 0, -16.0), Vector3(s * hx, 19.0, -16.0),
			Vector3(s * hx, 12.0, 16.0), Vector3(s, 0, 0))
	LandmarkFhParts.ribs(lm, "Steel", Vector3(-hx, 0, 16.1), Vector3(hx, 0, 16.1), Vector3.BACK, 0.0, 12.0, 4.0, 0.2, 0.2)
	lm.box("Trim", Vector3(0, 0.3, 0), Vector3(hx * 2.0, 0.6, 32.0))
	lm.commit(model)
