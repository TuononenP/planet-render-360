class_name LandmarkFhHelsinkiSacred
extends RefCounted

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

## Four Helsinki churches in true metres: Uspenski Cathedral (red-brick
## Orthodox, gilded onions), Temppeliaukio (the copper dome in its rock),
## St John's (twin 74 m neo-Gothic spires) and Kallio Church (granite Art
## Nouveau tower). Footprints and part heights follow OpenStreetMap.

# --- Uspenski Cathedral ---------------------------------------------

## Gornostayev's cathedral (1868), red brick from the dismantled
## Bomarsund fortress, origin at the OSM footprint centre (+X east, +Z
## south). Parts follow the OSM 3D outline: the 15.5 m square crossing
## (walls 18 m) and its four gabled arms (eaves 15 m, ridges 21 m), the
## low corner chambers, the octagonal main drum under a green copper tent
## (39 m) carrying the large gilded onion (44 m) and cross (50 m), a
## small gilded onion on each arm ridge and eight green spired turrets at
## the re-entrant corners: 13 gilded domes for Christ and the apostles.
## The apse with its two round side towers faces east; the porch and the
## small bell tower with the 14th onion stand to the south.
static func uspenski(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8A4638", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#DAD3C3", 2.5))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#5F8F78", 2.0, 0.5, 0.3))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Rock", LandmarkMaterials.pbr("stone", "#827D74", 4.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	# Granite terrace on the Katajanokka rock and the plinth course.
	lm.box("Rock", Vector3(1.0, 0.35, 0.5), Vector3(36.0, 0.7, 46.0))
	var cc := Vector3(-1.3, 0, -7.0)
	# Crossing: walls to 18 m, a low copper roof under the drum.
	FhU.blk(lm, "Brick", cc.x, 0.7, cc.z, 15.5, 17.3, 15.6)
	FhU.blk(lm, "Trim", cc.x, 0.7, cc.z, 16.1, 0.9, 16.2)
	FhP.box_band(lm, "Brick", cc.x, cc.z, 15.5, 15.6, 17.4, 0.6, 0.25)
	FhU.hip(lm, "Copper", cc + Vector3(0, 18.0, 0), 16.0, 16.0, 4.0, 0.62)
	# Four arms [centre x, z, width across, depth out, outward normal].
	var arms := [[-0.7, 3.05, 14.8, 6.3, Vector3(0, 0, 1)], [-1.85, -17.1, 15.1, 6.2, Vector3(0, 0, -1)],
		[8.8, -7.6, 15.0, 6.2, Vector3(1, 0, 0)], [-11.15, -6.5, 15.0, 6.1, Vector3(-1, 0, 0)]]
	for arm in arms:
		var out: Vector3 = arm[4]
		var ax := absf(out.x) > 0.5
		var c := Vector3(float(arm[0]), 0, float(arm[1]))
		var across: float = arm[2]
		var depth: float = arm[3]
		var w := depth if ax else across
		var d := across if ax else depth
		FhU.blk(lm, "Brick", c.x, 0.7, c.z, w, 14.3, d)
		FhU.blk(lm, "Trim", c.x, 0.7, c.z, w + 0.6, 0.9, d + 0.6)
		# Gable over the arm, ridge along the arm axis at 21 m.
		var rb := Basis(Vector3.UP, PI * 0.5) if ax else Basis()
		lm.gable("Copper", c + Vector3(0, 15.0, 0) - out * 0.4, across, depth + 0.8, 6.0, rb, 0.45, "Brick")
		var right := Vector3.UP.cross(out).normalized()
		var face := c + out * depth * 0.5
		# Raking cornice of moulded brick up both gable edges, and a ridge finial.
		for s in [-1.0, 1.0]:
			lm.beam("Brick", face + right * (across * 0.5 + 0.2) * float(s) + Vector3(0, 15.0, 0) + out * 0.25,
				face + Vector3(0, 21.1, 0) + out * 0.25, 0.55, 0.5, right)
		FhP.arch_frieze(lm, "Brick", face - right * across * 0.5 + Vector3(0, 0, 0),
			face + right * across * 0.5, out, 14.6, 0.95, 0.2)
		# Corner lesenes, the triple window under a round head and the gable oculus.
		FhP.strips(lm, "Brick", face - right * (across * 0.5 - 0.5), face + right * (across * 0.5 - 0.5), out,
			0.7, 13.8, 4, 0.9, 0.3)
		FhP.win_row(lm, "Brick", "Glass", face - right * 4.2, face + right * 4.2, out, 4.2, 3, 1.5, 6.4, true, 0.3)
		LandmarkDetail.arch(lm, "Brick", face + Vector3(0, 11.6, 0), out, 9.6, 0.6, 0.35)
		LandmarkDetail.window(lm, "Brick", "Glass", face + Vector3(0, 17.0, 0) + out * 0.02, out, 1.6, 2.4, true)
		lm.disc("Glass", face + Vector3(0, 12.3, 0) + out * 0.06, out, 0.7, 12)
		# Portal steps on the west and south arms; side windows on the arm flanks.
		for s in [-1.0, 1.0]:
			var side := c + right * across * 0.5 * float(s)
			FhP.win_row(lm, "Brick", "Glass", side - out * depth * 0.3, side + out * depth * 0.3,
				right * float(s), 5.0, 1, 1.2, 4.4, true, 0.25)
		# Gilded onion on its brick drum astride the ridge.
		var dt := c + Vector3(0, 20.4, 0) - out * 0.4
		lm.frustum("Brick", dt, 1.3, 1.3, 2.6, 16)
		FhP.arcade(lm, "Brick", dt + out * 1.32 - right * 0.9, dt + out * 1.32 + right * 0.9, out, 0.4, 1.8, 2, 0.08)
		lm.frustum("Brick", dt + Vector3(0, 2.6, 0), 1.45, 1.4, 0.3, 16)
		FhP.onion(lm, "Gold", dt + Vector3(0, 2.9, 0), 1.05, 3.2, 8)
		FhP.orthodox_cross(lm, "Gold", dt + Vector3(0, 6.1, 0), 1.9)
	# Low corner chambers between the arms (skillion roofs at 14.7 m).
	for q in [[8.2, -17.55, 5.6, 5.5], [-11.95, -16.25, 5.7, 5.1], [9.15, 2.25, 5.5, 5.1], [-10.65, 3.55, 5.5, 5.5]]:
		var qx: float = q[0]
		var qz: float = q[1]
		FhU.blk(lm, "Brick", qx, 0.7, qz, float(q[2]), 12.0, float(q[3]))
		FhU.blk(lm, "Brick", qx, 12.4, qz, float(q[2]) + 0.4, 0.5, float(q[3]) + 0.4)
		FhU.hip(lm, "Copper", Vector3(qx, 12.9, qz), float(q[2]) + 0.3, float(q[3]) + 0.3, 1.8, 0.3)
		var sx := signf(qx - cc.x)
		var sz := signf(qz - cc.z)
		FhP.win_row(lm, "Brick", "Glass", Vector3(qx - 1.2, 0, qz + sz * float(q[3]) * 0.5),
			Vector3(qx + 1.2, 0, qz + sz * float(q[3]) * 0.5), Vector3(0, 0, sz), 5.0, 1, 1.1, 3.6, true)
		FhP.win_row(lm, "Brick", "Glass", Vector3(qx + sx * float(q[2]) * 0.5, 0, qz - 1.2),
			Vector3(qx + sx * float(q[2]) * 0.5, 0, qz + 1.2), Vector3(sx, 0, 0), 5.0, 1, 1.1, 3.6, true)
	# Eight octagonal corner turrets: arcaded top, green spire, small gilded onion.
	for p in [Vector2(-8.75, -19.4), Vector2(4.7, -20.35), Vector2(11.15, -14.5), Vector2(11.95, -1.3),
			Vector2(6.15, 5.5), Vector2(-7.1, 6.35), Vector2(-14.55, -12.8), Vector2(-13.6, 0.7)]:
		var tb := Vector3(p.x, 12.4, p.y)
		lm.frustum("Brick", tb, 1.5, 1.5, 5.6, 8, PI / 8.0)
		for k in 8:
			var a := TAU * (float(k) + 0.5) / 8.0
			var d := Vector3(cos(a), 0, sin(a))
			lm.box("Glass", tb + d * 1.36 + Vector3(0, 3.3, 0), Vector3(0.7, 2.0, 0.08), Basis.looking_at(d), 0.0)
			lm.box("Brick", tb + Vector3(cos(TAU * float(k) / 8.0), 0, sin(TAU * float(k) / 8.0)) * 1.5
				+ Vector3(0, 2.8, 0), Vector3(0.28, 5.6, 0.28), Basis(Vector3.UP, -TAU * float(k) / 8.0), 0.0)
		lm.frustum("Brick", tb + Vector3(0, 5.3, 0), 1.75, 1.75, 0.35, 8, PI / 8.0)
		lm.lathe("Copper", tb + Vector3(0, 5.65, 0), PackedVector2Array([Vector2(1.8, 0), Vector2(1.1, 1.2),
			Vector2(0.45, 3.0), Vector2(0.18, 3.9)]), 8, 1.0, 1.0, PI / 8.0, false)
		FhP.onion(lm, "Gold", tb + Vector3(0, 9.4, 0), 0.38, 1.3, 6, 10)
		FhP.orthodox_cross(lm, "Gold", tb + Vector3(0, 10.65, 0), 1.2)
	# Apse east: transverse gabled bay, the half-round sanctuary and its two round towers.
	FhU.blk(lm, "Brick", 13.2, 0.7, -7.7, 4.2, 9.3, 14.8)
	FhU.ridge_z(lm, "Copper", "Brick", Vector3(13.2, 10.0, -7.7), 4.2, 14.8, 3.0, 0.3)
	var ap := Vector3(12.8, 0.0, -7.65)
	lm.frustum("Brick", ap + Vector3(0, 0.7, 0), 5.3, 5.3, 11.3, 16)
	lm.frustum("Brick", ap + Vector3(0, 11.5, 0), 5.6, 5.6, 0.5, 16)
	lm.lathe("Copper", ap + Vector3(0, 12.0, 0), PackedVector2Array([Vector2(5.7, 0), Vector2(3.0, 2.6),
		Vector2(0.4, 4.0)]), 16)
	for k in 5:
		var a := -PI * 0.4 + PI * 0.2 * float(k)
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.window(lm, "Brick", "Glass", ap + d * 5.32 + Vector3(0, 6.6, 0), d, 1.2, 4.4, true)
		lm.box("Brick", ap + Vector3(cos(a + PI * 0.1), 0, sin(a + PI * 0.1)) * 5.4 + Vector3(0, 6.0, 0),
			Vector3(0.6, 10.6, 0.3), Basis.looking_at(Vector3(cos(a + PI * 0.1), 0, sin(a + PI * 0.1))))
	for p in [Vector3(12.15, 0, -15.9), Vector3(13.35, 0, 0.75)]:
		lm.frustum("Brick", p + Vector3(0, 0.7, 0), 1.7, 1.7, 6.6, 16)
		lm.frustum("Brick", p + Vector3(0, 7.1, 0), 1.9, 1.9, 0.3, 16)
		lm.lathe("Copper", p + Vector3(0, 7.4, 0), PackedVector2Array([Vector2(1.95, 0), Vector2(0.9, 1.0),
			Vector2(0.1, 1.6)]), 16)
		LandmarkDetail.window(lm, "Brick", "Glass", p + Vector3(1.72, 4.0, 0), Vector3(1, 0, 0), 0.7, 2.2, true)
	# Main drum, octagonal: arched windows between corner shafts, arcaded
	# cornice, then the green tent, the large gilded onion and the cross.
	var dr := cc + Vector3(0, 21.0, 0)
	lm.frustum("Brick", dr, 6.4, 6.4, 8.0, 8, PI / 8.0)
	lm.frustum("Brick", dr, 6.8, 6.75, 0.7, 8, PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var face_r := 6.4 * cos(PI / 8.0)
		LandmarkDetail.window(lm, "Brick", "Glass", dr + d * face_r + Vector3(0, 3.6, 0), d, 1.5, 4.4, true, 0.3)
		var cd := Vector3(cos(a + PI / 8.0), 0, sin(a + PI / 8.0))
		lm.box("Brick", dr + cd * 6.35 + Vector3(0, 4.0, 0), Vector3(0.8, 8.0, 0.8), Basis.looking_at(cd))
		var rt := Vector3.UP.cross(d).normalized()
		FhP.arch_frieze(lm, "Brick", dr + d * face_r - rt * 2.3, dr + d * face_r + rt * 2.3, d, 7.6, 0.8, 0.2)
	lm.frustum("Brick", dr + Vector3(0, 7.8, 0), 6.9, 7.0, 0.6, 8, PI / 8.0)
	lm.lathe("Copper", dr + Vector3(0, 8.4, 0), PackedVector2Array([Vector2(7.1, 0), Vector2(5.2, 2.4),
		Vector2(3.4, 5.2), Vector2(2.1, 7.8), Vector2(1.5, 9.6)]), 8, 1.0, 1.0, PI / 8.0, false)
	# Ribs down the tent's hips.
	for k in 8:
		var a := TAU * float(k) / 8.0 + PI / 8.0
		var d := Vector3(cos(a), 0, sin(a)) / cos(PI / 8.0)
		lm.beam("Copper", dr + Vector3(0, 8.4, 0) + d * 7.1, dr + Vector3(0, 18.0, 0) + d * 1.5, 0.3, 0.2)
	lm.frustum("Brick", dr + Vector3(0, 18.0, 0), 1.7, 1.6, 1.0, 16)
	FhP.onion(lm, "Gold", dr + Vector3(0, 19.0, 0), 2.05, 4.6, 12, 20)
	FhP.orthodox_cross(lm, "Gold", dr + Vector3(0, 23.5, 0), 5.5)
	# South porch with its crossed gables, then the bell tower over the door.
	FhU.blk(lm, "Brick", -0.9, 0.7, 11.4, 5.8, 5.8, 9.6)
	FhU.ridge_z(lm, "Copper", "Brick", Vector3(-0.9, 6.5, 11.4), 5.8, 9.6, 1.4, 0.3)
	FhU.ridge_x(lm, "Copper", "Brick", Vector3(-0.9, 6.5, 11.4), 8.0, 3.0, 1.4, 0.3)
	for s in [-1.0, 1.0]:
		FhP.win_row(lm, "Brick", "Glass", Vector3(-0.9 + s * 2.9, 0, 7.4), Vector3(-0.9 + s * 2.9, 0, 15.4),
			Vector3(s, 0, 0), 2.4, 2, 1.0, 2.8, true)
	var bt := Vector3(-0.1, 0, 19.05)
	FhU.blk(lm, "Brick", bt.x, 0.7, bt.z, 6.4, 8.7, 6.3)
	FhU.blk(lm, "Brick", bt.x, 9.2, bt.z, 6.8, 0.4, 6.7)
	FhU.hip(lm, "Copper", bt + Vector3(0, 9.6, 0), 6.7, 6.6, 1.0, 0.65)
	# Portal: stepped arched doorway with the steps down to the square.
	LandmarkDetail.arch(lm, "Brick", bt + Vector3(0, 4.2, 3.15), Vector3(0, 0, 1), 2.6, 0.45, 0.4)
	lm.quad("Glass", bt + Vector3(-1.3, 0.7, 3.17), bt + Vector3(1.3, 0.7, 3.17), bt + Vector3(1.3, 4.2, 3.17),
		bt + Vector3(-1.3, 4.2, 3.17), Vector3(0, 0, 1))
	FhP.strips(lm, "Brick", bt + Vector3(-3.0, 0, 3.15), bt + Vector3(3.0, 0, 3.15), Vector3(0, 0, 1), 0.7,
		8.5, 2, 0.8, 0.3)
	FhU.steps(lm, "Rock", bt + Vector3(0, 0, 3.2), Vector3(0, 0, 1), 4.6, 0.35, 0.18, 4)
	# Belfry: four open round arches, cornice, tent, onion and cross.
	var bf := bt + Vector3(0.05, 9.6, -0.3)
	FhU.blk(lm, "Brick", bf.x, bf.y, bf.z, 4.5, 5.3, 4.1)
	for face in FhP.faces(bf.x, bf.z, 4.5, 4.1):
		var fa: Vector3 = face[0]
		var fb: Vector3 = face[1]
		var fo: Vector3 = face[2]
		var m := (fa + fb) * 0.5
		lm.quad("Glass", m - fa.direction_to(fb) * 0.9 + Vector3(0, bf.y + 1.0, 0) + fo * 0.02,
			m + fa.direction_to(fb) * 0.9 + Vector3(0, bf.y + 1.0, 0) + fo * 0.02,
			m + fa.direction_to(fb) * 0.9 + Vector3(0, bf.y + 3.4, 0) + fo * 0.02,
			m - fa.direction_to(fb) * 0.9 + Vector3(0, bf.y + 3.4, 0) + fo * 0.02, fo)
		LandmarkDetail.arch(lm, "Brick", m + Vector3(0, bf.y + 3.4, 0), fo, 1.8, 0.3, 0.3)
	FhU.blk(lm, "Brick", bf.x, bf.y + 5.3, bf.z, 4.9, 0.5, 4.5)
	FhU.hip(lm, "Copper", bf + Vector3(0, 5.8, 0), 3.4, 3.2, 3.8, 0.12)
	FhP.onion(lm, "Gold", bf + Vector3(0, 9.4, 0), 0.75, 2.0, 8, 12)
	FhP.orthodox_cross(lm, "Gold", bf + Vector3(0, 11.3, 0), 1.8)
	lm.commit(model)

# --- Temppeliaukio Church -------------------------------------------

## The Rock Church (Timo and Tuomo Suomalainen, 1969), hewn into the
## granite outcrop with its floor at street level: from outside only the
## rough rock rim, the rubble walls built from the blasted stone and the
## 24 m copper dome show. The dome rests on 180 radial concrete beams
## with the glazed ring between them; the granite entrance building with
## its copper-roofed porch stands to the south. Origin at the OSM
## footprint centre, the dome axis at (-1, -5.5).
static func temppeliaukio(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Rock", LandmarkMaterials.pbr("cliff", "#8C8780", 4.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#7C9A86", 2.0, 0.45, 0.4))
	lm.use("Glass", LandmarkMaterials.glass("#3A4A52"))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#7E7B76", 3.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#9A9892", 3.0))
	var c := Vector3(-1.0, 0, -5.5)
	# Rock outcrop: an irregular rim of blasted granite rising to the dome.
	var rows: Array = []
	var radii := [23.5, 22.0, 20.0, 17.6, 15.2, 14.2]
	var hts := [0.0, 1.6, 3.2, 4.4, 5.0, 5.1]
	for j in radii.size():
		var row := PackedVector3Array()
		for i in 49:
			var a := TAU * float(i) / 48.0
			var n := 1.0 + 0.07 * sin(a * 5.0 + float(j)) + 0.05 * sin(a * 11.0 + 1.7 * float(j)) \
				+ 0.03 * sin(a * 23.0)
			var hn := float(hts[j]) * (1.0 + 0.12 * sin(a * 7.0 + float(j) * 0.7))
			row.append(c + Vector3(cos(a) * float(radii[j]) * n * 0.95, minf(hn, 5.1), sin(a) * float(radii[j]) * n * 1.1))
		rows.append(row)
	lm.grid("Rock", rows, c + Vector3(0, -20.0, 0), true)
	# Boulders strewn on the rim.
	for k in 16:
		var a := TAU * float(k) / 16.0 + 0.2
		var r := 17.0 + 3.0 * sin(float(k) * 2.1)
		lm.lathe("Rock", c + Vector3(cos(a) * r * 0.95, 3.0 + 0.6 * sin(float(k)), sin(a) * r * 1.1),
			FhU.ball(0.7 + 0.4 * absf(sin(float(k) * 1.3))), 7, 1.4, 1.0, float(k))
	# Rubble wall ringing the hall, laid from the blasted stone.
	lm.frustum("Rock", c + Vector3(0, 4.6, 0), 14.6, 14.2, 0.9, 40)
	for k in 60:
		var a := TAU * float(k) / 60.0
		lm.box("Granite", c + Vector3(cos(a), 0, sin(a)) * 14.4 + Vector3(0, 5.2 + 0.15 * sin(float(k) * 1.7), 0),
			Vector3(1.4, 0.55, 0.9), Basis(Vector3.UP, -a), 0.12)
	# Ring beam, the glazed band between 180 radial beams, the copper dome
	# with its concentric strips.
	lm.frustum("Concrete", c + Vector3(0, 5.5, 0), 13.8, 13.4, 0.6, 48)
	lm.frustum("Glass", c + Vector3(0, 6.1, 0), 12.9, 12.6, 0.8, 48)
	for k in 180:
		var a := TAU * float(k) / 180.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Concrete", c + d * 12.9 + Vector3(0, 6.5, 0), Vector3(0.12, 0.8, 1.6), Basis(Vector3.UP, -a), 0.0)
	lm.lathe("Copper", c + Vector3(0, 6.9, 0), PackedVector2Array([Vector2(13.4, 0), Vector2(12.0, 0.25),
		Vector2(9.5, 0.6), Vector2(6.5, 0.85), Vector2(3.5, 1.0), Vector2(0, 1.08)]), 48)
	for k in 9:
		var rr := 12.6 - 1.35 * float(k)
		var y := 6.9 + 1.08 * (1.0 - pow(rr / 13.4, 2.0)) + 0.02
		lm.frustum("Copper", c + Vector3(0, y, 0), rr, rr - 0.12, 0.05, 48)
	lm.frustum("Copper", c + Vector3(0, 7.95, 0), 1.2, 1.0, 0.08, 16)
	# Granite entrance building to the south, its copper-roofed porch and steps.
	FhU.blk(lm, "Granite", 7.0, 0.0, 19.5, 14.0, 4.6, 10.0)
	FhU.blk(lm, "Concrete", 7.0, 4.6, 19.5, 14.6, 0.5, 10.6)
	FhP.pierce(lm, "Granite", "Glass", Vector3(0.0, 0, 24.5), Vector3(14.0, 0, 24.5), Vector3(0, 0, 1), 0.0, 4.6, 5, 1,
		Vector2(1.6, 1.4), 2.4, 3.0, 0.25)
	lm.quad("Glass", Vector3(5.0, 0.0, 24.81), Vector3(9.0, 0.0, 24.81), Vector3(9.0, 3.2, 24.81),
		Vector3(5.0, 3.2, 24.81), Vector3(0, 0, 1))
	lm.box("Copper", Vector3(7.0, 3.6, 26.4), Vector3(7.0, 0.3, 3.6))
	for x in [4.0, 10.0]:
		lm.frustum("Concrete", Vector3(float(x), 0.0, 27.8), 0.2, 0.2, 3.45, 10)
	FhU.blk(lm, "Granite", -3.0, 0.0, 15.0, 6.0, 3.4, 4.0)
	lm.commit(model)
