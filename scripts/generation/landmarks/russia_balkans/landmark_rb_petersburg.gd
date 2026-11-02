class_name LandmarkRbPetersburg
extends RefCounted

## Two imperial landmarks of Saint Petersburg in true metres: the Winter
## Palace (the closed Baroque rectangle round its great court, pale green
## with white giant-order columns and 176 roof statues) and Saint Isaac's
## Cathedral (granite-columned porticoes, the gilded dome on its 24-column
## peristyle and four corner domes).

const WP_TOP := 30.0
const WP_EAVE := 22.0
const WP_BAYS := 5.3

## Origin at the palace centre; long (Neva) front along X, the Palace
## Square front facing +Z. Plan 212 x 170 m round a 124 x 105 m court.
static func winter_palace(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#7FB6A0", 4.0))
	lm.use("White", LandmarkMaterials.pbr("render", "#F0EDE2", 3.0))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#8A8478", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#667A70", 3.0, 0.6, 0.2))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Dome", LandmarkMaterials.pbr("slate", "#4E8A74", 3.0, 0.5, 0.3))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Four wings round the court: Palace Square (+Z), Neva (-Z), two sides.
	var wings := [[0.0, 67.5, 212.0, 35.0], [0.0, -70.0, 212.0, 30.0],
		[-84.0, -2.5, 44.0, 105.0], [84.0, -2.5, 44.0, 105.0]]
	for w in wings:
		var c := Vector3(float(w[0]), WP_EAVE * 0.5, float(w[1]))
		lm.box("Wall", c, Vector3(float(w[2]), WP_EAVE, float(w[3])))
		lm.box("Roof", c + Vector3(0, WP_EAVE * 0.5 + 0.6, 0), Vector3(float(w[2]) - 2.4, 1.2, float(w[3]) - 2.4))
	lm.box("Plinth", Vector3(0, 1.0, 85.5), Vector3(214.0, 2.0, 1.0))
	lm.box("Plinth", Vector3(0, 1.0, -85.5), Vector3(214.0, 2.0, 1.0))
	lm.box("Plinth", Vector3(106.5, 1.0, 0), Vector3(1.0, 2.0, 170.0))
	lm.box("Plinth", Vector3(-106.5, 1.0, 0), Vector3(1.0, 2.0, 170.0))
	# Outer fronts (the two long ones carry a central projecting gateway),
	# then the plainer court fronts.
	_wp_face(lm, Vector3(0, 0, 85.0), Vector3(0, 0, 1), 212.0, true, true)
	_wp_face(lm, Vector3(0, 0, -85.0), Vector3(0, 0, -1), 212.0, true, true)
	_wp_face(lm, Vector3(106.0, 0, 0), Vector3(1, 0, 0), 170.0, true, false)
	_wp_face(lm, Vector3(-106.0, 0, 0), Vector3(-1, 0, 0), 170.0, true, false)
	_wp_face(lm, Vector3(0, 0, 50.0), Vector3(0, 0, -1), 124.0, false, false)
	_wp_face(lm, Vector3(0, 0, -55.0), Vector3(0, 0, 1), 124.0, false, false)
	_wp_face(lm, Vector3(62.0, 0, -2.5), Vector3(-1, 0, 0), 105.0, false, false)
	_wp_face(lm, Vector3(-62.0, 0, -2.5), Vector3(1, 0, 0), 105.0, false, false)
	# The Great Church: green dome and gilded cross on the roof (30 m).
	var cb := Vector3(76.0, WP_EAVE + 1.2, 58.0)
	lm.frustum("White", cb, 4.2, 4.2, 2.8, 16)
	lm.frustum("White", cb + Vector3(0, 2.8, 0), 4.6, 4.6, 0.4, 16)
	lm.lathe("Dome", cb + Vector3(0, 3.2, 0), LandmarkRbParts.dome_profile(4.6, 2.0), 16)
	LandmarkRbParts.cross(lm, "Gilt", cb + Vector3(0, 5.2, 0), WP_TOP - cb.y - 5.2)
	lm.commit(model)

## One wall of the palace. `o` is the wall centre at ground, `out` its
## outward normal. Three window rows run between giant columns (pilasters
## on the court), under the entablature and a statue-crowned parapet.
## `gate` adds the 3 m deep central projection (seven bays wide) with
## its three-arched gateway.
static func _wp_face(lm: LandmarkMesh, o: Vector3, out: Vector3, length: float, outer: bool,
		gate: bool) -> void:
	var b := LandmarkRbParts.facing(out)
	var right := b.x
	var bays := roundi(length / WP_BAYS)
	if gate and bays % 2 == 0:
		bays += 1
	var pitch := length / float(bays)
	var gap := pitch * 3.5 if gate else 0.0
	var proj := 3.0
	for i in bays + 1:
		var s := (float(i) - float(bays) * 0.5) * pitch
		var off := proj if absf(s) < gap else 0.0
		var base := o + right * s + out * (off + 0.35) + Vector3(0, 7.4, 0)
		if outer:
			LandmarkRbParts.column(lm, "White", "White", base, 0.55, 12.1, 8)
			var top := o + right * s + out * (off + 1.7) + Vector3(0, WP_EAVE, 0)
			if off == 0.0:
				LandmarkRbParts.roof_statue(lm, "White", top, 3.0)
			else:
				LandmarkRbParts.urn(lm, "White", top, 3.4)
		else:
			lm.box("White", base + Vector3(0, 6.0, 0), Vector3(0.9, 12.1, 0.7), b)
		if i == bays:
			continue
		var sc := s + pitch * 0.5
		var in_gate := absf(sc) < gap
		var m := o + right * sc + out * (0.06 + (proj if in_gate else 0.0))
		var arch := in_gate and roundi(sc / pitch) % 2 == 0
		if arch:
			SEuUtil.opening(lm, "Windows", m + Vector3(0, 0.4, 0), right, Vector3.UP, 4.4, 10.5)
		else:
			LandmarkRbParts.pane(lm, "Windows", m + Vector3(0, 1.8, 0), right, out, 2.2, 4.4)
		for y in [8.3, 14.0]:
			LandmarkRbParts.pane(lm, "Windows", m + Vector3(0, y, 0), right, out, 2.2, 4.8)
	# String course, entablature and cornice; parapet on the street fronts.
	var ext := 2.2 if outer and absf(out.z) > 0.5 else 0.0
	lm.box("White", o + Vector3(0, 7.2, 0) + out * 0.25, Vector3(length, 0.5, 0.5), b)
	lm.box("White", o + Vector3(0, 20.45, 0) + out * 0.6, Vector3(length, 1.9, 1.2), b)
	lm.box("White", o + Vector3(0, 21.7, 0) + out * 1.1, Vector3(length + ext * 2.0, 0.6, 2.2), b)
	if gate:
		lm.box("Wall", o + Vector3(0, WP_EAVE * 0.5, 0) + out * (proj * 0.5), Vector3(gap * 2.0, WP_EAVE, proj), b)
		lm.box("White", o + Vector3(0, 20.45, 0) + out * (proj + 0.6), Vector3(gap * 2.0, 1.9, 1.2), b)
		lm.box("White", o + Vector3(0, 21.7, 0) + out * (proj + 1.1), Vector3(gap * 2.0 + 0.6, 0.6, 2.2), b)
	if outer:
		var half := length * 0.5 + ext
		var y := Vector3(0, WP_EAVE, 0) + out * 1.7
		if gate:
			LandmarkRbParts.parapet(lm, "White", o + y - right * half, o + y - right * gap, 1.1)
			LandmarkRbParts.parapet(lm, "White", o + y + right * gap, o + y + right * half, 1.1)
			LandmarkRbParts.parapet(lm, "White", o + y + out * proj - right * gap, o + y + out * proj + right * gap, 1.1)
		else:
			LandmarkRbParts.parapet(lm, "White", o + y - right * half, o + y + right * half, 1.1)

# --- Saint Isaac's Cathedral ---

const ISAAC_TOP := 101.5

## Origin at the dome axis. Greek cross on a 70 x 83 m block with four
## eight-column porticoes (north and south doubled), the gilded dome on a
## 24-column peristyle, four small corner domes; 111 x 98 m overall.
static func st_isaacs(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#B9B3A6", 4.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#CFCAC0", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#9A6256", 3.0))
	lm.use("Steps", LandmarkMaterials.pbr("stone", "#8E8A82", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#7B8680", 3.0, 0.6, 0.25))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var wall_h := 37.0
	lm.box("Wall", Vector3(0, wall_h * 0.5, 0), Vector3(70.0, wall_h, 83.0))
	lm.box("Marble", Vector3(0, wall_h + 0.7, 0), Vector3(72.4, 1.4, 85.4))
	lm.box("Roof", Vector3(0, wall_h + 1.6, 0), Vector3(66.0, 0.5, 79.0))
	# Four porticoes on a 1.8 m podium: two rows of eight 17 m granite
	# columns, entablature and pediment, with a flight of steps below.
	var faces := [[Vector3(0, 0, 1), 41.5, 6.0], [Vector3(0, 0, -1), 41.5, 6.0],
		[Vector3(1, 0, 0), 35.0, 7.0], [Vector3(-1, 0, 0), 35.0, 7.0]]
	for f in faces:
		var out: Vector3 = f[0]
		var pitch: float = f[2]
		var right := LandmarkRbParts.facing(out).x
		var span := 7.0 * pitch + 4.5
		var o := out * float(f[1]) + Vector3(0, 1.8, 0)
		lm.box("Steps", out * (float(f[1]) + 7.0) + Vector3(0, 0.9, 0), Vector3(span + 3.0, 1.8, 14.4), LandmarkRbParts.facing(out))
		LandmarkRbParts.portico(lm, "Granite", "Marble", o, out, 8, pitch, 2, 7.0, 0.9, 17.0, 3.2, 4.4)
		LandmarkRbParts.steps(lm, "Steps", out * (float(f[1]) + 14.2), out, span + 3.0, 0.9, 0.3, 6)
		for sgn in [-1.0, 1.0]:
			for row in [8.0, 24.0]:
				SEuUtil.opening(lm, "Windows", out * (float(f[1]) + 0.05) + right * sgn * (span * 0.5 + 4.5) + Vector3(0, row, 0),
					right, Vector3.UP, 2.6, 8.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Marble", Vector3(sx * 34.4, wall_h * 0.5, sz * 40.9), Vector3(2.6, wall_h, 2.6))
	# Dome stack: attic, peristyle drum, windowed drum, gilded dome, lantern.
	var d0 := wall_h + 2.0
	lm.frustum("Wall", Vector3(0, d0, 0), 18.5, 18.5, 4.0, 24)
	var base := d0 + 4.0
	LandmarkRbParts.peristyle(lm, "Granite", "Marble", Vector3(0, base, 0), 15.0, 24, 0.75, 14.0)
	lm.frustum("Wall", Vector3(0, base, 0), 13.4, 13.4, 14.0, 24)
	lm.frustum("Marble", Vector3(0, base + 14.0, 0), 16.4, 16.4, 2.6, 24)
	var dr := base + 16.6
	lm.frustum("Wall", Vector3(0, dr, 0), 13.0, 13.0, 6.5, 24)
	SEuUtil.ring_openings(lm, "Windows", Vector3(0, dr, 0), 13.0, 24, 12, 1.3, 2.0, 4.0, false, PI / 24.0)
	var dy := dr + 6.5
	lm.lathe("Gilt", Vector3(0, dy, 0), LandmarkRbParts.dome_profile(12.9, 21.5, 10), 32)
	var ly := dy + 21.5
	LandmarkRbParts.peristyle(lm, "Marble", "Marble", Vector3(0, ly, 0), 2.9, 8, 0.28, 6.5)
	lm.frustum("Wall", Vector3(0, ly + 6.5, 0), 3.5, 3.0, 0.8, 12)
	lm.lathe("Gilt", Vector3(0, ly + 7.3, 0), LandmarkRbParts.dome_profile(3.0, 2.2, 5), 12)
	LandmarkRbParts.cross(lm, "Gilt", Vector3(0, ly + 9.5, 0), ISAAC_TOP - ly - 9.5)
	# Corner bell-tower domes.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var c := Vector3(sx * 30.0, wall_h + 1.9, sz * 36.0)
			lm.box("Wall", c + Vector3(0, 3.0, 0), Vector3(9.0, 6.0, 9.0))
			LandmarkRbParts.peristyle(lm, "Granite", "Marble", c + Vector3(0, 6.0, 0), 3.6, 12, 0.3, 7.0)
			lm.frustum("Wall", c + Vector3(0, 6.0, 0), 3.0, 3.0, 7.0, 12)
			lm.frustum("Marble", c + Vector3(0, 13.0, 0), 4.2, 4.2, 0.8, 12)
			lm.lathe("Gilt", c + Vector3(0, 13.8, 0), LandmarkRbParts.dome_profile(3.8, 5.0, 6), 16)
			LandmarkRbParts.cross(lm, "Gilt", c + Vector3(0, 18.8, 0), 3.0)
	lm.commit(model)
