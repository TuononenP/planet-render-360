class_name LandmarkCsWest
extends RefCounted

## Capital termini of western Europe in true metres, built in the station
## frame (+X along the main facade, +Z out to the forecourt, the tracks
## and train sheds toward -Z), origin at the head building's centre:
## Paris Gare du Nord, Amsterdam Centraal, Brussels-Central, Dublin
## Heuston, Bern, Madrid Atocha, Lisbon Rossio and Roma Termini.

const K = preload("res://scripts/generation/landmarks/capital_stations/landmark_station_kit.gd")

## Hittorff's Gare du Nord (1865): the 180 m limestone front on Place
## Napoléon III; its central pavilion, raised so its crown hides the shed,
## with the one great glazed arch between two lower glazed arches and the
## giant pilasters carrying statues, the attic of the cities' statues and
## Paris on the crown (about 39 m); the lower arcaded ranges and end
## pavilions, and the three-nave iron and glass train shed behind.
static func gare_du_nord(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "limestone", "#D9CDB4", "#E6DDCB", "slate", "#5B636B")
	lm.use("Glass", LandmarkMaterials.glass("#7E93A3"))
	K.shed(lm, "Roof", "Steel", "Glass", Vector3(0, 0, -8), Vector3.FORWARD, 70.0, 190.0, 20.0, 12.0, 10.0, 0.5, 1)
	for s in [-1.0, 1.0]:
		K.shed(lm, "Roof", "Steel", "Glass", Vector3(s * 56.0, 0, -8), Vector3.FORWARD, 42.0, 190.0, 15.0, 8.0,
			10.0, 0.5, 1)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 59.0, 0.0, 58.0, 16.0, 0.0, 17.0, "mansard", 3.5, 5.0, 6.0, true)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 81.0, 0.5, 18.0, 17.0, 0.0, 22.0, "mansard", 5.0, 4.5, 6.5, true)
		for x in [s * 76.0, s * 86.0]:
			K.statue(lm, "Trim", Vector3(x, 27.0, 8.6), 3.4)
	lm.box("Walls", Vector3(0, 16.0, 0.5), Vector3(60.0, 32.0, 17.0))
	K.arch_window(lm, "Trim", "Glass", Vector3(0, 1.2, 9.05), Vector3.BACK, 17.0, 27.0, 6, 1.0)
	for x in [-20.5, 20.5]:
		K.arch_window(lm, "Trim", "Glass", Vector3(x, 1.2, 9.05), Vector3.BACK, 11.0, 18.0, 3, 0.8)
	LandmarkFhParts.strips(lm, "Trim", Vector3(-27.5, 0, 9.0), Vector3(27.5, 0, 9.0), Vector3.BACK, 0.0, 29.0, 4, 2.2, 0.9)
	lm.box("Trim", Vector3(0, 29.6, 9.3), Vector3(61.0, 1.4, 1.6))
	lm.box("Walls", Vector3(0, 31.2, 8.6), Vector3(60.0, 1.8, 1.2))
	lm.box("Trim", Vector3(0, 32.3, 1.0), Vector3(61.0, 0.6, 18.0))
	for x in [-27.5, -9.2, 9.2, 27.5]:
		K.statue(lm, "Trim", Vector3(x, 32.6, 8.7), 4.2)
	lm.gable("Trim", Vector3(0, 32.6, 8.0), 24.0, 2.6, 3.0, Basis(Vector3.UP, PI * 0.5), 0.3, "Walls")
	K.statue(lm, "Trim", Vector3(0, 35.6, 8.0), 3.8)
	K.clock(lm, "Dial", "Trim", Vector3(0, 25.2, 9.3), Vector3.BACK, 1.8)
	lm.commit(model)

