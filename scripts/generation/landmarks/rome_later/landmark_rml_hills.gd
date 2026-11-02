class_name LandmarkRmLHills
extends RefCounted

## Piazza del Campidoglio and the Quirinal Palace with its piazza, in
## true metres.

# --- Capitoline Hill ------------------------------------------------------

## Origin at Michelangelo's piazza, over the equestrian Marcus Aurelius;
## y = 0 is the foot of the Cordonata and the piazza paving lies at 8 m
## on a stone platform, with the oval and its twelve-pointed star raised
## in the middle. Palazzo Senatorio closes the -Z end (rusticated base,
## double stair with the river gods and Dea Roma, giant Corinthian
## pilasters, statues on the balustrade and Longhi's campanile, 50 m);
## Palazzo Nuovo (-X) and Palazzo dei Conservatori (+X) face each other
## across the square: seven bays of giant Corinthian pilasters over an
## open portico of Ionic columns, windows under segmental pediments and
## a balustrade with statues. The Cordonata climbs from +Z between the
## basalt lions and the Dioscuri, with the balustrade of trophies and
## statues along the top.
static func capitoline(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D3C29E", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E7DCC4", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4136", 3.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#B98F66", 4.0))
	lm.use("Steps", LandmarkMaterials.pbr("limestone", "#CFC2A6", 2.0))
	lm.use("Bronze", LandmarkMaterials.paint("#5B6B50", 0.5, 0.5))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EDE8DC", 2.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A65A3E", 2.0))
	lm.use("Dome", LandmarkMaterials.pbr("concrete", "#8E9291", 3.0, 0.55, 0.3))
	var py := 8.0
	lm.box("Stone", Vector3(0, py * 0.5 - 0.1, -22.0), Vector3(92.0, py - 0.2, 100.0))
	lm.box("Steps", Vector3(0, py - 0.1, -22.0), Vector3(92.0, 0.2, 100.0))
	# The oval: three shallow steps up to the star-paved convex floor.
	for k in 3:
		var rr := 26.0 - 1.2 * float(k)
		lm.lathe("Steps", Vector3(0, py + 0.15 * float(k), 0), PackedVector2Array([Vector2(rr, 0.0), Vector2(rr, 0.15)]),
			40, 0.72, 1.0)
	lm.lathe("Steps", Vector3(0, py + 0.45, 0), PackedVector2Array([Vector2(23.6, 0.0), Vector2(16.0, 0.2),
		Vector2(6.0, 0.35), Vector2(0.0, 0.38)]), 40, 0.72, 1.0)
	for k in 24:
		var a := TAU * float(k) / 24.0
		var rr := 3.0 if k % 2 == 0 else 22.0
		var a1 := TAU * float(k + 1) / 24.0
		var rn := 22.0 if k % 2 == 0 else 3.0
		lm.beam("Trim", Vector3(cos(a) * rr * 0.72, py + 0.5, sin(a) * rr), Vector3(cos(a1) * rn * 0.72, py + 0.5, sin(a1) * rn),
			0.25, 0.06, Vector3.UP)
	# Cordonata with balustrades, the Dioscuri at the top, lions at the foot.
	LandmarkRmLUtil.flight(lm, "Steps", 0.0, 15.0, 78.0, 28.0, 0.2, py, 34)
	for s in [-1.0, 1.0]:
		LandmarkRmLKit.balustrade(lm, "Trim", Vector3(s * 8.0, 0.4, 78.0), Vector3(s * 8.0, py + 0.2, 28.0), 1.1, 5.0, 0.7)
		LandmarkRmLKit.balustrade(lm, "Trim", Vector3(s * 9.5, py, 27.8), Vector3(s * 46.0, py, 27.8), 1.1, 4.0)
		lm.box("Marble", Vector3(s * 10.8, py + 0.5, 30.0), Vector3(3.2, 1.0, 5.4))
		LandmarkRmLUtil.horse(lm, "Marble", Vector3(s * 10.8, py + 1.0, 30.0))
		LandmarkKits.statue_figure(lm, "Marble", Vector3(s * 9.4, py + 1.0, 28.8), 5.0)
		# Trophies of Marius, Constantine and his son, milestones.
		LandmarkRmLKit.statue_row(lm, "Marble", Vector3(s * 15.0, py + 1.1, 27.8), Vector3(s * 26.0, py + 1.1, 27.8), 3, 3.2, "Trim")
		lm.box("Bronze", Vector3(s * 9.0, 1.1, 77.0), Vector3(1.6, 1.2, 3.0))
		lm.box("Bronze", Vector3(s * 9.0, 1.8, 78.3), Vector3(1.0, 1.0, 1.0))
		lm.box("Stone", Vector3(s * 9.0, 0.25, 77.0), Vector3(2.2, 0.5, 3.8))
	# Marcus Aurelius on his pedestal.
	lm.box("Marble", Vector3(0, py + 0.5 + 1.5, 0), Vector3(3.4, 3.0, 6.4))
	lm.box("Marble", Vector3(0, py + 3.6, 0), Vector3(3.8, 0.4, 6.8), Basis(), 0.0)
	lm.box("Marble", Vector3(0, py + 0.65, 0), Vector3(4.0, 0.4, 7.0), Basis(), 0.0)
	LandmarkRmLUtil.horse(lm, "Bronze", Vector3(0, py + 3.8, 0))
	LandmarkKits.statue_figure(lm, "Bronze", Vector3(0, py + 6.2, -0.2), 2.4, true)
	_senatorio(lm, py)
	for s in [-1.0, 1.0]:
		_side_palace(lm, py, s)
	lm.commit(model)

