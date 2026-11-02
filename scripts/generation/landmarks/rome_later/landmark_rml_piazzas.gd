class_name LandmarkRmLPiazzas
extends RefCounted

## The Spanish Steps with Trinità dei Monti and Piazza del Popolo with
## its obelisk and twin churches, in true metres.

# --- Spanish Steps ------------------------------------------------------

## Origin at the middle of the stair, y = 0 at the foot (Piazza di
## Spagna, +Z); the 135 steps climb 23 m to the terrace in front of
## Trinità dei Monti (-Z; yaw_deg turns the model onto the hill): three
## flights split round planted islands, the Sallustian obelisk and the
## church with its twin domed bell towers on a podium reaching down to
## the street (54 m to the crosses).
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
	for s in [-1.0, 1.0]:
		lm.beam("Trim", Vector3(s * 18.4, 0.6, 34.0), Vector3(s * 18.4, 23.6, -22.0), 1.0, 1.2, Vector3.RIGHT)
		# Houses crowding the stair on both sides.
		LandmarkRmLUtil.block(lm, "Ochre", Vector3(s * 28.0, 0, 20.0), 28.0, 20.0, 18.0, Vector3(-s, 0, 0), 4, 5)
		LandmarkRmLUtil.block(lm, "Ochre", Vector3(s * 28.0, 0, -8.0), 24.0, 24.0, 18.0, Vector3(-s, 0, 0), 5, 4)
	# Barcaccia at the foot.
	SEuUtil.blob(lm, "Stone", Vector3(0, 0, 46.0), 2.4, 1.3, 5.2, Vector3.ZERO, true, 6, 14)
	_trinita(lm, 23.0)
	lm.commit(model)

## Trinità dei Monti on the terrace at height y0, facade at z = -34.
static func _trinita(lm: LandmarkMesh, y0: float) -> void:
	lm.box("Stone", Vector3(0, y0 * 0.5, -49.0), Vector3(28.0, y0, 34.0))
	lm.box("Stone", Vector3(0, y0 + 10.0, -50.0), Vector3(21.0, 20.0, 32.0))
	lm.gable("Tile", Vector3(0, y0 + 20.0, -50.0), 21.0, 32.0, 4.0, Basis(), 0.5, "Stone")
	lm.box("Stone", Vector3(0, y0 + 9.5, -34.8), Vector3(12.6, 19.0, 1.6))
	lm.box("Trim", Vector3(0, y0 + 19.4, -34.6), Vector3(13.6, 0.8, 2.4))
	LandmarkRmLUtil.pediment(lm, "Trim", Vector3(0, y0 + 19.8, -34.6), 13.6, 3.0, 2.4)
	LandmarkRmLUtil.pilasters(lm, "Trim", Vector3(0, y0, -34.0), Vector3(0, 0, 1), 4, 3.4, 18.4, 0.9, 0.6)
	SEuUtil.opening(lm, "Shadow", Vector3(0, y0, -33.9), Vector3.RIGHT, Vector3.UP, 3.2, 6.0)
	SEuUtil.opening(lm, "Shadow", Vector3(0, y0 + 10.0, -33.9), Vector3.RIGHT, Vector3.UP, 2.6, 5.0)
	for s in [-1.0, 1.0]:
		var base := Vector3(s * 9.5, y0, -35.5)
		LandmarkRmLUtil.tower(lm, "Stone", base, PackedVector2Array([Vector2(13.5, 3.5), Vector2(6.5, 3.2)]), 21.4)
		LandmarkKits.dome_on_drum(lm, "Stone", "Dome", base + Vector3(0, 21.0, 0), 2.8, 1.8, 3.2, 2.6, 16)
		SEuUtil.finial(lm, "Gold", base + Vector3(0, 28.6, 0), 2.4)
	# Sallustian obelisk in front of the church.
	lm.box("Trim", Vector3(0, y0 + 1.2, -27.0), Vector3(3.2, 2.4, 3.2))
	LandmarkRmLUtil.obelisk(lm, "Stone", Vector3(0, y0 + 2.4, -27.0), 13.9, 0.8)
	SEuUtil.finial(lm, "Gold", Vector3(0, y0 + 16.3, -27.0), 1.4)

# --- Piazza del Popolo --------------------------------------------------

