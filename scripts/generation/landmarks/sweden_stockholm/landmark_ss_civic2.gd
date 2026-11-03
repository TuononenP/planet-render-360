class_name LandmarkSsCivic2
extends RefCounted

## Civic landmarks of the sweden_stockholm batch, part two (the first is
## LandmarkSsCivic): the Concert Hall and the Riksdag Building, in true
## metres, origin at ground level at the footprint centre, front toward
## +Z (the registry yaw_deg turns it onto its real compass facing).
## Footprints are traced from the OpenStreetMap outlines and building
## parts in the model frame.

## Stockholm Concert Hall (Konserthuset, Ivar Tengbom, 1924-1926) on
## Hötorget: the plain block of rendered brick in the blue-violet
## "coelin" blue, 48.4 x 60.2 m and 22.2 m to the crest of its low hipped
## copper roof (set back behind a roof terrace), the front to Hötorget
## (+Z, WSW) a colonnade of ten 18 m warm-grey granite columns with
## Corinthian capitals under a plain entablature, tall windows and
## granite-framed doors in the recess behind, the granite steps, and
## Carl Milles' Orpheus fountain (1936) at their foot: Orpheus with his
## lyre raised on a tall pedestal over the basin, the shades round him.
## The sides carry rows of windows over granite-framed shop fronts and
## side doors under copper canopies; the back to Sveavägen is closed but
## for seven tall windows.
## Sources: sv.wikipedia "Konserthuset, Stockholm" (48.42 x 60.2 m, 22.2 m
## to the roof crest, ten 18 m granite columns, coelin blue, copper
## roof); OSM way 18779818 (outline) and way 163989308 (the fountain).
const CH_TOP := 22.2
const CH_WALL := 20.6
const CH_X0 := -24.9
const CH_X1 := 25.4
const CH_Z0 := -30.5
const CH_Z1 := 28.3
const CH_RECESS := 26.8