## Cuypers' Amsterdam Centraal (1889) on its islands in the IJ: the red
## brick neo-Renaissance range with cream stone bands, steep slate roofs
## and dormered pavilions; the tall stepped central gable between the two
## towers (about 45 m), each rising in stages to an open lantern and a
## slender spire, the west with the clock and the east with the gilt wind
## dial; the two arched train sheds behind, the tracks along the building.
static func amsterdam_centraal(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "brick", "#8E3B2B", "#E2D7BF", "slate", "#3F474F")
	K.shed(lm, "Roof", "Steel", "Glass", Vector3(-135, 0, -38), Vector3.RIGHT, 40.0, 270.0, 9.0, 14.0, 9.0, 0.5, 3)
	K.shed(lm, "Roof", "Steel", "Glass", Vector3(-110, 0, -75), Vector3.RIGHT, 32.0, 220.0, 8.0, 10.0, 9.0, 0.5, 3)
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 47.0, 0.0, 58.0, 24.0, 0.0, 16.0, "hip", 7.0, 4.2, 5.0, true)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 83.0, 0.0, 14.0, 27.0, 0.0, 19.0, "hip", 8.0, 3.5, 5.5, true)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 105.0, 0.0, 30.0, 24.0, 0.0, 15.0, "hip", 6.5, 4.2, 5.0, true)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 124.0, 0.0, 10.0, 26.0, 0.0, 17.0, "hip", 7.0, 3.5, 5.5, true)
		var t := Vector3(s * 13.0, 0, 6.0)
		K.clock_tower(lm, "Walls", "Trim", "Roof", "Dial" if s < 0.0 else "Gilt", "Glass", t, 9.0, 27.0, "flat", 0.6)
		lm.box("Walls", t + Vector3.UP * 30.5, Vector3(6.5, 6.0, 6.5))
		LandmarkFhUtil.openings(lm, "Glass", t + Vector3(-2.0, 0, 3.27), t + Vector3(2.0, 0, 3.27), Vector3.BACK, 28.5,
			2, 1.2, 4.0, true, 0.02)
		lm.spire("Roof", t + Vector3.UP * 33.5, 3.6, 11.5)
	# The central gable: a tall stepped front over the entrance.
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 1.5, 17.0, 27.0, 0.0, 24.0, "gable_z", 9.0, 4.0, 5.5, false)
	LandmarkFhParts.crow_gable(lm, "Walls", "Trim", Vector3(0, 0, 14.6), Vector3.BACK, 17.0, 24.0, 9.0, 5, 0.8)
	K.arch_row(lm, "Trim", "Glass", Vector3(-7.5, 0, 15.05), Vector3(7.5, 0, 15.05), Vector3.BACK, 0.6, 3, 4.0, 8.5, 2)
	K.arch_window(lm, "Trim", "Glass", Vector3(0, 11.0, 15.05), Vector3.BACK, 9.0, 10.0, 3)
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

## Sancton Wood's Heuston (1846): the warm grey Italianate palazzo of
## three storeys, its upper floors ordered by pilasters between tall
## windows under a heavy cornice and a balustrade with urns, the corner
## turrets rising above the cornice to domed cupolas (the left one the
## clock turret with its lantern), the long single-storey arcaded range
## beside the shed, and the iron train shed behind.
static func heuston(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "stone", "#BDB3A0", "#CFC6B4", "slate", "#454C53")
	for i in 3:
		K.shed(lm, "Roof", "Steel", "Glass", Vector3(-26.0 + 26.0 * float(i), 0, -10), Vector3.FORWARD, 26.0, 180.0,
			7.0, 6.5, 8.0, 0.55, 1)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 64.0, 18.0, 0.0, 17.0, "flat", 0.0, 4.6, 5.5, true)
	LandmarkFhParts.strips(lm, "Trim", Vector3(-30, 0, 9.0), Vector3(30, 0, 9.0), Vector3.BACK, 5.5, 10.5, 14, 0.8, 0.5)
	lm.box("Trim", Vector3(0, 16.4, 0), Vector3(66.0, 1.2, 20.0))
	LandmarkFhUtil.merlons(lm, "Trim", Vector3(-31.5, 17.0, 9.6), Vector3(31.5, 17.0, 9.6), 1.0, 0.35, 1.0, 0.35)
	lm.box("Trim", Vector3(0, 18.1, 9.6), Vector3(63.0, 0.3, 0.6))
	for x in [-24.0, -12.0, 0.0, 12.0, 24.0]:
		lm.lathe("Trim", Vector3(x, 18.2, 9.6), PackedVector2Array([Vector2(0.35, 0.0), Vector2(0.45, 0.5),
			Vector2(0.2, 1.0), Vector2(0.0, 1.2)]), 8)
	for s in [-1.0, 1.0]:
		var c := Vector3(s * 28.5, 17.0, 6.5)
		lm.box("Walls", c + Vector3.UP * 3.5, Vector3(6.4, 7.0, 6.4))
		LandmarkFhParts.box_band(lm, "Trim", c.x, c.z, 6.4, 6.4, 23.4, 0.6, 0.3)
		lm.lathe("Roof", c + Vector3.UP * 7.6, LandmarkFhUtil.dome_prof(3.4, 2.6), 12)
		lm.frustum("Trim", c + Vector3.UP * 10.2, 0.9, 0.7, 1.6, 8)
		lm.lathe("Roof", c + Vector3.UP * 11.8, LandmarkFhUtil.dome_prof(0.9, 1.0), 8)
	K.clock(lm, "Dial", "Trim", Vector3(-28.5, 21.5, 9.8), Vector3.BACK, 1.3)
	# The arcaded range along the shed's side.
	K.block(lm, "Walls", "Trim", "Glass", "Roof", -45.0, -70.0, 8.0, 140.0, 0.0, 6.0, "flat", 0.0, 4.0, 5.0)
	K.arch_row(lm, "Trim", "Glass", Vector3(-49.05, 0, -2.0), Vector3(-49.05, 0, -138.0), Vector3.LEFT, 0.4, 30, 3.0, 4.6, 0)
	lm.commit(model)

