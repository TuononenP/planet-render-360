class_name LandmarkIbJeronimos
extends RefCounted

## The Jeronimos Monastery of Belem in true metres, the 300 m south front
## toward +Z with +X along it to the east (bearing about 75 degrees once
## the registry yaw_deg turns it).

const JER_TOP := 56.0
const CH_X0 := 64.0
const CH_X1 := 148.0
const CH_EAVE := 26.0

## The Manueline monastery (Boitaca, Joao de Castilho, 1501-1601), origin
## at the middle of its 300 m front of gold Lioz limestone: at the east
## end the church of Santa Maria, a hall church about 19 m wide inside,
## its south wall of buttresses with pinnacles and tall round-arched
## windows under a pierced crest, the 32 x 12 m south portal (two
## storeys of niches with saints round the trumeau figure of Henry the
## Navigator, archivolts and a canopied spire), the slightly projecting
## transept and the chancel; the bell tower at its north-west corner
## with the octagonal belfry and the mitre roof of 1867-68 (56 m); north
## of the church the two-storey 55 x 55 m cloister of arcades; and west
## of it the 193 m two-storey conventual wing (rebuilt in the 19th
## century, now the Archaeology and Navy museums) with its central
## pavilion and the domed end pavilion.
static func jeronimos(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Lioz", LandmarkMaterials.pbr("limestone", "#D9CCA8", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#EADFC3", 2.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#7B7F7E", 3.0))
	lm.use("Dome", LandmarkMaterials.paint("#6E9283", 0.5, 0.3))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3B3329", 3.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#BFB6A3", 4.0))
	lm.use("Glass", LandmarkMaterials.glass())
	lm.box("Paving", Vector3(0, 0.15, 56.0), Vector3(296.0, 0.3, 32.0))
	_church(lm)
	_portal(lm, Vector3(90.0, 0, 40.0))
	_tower(lm, Vector3(69.0, 0, 9.0))
	_wing(lm)
	_cloister(lm, Vector3(80.0, 0, -14.0))
	lm.commit(model)

## The church: hall under one roof, buttresses and pinnacles, windows,
## the crest, the transept and the chancel.
static func _church(lm: LandmarkMesh) -> void:
	var zn := Vector3(0, 0, 1)
	var cx := (CH_X0 + CH_X1 - 14.0) * 0.5
	var cl := CH_X1 - 14.0 - CH_X0
	lm.box("Lioz", Vector3(cx, CH_EAVE * 0.5, 27.0), Vector3(cl, CH_EAVE, 26.0))
	LandmarkCeParts.hip(lm, "Roof", Vector3(cx, CH_EAVE, 27.0), cl - 1.0, 25.0, 4.0)
	# Transept, a little proud of the walls, and the chancel.
	lm.box("Lioz", Vector3(118.0, CH_EAVE * 0.5, 27.0), Vector3(14.0, CH_EAVE, 30.0))
	lm.gable("Roof", Vector3(118.0, CH_EAVE, 27.0), 14.0, 30.0, 4.5, Basis(), 0.4, "Lioz")
	lm.box("Lioz", Vector3(CH_X1 - 7.0, 11.0, 27.0), Vector3(14.0, 22.0, 18.0))
	LandmarkCeParts.hip(lm, "Roof", Vector3(CH_X1 - 7.0, 22.0, 27.0), 14.0, 18.0, 3.0)
	for s in [-1.0, 1.0]:
		var sn := Vector3(0, 0, s)
		var fz: float = 27.0 + s * 13.0
		# The north wall rises over the cloister: no buttresses there.
		for i in (6 if s > 0.0 else 0):
			var bx := CH_X0 + 2.0 + 8.0 * float(i)
			if absf(bx - 90.0) < 7.0:
				continue
			LandmarkIbParts.buttress(lm, "Lioz", Vector3(bx, 0, fz), sn, 1.6, 2.2, 22.0)
			LandmarkCeParts.pinnacle(lm, "Trim", Vector3(bx, 22.0, fz + s * 0.6), 1.0, 7.0)
			if i < 5 and absf(bx + 4.0 - 90.0) > 7.0:
				LandmarkDetail.window(lm, "Trim", "Glass", Vector3(bx + 4.0, 15.0, fz), sn, 2.8, 9.0, true, 0.4)
				LandmarkIbParts.portal(lm, "Trim", "Shadow", Vector3(bx + 4.0, 3.0, fz), Vector3.UP.cross(sn), sn, 1.4, 3.6, 1, 0.2)
		_crest(lm, Vector3(CH_X0, CH_EAVE, fz + s * 0.3), Vector3(CH_X1 - 14.0, CH_EAVE, fz + s * 0.3))
		var tz: float = 27.0 + s * 15.0
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(118.0, 14.0, tz), sn, 3.4, 10.0, true, 0.4)
		LandmarkCeParts.pinnacle(lm, "Trim", Vector3(111.5, CH_EAVE, tz), 1.0, 6.0)
		LandmarkCeParts.pinnacle(lm, "Trim", Vector3(124.5, CH_EAVE, tz), 1.0, 6.0)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(CH_X1 - 7.0, 12.0, 27.0 + s * 9.0), sn, 2.4, 7.0, true)
	LandmarkDetail.window(lm, "Trim", "Glass", Vector3(CH_X1, 12.0, 27.0), Vector3(1, 0, 0), 2.6, 8.0, true)
	LandmarkIbParts.band(lm, "Trim", Vector3(cx, 0, 40.0), Vector3.RIGHT, zn, cl, 0.6, 1.2, 0.6)