static func concert_hall(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Render", LandmarkMaterials.pbr("render", "#5C7DB0", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#8FA3C2", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#9A958D", 2.5))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E9C88", 2.0, 0.55, 0.3))
	lm.use("Windows", LandmarkMaterials.glass("#1F262B"))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#4A5C4E", 2.0, 0.42, 0.6))
	lm.use("Water", LandmarkMaterials.glass("#3A5868"))
	var cx := (CH_X0 + CH_X1) * 0.5
	var lx := CH_X1 - CH_X0
	# Main block to the colonnade recess, the two corner pylons beside it.
	LandmarkFhUtil.blk(lm, "Render", cx, 0.0, (CH_Z0 + CH_RECESS) * 0.5, lx, CH_WALL, CH_RECESS - CH_Z0)
	for s in [-1.0, 1.0]:
		var px: float = (CH_X1 - 3.25) if s > 0.0 else (CH_X0 + 3.3)
		LandmarkFhUtil.blk(lm, "Render", px, 0.0, (CH_RECESS + CH_Z1) * 0.5, 6.5, CH_WALL, CH_Z1 - CH_RECESS)
	LandmarkFhUtil.blk(lm, "Granite", cx, 0.0, (CH_Z0 + CH_Z1) * 0.5, lx + 0.5, 0.8, CH_Z1 - CH_Z0 + 0.5)
	LandmarkFhParts.box_band(lm, "Trim", cx, (CH_Z0 + CH_Z1) * 0.5, lx, CH_Z1 - CH_Z0, CH_WALL - 0.9, 0.5, 0.55)
	LandmarkFhParts.box_band(lm, "Granite", cx, (CH_Z0 + CH_Z1) * 0.5, lx, CH_Z1 - CH_Z0, 3.9, 0.45, 0.3)
	# Roof terrace with its copper coping, the set-back low hipped roof.
	LandmarkFhUtil.blk(lm, "Granite", cx, CH_WALL - 0.05, (CH_Z0 + CH_Z1) * 0.5, lx - 0.4, 0.2, CH_Z1 - CH_Z0 - 0.4)
	LandmarkFhParts.box_band(lm, "Copper", cx, (CH_Z0 + CH_Z1) * 0.5, lx, CH_Z1 - CH_Z0, CH_WALL - 0.1, 0.35, 0.15)
	LandmarkFhUtil.blk(lm, "Render", cx, CH_WALL - 0.4, -1.8, lx - 8.0, 0.6, 49.0)
	LandmarkFhUtil.hip(lm, "Copper", Vector3(cx, CH_WALL + 0.2, -1.8), lx - 8.6, 48.4, CH_TOP - CH_WALL - 0.2, 0.55)
	_ch_sides(lm, cx)
	_ch_colonnade(lm, cx)
	_ch_orpheus(lm, Vector3(cx, 0, 40.0))
	lm.commit(model)

## Side and back fronts: four rows of windows over the shop fronts on the
## sides, the side doors under copper canopies, the corner pylons' windows
## and the seven tall windows of the back.
static func _ch_sides(lm: LandmarkMesh, cx: float) -> void:
	for s in [-1.0, 1.0]:
		var x: float = CH_X1 if s > 0.0 else CH_X0
		var o := Vector3(s, 0, 0)
		LandmarkFhParts.pierce(lm, "Render", "Windows", Vector3(x, 0, CH_Z0), Vector3(x, 0, CH_Z1), o, 4.4,
			CH_WALL - 5.5, 13, 4, Vector2(1.4, 2.1), 1.0, 3.6, 0.35)
		for k in 12:
			if k == 6:
				continue
			var z := CH_Z0 + 2.4 + (CH_Z1 - CH_Z0 - 4.8) * (float(k) + 0.5) / 12.0
			var basis := Basis(Vector3.UP, s * PI * 0.5)
			lm.box("Windows", Vector3(x + s * 0.03, 2.2, z), Vector3(3.0, 2.6, 0.06), basis, 0.0)
			lm.box("Granite", Vector3(x + s * 0.1, 3.65, z), Vector3(3.5, 0.3, 0.2), basis, 0.0)
			for e in [-1.0, 1.0]:
				lm.box("Granite", Vector3(x + s * 0.1, 2.2, z + float(e) * 1.65), Vector3(0.25, 2.9, 0.2), basis, 0.0)
		# Side door and its baldachin canopy.
		var dz := CH_Z0 + 2.4 + (CH_Z1 - CH_Z0 - 4.8) * 6.5 / 12.0
		lm.box("Windows", Vector3(x + s * 0.03, 1.9, dz), Vector3(0.06, 3.0, 2.4), Basis(), 0.0)
		lm.box("Copper", Vector3(x + s * 1.1, 3.6, dz), Vector3(2.2, 0.25, 3.6))
		lm.lathe("Copper", Vector3(x + s * 1.1, 3.72, dz), PackedVector2Array([Vector2(2.4, 0), Vector2(1.8, 0.6),
			Vector2(0.0, 1.1)]), 4, 0.6, 0.85, PI * 0.25, false)
		for e in [-1.0, 1.0]:
			lm.beam("Copper", Vector3(x + s * 2.1, 3.6, dz + float(e) * 1.6), Vector3(x + s * 0.1, 2.8, dz + float(e) * 1.6),
				0.1, 0.1)
		# Corner pylon fronts beside the colonnade.
		var pc: float = (CH_X1 - 3.25) if s > 0.0 else (CH_X0 + 3.3)
		LandmarkFhParts.win_row(lm, "Trim", "Windows", Vector3(pc - 1.0, 0, CH_Z1), Vector3(pc + 1.0, 0, CH_Z1),
			Vector3(0, 0, 1), 1.0, 1, 1.4, 2.6)
		for row in 4:
			LandmarkFhParts.win_row(lm, "Trim", "Windows", Vector3(pc - 1.0, 0, CH_Z1), Vector3(pc + 1.0, 0, CH_Z1),
				Vector3(0, 0, 1), 5.4 + 3.6 * float(row), 1, 1.3, 2.0, false, 0.15)
	# The back to Sveavägen: seven tall windows.
	for k in 7:
		var x := cx - 15.0 + 5.0 * float(k)
		LandmarkDetail.window(lm, "Trim", "Windows", Vector3(x, 10.6, CH_Z0 - 0.02), Vector3(0, 0, -1), 1.8, 11.0, false, 0.25)

## The colonnade to Hötorget: ten granite Corinthian columns on the
## stylobate, the plain entablature over them, doors and tall windows in
## the recess behind, the steps down to the square.
static func _ch_colonnade(lm: LandmarkMesh, cx: float) -> void:
	var zc := 29.4
	var base_y := 1.2
	var col_h := 18.0
	var x0 := cx - 16.9
	var x1 := cx + 16.9
	lm.box("Granite", Vector3(cx, base_y * 0.5, (CH_RECESS + 30.6) * 0.5), Vector3(37.4, base_y, 30.6 - CH_RECESS))
	LandmarkFhUtil.steps(lm, "Granite", Vector3(cx, 0, 30.6), Vector3(0, 0, 1), 37.4, 0.45, 0.2, 6)
	for i in 10:
		var x := lerpf(x0, x1, float(i) / 9.0)
		LandmarkDetail.column(lm, "Granite", Vector3(x, base_y, zc), 0.78, col_h, "corinthian", 0, 14)
	var ey := base_y + col_h
	var ez := (CH_RECESS + 30.6) * 0.5
	lm.box("Granite", Vector3(cx, ey + 0.55, ez), Vector3(38.0, 1.1, 30.6 - CH_RECESS + 0.2))
	lm.box("Trim", Vector3(cx, CH_WALL - 0.45, ez), Vector3(38.4, 0.9, 30.6 - CH_RECESS + 0.6))
	lm.box("Copper", Vector3(cx, CH_WALL + 0.1, ez), Vector3(38.6, 0.2, 30.6 - CH_RECESS + 0.8))
	# The recess behind: granite-framed doors and tall windows in each bay,
	# the architect's inscription band on the plinth.
	var n := Vector3(0, 0, 1)
	for i in 9:
		var x := lerpf(x0, x1, (float(i) + 0.5) / 9.0)
		var z := CH_RECESS + 0.02
		lm.box("Windows", Vector3(x, base_y + 2.1, z), Vector3(2.0, 4.2, 0.06), Basis(), 0.0)
		for e in [-1.0, 1.0]:
			lm.box("Granite", Vector3(x + float(e) * 1.2, base_y + 2.2, z + 0.12), Vector3(0.4, 4.4, 0.25))
		lm.box("Granite", Vector3(x, base_y + 4.6, z + 0.14), Vector3(2.9, 0.5, 0.3))
		LandmarkDetail.window(lm, "Trim", "Windows", Vector3(x, 11.6, z), n, 1.6, 8.2, false, 0.2)
	lm.box("Trim", Vector3(cx, base_y + 6.6, CH_RECESS + 0.1), Vector3(37.0, 0.4, 0.2))

## Carl Milles' Orpheus group: a round granite basin with its water, the
## tall pedestal with Orpheus on top raising his lyre, eight shades on low
## plinths round it and the jets.
static func _ch_orpheus(lm: LandmarkMesh, c: Vector3) -> void:
	lm.frustum("Granite", c, 6.4, 6.2, 0.75, 24)
	lm.frustum("Water", c + Vector3(0, 0.75, 0), 5.8, 5.8, 0.02, 24)
	lm.frustum("Granite", c, 1.9, 1.7, 1.4, 12)
	lm.lathe("Granite", c + Vector3(0, 1.4, 0), PackedVector2Array([Vector2(1.2, 0), Vector2(1.0, 0.5),
		Vector2(0.85, 4.6), Vector2(1.05, 5.0), Vector2(1.1, 5.4)]), 12)
	var ob := c + Vector3(0, 6.8, 0)
	LandmarkKits.statue_figure(lm, "Bronze", ob, 3.6, true)
	lm.box("Bronze", ob + Vector3(0.5, 3.6, 0.1), Vector3(0.5, 0.7, 0.1))
	for k in 8:
		var a := TAU * (float(k) + 0.5) / 8.0
		var p := c + Vector3(cos(a), 0, sin(a)) * 3.8
		lm.frustum("Granite", p, 0.5, 0.45, 0.9, 8)
		LandmarkKits.statue_figure(lm, "Bronze", p + Vector3(0, 0.9, 0), 2.3, k % 3 == 0)
	for k in 6:
		var a := TAU * float(k) / 6.0
		var p := c + Vector3(cos(a), 0, sin(a)) * 5.0 + Vector3(0, 0.77, 0)
		lm.frustum("Water", p, 0.08, 0.03, 1.6, 6)

## Riksdag Building (Riksdagshuset, Aron Johansson, 1897-1905, rebuilt
## 1978-1983) on Helgeandsholmen. The east block (the parliament house of
## 1905, +Z toward Riksplan and Norrbro, ENE): a rusticated granite ground
## floor with arched windows, the colossal Corinthian order over two
## upper storeys, entablature, cornice and attic balustrade, the
## triumphal-arch centre with paired columns, the great arch, the granite
## coat of arms and the four estates on the attic; behind, the spine over
## the central hall with low copper roofs and the two octagonal halls of
## the old chambers under glass pyramids. Riksgatan runs through the
## complex between the blocks under the two vaulted gateways. The west
## block (the former Riksbank, 1906): the semicircular granite bank
## building with three rows of windows, the copper-clad two-storey
## addition of 1983 on top housing the hemicycle chamber with its glazed
## roof, and the west entrance with the two colossal granite lions.
## Sources: sv.wikipedia "Riksdagshuset i Stockholm" (colossal
## Corinthian order, triumphal-arch centre, the four estates, copper-clad
## addition, Riksgatan, granite lions; the planned dome was never built);
## OSM relation 34395 (outline 104 x 125 m, 35 m) and its building parts
## (east wings 28.5 m, spine 32-35 m, octagon halls 31 m, bank 24.5 m,
## chamber 30 m, gateways 16 and 18 m).
const RD_TOP := 35.0
const RD_X0 := -51.2
const RD_X1 := 52.2
const RD_Z0 := 2.6
const RD_Z1 := 60.6
const RD_WALL := 28.5
const RD_SPINE_X0 := -9.6
const RD_SPINE_X1 := 11.9

static func riksdag(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CBC3B3", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8E8983", 2.5))
	lm.use("Dressing", LandmarkMaterials.pbr("limestone", "#DAD3C4", 3.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E9C88", 2.0, 0.55, 0.3))
	lm.use("Windows", LandmarkMaterials.glass("#1E2528"))
	lm.use("Glass", LandmarkMaterials.glass("#3A4E58"))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#2C2A28", 2.0, 0.8))
	lm.use("Gilt", LandmarkMaterials.gold())
	_rd_east(lm)
	_rd_front(lm)
	_rd_centre(lm, (RD_SPINE_X0 + RD_SPINE_X1) * 0.5)
	_rd_gateways(lm)
	_rd_bank(lm)
	lm.commit(model)

## The east block's masses: the perimeter wings and the spine, the two
## octagonal halls under their glass pyramids, the flat copper roofs, the
## side and Riksgatan fronts with their windows.
static func _rd_east(lm: LandmarkMesh) -> void:
	var cz := (RD_Z0 + RD_Z1) * 0.5
	var cx := (RD_X0 + RD_X1) * 0.5
	# Wings round two courts: front, back, ends; the spine between.
	var wings := [[cx, 52.8, RD_X1 - RD_X0, 15.6], [cx, 9.0, RD_X1 - RD_X0, 12.8],
		[RD_X0 + 5.1, cz, 10.2, RD_Z1 - RD_Z0], [RD_X1 - 5.1, cz, 10.2, RD_Z1 - RD_Z0]]
	for w in wings:
		LandmarkFhUtil.blk(lm, "Stone", float(w[0]), 0.0, float(w[1]), float(w[2]), RD_WALL - 2.0, float(w[3]))
		LandmarkFhUtil.blk(lm, "Copper", float(w[0]), RD_WALL - 2.0, float(w[1]), float(w[2]) - 0.6, 0.4, float(w[3]) - 0.6)
	LandmarkFhUtil.blk(lm, "Stone", (RD_SPINE_X0 + RD_SPINE_X1) * 0.5, 0.0, (RD_Z0 + RD_Z1) * 0.5,
		RD_SPINE_X1 - RD_SPINE_X0, 32.0, RD_Z1 - RD_Z0)
	LandmarkFhUtil.blk(lm, "Granite", cx, 0.0, cz, RD_X1 - RD_X0 + 0.8, 8.5, RD_Z1 - RD_Z0 + 0.8)
	# Octagonal halls of the old chambers: drums in the courts, glass
	# pyramids ribbed in copper.
	for c in [Vector3(26.5, 0, 29.7), Vector3(-24.2, 0, 30.7)]:
		var hc: Vector3 = c
		LandmarkFhUtil.blk(lm, "Stone", hc.x, 0.0, hc.z, 29.0, 23.0, 29.0)
		LandmarkFhUtil.blk(lm, "Copper", hc.x, 23.0, hc.z, 28.8, 0.2, 28.8)
		lm.frustum("Stone", hc + Vector3(0, 23.0, 0), 15.4, 15.4, 0.6, 8, PI / 8.0)
		lm.frustum("Glass", hc + Vector3(0, 23.6, 0), 15.0, 0.9, 7.4, 8, PI / 8.0)
		for k in 8:
			var a := PI / 8.0 + PI * 0.25 * float(k)
			var d := Vector3(cos(a), 0, sin(a))
			lm.beam("Copper", hc + d * 15.05 + Vector3(0, 23.65, 0), hc + d * 0.95 + Vector3(0, 31.0, 0), 0.35, 0.25)
		lm.frustum("Copper", hc + Vector3(0, 30.6, 0), 1.0, 0.3, 0.5, 8, PI / 8.0)
	# Low copper roofs along the spine.
	var sx := (RD_SPINE_X0 + RD_SPINE_X1) * 0.5
	for r in [[9.8, 6.5, 3.2, 2.0], [28.8, 6.6, 6.4, 3.0], [42.1, 3.6, 4.0, 2.0]]:
		lm.lathe("Copper", Vector3(sx, 32.0, float(r[0])), LandmarkFhUtil.dome_prof(1.0, float(r[3]), 8), 20,
			float(r[1]), float(r[2]))
	lm.box("Copper", Vector3(sx, 32.15, cz), Vector3(RD_SPINE_X1 - RD_SPINE_X0 + 0.4, 0.3, RD_Z1 - RD_Z0 + 0.4))
	# Fronts to Riksgatan (back) and the two ends.
	LandmarkFhParts.pierce(lm, "Stone", "Windows", Vector3(RD_X1, 0, RD_Z0), Vector3(RD_X0, 0, RD_Z0), Vector3(0, 0, -1),
		8.5, RD_WALL - 10.5, 22, 4, Vector2(1.5, 2.4), 1.2, 4.4, 0.35)
	for s in [-1.0, 1.0]:
		var x: float = RD_X1 if s > 0.0 else RD_X0
		LandmarkFhParts.pierce(lm, "Stone", "Windows", Vector3(x, 0, RD_Z0), Vector3(x, 0, RD_Z1), Vector3(s, 0, 0),
			8.5, RD_WALL - 10.5, 12, 4, Vector2(1.5, 2.4), 1.2, 4.4, 0.35)
		LandmarkFhParts.win_row(lm, "Granite", "Windows", Vector3(x, 0, RD_Z0 + 2.0), Vector3(x, 0, RD_Z1 - 2.0),
			Vector3(s, 0, 0), 2.2, 10, 1.6, 3.6, true, 0.3)
	LandmarkFhParts.win_row(lm, "Granite", "Windows", Vector3(RD_X1 - 2.0, 0, RD_Z0), Vector3(RD_X0 + 2.0, 0, RD_Z0),
		Vector3(0, 0, -1), 2.2, 18, 1.6, 3.6, true, 0.3)
	LandmarkFhParts.box_band(lm, "Dressing", cx, cz, RD_X1 - RD_X0, RD_Z1 - RD_Z0, 8.5, 0.5, 0.55)
	LandmarkFhParts.box_band(lm, "Dressing", cx, cz, RD_X1 - RD_X0, RD_Z1 - RD_Z0, RD_WALL - 2.8, 0.8, 0.6)

## The front to Riksplan on both wings: rusticated granite ground floor
## with arched windows, the colossal Corinthian columns over two upper
## storeys with windows between, entablature, cornice and balustrade.
static func _rd_front(lm: LandmarkMesh) -> void:
	var n := Vector3(0, 0, 1)
	for wing in [[RD_X0, RD_SPINE_X0 + 0.3], [RD_SPINE_X1 - 0.0, RD_X1]]:
		var xa: float = wing[0]
		var xb: float = wing[1]
		var bays := 9
		var pitch := (xb - xa) / float(bays)
		# Rustication: courses of granite with shadow joints.
		for k in 6:
			lm.box("Granite", Vector3((xa + xb) * 0.5, 0.65 + 1.4 * float(k), RD_Z1 + 0.25), Vector3(xb - xa, 1.25, 0.5))
		for i in bays:
			var x := xa + pitch * (float(i) + 0.5)
			LandmarkDetail.window(lm, "Granite", "Windows", Vector3(x, 4.4, RD_Z1 + 0.5), n, 1.7, 4.2, true, 0.3)
			LandmarkDetail.window(lm, "Dressing", "Windows", Vector3(x, 12.4, RD_Z1 + 0.02), n, 1.7, 3.4, false, 0.25)
			LandmarkDetail.window(lm, "Dressing", "Windows", Vector3(x, 19.0, RD_Z1 + 0.02), n, 1.6, 2.8, false, 0.25)
		for i in bays + 1:
			var x := xa + pitch * float(i)
			LandmarkDetail.column(lm, "Dressing", Vector3(x, 8.5, RD_Z1 + 0.45), 0.7, 15.0, "corinthian", 0, 10)
		lm.box("Dressing", Vector3((xa + xb) * 0.5, 24.1, RD_Z1 + 0.6), Vector3(xb - xa, 1.2, 1.2))
		LandmarkDetail.cornice(lm, "Dressing", Vector3(xa, 24.7, RD_Z1 + 1.2), Vector3(xb, 24.7, RD_Z1 + 1.2), n, 1.0, true)
		LandmarkDetail.balustrade(lm, "Dressing", Vector3(xa, RD_WALL - 2.0, RD_Z1 - 0.3),
			Vector3(xb, RD_WALL - 2.0, RD_Z1 - 0.3), 1.2, pitch, 6)
		lm.box("Stone", Vector3((xa + xb) * 0.5, 25.2 + 0.5, RD_Z1 + 0.3), Vector3(xb - xa, 1.0, 0.6))

## The triumphal-arch centre: pedestals and paired free-standing
## Corinthian columns, the great arched entrance, the entablature, the
## tall attic with the granite coat of arms, and the four estates on top.
static func _rd_centre(lm: LandmarkMesh, cx: float) -> void:
	var zf := 62.6
	var w := RD_SPINE_X1 - RD_SPINE_X0
	var n := Vector3(0, 0, 1)
	LandmarkFhUtil.blk(lm, "Stone", cx, 0.0, (RD_Z1 + zf) * 0.5, w, 32.0, zf - RD_Z1)
	LandmarkFhUtil.blk(lm, "Granite", cx, 0.0, (RD_Z1 + zf) * 0.5, w + 0.6, 3.0, zf - RD_Z1 + 0.6)
	# The great arch: dark vault, archivolt and the doors.
	lm.box("Dark", Vector3(cx, 6.0, zf + 0.02), Vector3(7.0, 12.0, 0.06), Basis(), 0.0)
	LandmarkFhUtil.opening(lm, "Dark", Vector3(cx, 12.0, zf + 0.03), n, 7.0, 3.5, true)
	LandmarkDetail.arch(lm, "Dressing", Vector3(cx, 12.0, zf), n, 7.0, 0.9, 0.5)
	lm.box("Windows", Vector3(cx, 3.4, zf + 0.06), Vector3(4.0, 6.8, 0.06), Basis(), 0.0)
	LandmarkFhUtil.steps(lm, "Granite", Vector3(cx, 0, zf + 3.4), n, 14.0, 0.45, 0.2, 4)
	# Pedestals and paired columns, the entablature breaking forward.
	for x in [-8.4, -5.6, 5.6, 8.4]:
		var px := cx + float(x)
		lm.box("Granite", Vector3(px, 1.5, zf + 1.6), Vector3(2.4, 3.0, 2.6))
		LandmarkDetail.column(lm, "Dressing", Vector3(px, 3.0, zf + 1.6), 0.9, 18.0, "corinthian", 0, 14)
	for s in [-1.0, 1.0]:
		LandmarkDetail.window(lm, "Dressing", "Windows", Vector3(cx + s * 7.0, 15.0, zf + 0.02), n, 1.4, 3.0, false, 0.2)
	lm.box("Dressing", Vector3(cx, 22.0, zf + 1.4), Vector3(w + 1.0, 2.0, 2.8))
	LandmarkDetail.cornice(lm, "Dressing", Vector3(cx - w * 0.5 - 0.5, 23.0, zf + 2.8), Vector3(cx + w * 0.5 + 0.5, 23.0, zf + 2.8),
		n, 1.2, true)
	# Attic with the coat of arms in a frame; the four estates on top.
	lm.box("Stone", Vector3(cx, 27.9, zf + 0.4), Vector3(w - 1.0, 8.2, 0.8))
	lm.box("Granite", Vector3(cx, 27.6, zf + 0.9), Vector3(7.0, 5.6, 0.3))
	lm.lathe("Gilt", Vector3(cx, 25.6, zf + 1.05), PackedVector2Array([Vector2(0.0, 0), Vector2(1.4, 0.6),
		Vector2(1.6, 2.2), Vector2(1.5, 3.6), Vector2(0.0, 3.8)]), 8, 1.0, 0.1)
	for k in 3:
		var a := PI * 0.5 + (float(k) - 1.0) * 0.6
		lm.lathe("Gilt", Vector3(cx + cos(a) * 1.1, 29.9 + sin(a) * 0.3, zf + 1.15), PackedVector2Array([Vector2(0.45, 0),
			Vector2(0.55, 0.3), Vector2(0.0, 0.6)]), 6)
	lm.box("Dressing", Vector3(cx, 31.8, zf + 0.5), Vector3(w, 0.4, 1.0))
	for x in [-7.0, -2.4, 2.4, 7.0]:
		var p := Vector3(cx + float(x), 32.0, zf - 0.2)
		lm.box("Granite", p + Vector3(0, 0.25, 0), Vector3(1.4, 0.5, 1.4))
		LandmarkKits.statue_figure(lm, "Granite", p + Vector3(0, 0.5, 0), RD_TOP - 32.5 - 0.1)

## Riksgatan's two vaulted gateways: piers, the mass over the street and
## the arched vault openings on both faces.
static func _rd_gateways(lm: LandmarkMesh) -> void:
	for g in [[37.9, 7.6, 16.0], [-38.0, 6.2, 18.0]]:
		var gx: float = g[0]
		var gw: float = g[1]
		var gh: float = g[2]
		var z0 := -13.7
		var z1 := RD_Z0
		var span := 7.0
		var spring := 5.5
		var zc := (z0 + z1) * 0.5
		for s in [-1.0, 1.0]:
			var pz: float = zc + s * (span * 0.5 + ((z1 - z0) - span) * 0.25)
			LandmarkFhUtil.blk(lm, "Granite", gx, 0.0, pz, gw, spring, ((z1 - z0) - span) * 0.5)
		LandmarkFhUtil.blk(lm, "Stone", gx, spring, zc, gw, gh - spring, z1 - z0)
		LandmarkFhUtil.blk(lm, "Copper", gx, gh, zc, gw - 0.4, 0.3, z1 - z0 - 0.4)
		LandmarkFhParts.box_band(lm, "Dressing", gx, zc, gw, z1 - z0, gh - 1.2, 0.6, 0.3)
		for s in [-1.0, 1.0]:
			var fx: float = gx + s * gw * 0.5
			var o := Vector3(s, 0, 0)
			LandmarkFhUtil.opening(lm, "Dark", Vector3(fx + s * 0.02, spring, zc), o, span, span * 0.5, true)
			LandmarkDetail.arch(lm, "Granite", Vector3(fx, spring, zc), o, span, 0.7, 0.4)
			lm.box("Gilt", Vector3(fx + s * 0.25, spring + span * 0.5 + 1.6, zc), Vector3(0.1, 1.6, 1.3), Basis(), 0.0)
			LandmarkFhParts.win_row(lm, "Dressing", "Windows", Vector3(fx, 0, z1 - 2.0), Vector3(fx, 0, z0 + 2.0), o,
				spring + span * 0.5 + 3.6, 3, 1.3, 2.2)
		# The vault's soffit over the street.
		lm.quad("Dark", Vector3(gx - gw * 0.5, spring + 0.01, zc - span * 0.5),
			Vector3(gx + gw * 0.5, spring + 0.01, zc - span * 0.5), Vector3(gx + gw * 0.5, spring + 0.01, zc + span * 0.5),
			Vector3(gx - gw * 0.5, spring + 0.01, zc + span * 0.5), Vector3.DOWN)

## Half-ellipse outline (XZ) bulging toward -Z from the chord at z0,
## centre x cx, radii rx and rz, `n` segments.
static func _half_ellipse(cx: float, z0: float, rx: float, rz: float, n: int) -> PackedVector2Array:
	var p := PackedVector2Array()
	for k in n + 1:
		var a := PI * float(k) / float(n)
		p.append(Vector2(cx + cos(a) * rx, z0 - sin(a) * rz))
	return p

## The west block, the former Riksbank: the strip along Riksgatan, the
## semicircular bank building with rustication and three rows of windows,
## the copper-clad chamber addition with its glazed roof, and the west
## entrance with the two granite lions.
static func _rd_bank(lm: LandmarkMesh) -> void:
	# The strip along Riksgatan: lower ends, the taller centre.
	LandmarkFhUtil.blk(lm, "Stone", 0.5, 0.0, -19.8, 48.0, 26.5, 12.2)
	for s in [-1.0, 1.0]:
		LandmarkFhUtil.blk(lm, "Stone", 0.5 + s * 33.4, 0.0, -18.8, 18.8, 20.0, 10.2)
		LandmarkFhUtil.blk(lm, "Copper", 0.5 + s * 33.4, 20.0, -18.8, 18.4, 0.3, 9.8)
	LandmarkFhUtil.blk(lm, "Copper", 0.5, 26.5, -19.8, 47.6, 0.3, 11.8)
	LandmarkFhUtil.blk(lm, "Stone", 0.35, 0.0, -21.8, 34.7, 29.5, 7.4)
	LandmarkFhUtil.blk(lm, "Copper", 0.35, 29.5, -21.8, 34.3, 0.3, 7.0)
	LandmarkFhParts.pierce(lm, "Stone", "Windows", Vector3(-24.0, 0, -13.6), Vector3(24.0, 0, -13.6), Vector3(0, 0, 1),
		8.5, 17.0, 12, 4, Vector2(1.5, 2.4), 1.2, 4.2, 0.35)
	LandmarkFhParts.win_row(lm, "Granite", "Windows", Vector3(-24.0, 0, -13.6), Vector3(24.0, 0, -13.6), Vector3(0, 0, 1),
		2.2, 10, 1.6, 3.6, true, 0.3)
	# The semicircular bank building on its granite ground floor.
	var bank := _half_ellipse(1.3, -24.5, 40.4, 30.9, 18)
	lm.poly_prism("Stone", bank, 0.0, 24.5)
	var plinth := _half_ellipse(1.3, -24.5, 40.8, 31.3, 18)
	lm.poly_prism("Granite", plinth, 0.0, 8.0)
	var band := _half_ellipse(1.3, -24.5, 40.9, 31.4, 18)
	lm.poly_prism("Dressing", band, 22.9, 23.7, false)
	lm.poly_prism("Dressing", band, 7.9, 8.4, false)
	for i in bank.size() - 1:
		var a := Vector3(bank[i].x, 0, bank[i].y)
		var b := Vector3(bank[i + 1].x, 0, bank[i + 1].y)
		var o := LandmarkFhParts.edge_out(bank, i)
		if o.z > 0.2:
			continue
		var nw := maxi(int(a.distance_to(b) / 3.0), 1)
		LandmarkFhParts.win_row(lm, "Granite", "Windows", a + o * 0.4, b + o * 0.4, o, 2.0, nw, 1.6, 3.8, true, 0.3)
		LandmarkFhParts.win_row(lm, "Dressing", "Windows", a, b, o, 10.4, nw, 1.6, 3.2)
		LandmarkFhParts.win_row(lm, "Dressing", "Windows", a, b, o, 16.4, nw, 1.5, 3.0)
	# The copper-clad chamber addition with its ribbon of windows and the
	# glazed roof over the hemicycle.
	var cham := _half_ellipse(2.15, -24.6, 31.9, 23.8, 18)
	lm.poly_prism("Copper", cham, 24.5, 27.6)
	var ribbon := _half_ellipse(2.15, -24.6, 31.95, 23.85, 18)
	lm.poly_prism("Windows", ribbon, 25.3, 26.6, false)
	var cen := Vector2(2.15, -27.0)
	LandmarkFhParts.slope_roof(lm, "Copper", cham, cen, 0.62, 27.6, 29.3)
	var glaze := PackedVector2Array()
	for p in cham:
		glaze.append(cen + (p - cen) * 0.62)
	LandmarkFhParts.slope_roof(lm, "Glass", glaze, cen, 0.2, 29.3, 30.0)
	for i in glaze.size():
		if i % 3 != 0:
			continue
		var g := glaze[i]
		var gc := cen + (g - cen) * 0.2
		lm.beam("Copper", Vector3(g.x, 29.32, g.y), Vector3(gc.x, 30.02, gc.y), 0.25, 0.15)
	# West entrance and the two colossal granite lions.
	LandmarkFhUtil.blk(lm, "Granite", 0.65, 0.0, -58.4, 16.1, 14.0, 8.6)
	LandmarkFhUtil.hip(lm, "Copper", Vector3(0.65, 14.0, -58.4), 16.5, 9.0, 4.5, 0.35)
	var wn := Vector3(0, 0, -1)
	lm.box("Windows", Vector3(0.65, 3.2, -62.72), Vector3(3.6, 6.4, 0.06), Basis(), 0.0)
	LandmarkDetail.arch(lm, "Dressing", Vector3(0.65, 6.4, -62.7), wn, 3.6, 0.6, 0.4)
	for s in [-1.0, 1.0]:
		LandmarkDetail.column(lm, "Dressing", Vector3(0.65 + s * 3.6, 0.0, -63.3), 0.5, 10.5, "tuscan", 0, 12)
		_lion(lm, Vector3(0.65 + s * 10.0, 0, -64.5), wn)
	lm.box("Dressing", Vector3(0.65, 11.0, -63.1), Vector3(9.6, 1.0, 1.4))

## A colossal recumbent granite lion on its plinth, facing `out`.
static func _lion(lm: LandmarkMesh, base: Vector3, out: Vector3) -> void:
	var basis := Basis(Vector3.UP.cross(out).normalized(), Vector3.UP, out)
	lm.box("Granite", base + Vector3(0, 0.8, 0), Vector3(2.6, 1.6, 5.0), basis)
	lm.lathe("Granite", base + Vector3(0, 1.6, 0) - out * 0.6, PackedVector2Array([Vector2(0.9, 0), Vector2(1.1, 0.6),
		Vector2(0.9, 1.4), Vector2(0.0, 1.7)]), 10, 1.0, 1.9)
	var head := base + out * 1.6 + Vector3(0, 2.4, 0)
	lm.lathe("Granite", head - Vector3(0, 0.8, 0), LandmarkFhUtil.ball(0.85), 10)
	lm.lathe("Granite", head - Vector3(0, 1.2, 0) + out * 0.3, PackedVector2Array([Vector2(0.0, 0), Vector2(1.15, 0.3),
		Vector2(1.2, 1.0), Vector2(0.9, 1.6), Vector2(0.0, 1.9)]), 10)
	for s in [-1.0, 1.0]:
		lm.box("Granite", base + basis.x * (0.6 * float(s)) + out * 2.4 + Vector3(0, 0.3, 0), Vector3(0.6, 0.6, 1.4), basis)