## Bern's station (1974 hall, the 2008 Baldachin): the low concourse
## block of horizontal concrete bands and glazing on the Bahnhofplatz,
## the great glass Baldachin leaning out over the square on its slender
## raking columns, the platform deck over the western tracks and the
## canopies over the rest.
static func bern(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "concrete", "#A9A59E", "#C8C3BA", "roof_concrete", "#6B6862")
	lm.box("Walls", Vector3(0, 8.0, -10.0), Vector3(150.0, 16.0, 34.0))
	for y in [3.0, 7.2, 11.4]:
		lm.box("Glass", Vector3(0, y, -10.0), Vector3(150.2, 2.6, 34.2), Basis(), 0.0)
	lm.box("Trim", Vector3(0, 16.2, -10.0), Vector3(151.0, 0.6, 35.0))
	K.block(lm, "Walls", "Trim", "Glass", "Roof", -40.0, -14.0, 30.0, 24.0, 16.0, 4.0, "flat", 0.0, 3.5, 4.0)
	lm.box("Roof", Vector3(-40.0, 7.5, -110.0), Vector3(70.0, 1.2, 150.0))
	for ix in 4:
		for iz in 7:
			lm.box("Trim", Vector3(-70.0 + 20.0 * float(ix), 3.45, -45.0 - 22.0 * float(iz)), Vector3(1.0, 6.9, 1.0))
	for i in 3:
		K.shed(lm, "Roof", "Steel", "Glass", Vector3(5.0 + 30.0 * float(i), 0, -30), Vector3.FORWARD, 12.0, 160.0,
			6.0, 1.5, 12.0, 0.3, 0)
	# The Baldachin: a thick glass roof from 12 m at the hall rising to 15 m
	# about 18 m out over the square, its deep steel edge on raking columns.
	var a := Vector3(-34, 12.0, 7.5)
	var b := Vector3(34, 12.0, 7.5)
	var c := Vector3(30, 15.0, 25.5)
	var d := Vector3(-30, 15.0, 25.5)
	var up := (b - a).cross(d - a).normalized()
	if up.y < 0.0:
		up = -up
	lm.quad("Glass", a, b, c, d, up)
	lm.quad("Glass", b + Vector3.DOWN * 0.6, a + Vector3.DOWN * 0.6, d + Vector3.DOWN * 0.6, c + Vector3.DOWN * 0.6, -up)
	for e in [[a, b], [b, c], [c, d], [d, a]]:
		lm.beam("Steel", e[0] + Vector3.DOWN * 0.3, e[1] + Vector3.DOWN * 0.3, 0.8, 1.2)
	for k in 6:
		var t := float(k) / 5.0
		var top := d.lerp(c, t).lerp(a.lerp(b, t), 0.25)
		lm.beam("Steel", Vector3(top.x * 0.9, 0, top.z - 3.0), top + Vector3.DOWN * 0.6, 0.6, 0.6)
	lm.commit(model)