## Palazzo Nuovo (s = -1) or dei Conservatori (s = +1): 40 m front on
## the line x = 22 s facing the piazza, 21 m to the balustrade.
static func _side_palace(lm: LandmarkMesh, py: float, s: float) -> void:
	var n := Vector3(-s, 0, 0)
	var r := Vector3.UP.cross(n)
	var fx := s * 22.0
	var w := 40.0
	var h := 20.0
	var o := Vector3(fx, py, -22.0) - r * w * 0.5
	# Upper storey to the front line, the portico 4 m deep beneath it.
	lm.box("Stone", Vector3(s * 33.0, py + 8.4 + (h - 8.4) * 0.5, -22.0), Vector3(22.0, h - 8.4, w))
	lm.box("Stone", Vector3(s * 35.0, py + 4.2, -22.0), Vector3(18.0, 8.4, w))
	lm.box("Shadow", Vector3(s * 25.95, py + 3.8, -22.0), Vector3(0.1, 7.6, w - 1.0), Basis(), 0.0)
	var bay := w / 7.0
	# Giant pilasters on pedestals, eight of them, carrying the
	# entablature; Ionic columns of the portico between them.
	for i in 8:
		var p := o + r * bay * float(i)
		lm.box("Stone", p + Vector3(0, 0.8, 0) + n * 0.3, Vector3(1.9, 1.6, 2.2), Basis(r, Vector3.UP, n))
		LandmarkRmLKit.pilaster(lm, "Trim", p + Vector3(0, 1.6, 0), r, n, 1.5, h - 3.6, 0.5)
	for i in 7:
		for t in [0.25, 0.75]:
			var p := o + r * bay * (float(i) + float(t)) + n * 0.6
			LandmarkRmLKit.column_ionic(lm, "Trim", p, 0.38, 7.4, n)
	LandmarkRmLKit.entablature(lm, "Trim", o + Vector3(0, 7.4, 0), o + r * w + Vector3(0, 7.4, 0), n, 1.2, 0.9)
	LandmarkRmLKit.entablature(lm, "Trim", o + Vector3(0, h - 2.0, 0) - r * 0.6, o + r * (w + 0.6) + Vector3(0, h - 2.0, 0), n, 2.0, 0.8, true)
	# Piano nobile windows: segmental pediments on paired columns, the
	# centre one wider with a balcony.
	for i in 7:
		var c := o + r * bay * (float(i) + 0.5) + Vector3(0, 10.2, 0)
		var ww := 2.6 if i == 3 else 2.0
		lm.box("Shadow", c + Vector3(0, 2.3, 0) + n * 0.05, Vector3(ww, 4.6, 0.1), Basis(r, Vector3.UP, n), 0.0)
		LandmarkRmLKit.frame_opening(lm, "Trim", c + n * 0.1, r, n, ww, 4.6, 4)
		for sd in [-1.0, 1.0]:
			lm.box("Trim", c + r * float(sd) * (ww * 0.5 + 0.55) + Vector3(0, 2.3, 0) + n * 0.25, Vector3(0.35, 4.6, 0.35),
				Basis(r, Vector3.UP, n), 0.0)
		LandmarkRmLKit.balustrade(lm, "Trim", c - r * (ww * 0.5 + 0.6) + n * 0.6 - Vector3(0, 0.9, 0),
			c + r * (ww * 0.5 + 0.6) + n * 0.6 - Vector3(0, 0.9, 0), 0.8, 4.0)
	LandmarkRmLKit.balustrade(lm, "Trim", o + Vector3(0, h, 0) + n * 0.4, o + r * w + Vector3(0, h, 0) + n * 0.4, 1.2, bay)
	for i in 8:
		LandmarkKits.statue_figure(lm, "Marble", o + r * bay * float(i) + Vector3(0, h + 1.2, 0) + n * 0.4, 3.2, i % 2 == 0)
	lm.gable("Tile", Vector3(s * 33.0, py + h, -22.0), 18.0, w, 2.2, Basis(), 0.3)

