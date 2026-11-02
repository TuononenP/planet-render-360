class_name LandmarkEgNile
extends RefCounted

## Three Ptolemaic and Roman temples of the upper Nile in true metres,
## entrance toward +Z and sanctuary toward -Z (registry yaw_deg turns
## them onto the real axis): Philae (Isis, relocated to Agilkia), Edfu
## (Horus) and Kom Ombo (Sobek and Haroeris).

# --- Philae ---

## Temple of Isis on Agilkia Island: the outer court approached past the
## Kiosk of Nectanebo between the long west colonnade (32 columns, each
## capital different) and the unfinished east colonnade (16), the 45 m
## first pylon (18 m) with its two granite lions, the forecourt with the
## birth house (mammisi, ringed by Hathor-headed columns) west and the
## east colonnade, the 32 m second pylon, the long roofed temple behind
## its pronaos, Hadrian's gate and, 72 m east, the unroofed Kiosk of
## Trajan. Origin at the centre of the temple.
static func philae(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Sand", LandmarkMaterials.pbr("stone", "#CDB083", 3.2))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A2E22", 2.0))
	lm.use("Ground", LandmarkMaterials.pbr("sand", "#D2BA8A", 8.0))
	lm.box("Ground", Vector3(14.0, 0.1, 50.0), Vector3(130.0, 0.2, 156.0), Basis(), 0.0)
	_outer_court(lm)
	LandmarkEgParts.pylon(lm, "Sand", "Dark", Vector3(0, 0, 48.0), 45.0, 18.0, 9.0, 7.0)
	LandmarkEgParts.pylon(lm, "Sand", "Dark", Vector3(0, 0, 24.0), 32.0, 12.5, 6.0, 5.0)
	# The temple proper: pronaos front, roofed body, cavetto cornice.
	lm.box("Sand", Vector3(0, 4.75, 0), Vector3(27.0, 9.5, 38.0))
	LandmarkEgParts.cavetto(lm, "Sand", Vector3(0, 9.5, 0), 27.0, 38.0, 1.3, 1.0)
	for s in [-1.0, 1.0]:
		for k in 6:
			lm.box("Dark", Vector3(s * 13.55, 6.5, -14.0 + 5.6 * float(k)), Vector3(0.1, 0.6, 1.4), Basis(), 0.0)
	lm.box("Dark", Vector3(0, 3.0, 19.2), Vector3(3.0, 6.0, 0.4))
	for x in [-8.0, -4.5, 4.5, 8.0]:
		LandmarkEgParts.column(lm, "Sand", Vector3(x, 0, 21.0), 0.6, 8.2, LandmarkEgParts.OPEN)
	lm.box("Sand", Vector3(0, 8.8, 21.0), Vector3(20.0, 1.0, 2.6))
	# Mammisi (birth house) west of the forecourt, east colonnade opposite.
	lm.box("Sand", Vector3(-26.0, 4.0, 36.0), Vector3(9.0, 8.0, 18.0))
	LandmarkEgParts.cavetto(lm, "Sand", Vector3(-26.0, 8.0, 36.0), 13.0, 22.0, 1.0, 0.8)
	# Its ambulatory of Hathor columns joined by half-height screen walls.
	for p in [[-19.2, 44.0, -19.2, 28.0, 5], [-32.8, 44.0, -32.8, 28.0, 5], [-29.6, 46.2, -22.4, 46.2, 3]]:
		var pa := Vector3(float(p[0]), 0, float(p[1]))
		var pb := Vector3(float(p[2]), 0, float(p[3]))
		var n: int = p[4]
		for k in n:
			_hathor_column(lm, pa.lerp(pb, float(k) / float(n - 1)), 0.5, 7.0)
		for k in n - 1:
			var sc := pa.lerp(pb, (float(k) + 0.5) / float(n - 1))
			var sz := Vector3(0.6, 3.2, 0.6) + (pb - pa).abs().normalized() * (pa.distance_to(pb) / float(n - 1) - 1.2)
			lm.box("Sand", sc + Vector3(0, 1.6, 0), sz)
		lm.box("Sand", (pa + pb) * 0.5 + Vector3(0, 7.5, 0), (pb - pa).abs() + Vector3(1.4, 1.0, 1.4))
	LandmarkEgParts.colonnade(lm, "Sand", Vector3(17.0, 0, 44.0), Vector3(17.0, 0, 28.0), 7, 0.55,
		6.6, LandmarkEgParts.OPEN)
	lm.box("Sand", Vector3(17.0, 7.1, 36.0), Vector3(3.0, 0.9, 19.0))
	LandmarkEgParts.wall(lm, "Sand", Vector2(21.0, 45.0), Vector2(21.0, 27.0), 7.2, 1.4)
	# Gate of Hadrian, west of the temple.
	for s in [-1.0, 1.0]:
		lm.box("Sand", Vector3(-23.0 + s * 2.5, 3.5, -1.0), Vector3(1.6, 7.0, 3.6))
	lm.box("Sand", Vector3(-23.0, 7.4, -1.0), Vector3(6.6, 1.2, 4.0))
	_kiosk(lm, Vector3(72.0, 0, 30.0))
	lm.commit(model)

## The outer court south of the first pylon: the Kiosk of Nectanebo at
## its far end, the west colonnade of 32 columns in front of a windowed
## back wall and the shorter, unfinished east colonnade of 16, both under
## architraves; the two granite lions guarding the pylon gate.
static func _outer_court(lm: LandmarkMesh) -> void:
	for p in [[-15.0, 32, 118.0, -18.0], [14.0, 16, 86.0, 17.0]]:
		var x: float = p[0]
		var n: int = p[1]
		var z1: float = p[2]
		var wx: float = p[3]
		LandmarkEgParts.colonnade(lm, "Sand", Vector3(x, 0, 55.0), Vector3(x, 0, z1), n, 0.55, 6.4,
			LandmarkEgParts.OPEN, 10)
		lm.beam("Sand", Vector3(x, 6.85, 54.0), Vector3(x, 6.85, z1 + 1.0), 1.0, 1.2, Vector3.UP, true)
		LandmarkEgParts.temple_wall(lm, "Sand", Vector2(wx, 54.0), Vector2(wx, z1 + 1.0), 7.4, 1.0)
		lm.box("Sand", Vector3((x + wx) * 0.5, 7.2, (55.0 + z1) * 0.5), Vector3(absf(wx - x) + 1.0, 0.5,
			z1 - 54.0))
		if n == 32:
			for k in 15:
				lm.box("Dark", Vector3(wx + 0.52, 5.4, 58.0 + 4.0 * float(k)), Vector3(0.1, 0.8, 0.6), Basis(), 0.0)
	# Kiosk of Nectanebo I: Hathor columns joined by screen walls.
	var kc := Vector3(0, 0, 126.0)
	lm.box("Sand", kc + Vector3(0, 0.4, 0), Vector3(10.0, 0.8, 8.0))
	for x in [-4.0, 4.0]:
		for z in [-3.0, 0.0, 3.0]:
			_hathor_column(lm, kc + Vector3(x, 0.8, z), 0.4, 5.4)
	for z in [-3.0, 3.0]:
		_hathor_column(lm, kc + Vector3(0, 0.8, z), 0.4, 5.4)
	for z in [-1.5, 1.5]:
		for x in [-4.0, 4.0]:
			lm.box("Sand", kc + Vector3(x, 2.3, z), Vector3(0.5, 3.0, 2.4))
	# Granite lions couchant before the first pylon.
	for s in [-1.0, 1.0]:
		lm.box("Sand", Vector3(s * 5.0, 0.5, 56.0), Vector3(1.6, 1.0, 3.4))
		LandmarkEgParts.sphinx(lm, "Dark", Vector3(s * 5.0, 1.0, 56.0), 3.0)

## Hathor column: a round shaft carrying a four-faced block capital
## (the goddess's face and cow ears on each side) under a sistrum-shaped
## naos block.
static func _hathor_column(lm: LandmarkMesh, base: Vector3, r: float, h: float) -> void:
	lm.frustum("Sand", base, r * 1.35, r * 1.3, r * 0.3, 10)
	lm.lathe("Sand", base + Vector3(0, r * 0.3, 0), PackedVector2Array([Vector2(r, 0),
		Vector2(r * 0.9, h * 0.66)]), 10, 1.0, 1.0, 0.0, true, false)
	var cb := base + Vector3(0, r * 0.3 + h * 0.66, 0)
	var ch := h - r * 0.3 - h * 0.66
	lm.box("Sand", cb + Vector3(0, ch * 0.32, 0), Vector3(r * 2.2, ch * 0.64, r * 2.2))
	for k in 4:
		var d := Vector3(cos(PI * 0.5 * k), 0, sin(PI * 0.5 * k))
		lm.lathe("Sand", cb + d * r * 1.1 + Vector3(0, ch * 0.1, 0), PackedVector2Array([Vector2(r * 0.5, 0),
			Vector2(r * 0.55, ch * 0.25), Vector2(r * 0.4, ch * 0.5)]), 6, 1.0, 0.4)
	lm.box("Sand", cb + Vector3(0, ch * 0.82, 0), Vector3(r * 1.6, ch * 0.36, r * 1.6))

## Kiosk of Trajan: a 16 x 21 m platform ringed by 14 open-papyrus
## columns (4 per end, 3 along each side) joined by half-height screen
## walls, never roofed.
static func _kiosk(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Sand", c + Vector3(0, 0.8, 0), Vector3(16.0, 1.6, 21.0))
	var spots: Array[Vector2] = []
	for x in [-6.0, -2.0, 2.0, 6.0]:
		spots.append(Vector2(x, -9.0))
		spots.append(Vector2(x, 9.0))
	for z in [-4.5, 0.0, 4.5]:
		spots.append(Vector2(-6.0, z))
		spots.append(Vector2(6.0, z))
	for p in spots:
		LandmarkEgParts.column(lm, "Sand", c + Vector3(p.x, 1.6, p.y), 0.62, 10.2,
			LandmarkEgParts.OPEN)
		lm.box("Sand", c + Vector3(p.x, 12.7, p.y), Vector3(2.0, 1.8, 2.0))
	for x in [-4.0, 0.0, 4.0]:
		for z in [-9.0, 9.0]:
			lm.box("Sand", c + Vector3(x, 4.0, z), Vector3(2.9, 4.8, 0.9))
	for z in [-6.75, -2.25, 2.25, 6.75]:
		for x in [-6.0, 6.0]:
			lm.box("Sand", c + Vector3(x, 4.0, z), Vector3(0.9, 4.8, 3.0))
	for z in [-9.0, 9.0]:
		lm.beam("Sand", c + Vector3(-6.0, 13.0, z), c + Vector3(6.0, 13.0, z), 1.2, 1.8, Vector3.UP, true)
	for x in [-6.0, 6.0]:
		lm.beam("Sand", c + Vector3(x, 13.0, -9.0), c + Vector3(x, 13.0, 9.0), 1.2, 1.8, Vector3.UP, true)

# --- Temple of Horus at Edfu ---

## The best preserved Egyptian temple: the 64 m pylon of 36 m with its
## two granite Horus falcons at the gate, the Court of Offerings ringed
## on three sides by 32 columns with composite capitals, the pronaos
## facade of six columns joined by screen walls with the crowned granite
## falcon by its door, the roofed halls stepping down in three stages,
## and the 12 m enclosure wall round all with its ambulatory, 137 m end
## to end; the mammisi with its Bes pillars in front of the pylon, west.
## Origin at the centre of the roofed temple.
static func edfu(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Sand", LandmarkMaterials.pbr("stone", "#CFB487", 3.4))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A2E22", 2.0))
	lm.use("Falcon", LandmarkMaterials.pbr("stone", "#2E2926", 2.0))
	lm.use("Ground", LandmarkMaterials.pbr("sand", "#D6BE8C", 8.0))
	lm.box("Ground", Vector3(0, 0.1, 40.0), Vector3(90.0, 0.2, 180.0), Basis(), 0.0)
	LandmarkEgParts.pylon(lm, "Sand", "Dark", Vector3(0, 0, 84.0), 64.0, 36.0, 12.0, 10.0)
	for s in [-1.0, 1.0]:
		_falcon(lm, Vector3(s * 7.5, 0, 92.5), 4.6)
	# Court of Offerings: 12 columns down each side and 8 against the pylon.
	for s in [-1.0, 1.0]:
		LandmarkEgParts.colonnade(lm, "Sand", Vector3(s * 27.0, 0, 74.0), Vector3(s * 27.0, 0, 40.0),
			12, 0.8, 9.0, LandmarkEgParts.OPEN, 12)
		lm.box("Sand", Vector3(s * 31.5, 9.5, 57.0), Vector3(9.0, 1.0, 40.0))
		LandmarkEgParts.temple_wall(lm, "Sand", Vector2(s * 35.5, 78.0), Vector2(s * 35.5, -40.0), 12.0, 3.0)
		LandmarkEgParts.colonnade(lm, "Sand", Vector3(s * 7.5, 0, 74.0), Vector3(s * 22.5, 0, 74.0), 4, 0.8,
			9.0, LandmarkEgParts.OPEN, 12)
		lm.box("Sand", Vector3(s * 17.0, 9.5, 75.5), Vector3(23.0, 1.0, 5.0))
	LandmarkEgParts.temple_wall(lm, "Sand", Vector2(-35.5, -40.0), Vector2(35.5, -40.0), 12.0, 3.0)
	# Roofed temple in three descending stages, each under a cavetto cornice.
	lm.box("Sand", Vector3(0, 6.0, 24.0), Vector3(38.0, 12.0, 24.0))
	LandmarkEgParts.cavetto(lm, "Sand", Vector3(0, 12.0, 24.0), 38.0, 24.0, 1.6, 1.2)
	lm.box("Sand", Vector3(0, 5.0, 0.0), Vector3(38.0, 10.0, 24.0))
	LandmarkEgParts.cavetto(lm, "Sand", Vector3(0, 10.0, 0.0), 38.0, 24.0, 1.3, 1.0)
	lm.box("Sand", Vector3(0, 3.8, -24.0), Vector3(38.0, 7.6, 24.0))
	LandmarkEgParts.cavetto(lm, "Sand", Vector3(0, 7.6, -24.0), 38.0, 24.0, 1.1, 0.8)
	for s in [-1.0, 1.0]:
		LandmarkEgParts.rod(lm, "Sand", Vector3(s * 19.0, 0.3, 36.0), Vector3(s * 19.0, 12.0, 36.0), 0.3, 6)
		for k in 5:
			lm.box("Falcon", Vector3(s * 19.05, 9.0 - 0.2 * float(k), -6.0 + 7.0 * float(k)),
				Vector3(0.1, 0.6, 0.6), Basis(), 0.0)
	# Pronaos facade: six columns, screen walls between all but the door bay.
	var xs := [-15.0, -9.0, -3.0, 3.0, 9.0, 15.0]
	for x in xs:
		LandmarkEgParts.column(lm, "Sand", Vector3(x, 0, 37.0), 0.85, 10.6, LandmarkEgParts.OPEN, 12)
	for k in 5:
		if k == 2:
			continue
		var cx := (float(xs[k]) + float(xs[k + 1])) * 0.5
		lm.box("Sand", Vector3(cx, 2.9, 37.0), Vector3(4.4, 5.8, 0.8))
		LandmarkEgParts.cavetto(lm, "Sand", Vector3(cx, 5.8, 37.0), 4.4, 0.8, 0.7, 0.3)
		LandmarkEgParts.winged_disc(lm, "Sand", Vector3(cx, 5.2, 37.42), 3.0)
	for s in [-1.0, 1.0]:
		lm.box("Sand", Vector3(s * 3.0, 3.4, 37.0), Vector3(1.2, 6.8, 1.0))
	lm.box("Sand", Vector3(0, 10.9, 37.0), Vector3(38.0, 1.4, 2.4))
	lm.box("Dark", Vector3(0, 3.0, 36.1), Vector3(3.6, 6.0, 0.2), Basis(), 0.0)
	_falcon(lm, Vector3(-4.8, 0, 39.0), 3.0)
	# Mammisi in front of the pylon, west side: Bes pillars round its sanctuary.
	lm.box("Sand", Vector3(-30.0, 3.5, 104.0), Vector3(10.0, 7.0, 18.0))
	LandmarkEgParts.cavetto(lm, "Sand", Vector3(-30.0, 7.0, 104.0), 15.0, 24.0, 0.8, 0.5)
	for p in [[-37.0, 93.0, -37.0, 115.0, 6], [-23.0, 93.0, -23.0, 115.0, 6], [-37.0, 116.5, -23.0, 116.5, 4]]:
		var pa := Vector3(float(p[0]), 0, float(p[1]))
		var pb := Vector3(float(p[2]), 0, float(p[3]))
		for k in int(p[4]):
			var cp := pa.lerp(pb, float(k) / float(int(p[4]) - 1))
			LandmarkEgParts.column(lm, "Sand", cp, 0.45, 6.2, LandmarkEgParts.OPEN, 10)
			lm.box("Sand", cp + Vector3(0, 6.6, 0), Vector3(1.0, 0.8, 1.0))
		lm.box("Sand", (pa + pb) * 0.5 + Vector3(0, 7.3, 0), (pb - pa).abs() + Vector3(1.2, 0.6, 1.2))
	lm.commit(model)

## Horus falcon statue `h` tall facing +Z on its pedestal: the folded
## wings and tail, the hooked beak and the double crown of the Two Lands.
static func _falcon(lm: LandmarkMesh, c: Vector3, h: float) -> void:
	lm.box("Falcon", c + Vector3(0, h * 0.14, 0), Vector3(h * 0.34, h * 0.28, h * 0.5))
	var b := c + Vector3(0, h * 0.28, 0)
	lm.lathe("Falcon", b, PackedVector2Array([Vector2(h * 0.1, 0), Vector2(h * 0.14, h * 0.12),
		Vector2(h * 0.13, h * 0.3), Vector2(h * 0.09, h * 0.42), Vector2(h * 0.05, h * 0.47)]), 10, 0.85, 1.25)
	lm.beam("Falcon", b + Vector3(0, h * 0.06, -h * 0.12), b + Vector3(0, -h * 0.0, -h * 0.24), h * 0.12, h * 0.03)
	var hd := b + Vector3(0, h * 0.46, h * 0.03)
	lm.lathe("Falcon", hd, PackedVector2Array([Vector2(h * 0.06, 0), Vector2(h * 0.075, h * 0.05),
		Vector2(h * 0.06, h * 0.1), Vector2(0.0, h * 0.12)]), 10)
	lm.beam("Falcon", hd + Vector3(0, h * 0.06, h * 0.06), hd + Vector3(0, h * 0.02, h * 0.11), h * 0.04, h * 0.03)
	var cr := hd + Vector3(0, h * 0.1, 0)
	lm.frustum("Falcon", cr, h * 0.075, h * 0.08, h * 0.06, 10)
	lm.lathe("Falcon", cr, PackedVector2Array([Vector2(h * 0.05, 0), Vector2(h * 0.045, h * 0.1),
		Vector2(h * 0.025, h * 0.16), Vector2(0.0, h * 0.18)]), 8)

# --- Temple of Kom Ombo ---

## Double temple of Sobek (east) and Haroeris (west) on its terrace over
## the river: the court whose 16 columns survive only as stumps carved
## with reliefs, the outer hypostyle facade of five columns with screen
## walls and two doors (one for each god), its 15 composite columns, the
## roofed inner halls and the two parallel sanctuaries, 15 m to the
## cornice; the Ptolemaic gateway in front, the Hathor chapel (the
## crocodile chapel) south-east and the round, stepped nilometer well.
static func kom_ombo(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Sand", LandmarkMaterials.pbr("stone", "#D2B98E", 3.4))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A2E22", 2.0))
	lm.use("Ground", LandmarkMaterials.pbr("sand", "#D6BE8C", 8.0))
	lm.box("Ground", Vector3(0, 0.1, 10.0), Vector3(90.0, 0.2, 130.0), Basis(), 0.0)
	lm.box("Ground", Vector3(0, 0.4, 0), Vector3(62.0, 0.4, 104.0))
	# Court: 16 column stumps (6 down each side, 4 across the front of the
	# hall), the enclosure walls and the gateway of Ptolemy XII.
	for s in [-1.0, 1.0]:
		for k in 6:
			_stump(lm, Vector3(s * 17.0, 0.6, 42.0 - 3.6 * float(k)), 0.8, 1.2 + 0.6 * float((k * 7 + int(s + 1.0)) % 3))
		LandmarkEgParts.temple_wall(lm, "Sand", Vector2(s * 22.0, 47.0), Vector2(s * 22.0, 21.0), 9.6, 2.0)
	for x in [-12.0, -4.0, 4.0, 12.0]:
		_stump(lm, Vector3(x, 0.6, 26.0), 0.8, 1.6)
	for s in [-1.0, 1.0]:
		LandmarkEgParts.temple_wall(lm, "Sand", Vector2(s * 22.0, 47.0), Vector2(s * 4.0, 47.0), 9.6, 2.0)
	lm.box("Sand", Vector3(0, 0.9, 44.0), Vector3(44.0, 0.6, 2.0))
	lm.box("Sand", Vector3(0, 7.0, 47.0), Vector3(8.0, 1.6, 2.6))
	for s in [-1.0, 1.0]:
		lm.box("Sand", Vector3(s * 3.4, 3.5, 47.0), Vector3(1.4, 7.0, 2.6))
	LandmarkEgParts.cavetto(lm, "Sand", Vector3(0, 7.8, 47.0), 8.0, 2.6, 1.0, 0.5)
	# Outer hypostyle: 15 composite columns in 3 rows under an architrave grid,
	# screen walls and the two doors on the facade, side walls to the cornice.
	for zr in [16.0, 9.0, 2.0]:
		for i in 5:
			LandmarkEgParts.column(lm, "Sand", Vector3(-17.0 + 8.5 * i, 0.6, zr), 1.0, 10.5,
				LandmarkEgParts.OPEN, 14)
		lm.beam("Sand", Vector3(-20.0, 11.9, zr), Vector3(20.0, 11.9, zr), 1.6, 2.4, Vector3.UP, true)
	for i in 5:
		lm.beam("Sand", Vector3(-17.0 + 8.5 * i, 11.9, 17.0), Vector3(-17.0 + 8.5 * i, 11.9, 1.0),
			1.6, 2.2, Vector3.UP, true)
	for x in [-12.75, 0.0, 12.75]:
		lm.box("Sand", Vector3(x, 3.0, 16.0), Vector3(6.6, 4.8, 1.0))
		LandmarkEgParts.cavetto(lm, "Sand", Vector3(x, 5.4, 16.0), 6.6, 1.0, 0.7, 0.3)
	for s in [-1.0, 1.0]:
		lm.box("Dark", Vector3(s * 4.25, 3.4, 9.0), Vector3(2.6, 6.2, 0.3), Basis(), 0.0)
		for k in 2:
			lm.box("Sand", Vector3(s * 4.25 + float(k * 2 - 1) * 1.6, 3.9, 16.0), Vector3(0.6, 6.6, 1.2))
		LandmarkEgParts.winged_disc(lm, "Sand", Vector3(s * 4.25, 7.6, 16.6), 3.0)
		LandmarkEgParts.temple_wall(lm, "Sand", Vector2(s * 22.5, 18.0), Vector2(s * 22.5, -2.0), 12.0, 2.0)
	lm.box("Sand", Vector3(-10.0, 12.6, 4.5), Vector3(24.0, 1.2, 13.0))
	# Inner hypostyle hall and the two parallel sanctuaries under cavetto cornices.
	lm.box("Sand", Vector3(0, 6.9, -7.0), Vector3(44.0, 12.6, 10.0))
	LandmarkEgParts.cavetto(lm, "Sand", Vector3(0, 13.2, -7.0), 44.0, 10.0, 1.8, 1.2)
	lm.box("Sand", Vector3(0, 5.6, -30.0), Vector3(44.0, 10.0, 28.0))
	LandmarkEgParts.cavetto(lm, "Sand", Vector3(0, 10.6, -30.0), 44.0, 28.0, 1.3, 0.9)
	for s in [-1.0, 1.0]:
		lm.box("Dark", Vector3(s * 11.0, 3.4, -1.95), Vector3(2.4, 5.0, 0.1), Basis(), 0.0)
	# Hathor (crocodile) chapel south-east and the nilometer north-east.
	lm.box("Sand", Vector3(-27.0, 3.0, 38.0), Vector3(6.0, 6.0, 8.0))
	LandmarkEgParts.cavetto(lm, "Sand", Vector3(-27.0, 6.0, 38.0), 6.0, 8.0, 0.8, 0.5)
	lm.box("Dark", Vector3(-27.0, 2.2, 42.05), Vector3(1.4, 3.2, 0.1), Basis(), 0.0)
	lm.lathe("Sand", Vector3(27.0, 0, -20.0), PackedVector2Array([Vector2(4.6, 0), Vector2(4.6, 1.2),
		Vector2(3.8, 1.2), Vector2(3.8, 0.4)]), 20)
	for k in 6:
		var a := TAU * float(k) / 6.0
		lm.box("Sand", Vector3(27.0 + cos(a) * 3.2, 0.3, -20.0 + sin(a) * 3.2), Vector3(1.0, 0.25, 1.0),
			Basis(Vector3.UP, -a))
	lm.box("Dark", Vector3(27.0, 0.42, -20.0), Vector3(5.0, 0.05, 5.0), Basis(Vector3.UP, PI * 0.25), 0.0)
	lm.commit(model)

## Broken column stump `h` high on its base, its drums carved in relief.
static func _stump(lm: LandmarkMesh, c: Vector3, r: float, h: float) -> void:
	lm.frustum("Sand", c, r * 1.4, r * 1.32, r * 0.3, 12)
	lm.lathe("Sand", c + Vector3(0, r * 0.3, 0), PackedVector2Array([Vector2(r * 0.86, 0), Vector2(r, h * 0.15),
		Vector2(r, h - r * 0.3), Vector2(r * 0.9, h - r * 0.25)]), 14)
	for k in 2:
		lm.lathe("Sand", c + Vector3(0, r * 0.3 + h * (0.3 + 0.3 * float(k)), 0),
			PackedVector2Array([Vector2(r * 1.03, 0), Vector2(r * 1.03, 0.08)]), 14, 1.0, 1.0, 0.0, true, false)