## Origin midway between the obelisk and the churches; the churches
## face +Z toward the piazza (yaw_deg turns it onto the Corso axis).
## Santa Maria dei Miracoli (+X) and Santa Maria in Montesanto (-X)
## are Rainaldi's twins: pedimented porches of columns, domed drums
## behind; the 24 m Flaminian obelisk (36.5 m with its pedestal and
## cross) stands in the piazza on a stepped base with four lions.
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
	_church(lm, 21.0, 8.4, 6.0, 9.0, 4.5, 22.0)
	_church(lm, -21.0, 7.4, 6.5, 8.0, 4.5, 21.5)
	for s in [-1.0, 1.0]:
		LandmarkRmLUtil.block(lm, "Ochre", Vector3(s * 41.0, 0, -55.0), 28.0, 21.0, 18.0, Vector3(s, 0, 0), 4, 5)
	# Obelisk on its stepped octagonal base, basin and four lions.
	var o := Vector3(0, 0, 43.0)
	var rim := PackedVector2Array([Vector2(10.0, 0.0), Vector2(10.0, 0.9), Vector2(9.0, 0.9), Vector2(9.0, 0.6)])
	lm.lathe("Stone", o, rim, 24, 1.0, 1.0, 0.0, true, false)
	lm.disc("Water", o + Vector3(0, 0.75, 0), Vector3.UP, 9.1, 24)
	lm.frustum("Stone", o, 6.6, 6.0, 1.0, 8)
	lm.frustum("Stone", o + Vector3(0, 1.0, 0), 5.2, 5.0, 1.0, 8)
	lm.box("Trim", o + Vector3(0, 5.25, 0), Vector3(4.6, 6.5, 4.6))
	lm.box("Stone", o + Vector3(0, 8.6, 0), Vector3(5.2, 0.5, 5.2))
	LandmarkRmLUtil.obelisk(lm, "Granite", o + Vector3(0, 8.5, 0), 24.0, 1.2)
	SEuUtil.finial(lm, "Gold", o + Vector3(0, 32.5, 0), 4.0)
	for k in 4:
		var a := PI * 0.25 + PI * 0.5 * float(k)
		var p := o + Vector3(cos(a) * 3.6, 2.0, sin(a) * 3.6)
		var b := Basis(Vector3.UP, -a)
		lm.box("Stone", p + Vector3(0, 0.55, 0), Vector3(1.4, 1.1, 2.2), b)
		lm.box("Stone", p + b * Vector3(0, 1.4, 0.9), Vector3(0.9, 1.0, 0.9))
	lm.commit(model)

## One of the twin churches centred on x0: hexastyle porch, tall body,
## drum and dome of radius r.
static func _church(lm: LandmarkMesh, x0: float, r: float, drum_h: float, dome_h: float,
		lantern_h: float, top_h: float) -> void:
	lm.box("Stone", Vector3(x0, 9.0, -55.0), Vector3(20.0, 18.0, 28.0))
	lm.box("Trim", Vector3(x0, 18.4, -55.0), Vector3(21.4, 0.8, 29.4))
	for row in [-37.5, -40.0]:
		SEuUtil.column_row(lm, "Trim", Vector3(x0 - 6.5, 0.8, float(row)), Vector3(x0 + 6.5, 0.8, float(row)),
			3, 12.5, 0.75, 12)
	lm.box("Trim", Vector3(x0, 0.4, -39.0), Vector3(20.0, 0.8, 6.0))
	lm.box("Trim", Vector3(x0, 14.1, -39.0), Vector3(20.6, 1.4, 5.0))
	LandmarkRmLUtil.pediment(lm, "Trim", Vector3(x0, 14.8, -39.0), 20.6, 3.2, 5.0)
	SEuUtil.opening(lm, "Shadow", Vector3(x0, 0.8, -41.06), Vector3.RIGHT, Vector3.UP, 3.4, 7.2)
	SEuUtil.face_row(lm, "Shadow", Vector3(x0, 0, -41.0), Vector3.RIGHT, Vector3(0, 0, 1), 8.6, 1, 4.0, 2.2, 5.0)
	LandmarkRmLUtil.dome_stack(lm, Vector3(x0, 18.4, -57.0), r, drum_h, dome_h, lantern_h, top_h - 0.4, 8, 8)