## Palazzo Senatorio at z = -42 with the Campanile above its centre.
static func _senatorio(lm: LandmarkMesh, py: float) -> void:
	var n := Vector3(0, 0, 1)
	var r := Vector3.RIGHT
	lm.box("Stone", Vector3(0, py + 4.8, -57.0), Vector3(48.0, 9.6, 30.0))
	# Rustication: horizontal channelled courses on the base.
	for k in 8:
		lm.box("Stone", Vector3(0, py + 0.6 + 1.2 * float(k), -41.95), Vector3(48.0, 0.9, 0.1), Basis(), 0.0)
	lm.box("Plaster", Vector3(0, py + 17.8, -57.0), Vector3(48.0, 16.4, 30.0))
	lm.gable("Tile", Vector3(0, py + 26.8, -57.0), 30.0, 48.0, 2.6, Basis(Vector3.UP, PI * 0.5), 0.5, "Plaster")
	var o := Vector3(-24.0, py + 9.6, -42.0)
	LandmarkRmLKit.pilaster_row(lm, "Trim", o + r * 0.8, r, n, 46.4, 9, 1.4, 15.0, 0.6)
	LandmarkRmLKit.windows(lm, "Plaster", "Shadow", "Trim", o + r * 0.8, r, n, 46.4, 15.0, 8, 2, Vector2(2.0, 4.2), 1.6, 7.6, 2)
	LandmarkRmLKit.entablature(lm, "Trim", o + Vector3(0, 15.0, 0) - r * 0.4, o + r * 48.4 + Vector3(0, 15.0, 0), n, 1.6, 0.8, true)
	LandmarkRmLKit.balustrade(lm, "Trim", o + Vector3(0, 16.6, 0.6), o + r * 48.0 + Vector3(0, 16.6, 0.6), 1.2, 5.8)
	LandmarkRmLKit.statue_row(lm, "Marble", o + r * 0.8 + Vector3(0, 17.8, 0.6), o + r * 47.2 + Vector3(0, 17.8, 0.6), 9, 3.0)
	SEuUtil.face_row(lm, "Shadow", Vector3(0, py, -42.0), Vector3.RIGHT, Vector3(0, 0, 1), 1.5, 8, 5.6, 1.4, 2.4)
	# Michelangelo's double ramp meeting at the central landing, with
	# its balustrades, the river gods and Dea Roma's fountain niche.
	for s in [-1.0, 1.0]:
		for k in 14:
			var hh := 9.6 * float(k + 1) / 14.0
			lm.box("Steps", Vector3(s * (18.5 - (float(k) + 0.5) * 15.0 / 14.0), py + hh * 0.5, -40.2),
				Vector3(15.0 / 14.0, hh, 3.6))
		LandmarkRmLKit.balustrade(lm, "Trim", Vector3(s * 19.0, py + 0.2, -38.4), Vector3(s * 3.5, py + 9.8, -38.4), 1.0, 3.8)
		LandmarkKits.statue_figure(lm, "Marble", Vector3(s * 9.5, py + 0.3, -37.0), 3.0)
		lm.box("Marble", Vector3(s * 9.5, py + 0.6, -36.5), Vector3(5.0, 1.2, 2.0))
	lm.box("Steps", Vector3(0, py + 4.8, -40.2), Vector3(7.0, 9.6, 3.6))
	LandmarkRmLKit.balustrade(lm, "Trim", Vector3(-3.5, py + 9.6, -38.4), Vector3(3.5, py + 9.6, -38.4), 1.0, 3.5)
	LandmarkRmLKit.arcade(lm, "Stone", "Shadow", Vector3(-2.0, py, -38.4), r, n, 4.0, 6.0, 1, 2.8, 3.0, 0.5)
	LandmarkKits.statue_figure(lm, "Marble", Vector3(0, py + 0.6, -38.2), 3.6)
	lm.lathe("Marble", Vector3(0, py, -36.0), PackedVector2Array([Vector2(2.4, 0.0), Vector2(2.5, 0.8),
		Vector2(2.1, 0.8), Vector2(2.1, 0.5)]), 20, 1.4, 0.7, 0.0, true, false)
	LandmarkRmLUtil.tower(lm, "Plaster", Vector3(0, py + 27.0, -57.0),
		PackedVector2Array([Vector2(5.5, 3.7), Vector2(5.5, 3.3)]), 15.0)
	lm.disc("Trim", Vector3(0, py + 29.8, -53.25), n, 1.3, 20)
	lm.disc("Shadow", Vector3(0, py + 29.8, -53.2), n, 1.05, 20)