## The old Atocha (Alberto de Palacio, 1892): the iron and glass shed of
## 48 m span and 27 m rise, roofed in dark grey zinc with a glazed ridge,
## its gable to the Glorieta del Emperador Carlos V an iron lattice with
## the clock and the bronze globe on the apex; the two red brick
## pavilions with their tiled cupolas, and the brick side ranges of deep
## arched bays between stone piers.
static func atocha(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "brick", "#A0482F", "#D8C3A0", "sheet_metal", "#4E555C")
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#8C5A3C", 2.0))
	K.shed(lm, "Roof", "Steel", "Glass", Vector3(0, 0, 0), Vector3.FORWARD, 48.0, 152.0, 12.0, 15.0, 8.0, 0.18, 3)
	for s in [-1.0, 1.0]:
		var x: float = s * 30.5
		K.block(lm, "Walls", "Trim", "Glass", "Roof", x, -76.0, 13.0, 152.0, 0.0, 11.0, "gable_z", 3.0, 6.0, 5.5)
		K.arch_row(lm, "Trim", "Glass", Vector3(x + s * 6.55, 0, -4.0), Vector3(x + s * 6.55, 0, -148.0), Vector3(s, 0, 0),
			0.6, 24, 4.0, 8.5, 1)
		LandmarkFhParts.strips(lm, "Trim", Vector3(x + s * 6.5, 0, -2.0), Vector3(x + s * 6.5, 0, -150.0), Vector3(s, 0, 0),
			0.0, 11.0, 25, 1.0, 0.4)
		var c := Vector3(s * 31.0, 0, 3.5)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", c.x, c.z, 13.0, 13.0, 0.0, 22.0, "flat", 0.0, 3.2, 5.5, true)
		lm.lathe("Tile", c + Vector3.UP * 22.0, LandmarkFhUtil.dome_prof(6.0, 5.0), 16)
		lm.frustum("Trim", c + Vector3.UP * 27.0, 0.6, 0.2, 1.0, 8)
	K.clock(lm, "Dial", "Trim", Vector3(0, 19.0, 0.6), Vector3.BACK, 2.0)
	lm.lathe("Gilt", Vector3(0, 27.0, 0.4), LandmarkFhUtil.ball(1.2), 12)
	lm.box("Trim", Vector3(0, 26.7, 0.4), Vector3(3.0, 0.6, 1.2))
	lm.commit(model)

## José Luís Monteiro's Rossio (1890) on the Praça D. João da Câmara: the
## light cream neo-Manueline front, its ground floor an arcade of
## horseshoe arches with the two great keyhole portals rising two and a
## half storeys in the middle, the upper floors grouped into five bays by
## buttress piers ending in pinnacles, the row of arched windows on the
## second floor, the crenellated skyline, and the square crowned clock
## turret two storeys above the parapet with its corner pinnacles.
static func rossio(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "limestone", "#E6DCC6", "#EEE7D6", "slate", "#5A6168")
	lm.box("Walls", Vector3(0, 12.0, 0), Vector3(58.0, 24.0, 20.0))
	lm.box("Trim", Vector3(0, 23.6, 0), Vector3(58.6, 0.8, 20.6))
	for x in [-24.0, -18.0, 18.0, 24.0]:
		K.arch_window(lm, "Trim", "Glass", Vector3(x, 0.4, 10.05), Vector3.BACK, 4.0, 6.5, 1, 0.5)
	for x in [-6.5, 6.5]:
		K.arch_window(lm, "Trim", "Glass", Vector3(x, 0.4, 10.05), Vector3.BACK, 8.0, 12.5, 3, 1.0)
	K.arch_row(lm, "Trim", "Glass", Vector3(-28, 0, 10.05), Vector3(28, 0, 10.05), Vector3.BACK, 13.2, 10, 2.4, 4.4, 1)
	LandmarkFhUtil.window_grid(lm, "Glass", Vector3(-27, 0, 10.05), Vector3(27, 0, 10.05), Vector3.BACK, 18.6, 1, 4.0,
		10, 1.8, 3.0)
	for k in 6:
		var x := -29.0 + 11.6 * float(k)
		lm.box("Walls", Vector3(x, 12.5, 10.6), Vector3(1.4, 25.0, 1.2))
		lm.frustum("Trim", Vector3(x, 25.0, 10.6), 0.6, 0.12, 3.2, 8)
	LandmarkFhUtil.merlons(lm, "Trim", Vector3(-28.5, 24.0, 10.0), Vector3(28.5, 24.0, 10.0), 1.6, 0.8, 1.3, 0.5)
	var t := Vector3(0, 24.0, 7.0)
	lm.box("Walls", t + Vector3.UP * 4.5, Vector3(7.0, 9.0, 7.0))
	K.clock(lm, "Dial", "Trim", t + Vector3(0, 6.0, 3.55), Vector3.BACK, 1.6)
	LandmarkFhUtil.merlons(lm, "Trim", t + Vector3(-3.5, 9.0, 3.5), t + Vector3(3.5, 9.0, 3.5), 1.2, 0.6, 1.0, 0.4)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.frustum("Trim", t + Vector3(sx * 3.3, 9.0, sz * 3.3), 0.5, 0.1, 3.0, 8)
	lm.lathe("Roof", t + Vector3.UP * 9.0, LandmarkFhUtil.dome_prof(2.4, 2.4), 12)
	K.shed(lm, "Roof", "Steel", "Glass", Vector3(0, 18.0, -10), Vector3.FORWARD, 40.0, 90.0, 4.0, 5.0, 9.0, 0.5, 0)
	lm.commit(model)

