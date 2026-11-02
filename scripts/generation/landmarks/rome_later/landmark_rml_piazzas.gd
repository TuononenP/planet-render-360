class_name LandmarkRmLPiazzas
extends RefCounted

## The Spanish Steps with Trinità dei Monti and Piazza del Popolo with
## its obelisk and twin churches, in true metres.

# --- Spanish Steps ------------------------------------------------------

## Origin at the middle of the stair, y = 0 at the foot (Piazza di
## Spagna, +Z); the 135 travertine steps (1723-25) climb 23 m to the
## terrace in front of Trinità dei Monti (-Z; yaw_deg turns the model
## onto the hill): flights split round planted islands and opening onto
## two landings, parapets with pedestal posts and balustraded terraces,
## the Sallustian obelisk (13.91 m shaft, 30.45 m with its pedestal and
## cross), Domenico Fontana's double stair up to the church door and the
## church with its twin bell towers (54 m to the crosses); at the foot
## Pietro Bernini's half-sunk Barcaccia boat fountain.
static func steps(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D1BE9A", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E6DBC2", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4136", 3.0))
	lm.use("Steps", LandmarkMaterials.pbr("limestone", "#CFC2A6", 2.0))
	lm.use("Garden", LandmarkMaterials.pbr("lawn", "#6E8F4E", 3.0))
	lm.use("Ochre", LandmarkMaterials.pbr("render", "#C99A66", 4.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A65A3E", 2.0))
	lm.use("Dome", LandmarkMaterials.pbr("concrete", "#8E9291", 3.0, 0.55, 0.3))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Water", LandmarkMaterials.glass("#2A6C78"))
	# Flights, landings and the planted islands between the arms.
	LandmarkRmLUtil.flight(lm, "Steps", 0.0, 36.0, 34.0, 22.0, 0.0, 6.0, 24)
	lm.box("Steps", Vector3(0, 3.0, 19.5), Vector3(36.0, 6.0, 5.0))
	LandmarkRmLUtil.flight(lm, "Steps", -12.0, 12.0, 17.0, 7.0, 6.0, 12.0, 24)
	LandmarkRmLUtil.flight(lm, "Steps", 12.0, 12.0, 17.0, 7.0, 6.0, 12.0, 24)
	LandmarkRmLUtil.flight(lm, "Garden", 0.0, 12.0, 17.0, 7.0, 6.7, 12.7, 8)
	lm.box("Steps", Vector3(0, 6.0, 4.0), Vector3(36.0, 12.0, 6.0))
	LandmarkRmLUtil.flight(lm, "Steps", -12.0, 12.0, 1.0, -9.0, 12.0, 17.5, 22)
	LandmarkRmLUtil.flight(lm, "Steps", 12.0, 12.0, 1.0, -9.0, 12.0, 17.5, 22)
	LandmarkRmLUtil.flight(lm, "Garden", 0.0, 12.0, 1.0, -9.0, 12.7, 18.2, 8)
	lm.box("Steps", Vector3(0, 8.75, -11.0), Vector3(36.0, 17.5, 4.0))
	LandmarkRmLUtil.flight(lm, "Steps", 0.0, 24.0, -13.0, -22.0, 17.5, 23.0, 22)
	lm.box("Steps", Vector3(0, 11.5, -28.0), Vector3(40.0, 23.0, 12.0))
	# Island cheeks: low parapets round the planted islands.
	for s in [-1.0, 1.0]:
		for seg in [[17.0, 7.0, 6.0, 12.0], [1.0, -9.0, 12.0, 17.5]]:
			lm.beam("Trim", Vector3(s * 6.2, float(seg[2]) + 1.0, float(seg[0])), Vector3(s * 6.2, float(seg[3]) + 1.0, float(seg[1])),
				0.5, 1.2, Vector3.RIGHT)
	for s in [-1.0, 1.0]:
		# Outer parapets up the flights with a pedestal post at every
		# landing, and balustrades across the landings.
		var pts: Array = [Vector3(s * 18.4, 0.0, 34.0), Vector3(s * 18.4, 6.0, 22.0), Vector3(s * 18.4, 6.0, 17.0),
			Vector3(s * 18.4, 12.0, 7.0), Vector3(s * 18.4, 12.0, 1.0), Vector3(s * 18.4, 17.5, -9.0),
			Vector3(s * 18.4, 17.5, -13.0), Vector3(s * 18.4, 23.0, -22.0)]
		for i in pts.size() - 1:
			var a: Vector3 = pts[i]
			var b: Vector3 = pts[i + 1]
			lm.beam("Trim", a + Vector3(0, 0.6, 0), b + Vector3(0, 0.6, 0), 1.0, 1.2, Vector3.RIGHT)
			lm.beam("Trim", a + Vector3(0, 1.25, 0), b + Vector3(0, 1.25, 0), 0.25, 1.4, Vector3.RIGHT)
			lm.box("Trim", a + Vector3(0, 0.8, 0), Vector3(1.6, 1.6, 1.6))
			lm.box("Trim", a + Vector3(0, 1.7, 0), Vector3(1.8, 0.25, 1.8), Basis(), 0.0)
		for y in [[6.0, 19.5], [12.0, 4.0], [17.5, -11.0]]:
			lm.box("Trim", Vector3(s * 18.4, float(y[0]) * 0.5, float(y[1])), Vector3(1.0, float(y[0]), 6.0))
		# Houses crowding the stair on both sides (the Keats-Shelley House
		# and Babington's at the foot).
		LandmarkRmLUtil.block(lm, "Ochre", Vector3(s * 28.0, 0, 20.0), 28.0, 20.0, 18.0, Vector3(-s, 0, 0), 4, 5,
			1.3, 2.3, "Tile", 2)
		LandmarkRmLUtil.block(lm, "Ochre", Vector3(s * 28.0, 0, -8.0), 24.0, 24.0, 18.0, Vector3(-s, 0, 0), 5, 4,
			1.3, 2.3, "Tile")
	# Terrace balustrade along the top edge either side of the last flight.
	for s in [-1.0, 1.0]:
		LandmarkRmLKit.balustrade(lm, "Trim", Vector3(s * 12.4, 23.0, -22.2), Vector3(s * 19.8, 23.0, -22.2), 1.1, 3.6)
	_barcaccia(lm, Vector3(0, 0, 46.0))
	_trinita(lm, 23.0)
	lm.commit(model)

## Barcaccia: an oval basin with the half-sunk travertine boat, its
## raised bow and stern, the papal sun shields and a central spout.
static func _barcaccia(lm: LandmarkMesh, c: Vector3) -> void:
	lm.lathe("Stone", c, PackedVector2Array([Vector2(4.6, 0.0), Vector2(4.7, 0.4), Vector2(4.4, 0.6),
		Vector2(4.0, 0.6), Vector2(4.0, 0.3)]), 32, 1.0, 1.7, 0.0, true, false)
	lm.lathe("Water", c + Vector3(0, 0.35, 0), PackedVector2Array([Vector2(4.05, 0.0), Vector2(0.0, 0.0)]), 32, 1.0, 1.7)
	# Hull: a stretched bowl with bow and stern lifting at each end.
	lm.lathe("Stone", c + Vector3(0, 0.1, 0), PackedVector2Array([Vector2(1.4, 0.0), Vector2(2.1, 0.5),
		Vector2(2.4, 1.1), Vector2(2.3, 1.3), Vector2(2.0, 1.3)]), 24, 1.0, 2.0, 0.0, true, false)
	for s in [-1.0, 1.0]:
		lm.beam("Stone", c + Vector3(0, 1.1, s * 4.0), c + Vector3(0, 2.0, s * 5.0), 1.6, 0.9, Vector3.RIGHT)
		lm.disc("Trim", c + Vector3(0, 1.8, s * 5.0) + Vector3(0, 0, s * 0.5), Vector3(0, 0.3, s).normalized(), 0.6, 12)
	lm.frustum("Stone", c + Vector3(0, 0.6, 0), 0.5, 0.35, 1.2, 10)
	lm.lathe("Stone", c + Vector3(0, 1.8, 0), SEuUtil.dome(0.9, 0.4, 3), 12)

## Trinità dei Monti on the terrace at height y0, facade at z = -34:
## two orders of pilasters, a central portal and window, the pediment,
## the twin bell towers with their cupolas, Fontana's double stair
## curving up to the door and the Sallustian obelisk.
static func _trinita(lm: LandmarkMesh, y0: float) -> void:
	var n := Vector3(0, 0, 1)
	var r := Vector3.RIGHT
	lm.box("Stone", Vector3(0, y0 * 0.5, -49.0), Vector3(28.0, y0, 34.0))
	lm.box("Stone", Vector3(0, y0 + 10.0, -50.0), Vector3(21.0, 20.0, 32.0))
	lm.gable("Tile", Vector3(0, y0 + 20.0, -50.0), 21.0, 32.0, 4.0, Basis(), 0.5, "Stone")
	# Podium raising the church door: rusticated base with the stair.
	lm.box("Stone", Vector3(0, y0 + 2.4, -34.4), Vector3(12.6, 4.8, 3.0))
	lm.box("Stone", Vector3(0, y0 + 11.9, -34.8), Vector3(12.6, 14.2, 1.6))
	lm.box("Trim", Vector3(0, y0 + 4.9, -32.8), Vector3(13.0, 0.4, 0.4))
	for s in [-1.0, 1.0]:
		# Fontana's double stair: two flights curving out and up to the
		# landing before the door.
		for k in 16:
			var t := float(k) / 15.0
			var a := PI * 0.5 * t
			var p := Vector3(s * (2.6 + 5.4 * cos(a)), 0, -32.6 + 5.4 * sin(a) * 0.9)
			var hgt := 4.8 * (1.0 - t)
			lm.box("Steps", Vector3(p.x, y0 + hgt * 0.5, p.z), Vector3(1.4, hgt + 0.1, 2.6), Basis(Vector3.UP, -s * a))
		LandmarkRmLKit.balustrade(lm, "Trim", Vector3(s * 8.0, y0 + 0.2, -32.6), Vector3(s * 3.4, y0 + 4.9, -27.8), 0.9, 2.2)
	LandmarkRmLKit.balustrade(lm, "Trim", Vector3(-6.2, y0 + 4.8, -32.8), Vector3(-1.6, y0 + 4.8, -32.8), 0.9, 2.3)
	LandmarkRmLKit.balustrade(lm, "Trim", Vector3(1.6, y0 + 4.8, -32.8), Vector3(6.2, y0 + 4.8, -32.8), 0.9, 2.3)
	# Two orders of pilasters, portal, window and the pediment.
	var f := Vector3(0, y0 + 4.8, -34.0)
	LandmarkRmLKit.pilaster_row(lm, "Trim", f - r * 5.4, r, n, 10.8, 4, 0.9, 7.6, 0.5)
	LandmarkRmLKit.pilaster_row(lm, "Trim", f - r * 5.4 + Vector3(0, 8.4, 0), r, n, 10.8, 4, 0.8, 6.0, 0.45)
	LandmarkRmLKit.entablature(lm, "Trim", f - r * 6.3 + Vector3(0, 7.6, 0), f + r * 6.3 + Vector3(0, 7.6, 0), n, 0.9, 0.5)
	lm.box("Trim", Vector3(0, y0 + 19.4, -34.6), Vector3(13.6, 0.8, 2.4))
	LandmarkRmLKit.pediment(lm, "Trim", Vector3(0, y0 + 19.8, -35.8), r, n, 13.6, 3.0, 2.4, true)
	lm.box("Shadow", f + Vector3(0, 2.6, 0.05), Vector3(2.4, 5.0, 0.1), Basis(), 0.0)
	LandmarkRmLKit.frame_opening(lm, "Trim", f + Vector3(0, 0.1, 0.1), r, n, 2.4, 5.0, 1)
	LandmarkRmLKit.arcade(lm, "Stone", "Shadow", f + Vector3(-1.4, 9.0, 0), r, n, 2.8, 5.0, 1, 2.0, 2.4, 0.4)
	for s in [-1.0, 1.0]:
		lm.box("Shadow", f + Vector3(s * 3.6, 9.6, 0.05), Vector3(1.1, 2.6, 0.1), Basis(), 0.0)
		LandmarkRmLKit.frame_opening(lm, "Trim", f + Vector3(s * 3.6, 9.3, 0.1), r, n, 1.1, 2.6, 0)
	for s in [-1.0, 1.0]:
		var base := Vector3(s * 9.5, y0, -35.5)
		LandmarkRmLUtil.tower(lm, "Stone", base, PackedVector2Array([Vector2(13.5, 3.5), Vector2(6.5, 3.2)]), 21.4)
		LandmarkRmLKit.pilaster_row(lm, "Trim", base + Vector3(-3.1, 0, 3.5), r, n, 6.2, 2, 0.8, 13.0, 0.4)
		lm.box("Shadow", base + Vector3(0, 8.0, 3.55), Vector3(1.2, 2.6, 0.1), Basis(), 0.0)
		LandmarkRmLKit.frame_opening(lm, "Trim", base + Vector3(0, 6.7, 3.6), r, n, 1.2, 2.6, 4)
		LandmarkKits.dome_on_drum(lm, "Stone", "Dome", base + Vector3(0, 21.0, 0), 2.8, 1.8, 3.2, 2.6, 16)
		SEuUtil.finial(lm, "Gold", base + Vector3(0, 28.6, 0), 2.4)
	# Sallustian obelisk in front of the church: pedestal, 13.91 m shaft.
	LandmarkRmLKit.obelisk(lm, "Stone", "Trim", "Gold", Vector3(0, y0, -24.5), 14.0, 13.91, 0.8, 2.2)

# --- Piazza del Popolo --------------------------------------------------

## Origin midway between the obelisk and the churches; the churches
## face +Z toward the piazza (yaw_deg turns it onto the Corso axis).
## Santa Maria dei Miracoli (+X, west of the Corso; octagonal dome) and
## Santa Maria in Montesanto (-X; twelve-sided oval dome) are Rainaldi's
## "twins" (1675-79): tetrastyle porches under pediments, balustrades
## with statues, the domes on their drums and small bell towers behind.
## The 24 m Flaminian obelisk (36.5 m with pedestal and cross) stands in
## the middle on Valadier's stepped base with four lions spouting into
## round basins; the hemicycles with their fountains close the east and
## west sides.
static func popolo(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D2C2A0", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E6DBC2", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4136", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#A0593F", 3.0))
	lm.use("Dome", LandmarkMaterials.pbr("concrete", "#8E9291", 3.0, 0.55, 0.3))
	lm.use("Ochre", LandmarkMaterials.pbr("render", "#C9965F", 4.0))
	lm.use("Water", LandmarkMaterials.glass("#2A6C78"))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EDE8DC", 2.0))
	_church(lm, 21.0, 8.4, 8.4, 6.0, 9.0, 4.5, 22.0, 8)
	_church(lm, -21.0, 7.4, 9.4, 6.5, 8.0, 4.5, 21.5, 12)
	for s in [-1.0, 1.0]:
		LandmarkRmLUtil.block(lm, "Ochre", Vector3(s * 41.0, 0, -55.0), 28.0, 21.0, 18.0, Vector3(0, 0, 1), 4, 5,
			1.3, 2.3, "", 2)
		_exedra(lm, Vector3(s * 66.0, 0, 43.0), -s)
	# Obelisk on its stepped base, basins and four lions.
	var o := Vector3(0, 0, 43.0)
	for k in 3:
		lm.frustum("Stone", o + Vector3(0, 0.5 * float(k), 0), 7.2 - 1.2 * float(k), 7.2 - 1.2 * float(k), 0.5, 8, PI / 8.0)
	LandmarkRmLKit.obelisk(lm, "Granite", "Trim", "Gold", o + Vector3(0, 1.5, 0), 7.0, 24.0, 1.2, 4.0)
	for k in 4:
		var a := PI * 0.25 + PI * 0.5 * float(k)
		var d := Vector3(cos(a), 0, sin(a))
		var p := o + d * 7.6
		# Stepped plinth with the lion, spouting into a round basin.
		for t in 3:
			lm.box("Stone", p + Vector3(0, 0.35 + 0.7 * float(t), 0), Vector3(3.0 - 0.6 * float(t), 0.7, 3.0 - 0.6 * float(t)),
				Basis(Vector3.UP, -a))
		_lion(lm, p + Vector3(0, 2.1, 0), d)
		var bc := p + d * 4.2
		lm.lathe("Marble", bc, PackedVector2Array([Vector2(2.4, 0.0), Vector2(2.5, 0.6), Vector2(2.1, 0.7),
			Vector2(2.1, 0.4)]), 20, 1.0, 1.0, 0.0, true, false)
		lm.disc("Water", bc + Vector3(0, 0.55, 0), Vector3.UP, 2.15, 20)
	lm.commit(model)

## A seated Egyptian-style lion facing d on its plinth top `p`.
static func _lion(lm: LandmarkMesh, p: Vector3, d: Vector3) -> void:
	var b := Basis(Vector3.UP.cross(d), Vector3.UP, d)
	lm.box("Marble", p + d * -0.3 + Vector3(0, 0.45, 0), Vector3(0.9, 0.9, 2.0), b)
	lm.box("Marble", p + d * 0.6 + Vector3(0, 0.25, 0), Vector3(0.8, 0.5, 0.6), b)
	lm.lathe("Marble", p + d * 0.55 + Vector3(0, 0.8, 0), PackedVector2Array([Vector2(0.55, 0.0),
		Vector2(0.6, 0.35), Vector2(0.45, 0.7), Vector2(0.0, 0.85)]), 10)
	lm.box("Marble", p + d * 0.9 + Vector3(0, 1.05, 0), Vector3(0.4, 0.35, 0.4), b)

## Hemicycle on the east or west side of the piazza: a curved wall with
## statues on its parapet and a fountain with a figure group, opening
## toward `toward` (+1 = +X).
static func _exedra(lm: LandmarkMesh, c: Vector3, toward: float) -> void:
	var prev := Vector3.ZERO
	for k in 13:
		var a := PI * 0.5 + PI * float(k) / 12.0
		var p := c + Vector3(-cos(a) * 18.0 * toward, 0, sin(a) * 18.0)
		if k > 0:
			lm.beam("Stone", prev + Vector3(0, 1.4, 0), p + Vector3(0, 1.4, 0), 2.8, 1.0, Vector3.UP)
			lm.beam("Trim", prev + Vector3(0, 2.95, 0), p + Vector3(0, 2.95, 0), 0.3, 1.3, Vector3.UP)
		if k % 3 == 0:
			lm.box("Trim", p + Vector3(0, 3.6, 0), Vector3(1.2, 1.3, 1.2))
			LandmarkKits.statue_figure(lm, "Marble", p + Vector3(0, 4.25, 0), 2.6)
		prev = p
	var f := c + Vector3(toward * -8.0, 0, 0)
	lm.lathe("Marble", f, PackedVector2Array([Vector2(5.0, 0.0), Vector2(5.1, 0.7), Vector2(4.6, 0.8),
		Vector2(4.6, 0.5)]), 24, 1.0, 1.0, 0.0, true, false)
	lm.disc("Water", f + Vector3(0, 0.65, 0), Vector3.UP, 4.65, 24)
	SEuUtil.blob(lm, "Stone", f + Vector3(0, 0.5, 0), 2.0, 1.6, 2.0, Vector3.ZERO, true, 4, 10)
	LandmarkKits.statue_figure(lm, "Marble", f + Vector3(0, 2.0, 0), 3.6, true)
	for s in [-1.0, 1.0]:
		LandmarkKits.statue_figure(lm, "Marble", f + Vector3(0, 0.8, s * 2.4), 2.4)

## One of the twin churches centred on x0: tetrastyle Ionic porch under
## a pediment, the body with a balustrade and statues, a drum and a
## faceted dome of `sides` sides (stretched `oval` front to back), the
## lantern, and a small bell tower behind.
static func _church(lm: LandmarkMesh, x0: float, r: float, ry: float, drum_h: float, dome_h: float,
		lantern_h: float, top_h: float, sides: int) -> void:
	var n := Vector3(0, 0, 1)
	var rr := Vector3.RIGHT
	lm.box("Stone", Vector3(x0, 9.0, -55.0), Vector3(20.0, 18.0, 28.0))
	LandmarkDetail.cornice(lm, "Trim", Vector3(x0 - 10.4, 17.6, -41.0), Vector3(x0 + 10.4, 17.6, -41.0), n, 1.0, true)
	lm.box("Trim", Vector3(x0, 18.4, -55.0), Vector3(21.4, 0.8, 29.4))
	LandmarkRmLKit.balustrade(lm, "Trim", Vector3(x0 - 10.0, 18.8, -40.8), Vector3(x0 + 10.0, 18.8, -40.8), 1.2, 4.0)
	LandmarkRmLKit.statue_row(lm, "Marble", Vector3(x0 - 10.0, 20.0, -40.8), Vector3(x0 + 10.0, 20.0, -40.8), 6, 2.6)
	LandmarkRmLKit.pilaster_row(lm, "Trim", Vector3(x0 - 9.4, 0.8, -41.0), rr, n, 18.8, 6, 1.0, 12.5, 0.4)
	# Porch: four Ionic columns in front, a podium of steps.
	lm.box("Trim", Vector3(x0, 0.4, -38.5), Vector3(16.0, 0.8, 5.4))
	SEuUtil.steps_up(lm, "Trim", Vector3(x0, 0, -35.8), n, 16.0, 0.6, 0.2, 2)
	for i in 4:
		LandmarkRmLKit.column_ionic(lm, "Trim", Vector3(x0 - 6.0 + 4.0 * float(i), 0.8, -37.0), 0.72, 12.5, n)
	LandmarkRmLKit.entablature(lm, "Trim", Vector3(x0 - 7.8, 13.3, -38.0), Vector3(x0 + 7.8, 13.3, -38.0), n, 1.6, 2.2)
	lm.box("Stone", Vector3(x0, 13.8, -39.5), Vector3(15.6, 1.4, 3.0))
	LandmarkRmLKit.pediment(lm, "Trim", Vector3(x0, 14.9, -39.8), rr, n, 16.2, 3.2, 4.0, true)
	lm.box("Shadow", Vector3(x0, 4.6, -40.95), Vector3(3.4, 7.2, 0.1), Basis(), 0.0)
	LandmarkRmLKit.frame_opening(lm, "Trim", Vector3(x0, 1.0, -40.9), rr, n, 3.4, 7.2, 4)
	lm.box("Shadow", Vector3(x0, 10.6, -40.95), Vector3(2.2, 2.4, 0.1), Basis(), 0.0)
	LandmarkRmLKit.frame_opening(lm, "Trim", Vector3(x0, 9.4, -40.9), rr, n, 2.2, 2.4, 0)
	# Drum, faceted dome, lantern and cross.
	var base := Vector3(x0, 18.4, -57.0)
	var sz := ry / r
	lm.lathe("Stone", base, PackedVector2Array([Vector2(r, 0.0), Vector2(r, drum_h)]), sides, 1.0, sz, PI / float(sides), false)
	var ap := cos(PI / float(sides))
	for k in sides:
		# Windows on the faces, pilasters on the angles.
		var a := TAU * float(k) / float(sides)
		var dn := Vector3(cos(a), 0, sin(a) / sz).normalized()
		lm.box("Shadow", base + Vector3(cos(a), 0, sin(a) * sz) * r * ap + dn * 0.05 + Vector3(0, drum_h * 0.5, 0),
			Vector3(1.4, drum_h * 0.5, 0.1), Basis(Vector3.UP.cross(dn), Vector3.UP, dn), 0.0)
		var a2 := a + PI / float(sides)
		var n2 := Vector3(cos(a2), 0, sin(a2) / sz).normalized()
		LandmarkRmLKit.pilaster(lm, "Trim", base + Vector3(cos(a2) * r, 0, sin(a2) * r * sz), Vector3.UP.cross(n2), n2,
			0.8, drum_h, 0.35)
	lm.lathe("Trim", base + Vector3(0, drum_h, 0), PackedVector2Array([Vector2(r * 1.03, 0.0), Vector2(r * 1.08, 0.8)]),
		sides, 1.0, sz, PI / float(sides), false)
	var prof := PackedVector2Array()
	for k in 9:
		var t := float(k) / 8.0
		prof.append(Vector2(r * 1.02 * cos(t * PI * 0.5), dome_h * sin(t * PI * 0.5)))
	prof[8] = Vector2(r * 0.18, dome_h)
	lm.lathe("Dome", base + Vector3(0, drum_h + 0.8, 0), prof, sides, 1.0, sz, PI / float(sides), false)
	for k in sides:
		# Ribs up the angles of the faceted shell.
		var a := TAU * float(k) / float(sides) + PI / float(sides)
		for j in prof.size() - 1:
			var q0 := prof[j]
			var q1 := prof[j + 1]
			lm.beam("Trim", base + Vector3(cos(a) * q0.x, drum_h + 0.8 + q0.y, sin(a) * q0.x * sz),
				base + Vector3(cos(a) * q1.x, drum_h + 0.8 + q1.y, sin(a) * q1.x * sz), 0.35, 0.3)
	var ly := drum_h + 0.8 + dome_h
	lm.frustum("Stone", base + Vector3(0, ly, 0), 1.6, 1.6, lantern_h - 1.8, sides)
	for k in 8:
		var a := TAU * float(k) / 8.0
		LandmarkRmLKit.column_lite(lm, "Trim", base + Vector3(cos(a) * 1.75, ly, sin(a) * 1.75), 0.16, lantern_h - 1.8)
	lm.lathe("Dome", base + Vector3(0, ly + lantern_h - 1.8, 0), SEuUtil.dome(2.0, 1.4, 4), sides)
	SEuUtil.finial(lm, "Gold", base + Vector3(0, ly + lantern_h - 0.4, 0), maxf(top_h - ly - lantern_h + 0.4, 1.0))
	# Small bell tower at the rear outer corner.
	var tb := Vector3(x0 + signf(x0) * 7.0, 0, -67.0)
	lm.box("Stone", tb + Vector3(0, 11.0, 0), Vector3(4.0, 22.0, 4.0))
	lm.box("Trim", tb + Vector3(0, 22.2, 0), Vector3(4.6, 0.4, 4.6))
	for f in 4:
		var out := Vector3(0, 0, 1).rotated(Vector3.UP, PI * 0.5 * float(f))
		SEuUtil.opening(lm, "Shadow", tb + out * 2.03 + Vector3(0, 18.0, 0), Vector3.UP.cross(out), Vector3.UP, 1.4, 3.2)
	lm.spire("Dome", tb + Vector3(0, 22.4, 0), 2.2, 3.0)