# --- Quirinal Palace ------------------------------------------------------

## Origin between the palace and the Dioscuri fountain; the palace faces
## the piazza along +Z (yaw_deg turns it onto the hill). The 110 m front
## in three storeys of framed windows under a tiled roof; Maderno's
## portal with its columns and Bernini's Loggia of the Blessings over
## it (statues of Peter and Paul, the Madonna in the lunette); the
## Torrino (1626 clock tower, 38 m) at the west corner. In the piazza
## the Quirinal obelisk (14.64 m shaft, 28.94 m in all) between the
## colossal Dioscuri and their horses over the granite basin.
static func quirinal(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#D4B57C", 4.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E7DCC4", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4136", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A65A3E", 2.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EDE8DC", 2.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#9B5B4B", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CDBE9E", 3.0))
	lm.use("Dome", LandmarkMaterials.pbr("concrete", "#8E9291", 3.0, 0.55, 0.3))
	lm.use("Water", LandmarkMaterials.glass("#2A6C78"))
	lm.use("Gold", LandmarkMaterials.gold())
	var n := Vector3(0, 0, 1)
	var r := Vector3.RIGHT
	LandmarkRmLUtil.block(lm, "Plaster", Vector3(-45.0, 0, -51.0), 110.0, 22.0, 22.0, n, 3, 21, 1.6, 3.2, "", 2)
	lm.gable("Tile", Vector3(-45.0, 23.0, -51.0), 22.0, 110.0, 3.5, Basis(Vector3.UP, PI * 0.5), 0.6, "Plaster")
	# Portal: rusticated surround, two columns, entablature, the loggia
	# balcony and its pediment with the statues.
	var pc := Vector3(-45.0, 0, -39.6)
	lm.box("Stone", pc + Vector3(0, 5.0, -0.2), Vector3(9.0, 10.0, 0.6))
	for k in 6:
		lm.box("Stone", pc + Vector3(0, 0.8 + 1.5 * float(k), 0.15), Vector3(7.4, 1.1, 0.2), Basis(), 0.0)
	lm.box("Shadow", pc + Vector3(0, 3.4, 0.27), Vector3(3.4, 6.8, 0.1), Basis(), 0.0)
	LandmarkDetail.arch(lm, "Stone", pc + Vector3(0, 5.1, 0.25), n, 3.4, 0.7, 0.4)
	for s in [-1.0, 1.0]:
		LandmarkRmLKit.column_ionic(lm, "Trim", pc + Vector3(s * 3.6, 0, 1.2), 0.5, 8.6, n)
		LandmarkKits.statue_figure(lm, "Marble", pc + Vector3(s * 3.4, 11.3, 1.0), 3.0)
	LandmarkRmLKit.entablature(lm, "Trim", pc + Vector3(-4.6, 8.6, 0.6), pc + Vector3(4.6, 8.6, 0.6), n, 1.4, 1.4)
	LandmarkRmLKit.balustrade(lm, "Trim", pc + Vector3(-4.4, 10.0, 1.6), pc + Vector3(4.4, 10.0, 1.6), 1.1, 2.9)
	lm.box("Shadow", pc + Vector3(0, 12.8, 0.05), Vector3(2.4, 3.4, 0.1), Basis(), 0.0)
	LandmarkRmLKit.frame_opening(lm, "Trim", pc + Vector3(0, 11.1, 0.1), r, n, 2.4, 3.4, 4)
	LandmarkKits.statue_figure(lm, "Marble", pc + Vector3(0, 15.6, 0.4), 1.8)
	# The Torrino at the west corner: two storeys of the palace, the
	# clock stage and the belvedere loggia, a cupola and cross.
	var tc := Vector3(-95.0, 0, -45.0)
	lm.box("Plaster", tc + Vector3(0, 13.0, 0), Vector3(10.0, 26.0, 10.0))
	for s in [-1.0, 1.0]:
		for t in [-1.0, 1.0]:
			LandmarkRmLKit.quoins(lm, "Trim", tc + Vector3(s * 5.0, 0, t * 5.0), Vector3(0, 0, t), Vector3(s, 0, 0), 22.6, 26.0)
	lm.box("Trim", tc + Vector3(0, 26.3, 0), Vector3(11.0, 0.6, 11.0))
	lm.disc("Trim", tc + Vector3(0, 24.4, 5.05), n, 1.4, 24)
	lm.disc("Shadow", tc + Vector3(0, 24.4, 5.08), n, 1.15, 24)
	var bt := tc + Vector3(0, 26.6, 0)
	lm.box("Plaster", bt + Vector3(0, 3.0, 0), Vector3(6.0, 6.0, 6.0))
	for f in 4:
		var out := Vector3(0, 0, 1).rotated(Vector3.UP, PI * 0.5 * float(f))
		var fr := Vector3.UP.cross(out)
		LandmarkRmLKit.arcade(lm, "Plaster", "Shadow", bt + out * 3.0 - fr * 3.0, fr, out, 6.0, 6.0, 1, 2.6, 2.6, 0.4)
		for sd in [-1.0, 1.0]:
			LandmarkRmLKit.pilaster(lm, "Trim", bt + out * 3.4 + fr * float(sd) * 2.7, fr, out, 0.6, 6.0, 0.3)
	lm.box("Trim", bt + Vector3(0, 6.3, 0), Vector3(7.2, 0.6, 7.2))
	lm.lathe("Dome", bt + Vector3(0, 6.6, 0), SEuUtil.dome(2.8, 2.2, 6), 16)
	SEuUtil.finial(lm, "Gold", bt + Vector3(0, 8.8, 0), 2.6)
	# Piazza fountain: basin, pedestal, obelisk and the Dioscuri.
	var o := Vector3(43.5, 0, 35.6)
	var rim := PackedVector2Array([Vector2(5.4, 0.0), Vector2(5.5, 0.6), Vector2(5.3, 0.8), Vector2(5.4, 1.0),
		Vector2(4.6, 1.0), Vector2(4.6, 0.7)])
	lm.lathe("Granite", o, rim, 32, 1.0, 1.0, 0.0, true, false)
	lm.disc("Water", o + Vector3(0, 0.85, 0), Vector3.UP, 4.7, 32)
	LandmarkRmLKit.obelisk(lm, "Granite", "Stone", "Gold", o + Vector3(0, 0.6, 0), 10.0, 14.64, 0.85, 3.0)
	for s in [-1.0, 1.0]:
		lm.box("Stone", o + Vector3(s * 7.0, 1.0, 0), Vector3(3.2, 2.0, 6.2))
		lm.box("Stone", o + Vector3(s * 7.0, 2.1, 0), Vector3(3.5, 0.2, 6.5), Basis(), 0.0)
		LandmarkRmLUtil.horse(lm, "Marble", o + Vector3(s * 7.0, 2.2, -0.2))
		lm.beam("Marble", o + Vector3(s * 7.0, 4.0, 1.6), o + Vector3(s * 7.0, 5.6, 2.4), 0.5, 0.4)
		LandmarkKits.statue_figure(lm, "Marble", o + Vector3(s * 7.0 - s * 1.5, 2.2, 0.6), 5.6, true)
	lm.commit(model)
