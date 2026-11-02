class_name SEuRomeSacred
extends RefCounted

## St Peter's Basilica and the Pantheon in true metres.

# --- St Peter's -------------------------------------------------------

## Origin under Michelangelo's dome (136.6 m to the cross). Facade and
## Bernini's colonnaded oval face east (+X): the 115 m Maderno facade of
## eight giant columns and a statue-crowned attic, the 218 m Latin cross
## behind it, the 16-ribbed double dome on its columned drum with the
## lantern, ball and cross, two small corner domes, and the two curving
## colonnades round the obelisk.
static func peters(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D6CAAE", 4.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E7DDC6", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4338", 3.0))
	lm.use("Dome", LandmarkMaterials.pbr("concrete", "#A0A5A6", 3.0, 0.55, 0.3))
	lm.use("Steps", LandmarkMaterials.pbr("stone", "#BDB4A2", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	# Latin cross: nave and choir arm, transept with rounded ends.
	lm.box("Stone", Vector3(21.0, 22.0, 0), Vector3(182.0, 44.0, 58.0))
	lm.box("Stone", Vector3(0, 22.0, 0), Vector3(40.0, 44.0, 116.0))
	for s in [-1.0, 1.0]:
		lm.frustum("Stone", Vector3(0, 0, s * 58.0), 20.0, 20.0, 44.0, 16)
	lm.frustum("Stone", Vector3(-70.0, 0, 0), 29.0, 29.0, 44.0, 20)
	lm.box("Trim", Vector3(21.0, 44.6, 0), Vector3(183.0, 1.2, 59.0))
	for s in [-1.0, 1.0]:
		SEuUtil.face_row(lm, "Shadow", Vector3(21.0, 0, s * 29.05), Vector3.RIGHT, Vector3(0, 0, s),
			22.0, 14, 11.0, 2.6, 8.0)
		SEuUtil.face_row(lm, "Shadow", Vector3(21.0, 0, s * 29.05), Vector3.RIGHT, Vector3(0, 0, s),
			8.0, 14, 11.0, 2.4, 6.0)
	_facade(lm)
	# Dome: square-to-round plinth, columned drum, ribbed shell, lantern.
	lm.frustum("Stone", Vector3(0, 44.0, 0), 24.5, 24.5, 14.0, 24)
	lm.frustum("Stone", Vector3(0, 58.0, 0), 21.8, 21.8, 30.0, 32)
	SEuUtil.ring_openings(lm, "Shadow", Vector3.ZERO, 21.8, 32, 16, 66.0, 2.6, 9.0, false, PI / 16.0)
	SEuUtil.column_ring(lm, "Trim", Vector3(0, 60.0, 0), 22.4, 32, 26.0, 0.6, 8, PI / 32.0)
	lm.frustum("Trim", Vector3(0, 88.0, 0), 23.4, 23.4, 2.2, 32)
	var shell := SEuUtil.ogive(21.8, 26.0, 12)
	lm.lathe("Dome", Vector3(0, 90.2, 0), shell, 32)
	for k in 16:
		var a := TAU * float(k) / 16.0
		for j in shell.size() - 2:
			lm.beam("Trim", Vector3(cos(a) * shell[j].x, 90.2 + shell[j].y, sin(a) * shell[j].x),
				Vector3(cos(a) * shell[j + 1].x, 90.2 + shell[j + 1].y, sin(a) * shell[j + 1].x),
				1.0, 0.7)
	var ly := 116.2
	SEuUtil.column_ring(lm, "Trim", Vector3(0, ly, 0), 3.6, 16, 9.0, 0.3, 6)
	lm.frustum("Stone", Vector3(0, ly + 9.0, 0), 4.2, 4.0, 1.0, 16)
	lm.lathe("Dome", Vector3(0, ly + 10.0, 0), SEuUtil.dome(4.0, 3.6, 6), 16)
	SEuUtil.finial(lm, "Gold", Vector3(0, ly + 13.6, 0), 136.6 - ly - 13.6)
	# Two corner domes over the chapels.
	for sx in [-1.0, 1.0]:
		LandmarkKits.dome_on_drum(lm, "Stone", "Dome", Vector3(sx * 40.0, 44.0, 22.0), 7.0, 7.0,
			8.0, 4.0, 16)
		LandmarkKits.dome_on_drum(lm, "Stone", "Dome", Vector3(sx * 40.0, 44.0, -22.0), 7.0, 7.0,
			8.0, 4.0, 16)
	_piazza(lm)
	lm.commit(model)

## Maderno's facade (x = 112..120) with its stair and attic.
static func _facade(lm: LandmarkMesh) -> void:
	lm.box("Stone", Vector3(116.0, 24.0, 0), Vector3(8.0, 48.0, 115.0))
	lm.box("Trim", Vector3(120.4, 30.0, 0), Vector3(1.0, 4.0, 90.0))
	SEuUtil.column_row(lm, "Trim", Vector3(121.5, 1.0, -43.0), Vector3(121.5, 1.0, 43.0), 8, 28.0, 1.5, 12)
	lm.box("Stone", Vector3(118.0, 0.5, 0), Vector3(10.0, 1.0, 100.0))
	for s in [-1.0, 1.0]:
		SEuUtil.face_row(lm, "Shadow", Vector3(120.1, 0, s * 49.0), Vector3(0, 0, 1), Vector3.RIGHT,
			8.0, 2, 8.5, 3.0, 7.0)
	SEuUtil.face_row(lm, "Shadow", Vector3(120.15, 0, 0), Vector3(0, 0, 1), Vector3.RIGHT,
		34.0, 11, 8.0, 3.2, 6.5)
	SEuUtil.face_row(lm, "Shadow", Vector3(120.15, 0, 0), Vector3(0, 0, 1), Vector3.RIGHT,
		6.0, 5, 12.0, 4.0, 10.0)
	lm.gable("Trim", Vector3(116.0, 51.0, 0), 24.0, 4.0, 4.0, Basis(Vector3.UP, PI * 0.5), 0.4, "Trim")
	lm.box("Trim", Vector3(116.0, 49.5, 0), Vector3(9.5, 3.0, 116.0))
	for i in 13:
		var z := -54.0 + 9.0 * float(i)
		LandmarkKits.statue_figure(lm, "Trim", Vector3(116.0, 51.0, z), 5.5)
	SEuUtil.steps_up(lm, "Steps", Vector3(122.0, 0, 0), Vector3.RIGHT, 100.0, 1.6, 0.18, 6)

## Bernini's two colonnade arms round the oval, and the obelisk.
static func _piazza(lm: LandmarkMesh) -> void:
	var ex := 250.0
	var a := 96.0
	var b := 118.0
	for sz in [-1.0, 1.0]:
		for off in [-8.0, 0.0, 8.0]:
			var prev := Vector3.ZERO
			var carry := 0.0
			for k in 41:
				var t := lerpf(-1.2, 1.35, float(k) / 40.0)
				var p := Vector3(ex + (a + off) * sin(t), 0, sz * (b + off) * cos(t))
				if k > 0:
					carry += prev.distance_to(p)
					if off != 0.0:
						while carry >= 5.5:
							carry -= 5.5
							lm.frustum("Trim", p, 0.75, 0.62, 14.0, 6)
					else:
						lm.beam("Stone", prev + Vector3(0, 16.0, 0), p + Vector3(0, 16.0, 0), 18.0, 4.0)
						lm.beam("Trim", prev + Vector3(0, 18.6, 0), p + Vector3(0, 18.6, 0), 18.6, 1.2)
				prev = p
		# Straight arm from the facade corner to the oval.
		var q0 := Vector3(126.0, 16.0, sz * 57.0)
		var q1 := Vector3(ex + a * sin(-1.2), 16.0, sz * b * cos(-1.2))
		lm.beam("Stone", q0, q1, 18.0, 4.0)
		for i in 7:
			var p := q0.lerp(q1, float(i) / 6.0)
			for off in [-8.0, 8.0]:
				lm.frustum("Trim", Vector3(p.x, 0, p.z + off), 0.75, 0.62, 14.0, 6)
	lm.box("Stone", Vector3(ex, 1.5, 0), Vector3(8.0, 3.0, 8.0))
	lm.spire("Stone", Vector3(ex, 3.0, 0), 1.9, 21.0, 1.25)
	lm.spire("Trim", Vector3(ex, 24.0, 0), 1.25, 1.7)
	SEuUtil.finial(lm, "Gold", Vector3(ex, 25.7, 0), 2.4)

# --- Pantheon ---------------------------------------------------------

## Origin at the centre of the rotunda; the portico faces north (-Z).
## 43.3 m outer diameter and height: the brick drum with its cornice and
## stepped rings, the unreinforced concrete dome with its open oculus,
## and the sixteen-column granite porch under a pediment.
static func pantheon(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9C6E52", 3.0))
	lm.use("Dome", LandmarkMaterials.pbr("concrete", "#9B9486", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8C8B87", 2.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#D9CDB4", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A65A3E", 2.0))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#6C5A3C", 2.0, 0.4, 0.7))
	var r := 21.65
	var yc := 21.65
	var prof := PackedVector2Array([Vector2(r, -3.0), Vector2(r, 21.65), Vector2(r + 0.5, 21.65),
		Vector2(r + 0.5, 23.0), Vector2(r, 23.0), Vector2(r, 25.0), Vector2(r - 0.8, 25.0),
		Vector2(r - 0.8, 27.0), Vector2(r - 1.5, 27.0), Vector2(r - 1.5, 29.0)])
	lm.lathe("Brick", Vector3.ZERO, prof, 40, 1.0, 1.0, 0.0, false, false)
	var dprof := PackedVector2Array()
	for i in 9:
		var y := lerpf(29.0, 42.9, float(i) / 8.0)
		dprof.append(Vector2(sqrt(maxf(21.7 * 21.7 - (y - yc) * (y - yc), 0.0)), y))
	dprof.append(Vector2(4.35, 43.3))
	lm.lathe("Dome", Vector3.ZERO, dprof, 40, 1.0, 1.0, 0.0, true, false)
	lm.frustum("Bronze", Vector3(0, 42.9, 0), 4.9, 4.9, 0.4, 24)
	# Blind arches round the lower wall.
	SEuUtil.ring_openings(lm, "Dome", Vector3.ZERO, r, 40, 16, 3.0, 3.2, 9.0, false, 0.2)
	# Prothyrum block and portico (front to -Z).
	var z0 := -(r + 8.0)
	lm.box("Brick", Vector3(0, 11.0, z0 + 5.0), Vector3(24.0, 22.0, 18.0))
	lm.gable("Tile", Vector3(0, 22.0, z0 + 5.0), 24.0, 18.0, 6.0, Basis(), 0.4, "Brick")
	lm.box("Trim", Vector3(0, 0.6, z0 - 7.0), Vector3(37.0, 1.2, 25.0))
	var zf := z0 - 14.4
	var cols := PackedVector2Array()
	for i in 8:
		cols.append(Vector2(-14.7 + 4.2 * float(i), zf))
	for row in 2:
		for x in [-6.3, -2.1, 2.1, 6.3]:
			cols.append(Vector2(x, zf + 5.0 + 5.0 * float(row)))
	for c in cols:
		lm.frustum("Granite", Vector3(c.x, 1.2, c.y), 0.78, 0.66, 11.9, 12)
		lm.frustum("Trim", Vector3(c.x, 13.1, c.y), 0.78, 0.92, 1.0, 12)
	lm.box("Trim", Vector3(0, 15.1, z0 - 7.4), Vector3(35.4, 2.0, 24.0))
	lm.gable("Tile", Vector3(0, 16.1, z0 - 7.4), 34.0, 24.0, 5.4, Basis(), 0.5, "Trim")
	lm.commit(model)