## Roma Termini (Montuori and Calini, 1950): the long travertine office
## block with its ribbon windows, the glass-fronted atrium with its red
## name panels under the "dinosaur", the thick concrete canopy whose
## section rises in waves toward the Piazza dei Cinquecento and ends in a
## sharp overhang about 20 m out, and the flat canopies over the
## platforms behind.
static func termini(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "limestone", "#E8E2D2", "#EFEADD", "roof_concrete", "#B8B2A6")
	lm.use("Sign", LandmarkMaterials.lit("#B3262A", 0.35))
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, -24.0, 232.0, 16.0, 0.0, 25.0, "flat", 0.0, 3.2, 3.4)
	for y in range(3, 25, 3):
		LandmarkFhParts.band(lm, "Glass", Vector3(-115, 0, -15.95), Vector3(115, 0, -15.95), Vector3.BACK,
			float(y) - 0.4, 1.4, 0.06)
	# The wave section (z, y): five crests rising toward the piazza; the
	# soffit follows 1.8 m below, the front edge a deep fascia.
	var prof := [Vector2(-16.0, 12.0), Vector2(-10.0, 15.6), Vector2(-4.0, 13.4), Vector2(2.0, 17.2), Vector2(8.0, 14.8),
		Vector2(14.0, 18.6), Vector2(20.0, 16.0), Vector2(26.0, 19.8), Vector2(32.0, 17.2), Vector2(36.0, 20.6)]
	var hx := 64.0
	for i in prof.size() - 1:
		var p0: Vector2 = prof[i]
		var p1: Vector2 = prof[i + 1]
		lm.quad("Roof", Vector3(-hx, p0.y, p0.x), Vector3(hx, p0.y, p0.x), Vector3(hx, p1.y, p1.x), Vector3(-hx, p1.y, p1.x),
			Vector3.UP)
		lm.quad("Roof", Vector3(hx, p0.y - 1.8, p0.x), Vector3(-hx, p0.y - 1.8, p0.x), Vector3(-hx, p1.y - 1.8, p1.x),
			Vector3(hx, p1.y - 1.8, p1.x), Vector3.DOWN)
	var tip: Vector2 = prof[prof.size() - 1]
	lm.box("Roof", Vector3(0, tip.y - 1.0, tip.x), Vector3(hx * 2.0, 2.0, 0.6))
	for k in 17:
		var x := -hx + 2.0 * hx * float(k) / 16.0
		for i in prof.size() - 1:
			var p0: Vector2 = prof[i]
			var p1: Vector2 = prof[i + 1]
			lm.beam("Roof", Vector3(x, p0.y - 2.4, p0.x), Vector3(x, p1.y - 2.4, p1.x), 0.5, 1.0)
	lm.box("Glass", Vector3(0, 6.0, 16.0), Vector3(hx * 2.0, 12.0, 0.2), Basis(), 0.0)
	for x in [-40.0, 0.0, 40.0]:
		lm.box("Sign", Vector3(x, 10.5, 16.2), Vector3(14.0, 1.6, 0.15), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		lm.quad("Glass", Vector3(s * hx, 0, 16.0), Vector3(s * hx, 0, -16.0), Vector3(s * hx, 11.0, -16.0),
			Vector3(s * hx, 12.0, 16.0), Vector3(s, 0, 0))
	LandmarkFhParts.ribs(lm, "Steel", Vector3(-hx, 0, 16.1), Vector3(hx, 0, 16.1), Vector3.BACK, 0.0, 12.0, 4.0, 0.2, 0.2)
	lm.box("Trim", Vector3(0, 0.3, 0), Vector3(hx * 2.0, 0.6, 32.0))
	for i in 10:
		var x := -110.0 + 24.0 * float(i)
		lm.box("Roof", Vector3(x, 5.5, -200.0), Vector3(9.0, 0.5, 340.0))
		for k in 9:
			lm.box("Steel", Vector3(x, 2.7, -40.0 - 40.0 * float(k)), Vector3(0.5, 5.4, 0.5), Basis(), 0.0)
	lm.commit(model)