## Manueline crest along a roof edge a..b: a pierced parapet of little
## arches between posts topped with spikes.
static func _crest(lm: LandmarkMesh, a: Vector3, b: Vector3) -> void:
	var d := b - a
	var n := int(d.length() / 1.6)
	var basis := Basis(Vector3.UP, atan2(d.x, d.z))
	lm.box("Trim", (a + b) * 0.5 + Vector3(0, 0.15, 0), Vector3(0.6, 0.3, d.length()), basis, 0.0)
	lm.box("Trim", (a + b) * 0.5 + Vector3(0, 1.25, 0), Vector3(0.5, 0.2, d.length()), basis, 0.0)
	for i in n + 1:
		var p := a.lerp(b, float(i) / float(n))
		lm.box("Trim", p + Vector3(0, 0.7, 0), Vector3(0.3, 1.1, 0.3), basis, 0.0)
		lm.spire("Trim", p + Vector3(0, 1.35, 0), 0.15, 0.9)

## The south portal at p (foot of the wall face): a 12 m frame of
## buttress-shafts with pinnacles, two tiers of canopied niches with
## saints, the double door round the trumeau figure under a tympanum,
## the archivolts and the central canopy spire to 32 m.
static func _portal(lm: LandmarkMesh, p: Vector3) -> void:
	var zn := Vector3(0, 0, 1)
	lm.box("Lioz", p + Vector3(0, 13.5, 0.6), Vector3(13.0, 27.0, 1.2))
	lm.box("Trim", p + Vector3(0, 12.0, 1.4), Vector3(10.0, 24.0, 0.4))
	# Double door, trumeau and figure, tympanum.
	for x in [-1.6, 1.6]:
		LandmarkIbParts.portal(lm, "Trim", "Shadow", p + Vector3(x, 0.3, 1.6), Vector3.RIGHT, zn, 2.6, 6.4, 1, 0.4)
	lm.box("Trim", p + Vector3(0, 3.0, 2.2), Vector3(0.8, 5.4, 0.8))
	LandmarkKits.statue_figure(lm, "Trim", p + Vector3(0, 5.8, 2.4), 2.0)
	lm.box("Trim", p + Vector3(0, 8.4, 2.1), Vector3(7.4, 0.6, 1.0))
	SEuUtil.opening(lm, "Shadow", p + Vector3(0, 8.7, 1.62), Vector3.RIGHT, Vector3.UP, 6.4, 3.4, true)
	for k in 3:
		var w := 7.0 + 1.0 * float(k)
		LandmarkIbParts.arch_ring(lm, "Trim", p + Vector3(0, 8.7, 1.7 + 0.15 * float(k)), zn, w, 0.4, 0.4, 11)
	# Niches with saints in two tiers either side and over the door.
	for sx in [-1.0, 1.0]:
		var nx := float(sx) * 3.6
		for tier in 3:
			var y := 10.6 + 4.6 * float(tier)
			LandmarkIbParts.portal(lm, "Trim", "Shadow", p + Vector3(nx, y, 1.6), Vector3.RIGHT, zn, 1.3, 3.2, 1, 0.3)
			LandmarkKits.statue_figure(lm, "Trim", p + Vector3(nx, y + 0.1, 1.9), 1.7)
			lm.spire("Trim", p + Vector3(nx, y + 3.6, 2.0), 0.6, 1.0)
	for tier in 2:
		var y := 13.0 + 5.0 * float(tier)
		LandmarkIbParts.portal(lm, "Trim", "Shadow", p + Vector3(0, y, 1.6), Vector3.RIGHT, zn, 1.6, 3.8, 1, 0.3)
		LandmarkKits.statue_figure(lm, "Trim", p + Vector3(0, y + 0.1, 1.9), 2.0)
	# Buttress-shafts with pinnacles, the canopy spire.
	for x in [-6.0, -5.0, 5.0, 6.0]:
		var xx: float = x
		var hh := 24.0 if absf(xx) > 5.5 else 21.0
		lm.box("Trim", p + Vector3(xx, hh * 0.5, 2.0), Vector3(0.7, hh, 1.0))
		LandmarkCeParts.pinnacle(lm, "Trim", p + Vector3(xx, hh, 2.0), 0.9, 5.0)
	lm.box("Lioz", p + Vector3(0, 23.5, 1.6), Vector3(8.0, 1.2, 3.0))
	LandmarkCeParts.wimperg(lm, "Trim", p + Vector3(0, 24.1, 2.2), zn, 6.0, 3.6)
	lm.box("Trim", p + Vector3(0, 26.0, 1.6), Vector3(1.6, 3.6, 1.6))
	lm.spire("Trim", p + Vector3(0, 27.8, 1.6), 0.9, 4.2, 0.0, 6)
	lm.box("Gilt", p + Vector3(0, 32.4, 1.6), Vector3(0.18, 0.9, 0.18))

## The bell tower at the church's north-west corner: square shaft,
## octagonal belfry with corner pinnacles, the mitre roof and the cross.
static func _tower(lm: LandmarkMesh, tw: Vector3) -> void:
	lm.box("Lioz", tw + Vector3(0, 19.0, 0), Vector3(9.6, 38.0, 9.6))
	lm.box("Trim", tw + Vector3(0, 38.4, 0), Vector3(10.6, 0.8, 10.6))
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		LandmarkDetail.window(lm, "Trim", "Glass", tw + out * 4.8 + Vector3(0, 30.0, 0), out, 1.4, 4.0, true)
		LandmarkIbParts.band(lm, "Trim", tw + out * 4.8, right, out, 9.8, 26.0, 0.4, 0.3)
		LandmarkCeParts.pinnacle(lm, "Trim", tw + (out + right) * 4.6 + Vector3(0, 38.8, 0), 0.9, 4.6)
	lm.frustum("Lioz", tw + Vector3(0, 38.8, 0), 4.6, 4.4, 9.0, 8, PI / 8.0)
	SEuUtil.ring_openings(lm, "Shadow", tw + Vector3(0, 38.8, 0), 4.6, 8, 8, 1.8, 1.4, 5.4, false)
	for i in 8:
		var a := TAU * float(i) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Trim", tw + d * 4.6 + Vector3(0, 43.3, 0), Vector3(0.5, 9.0, 0.5), Basis.looking_at(d))
	lm.frustum("Trim", tw + Vector3(0, 47.8, 0), 5.0, 4.8, 0.8, 8, PI / 8.0)
	lm.lathe("Roof", tw + Vector3(0, 48.6, 0), PackedVector2Array([Vector2(4.8, 0), Vector2(4.4, 2.0),
		Vector2(3.0, 4.0), Vector2(1.6, 5.4), Vector2(0.6, 6.4), Vector2(0.0, 7.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	for i in 8:
		var a := PI / 8.0 + TAU * float(i) / 8.0
		lm.beam("Trim", tw + Vector3(cos(a) * 4.5, 48.6, sin(a) * 4.5), tw + Vector3(cos(a) * 0.5, 55.0, sin(a) * 0.5), 0.25, 0.2)
	LandmarkCeParts.cross(lm, "Gilt", tw + Vector3(0, 55.0, 0), JER_TOP - 55.0)

## The conventual wing west of the church: two storeys of framed windows
## between buttresses under a crest, the central pavilion and the end
## pavilion with its green dome.
static func _wing(lm: LandmarkMesh) -> void:
	var zn := Vector3(0, 0, 1)
	var x0 := -129.0
	var x1 := CH_X0
	var cx := (x0 + x1) * 0.5
	var length := x1 - x0
	lm.box("Lioz", Vector3(cx, 9.5, 29.0), Vector3(length, 19.0, 22.0))
	LandmarkCeParts.hip(lm, "Roof", Vector3(cx, 19.0, 29.0), length - 2.0, 21.0, 3.8)
	var f := Vector3(cx, 0, 40.0)
	LandmarkIbParts.band(lm, "Trim", f, Vector3.RIGHT, zn, length + 1.0, 0.6, 1.2, 0.5)
	LandmarkIbParts.band(lm, "Trim", f, Vector3.RIGHT, zn, length + 1.0, 10.2, 0.6, 0.4)
	LandmarkIbParts.band(lm, "Trim", f, Vector3.RIGHT, zn, length + 1.0, 18.6, 1.0, 0.6)
	_crest(lm, Vector3(x0, 19.1, 40.3), Vector3(x1, 19.1, 40.3))
	var bays := 35
	var pitch := length / float(bays)
	for i in bays:
		var x := x0 + pitch * (float(i) + 0.5)
		if absf(x + 33.0) < 8.0:
			continue
		LandmarkIbParts.portal(lm, "Trim", "Glass", Vector3(x, 2.4, 40.0), Vector3.RIGHT, zn, 2.0, 5.0, 1, 0.3)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, 14.0, 40.0), zn, 2.0, 4.2, true)
		if i % 5 == 0:
			LandmarkIbParts.buttress(lm, "Lioz", Vector3(x - pitch * 0.5, 0, 40.0), zn, 1.0, 1.0, 18.0)
	# Central pavilion: a taller block with a portal and a hipped roof.
	var pc := Vector3(-33.0, 0, 30.5)
	lm.box("Lioz", pc + Vector3(0, 12.5, 0), Vector3(16.0, 25.0, 23.0))
	LandmarkCeParts.hip(lm, "Roof", pc + Vector3(0, 25.0, 0), 16.6, 23.6, 5.0)
	LandmarkIbParts.portal(lm, "Trim", "Shadow", pc + Vector3(0, 0.3, 11.5), Vector3.RIGHT, zn, 4.0, 7.0, 1, 0.6)
	LandmarkDetail.window(lm, "Trim", "Glass", pc + Vector3(0, 15.0, 11.5), zn, 3.0, 6.0, true)
	for s in [-1.0, 1.0]:
		LandmarkCeParts.pinnacle(lm, "Trim", pc + Vector3(float(s) * 7.6, 25.0, 11.5), 1.2, 6.0)
		LandmarkDetail.window(lm, "Trim", "Glass", pc + Vector3(float(s) * 4.8, 15.0, 11.5), zn, 1.8, 4.6, true)
		LandmarkIbParts.portal(lm, "Trim", "Glass", pc + Vector3(float(s) * 4.8, 2.4, 11.5), Vector3.RIGHT, zn, 1.8, 4.6, 1, 0.3)
	_crest(lm, pc + Vector3(-8.0, 25.1, 11.8), pc + Vector3(8.0, 25.1, 11.8))
	# End pavilion (west) with its green dome.
	var ep := Vector3(-137.0, 0, 30.0)
	lm.box("Lioz", ep + Vector3(0, 11.0, 0), Vector3(16.0, 22.0, 24.0))
	LandmarkCeParts.hip(lm, "Roof", ep + Vector3(0, 22.0, 0), 16.0, 24.0, 3.0)
	lm.box("Lioz", ep + Vector3(-4.0, 13.0, 0), Vector3(12.0, 26.0, 12.0))
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		LandmarkDetail.window(lm, "Trim", "Glass", ep + Vector3(-4.0, 0, 0) + out * 6.0 + Vector3(0, 17.0, 0), out, 1.8, 4.6, true)
		LandmarkCeParts.pinnacle(lm, "Trim", ep + Vector3(-4.0, 0, 0) + (out + r * Vector3(1, 0, 0)) * 5.6 + Vector3(0, 26.0, 0), 0.9, 4.0)
	for i in 3:
		LandmarkDetail.window(lm, "Trim", "Glass", ep + Vector3(-5.0 + 5.0 * float(i), 14.0, 12.0), zn, 1.8, 4.2, true)
		LandmarkIbParts.portal(lm, "Trim", "Glass", ep + Vector3(-5.0 + 5.0 * float(i), 2.4, 12.0), Vector3.RIGHT, zn, 1.8, 4.6, 1, 0.3)
	var dc := ep + Vector3(-4.0, 26.0, 0)
	lm.frustum("Lioz", dc, 5.0, 5.0, 5.0, 16)
	LandmarkCeParts.arched_ring(lm, "Trim", "Glass", dc + Vector3(0, 1.0, 0), 5.0, 8, 1.2, 2.8)
	lm.lathe("Dome", dc + Vector3(0, 5.0, 0), SEuUtil.dome(5.2, 5.0, 8), 16)
	lm.frustum("Trim", dc + Vector3(0, 9.8, 0), 0.8, 0.7, 1.2, 8)
	lm.box("Gilt", dc + Vector3(0, 11.6, 0), Vector3(0.22, 1.8, 0.22))

## The two-storey cloister: ranges round a court, the lower arcade of
## wide arches between buttress-piers with tracery mullions, the upper
## arcade set back behind a balustrade, chamfered corners.
static func _cloister(lm: LandmarkMesh, c: Vector3) -> void:
	LandmarkIbUtil.ring_walls(lm, "Lioz", c, 27.5, 27.5, 7.0, 0.0, 15.0)
	lm.box("Paving", c + Vector3(0, 0.15, 0), Vector3(41.0, 0.3, 41.0))
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		var inner := c + out * 20.5
		for i in 7:
			var s := (float(i) - 3.0) * 6.0
			LandmarkIbParts.buttress(lm, "Lioz", inner + right * s, -out, 1.2, 1.4, 7.6)
			LandmarkCeParts.pinnacle(lm, "Trim", inner + right * s - out * 0.5 + Vector3(0, 7.6, 0), 0.6, 2.4)
		for i in 6:
			var s := (float(i) - 2.5) * 6.0
			SEuUtil.opening(lm, "Shadow", inner + right * s - out * 0.03 + Vector3(0, 0.3, 0), -right, Vector3.UP, 4.4, 6.0)
			LandmarkIbParts.arch_ring(lm, "Trim", inner + right * s - out * 0.2 + Vector3(0, 4.1, 0), -out, 4.4, 0.4, 0.5, 9)
			LandmarkIbParts.post(lm, "Trim", inner + right * s - out * 0.25 + Vector3(0, 0.3, 0), 0.18, 5.4, 6)
			SEuUtil.opening(lm, "Shadow", inner + right * s - out * 0.03 + Vector3(0, 8.6, 0), -right, Vector3.UP, 3.6, 4.6)
			LandmarkIbParts.arch_ring(lm, "Trim", inner + right * s - out * 0.2 + Vector3(0, 11.4, 0), -out, 3.6, 0.3, 0.4, 7)
		LandmarkIbParts.rail(lm, "Trim", inner - right * 18.0 - out * 0.8 + Vector3(0, 8.0, 0),
			inner + right * 18.0 - out * 0.8 + Vector3(0, 8.0, 0), 1.0, 6.0)
		LandmarkIbParts.band(lm, "Trim", inner, right, -out, 41.0, 7.8, 0.4, 1.4)
		_crest(lm, inner - right * 20.0 - out * 0.3 + Vector3(0, 15.0, 0), inner + right * 20.0 - out * 0.3 + Vector3(0, 15.0, 0))
		lm.box("Lioz", c + (out + right) * 19.0 + Vector3(0, 7.5, 0), Vector3(4.0, 15.0, 4.0), Basis(Vector3.UP, PI * 0.25))
