class_name SEuRomeCivic
extends RefCounted

## Castel Sant'Angelo, the Trevi Fountain and the Vittoriano in true
## metres.

# --- Castel Sant'Angelo ---------------------------------------------

const DRUM_Y := 16.0
const DRUM_TOP := 36.0

## Hadrian's Mausoleum (AD 123-139) turned papal fortress, origin at its
## axis: the square curtain wall (84 m) with the four round corner
## bastions of Nicholas V and Alexander VI, battlemented and corbelled;
## the drum 64 m across, its lower courses of travertine blocks and its
## brick upper storey under battlements; the papal apartments on top
## with the Loggia of Julius II facing the bridge (+X) and the Loggia of
## Paul III behind; the Angel terrace and Verschaffelt's bronze Archangel
## Michael (1753) at 48 m. Ponte Sant'Angelo (135 m, five arches, ten
## angels after Bernini, Peter and Paul at its far end) runs east; with
## no river pit under the model its deck is carried 7 m up on its piers
## and ramps down to the ground at both ends.
static func castel(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8F6A52", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CBB899", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4C4439", 3.0))
	lm.use("Bridge", LandmarkMaterials.pbr("limestone", "#BDAE92", 3.0))
	lm.use("Angel", LandmarkMaterials.paint("#5E6B4F", 0.5, 0.5))
	lm.use("Render", LandmarkMaterials.pbr("render", "#C9A27A", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#A65A3E", 2.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E6E0D2", 2.0))
	# Curtain walls round the square, battered at the foot.
	var hw := 42.0
	for k in 4:
		var bas := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := bas * Vector3(0, 0, 1)
		var rt := bas * Vector3(1, 0, 0)
		lm.box("Brick", out * (hw - 2.0) + Vector3(0, 8.0, 0), Vector3(hw * 2.0 - 16.0, 16.0, 4.0), bas)
		lm.box("Stone", out * (hw - 0.6) + Vector3(0, 1.5, 0), Vector3(hw * 2.0 - 16.0, 3.0, 1.6), bas)
		lm.box("Stone", out * (hw - 0.2) + Vector3(0, 13.0, 0), Vector3(hw * 2.0 - 16.0, 0.6, 0.8), bas)
		SEuUtil.crenels(lm, "Brick", out * (hw - 0.6) - rt * (hw - 8.0) + Vector3(0, 16.0, 0),
			out * (hw - 0.6) + rt * (hw - 8.0) + Vector3(0, 16.0, 0), 1.6, 1.6, 1.2)
		for i in 7:
			var x := -hw + 13.0 + (hw * 2.0 - 26.0) * float(i) / 6.0
			SEuParts.niche(lm, "Stone", "Shadow", out * hw + rt * x + Vector3(0, 7.0, 0), out, 1.0, 1.8,
				SEuParts.RECT, 0.2)
	# Main gate toward the bridge.
	SEuParts.niche(lm, "Stone", "Shadow", Vector3(hw, 0, 0), Vector3(1, 0, 0), 4.0, 6.5, SEuParts.ROUND, 0.6, 1.0, false)
	lm.box("Stone", Vector3(hw + 0.4, 8.6, 0), Vector3(1.0, 2.0, 7.0))
	# Round corner bastions: battered base, corbelled parapet, merlons.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var c := Vector3(sx * hw, 0, sz * hw)
			lm.frustum("Brick", c, 12.5, 11.0, 6.0, 32)
			lm.frustum("Brick", c + Vector3(0, 6.0, 0), 11.0, 11.0, 12.0, 32)
			lm.frustum("Stone", c + Vector3(0, 5.6, 0), 11.3, 11.3, 0.6, 32)
			for i in 24:
				var a := TAU * float(i) / 24.0
				var d := Vector3(cos(a), 0, sin(a))
				lm.box("Stone", c + d * 11.2 + Vector3(0, 17.4, 0), Vector3(0.6, 1.2, 0.8), Basis(Vector3.UP, atan2(d.x, d.z)), 0.0)
			lm.frustum("Brick", c + Vector3(0, 18.0, 0), 11.7, 11.7, 1.4, 32)
			for i in 16:
				var a := TAU * (float(i) + 0.5) / 16.0
				var d := Vector3(cos(a), 0, sin(a))
				lm.box("Brick", c + d * 11.2 + Vector3(0, 20.2, 0), Vector3(1.6, 1.6, 1.0), Basis(Vector3.UP, atan2(d.x, d.z)))
				if i % 4 == 1:
					SEuParts.niche(lm, "Stone", "Shadow", c + d * 10.95 + Vector3(0, 9.0, 0), d, 0.8, 1.4,
						SEuParts.RECT, 0.15)
	# Pius IV's pointed bastions (1561-65) round the old corner towers:
	# low battered walls with a cordon, sentry turrets at the salients.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var c := Vector3(sx * hw, 0, sz * hw)
			var tip := c + Vector3(sx, 0, sz).normalized() * 30.0
			var l := c + Vector3(sx * 22.0, 0, -sz * 6.0)
			var rr := c + Vector3(-sx * 6.0, 0, sz * 22.0)
			var poly := PackedVector2Array([Vector2(c.x, c.z), Vector2(l.x, l.z), Vector2(tip.x, tip.z),
				Vector2(rr.x, rr.z)])
			lm.poly_prism("Brick", poly, 0.0, 8.0)
			for e in [[l, tip], [tip, rr]]:
				var p0: Vector3 = e[0]
				var p1: Vector3 = e[1]
				var out := Vector3.UP.cross(p1 - p0).normalized()
				if out.dot(tip - c) < 0.0:
					out = -out
				var bas := Basis(Vector3.UP, atan2(out.x, out.z))
				lm.box("Stone", (p0 + p1) * 0.5 + out * 0.15 + Vector3(0, 6.0, 0), Vector3(p0.distance_to(p1), 0.5, 0.6),
					bas)
				SEuUtil.crenels(lm, "Brick", p0 + Vector3(0, 8.0, 0) - out * 0.6, p1 + Vector3(0, 8.0, 0) - out * 0.6,
					1.4, 1.2, 1.0)
			lm.frustum("Stone", tip + Vector3(0, 6.0, 0), 1.0, 1.4, 1.0, 12)
			lm.frustum("Stone", tip + Vector3(0, 7.0, 0), 1.3, 1.3, 2.6, 12)
			lm.lathe("Stone", tip + Vector3(0, 9.6, 0), SEuUtil.dome(1.5, 1.4, 4), 12)
			for i in 4:
				var a := TAU * float(i) / 4.0
				SEuParts.niche(lm, "Stone", "Shadow", tip + Vector3(cos(a), 0, sin(a)) * 1.28 + Vector3(0, 7.8, 0),
					Vector3(cos(a), 0, sin(a)), 0.3, 0.9, SEuParts.RECT, 0.08, 0.08, false)
	# The mausoleum drum: travertine lower courses, brick upper storey,
	# a cornice, battlements and its windows.
	var r := 32.0
	lm.frustum("Stone", Vector3(0, 0, 0), r + 0.4, r + 0.4, DRUM_Y, 48)
	lm.frustum("Stone", Vector3(0, DRUM_Y, 0), r, r, 9.0, 48)
	for k in 6:
		lm.frustum("Stone", Vector3(0, DRUM_Y + 1.5 * float(k), 0), r + 0.05, r + 0.05, 0.12, 48)
	lm.frustum("Brick", Vector3(0, DRUM_Y + 9.0, 0), r - 0.3, r - 0.3, DRUM_TOP - DRUM_Y - 9.0, 48)
	lm.frustum("Stone", Vector3(0, DRUM_Y + 8.6, 0), r + 0.3, r + 0.3, 0.6, 48)
	for i in 40:
		var a := TAU * (float(i) + 0.5) / 40.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Brick", d * (r - 0.6) + Vector3(0, DRUM_TOP + 0.8, 0), Vector3(2.2, 1.6, 1.0), Basis(Vector3.UP, atan2(d.x, d.z)))
		if i % 2 == 0:
			SEuParts.niche(lm, "Stone", "Shadow", d * (r - 0.35) + Vector3(0, DRUM_Y + 11.0, 0), d, 1.2, 2.2,
				SEuParts.RECT, 0.2)
	for i in 12:
		var a := TAU * float(i) / 12.0
		var d := Vector3(cos(a), 0, sin(a))
		SEuParts.niche(lm, "Stone", "Shadow", d * r + Vector3(0, DRUM_Y + 2.0, 0), d, 1.6, 3.0, SEuParts.ROUND, 0.25)
	lm.frustum("Stone", Vector3(0, DRUM_TOP - 0.2, 0), r - 0.1, r - 0.1, 0.2, 48)
	# Papal apartments on the drum: a block round the Angel court, the
	# Loggia of Julius II toward the bridge, the Loggia of Paul III.
	var py := DRUM_TOP
	lm.box("Render", Vector3(2.0, py + 3.0, 0), Vector3(30.0, 6.0, 34.0))
	lm.gable("Roof", Vector3(2.0, py + 6.0, 0), 30.0, 34.0, 1.2, Basis(), 0.6, "Render")
	for k in 4:
		var bas := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := bas * Vector3(0, 0, 1)
		var rt := bas * Vector3(1, 0, 0)
		var half := 17.0 if k % 2 == 0 else 15.0
		var span := 30.0 if k % 2 == 0 else 34.0
		for i in 6:
			var x := -span * 0.5 + span * (float(i) + 0.5) / 6.0
			SEuParts.niche(lm, "Stone", "Shadow", Vector3(2.0, 0, 0) + out * half + rt * x + Vector3(0, py + 1.0, 0), out,
				1.2, 2.2, SEuParts.RECT, 0.2)
			SEuParts.niche(lm, "Stone", "Shadow", Vector3(2.0, 0, 0) + out * half + rt * x + Vector3(0, py + 3.4, 0), out,
				1.2, 2.2, SEuParts.RECT, 0.2)
	# Loggia of Julius II: three arches on the bridge side.
	var lx := 17.0
	SEuParts.arcade_wall(lm, "Stone", Vector3(lx + 1.5, py + 3.0, 7.5), Vector3(lx + 1.5, py + 3.0, -7.5),
		Vector3(1, 0, 0), 3, 3.6, 2.6, 0.8, SEuParts.ROUND)
	for i in 4:
		SEuParts.col(lm, "Stone", Vector3(lx + 1.1, py, 7.5 - 5.0 * float(i)), 0.35, 3.0, "tuscan", 8)
	# Pedestal tower and the bronze archangel sheathing his sword.
	lm.box("Stone", Vector3(-4.0, py + 6.1, 0), Vector3(4.4, 0.4, 4.4))
	lm.box("Marble", Vector3(-4.0, py + 6.8, 0), Vector3(3.2, 1.2, 3.2))
	LandmarkKits.statue_figure(lm, "Angel", Vector3(-4.0, py + 7.4, 0), 4.6, true)
	for s in [-1.0, 1.0]:
		lm.box("Angel", Vector3(-4.0 - 0.6, py + 10.1, s * 1.6), Vector3(0.3, 2.6, 2.4), Basis(Vector3.RIGHT, s * 0.5))
	_bridge(lm)
	lm.commit(model)

## Ponte Sant'Angelo along +X: piers with cutwaters, five round arches,
## the parapets, the twelve statues on their pedestals and the ramps.
static func _bridge(lm: LandmarkMesh) -> void:
	var x0 := 62.0
	var x1 := 196.0
	var deck := 7.0
	var hw := 5.0
	var ramp := 18.0
	var spans := [16.0, 24.0, 26.0, 24.0, 16.0]
	var pier := 4.6
	var total := 0.0
	for s in spans:
		total += float(s)
	total += pier * float(spans.size() + 1)
	var scale := (x1 - x0 - ramp * 2.0) / total
	var x := x0 + ramp
	var pier_xs: Array[float] = []
	for i in spans.size() + 1:
		pier_xs.append(x + pier * scale * 0.5)
		x += pier * scale
		if i < spans.size():
			x += float(spans[i]) * scale
	# Piers with pointed cutwaters on both faces.
	for px in pier_xs:
		lm.box("Bridge", Vector3(px, deck * 0.5, 0), Vector3(pier * scale, deck, hw * 2.0))
		for s in [-1.0, 1.0]:
			lm.box("Bridge", Vector3(px, deck * 0.35, s * (hw + 0.9)), Vector3(pier * scale * 0.7, deck * 0.7, 1.8),
				Basis(Vector3.UP, PI * 0.25))
			lm.lathe("Bridge", Vector3(px, deck * 0.7, s * (hw + 0.9)), SEuUtil.dome(pier * scale * 0.5, 1.2, 4), 8)
	# Arches: spandrel walls on both faces and the barrel soffits.
	for i in spans.size():
		var a := pier_xs[i] + pier * scale * 0.5
		var b := pier_xs[i + 1] - pier * scale * 0.5
		var span := b - a
		var rise := minf(span * 0.5, deck - 1.4)
		SEuParts.arcade_wall(lm, "Bridge", Vector3(a, deck - 0.8 - rise, -hw), Vector3(b, deck - 0.8 - rise, -hw),
			Vector3(0, 0, -1), 1, span - 0.02, rise + 0.8, hw * 2.0, SEuParts.ROUND)
		lm.box("Bridge", Vector3((a + b) * 0.5, (deck - 0.8 - rise) * 0.5, 0), Vector3(span, deck - 0.8 - rise, hw * 2.0))
		SEuParts.arch_ring(lm, "Bridge", Vector3((a + b) * 0.5, deck - 0.8 - rise, -hw - 0.15), Vector3.RIGHT,
			Vector3(0, 0, -1), span, 0.6, 0.3, false, 8)
		SEuParts.arch_ring(lm, "Bridge", Vector3((a + b) * 0.5, deck - 0.8 - rise, hw + 0.15), Vector3.RIGHT,
			Vector3(0, 0, 1), span, 0.6, 0.3, false, 8)
	var mid_x := (pier_xs[0] + pier_xs[pier_xs.size() - 1]) * 0.5
	var run := pier_xs[pier_xs.size() - 1] - pier_xs[0] + pier * scale
	lm.box("Bridge", Vector3(mid_x, deck - 0.2, 0), Vector3(run, 0.4, hw * 2.0))
	# Ramps down to the ground at both ends.
	for s in [-1.0, 1.0]:
		var top_x: float = mid_x + float(s) * run * 0.5
		var foot_x: float = top_x + float(s) * ramp
		for k in 6:
			var t0 := float(k) / 6.0
			var t1 := float(k + 1) / 6.0
			var xa := lerpf(top_x, foot_x, t0)
			var xb := lerpf(top_x, foot_x, t1)
			var hgt := deck * (1.0 - t0)
			lm.box("Bridge", Vector3((xa + xb) * 0.5, hgt * 0.5, 0), Vector3(absf(xb - xa), hgt, hw * 2.0))
	# Parapets, and the statues on pedestals over the piers and spans.
	for s in [-1.0, 1.0]:
		lm.box("Bridge", Vector3(mid_x, deck + 0.55, s * (hw - 0.3)), Vector3(run, 1.1, 0.6))
		lm.box("Bridge", Vector3(mid_x, deck + 1.15, s * (hw - 0.3)), Vector3(run + 0.4, 0.2, 0.8))
	var spots: Array[float] = []
	for i in 5:
		spots.append(pier_xs[0] + (pier_xs[5] - pier_xs[0]) * (float(i) + 0.5) / 5.0)
	for px in spots:
		for s in [-1.0, 1.0]:
			lm.box("Bridge", Vector3(px, deck + 1.0, s * (hw - 0.3)), Vector3(1.4, 2.0, 1.4))
			SEuParts.figure(lm, "Marble", Vector3(px, deck + 2.0, s * (hw - 0.3)), 3.0, true, PI * 0.5 * s)
			lm.box("Marble", Vector3(px - 0.2, deck + 4.2, s * (hw - 0.3)), Vector3(0.2, 1.6, 1.6),
				Basis(Vector3.BACK, 0.3))
	for s in [-1.0, 1.0]:
		var ex := pier_xs[5] + pier * scale * 0.5 + ramp - 1.0
		lm.box("Bridge", Vector3(ex, 2.0, s * (hw + 1.0)), Vector3(2.0, 4.0, 2.0))
		SEuParts.figure(lm, "Marble", Vector3(ex, 4.0, s * (hw + 1.0)), 4.0, s > 0.0, PI * 0.5)

# --- Trevi Fountain -------------------------------------------------

## The Baroque wall-fountain (Salvi, 1732-62) against Palazzo Poli,
## origin at the centre of its basin, facade facing +Z: 49.15 m wide,
## 26.3 m to the top of the papal arms. A triumphal arch of four giant
## Corinthian columns frames the exedra where Oceanus rides his shell
## chariot behind two sea-horses and tritons; Abundance and Salubrity
## stand in the flanking niches under their reliefs; four statues of
## the seasons on the attic and two Fames holding Clement XII's arms
## crown it. The palace wings carry giant Corinthian pilasters and two
## storeys of pedimented windows; the travertine reef spreads across the
## whole front into the great basin.
static func trevi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Travertine", LandmarkMaterials.pbr("limestone", "#CDBB98", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E0D2B0", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#51493C", 3.0))
	lm.use("Rock", LandmarkMaterials.pbr("rock", "#B7AA8E", 4.0))
	lm.use("Water", LandmarkMaterials.glass("#2A6C78"))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EFEADF", 2.0))
	var f := -10.0
	var nz := Vector3(0, 0, 1)
	# Palazzo Poli: body, rusticated ground storey, giant pilasters,
	# windows, main cornice, attic with its windows and balustrade.
	lm.box("Travertine", Vector3(0, 10.0, f - 6.0), Vector3(49.15, 20.0, 12.0))
	lm.box("Trim", Vector3(0, 3.6, f + 0.1), Vector3(49.15, 0.5, 0.4))
	for s in [-1.0, 1.0]:
		for i in 4:
			var x: float = s * (13.0 + 3.6 * float(i))
			lm.box("Trim", Vector3(x, 10.4, f + 0.25), Vector3(1.2, 13.0, 0.5))
			lm.box("Trim", Vector3(x, 17.2, f + 0.35), Vector3(1.6, 0.9, 0.7))
		for i in 3:
			var x: float = s * (14.8 + 3.6 * float(i))
			LandmarkDetail.window(lm, "Trim", "Shadow", Vector3(x, 1.8, f + 0.02), nz, 1.2, 2.0, false, 0.2)
			LandmarkDetail.window(lm, "Trim", "Shadow", Vector3(x, 7.4, f + 0.02), nz, 1.4, 3.0, false, 0.25)
			lm.gable("Trim", Vector3(x, 9.6, f + 0.25), 2.2, 0.5, 0.6, Basis(), 0.0, "Trim")
			LandmarkDetail.window(lm, "Trim", "Shadow", Vector3(x, 13.4, f + 0.02), nz, 1.3, 2.4, false, 0.2)
			SEuParts.niche(lm, "Trim", "Shadow", Vector3(x, 19.3, f), nz, 1.0, 1.4, SEuParts.RECT, 0.15)
	LandmarkDetail.cornice(lm, "Trim", Vector3(-24.6, 18.0, f), Vector3(24.6, 18.0, f), nz, 1.2, true)
	lm.box("Travertine", Vector3(0, 20.3, f - 6.0), Vector3(49.15, 1.0, 12.0))
	SEuParts.rail(lm, "Trim", Vector3(-24.4, 20.8, f - 0.4), Vector3(-13.5, 20.8, f - 0.4), 1.1, 3.6)
	SEuParts.rail(lm, "Trim", Vector3(13.5, 20.8, f - 0.4), Vector3(24.4, 20.8, f - 0.4), 1.1, 3.6)
	# Triumphal arch: protruding central bay, attic, columns.
	lm.box("Travertine", Vector3(0, 10.4, f + 1.5), Vector3(24.0, 20.8, 3.0))
	for x in [-11.0, -6.6, 6.6, 11.0]:
		LandmarkDetail.column(lm, "Trim", Vector3(float(x), 1.6, f + 4.0), 0.85, 15.2, "corinthian", 24)
		lm.box("Trim", Vector3(float(x), 0.8, f + 4.0), Vector3(2.4, 1.6, 2.4))
	lm.box("Trim", Vector3(0, 17.6, f + 3.4), Vector3(25.0, 1.6, 2.4))
	LandmarkDetail.cornice(lm, "Trim", Vector3(-12.5, 18.4, f + 4.6), Vector3(12.5, 18.4, f + 4.6), nz, 1.0, true)
	# Attic with the dedication panel and four statues of the seasons.
	lm.box("Travertine", Vector3(0, 21.6, f + 1.5), Vector3(24.0, 4.4, 3.4))
	lm.box("Marble", Vector3(0, 21.4, f + 3.25), Vector3(12.0, 2.4, 0.1))
	for i in 10:
		lm.box("Shadow", Vector3(-5.0 + float(i) * 1.1, 21.6, f + 3.32), Vector3(0.6, 0.5, 0.04))
	LandmarkDetail.cornice(lm, "Trim", Vector3(-12.2, 23.8, f + 3.2), Vector3(12.2, 23.8, f + 3.2), nz, 0.5, false)
	for x in [-11.0, -6.6, 6.6, 11.0]:
		SEuParts.figure(lm, "Marble", Vector3(float(x), 19.4, f + 4.0), 2.8, int(x) % 2 == 0)
	# Clement XII's arms held by two Fames, to 26.3 m.
	lm.box("Trim", Vector3(0, 24.6, f + 1.6), Vector3(5.0, 1.0, 2.6))
	lm.lathe("Marble", Vector3(0, 25.1, f + 2.0), PackedVector2Array([Vector2(1.2, 0), Vector2(1.0, 0.8),
		Vector2(0.4, 1.2), Vector2(0.0, 1.2)]), 10, 1.0, 0.4)
	for s in [-1.0, 1.0]:
		SEuParts.figure(lm, "Marble", Vector3(s * 2.0, 25.1, f + 2.0), 1.2, true)
	# Exedra of Oceanus and the flanking niches with their reliefs.
	SEuParts.niche(lm, "Trim", "Shadow", Vector3(0, 3.0, f + 3.05), nz, 7.6, 13.4, SEuParts.ROUND, 0.6, 0.6, false)
	SEuParts.arch_ring(lm, "Trim", Vector3(0, 12.6, f + 3.4), Vector3.RIGHT, nz, 7.6, 0.6, 0.6, false, 10)
	for s in [-1.0, 1.0]:
		SEuParts.col(lm, "Trim", Vector3(s * 3.2, 3.0, f + 3.6), 0.4, 9.6, "corinthian", 10)
		SEuParts.niche(lm, "Trim", "Shadow", Vector3(s * 8.8, 4.2, f + 3.05), nz, 2.6, 5.4, SEuParts.ROUND, 0.35)
		SEuParts.figure(lm, "Marble", Vector3(s * 8.8, 4.4, f + 3.3), 3.4, s > 0.0)
		lm.box("Marble", Vector3(s * 8.8, 12.2, f + 3.1), Vector3(3.6, 2.4, 0.3))
		SEuParts.figure(lm, "Marble", Vector3(s * 9.4, 11.2, f + 3.3), 1.6)
		SEuParts.figure(lm, "Marble", Vector3(s * 8.2, 11.2, f + 3.3), 1.6)
	# The reef across the front, Oceanus on his shell, sea-horses, tritons.
	SEuUtil.blob(lm, "Rock", Vector3(0, 0, f + 5.0), 23.0, 4.2, 6.5, Vector3.ZERO, true, 8, 28)
	for p in [Vector3(-14.0, 0, f + 6.0), Vector3(14.0, 0, f + 6.0), Vector3(-6.0, 0, f + 8.0), Vector3(6.0, 0, f + 8.0)]:
		SEuUtil.blob(lm, "Rock", p, 4.0, 2.6, 3.0, Vector3.ZERO, true, 5, 12)
	lm.lathe("Marble", Vector3(0, 4.0, f + 5.2), PackedVector2Array([Vector2(0.0, 0), Vector2(1.6, 0.2),
		Vector2(2.4, 0.9), Vector2(2.2, 1.4)]), 12, 1.0, 0.7)
	lm.box("Marble", Vector3(0, 5.3, f + 4.2), Vector3(1.8, 0.8, 1.6))
	LandmarkKits.statue_figure(lm, "Marble", Vector3(0, 5.7, f + 4.4), 5.8, true)
	for s in [-1.0, 1.0]:
		var hc := Vector3(s * 4.4, 1.6, f + 9.4)
		SEuUtil.blob(lm, "Marble", hc, 1.2, 1.2, 2.2, Vector3.ZERO, false, 6, 10)
		lm.beam("Marble", hc + Vector3(0, 0.6, 1.4), hc + Vector3(0, 2.6, 2.4), 0.8, 0.6)
		lm.box("Marble", hc + Vector3(0, 2.9, 2.9), Vector3(0.6, 0.7, 1.2), Basis(Vector3.RIGHT, -0.4))
		for k in 2:
			lm.beam("Marble", hc + Vector3(s * 0.4 * (float(k) * 2.0 - 1.0), 0.3, 1.6),
				hc + Vector3(s * 0.4 * (float(k) * 2.0 - 1.0), 1.4 + float(k) * 0.6, 2.8), 0.3, 0.3)
		lm.beam("Marble", hc + Vector3(0, -0.4, -1.8), hc + Vector3(s * 1.6, 0.4, -3.6), 0.6, 0.5)
		SEuParts.figure(lm, "Marble", Vector3(s * 6.6, 2.4, f + 8.4), 2.6, true)
	# Basin: rim, water, the steps down from the piazza.
	lm.box("Water", Vector3(0, 0.55, f + 15.0), Vector3(48.0, 0.1, 22.0))
	lm.box("Travertine", Vector3(0, 0.6, f + 26.2), Vector3(50.0, 1.2, 0.8))
	lm.box("Travertine", Vector3(0, 1.25, f + 26.2), Vector3(50.4, 0.15, 1.1))
	for s in [-1.0, 1.0]:
		lm.box("Travertine", Vector3(s * 24.6, 0.6, f + 15.0), Vector3(0.8, 1.2, 23.0))
		lm.box("Travertine", Vector3(s * 24.6, 1.25, f + 15.0), Vector3(1.1, 0.15, 23.4))
	SEuUtil.steps_up(lm, "Travertine", Vector3(0, 0, f + 26.6), Vector3(0, 0, 1), 50.0, 1.0, 0.18, 3)
	lm.commit(model)

# --- Vittoriano ---------------------------------------------------------

const PORTICO_Y := 48.0

## Altare della Patria (Sacconi, 1885-1935) in Botticino marble, origin
## at the monument axis, facing +Z (yaw_deg turns it onto Piazza
## Venezia): 135 m wide, stepped terraces with the great stairs flanked
## by the sculpture groups of Thought and Action, the Altar of the
## Fatherland with the goddess Roma, the 12 m bronze equestrian statue
## of Victor Emmanuel II, the concave Portico della Libertà of sixteen
## 15 m Corinthian columns at 48-70 m with a statue of a region over
## each column, and the two temple-fronted propylaea crowned by the
## gilded bronze quadrigae of Unity and Freedom at 81 m.
static func vittoriano(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E8E4DA", 4.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#F1EDE3", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#58514A", 3.0))
	lm.use("Steps", LandmarkMaterials.pbr("limestone", "#D2CCBE", 2.0))
	lm.use("Bronze", LandmarkMaterials.paint("#58684F", 0.5, 0.5))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Water", LandmarkMaterials.glass("#3A6E7A"))
	var nz := Vector3(0, 0, 1)
	# Terraces.
	lm.box("Marble", Vector3(0, 6.5, 27.0), Vector3(135.0, 13.0, 26.0))
	lm.box("Marble", Vector3(0, 13.0, 2.0), Vector3(135.0, 26.0, 24.0))
	lm.box("Marble", Vector3(0, 24.0, -28.0), Vector3(135.0, 48.0, 36.0))
	LandmarkDetail.cornice(lm, "Trim", Vector3(-67.5, 12.4, 40.0), Vector3(67.5, 12.4, 40.0), nz, 0.9, false)
	LandmarkDetail.cornice(lm, "Trim", Vector3(-67.5, 25.4, 14.0), Vector3(67.5, 25.4, 14.0), nz, 0.9, false)
	LandmarkDetail.cornice(lm, "Trim", Vector3(-67.5, 47.0, -10.0), Vector3(67.5, 47.0, -10.0), nz, 1.2, true)
	for s in [-1.0, 1.0]:
		SEuParts.rail(lm, "Trim", Vector3(s * 67.0, 13.3, 39.6), Vector3(s * 17.0, 13.3, 39.6), 1.2, 5.0)
		SEuParts.rail(lm, "Trim", Vector3(s * 67.0, 26.3, 13.6), Vector3(s * 18.0, 26.3, 13.6), 1.2, 5.0)
		# Blind arcades on the terrace walls.
		for i in 6:
			var x: float = s * (22.0 + 7.5 * float(i))
			SEuParts.niche(lm, "Trim", "Shadow", Vector3(x, 2.0, 40.0), nz, 3.0, 7.5, SEuParts.ROUND, 0.4)
			SEuParts.niche(lm, "Trim", "Shadow", Vector3(x, 15.5, 14.0), nz, 3.0, 7.0, SEuParts.ROUND, 0.4)
			lm.box("Trim", Vector3(x + s * 3.75, 6.5, 40.3), Vector3(1.4, 13.0, 0.6))
		# Fountains of the Adriatic and the Tyrrhenian at the foot.
		lm.box("Water", Vector3(s * 50.0, 0.5, 44.0), Vector3(24.0, 0.2, 7.0))
		lm.box("Marble", Vector3(s * 50.0, 0.4, 47.6), Vector3(25.0, 0.8, 0.6))
		SEuUtil.blob(lm, "Marble", Vector3(s * 50.0, 0.5, 41.8), 4.0, 5.5, 2.0, Vector3.ZERO, true, 5, 12)
		SEuParts.figure(lm, "Bronze", Vector3(s * 50.0, 3.0, 42.6), 4.0, true)
		# Groups of Thought and Action flanking the stair foot.
		lm.box("Marble", Vector3(s * 21.0, 2.5, 46.0), Vector3(8.0, 5.0, 6.0))
		for k in 3:
			SEuParts.figure(lm, "Bronze", Vector3(s * 21.0 + float(k - 1) * 2.2, 5.0, 46.0), 4.2 - float(k % 2), k == 1)
		# Winged victories on rostral columns at the terrace corners.
		lm.frustum("Marble", Vector3(s * 64.0, 26.0, 13.0), 1.1, 0.95, 12.0, 16)
		lm.box("Trim", Vector3(s * 64.0, 38.4, 13.0), Vector3(2.6, 0.8, 2.6))
		SEuParts.figure(lm, "Gold", Vector3(s * 64.0, 38.8, 13.0), 4.0, true)
	SEuUtil.steps_up(lm, "Steps", Vector3(0, 0, 40.0), Vector3(0, 0, 1), 34.0, 1.4, 1.0, 13)
	for s in [-1.0, 1.0]:
		SEuUtil.steps_up(lm, "Steps", Vector3(s * 19.0, 13.0, 14.0), Vector3(0, 0, 1), 14.0, 1.1, 1.0, 13)
	SEuUtil.steps_up(lm, "Steps", Vector3(0, 26.0, -10.0), Vector3(0, 0, 1), 36.0, 1.0, 1.0, 22)
	# Altar of the Fatherland: the goddess Roma in her gilded niche.
	lm.box("Marble", Vector3(0, 19.0, 15.5), Vector3(22.0, 12.0, 3.0))
	SEuParts.niche(lm, "Trim", "Gold", Vector3(0, 15.0, 17.0), nz, 5.0, 9.0, SEuParts.ROUND, 0.5)
	SEuParts.figure(lm, "Marble", Vector3(0, 15.2, 17.4), 6.0)
	for i in 8:
		var x := -9.5 + 19.0 * float(i) / 7.0
		if absf(x) > 3.5:
			SEuParts.figure(lm, "Marble", Vector3(x, 14.5, 17.2), 2.6)
	# Equestrian Victor Emmanuel II on his pedestal (12 m bronze).
	lm.box("Marble", Vector3(0, 30.0, 4.0), Vector3(9.0, 8.0, 14.0))
	LandmarkDetail.cornice(lm, "Trim", Vector3(-4.5, 33.4, 11.0), Vector3(4.5, 33.4, 11.0), nz, 0.6, false)
	_horse(lm, Vector3(0, 34.0, 4.0), 12.0)
	# Portico della Libertà: concave colonnade of sixteen columns.
	var pr := 120.0
	var pc := Vector3(0, PORTICO_Y, pr - 38.0)
	var half := asin(48.0 / pr)
	for i in 16:
		var a := -half + 2.0 * half * float(i) / 15.0
		var p := pc + Vector3(sin(a) * pr, 0, -cos(a) * pr)
		LandmarkDetail.column(lm, "Trim", p, 0.9, 15.0, "corinthian", 24)
		SEuParts.figure(lm, "Trim", p + Vector3(0, 22.0, 0), 4.0, i % 3 == 0)
	_curved(lm, "Marble", pc, pr + 6.0, half * 1.04, PORTICO_Y + 11.0, 22.0, 3.0)
	_curved(lm, "Trim", pc, pr - 1.0, half * 1.04, PORTICO_Y + 16.6, 4.4, 4.0)
	_curved(lm, "Marble", pc, pr + 1.5, half * 1.04, PORTICO_Y + 20.4, 3.2, 12.0)
	for i in 15:
		var a := -half + 2.0 * half * (float(i) + 0.5) / 15.0
		var d := Vector3(sin(a), 0, -cos(a))
		SEuParts.niche(lm, "Trim", "Shadow", pc + d * (pr + 4.45) + Vector3(0, 0.5, 0), -d, 2.6, 7.0, SEuParts.ROUND, 0.3)
	# Propylaea at both ends: temple fronts crowned by the quadrigae.
	for s in [-1.0, 1.0]:
		var px: float = s * 57.0
		for i in 4:
			LandmarkDetail.column(lm, "Trim", Vector3(px - 7.5 + 5.0 * float(i), PORTICO_Y, -12.5), 0.9, 15.0, "corinthian", 24)
		for i in 2:
			LandmarkDetail.column(lm, "Trim", Vector3(px - 7.5 + 15.0 * float(i), PORTICO_Y, -18.5), 0.9, 15.0, "corinthian", 24)
		lm.box("Marble", Vector3(px, 59.0, -27.0), Vector3(22.0, 22.0, 3.0))
		SEuParts.niche(lm, "Trim", "Shadow", Vector3(px, PORTICO_Y + 0.5, -25.45), nz, 5.0, 10.0, SEuParts.ROUND, 0.5)
		lm.box("Marble", Vector3(px - s * 10.5, 59.0, -19.0), Vector3(1.0, 22.0, 18.0))
		lm.box("Marble", Vector3(px + s * 10.5, 59.0, -19.0), Vector3(1.0, 22.0, 18.0))
		lm.box("Trim", Vector3(px, 65.0, -19.0), Vector3(23.0, 4.0, 19.0))
		LandmarkDetail.cornice(lm, "Trim", Vector3(px - 11.8, 67.0, -9.5), Vector3(px + 11.8, 67.0, -9.5), nz, 1.0, true)
		lm.gable("Marble", Vector3(px, 68.0, -19.0), 23.0, 19.5, 2.2, Basis(), 0.3, "Trim")
		lm.box("Marble", Vector3(px, 68.6, -19.0), Vector3(23.5, 1.2, 19.5))
		_quadriga(lm, Vector3(px, 70.2, -19.0))
		lm.box("Marble", Vector3(px, 0.0, -19.0) + Vector3(0, PORTICO_Y + 0.2, 0), Vector3(22.0, 0.4, 14.0))
	lm.commit(model)

## Arc of the concave portico: a box-section band centred on the arc of
## radius r round `c` (the portico bows back toward -Z), between angles
## -half..half, centred at height y, h tall and d deep.
static func _curved(lm: LandmarkMesh, key: String, c: Vector3, r: float, half: float, y: float, h: float,
		d: float) -> void:
	var n := 16
	for i in n:
		var a0 := -half + 2.0 * half * float(i) / float(n)
		var a1 := -half + 2.0 * half * float(i + 1) / float(n)
		var p0 := Vector3(c.x + sin(a0) * r, y, c.z - cos(a0) * r)
		var p1 := Vector3(c.x + sin(a1) * r, y, c.z - cos(a1) * r)
		lm.beam(key, p0, p1, h, d, Vector3.UP)

## Bronze equestrian statue h tall on `base`: horse body, legs, neck and
## head, the king seated with his plumed helmet; facing +Z.
static func _horse(lm: LandmarkMesh, base: Vector3, h: float) -> void:
	var s := h / 12.0
	SEuUtil.blob(lm, "Bronze", base + Vector3(0, 5.4 * s, 0), 1.7 * s, 2.0 * s, 3.6 * s, Vector3.ZERO, false, 6, 12)
	for lx in [-0.9, 0.9]:
		for lz in [-2.4, 2.4]:
			lm.beam("Bronze", base + Vector3(float(lx) * s, 4.6 * s, float(lz) * s),
				base + Vector3(float(lx) * s, 0.0, (float(lz) + (0.6 if float(lz) > 0.0 else -0.2)) * s), 0.6 * s, 0.7 * s)
	lm.beam("Bronze", base + Vector3(0, 6.2 * s, 2.6 * s), base + Vector3(0, 8.6 * s, 4.0 * s), 1.2 * s, 1.6 * s)
	lm.beam("Bronze", base + Vector3(0, 8.8 * s, 3.8 * s), base + Vector3(0, 8.0 * s, 5.4 * s), 0.9 * s, 1.0 * s)
	lm.beam("Bronze", base + Vector3(0, 5.6 * s, -3.4 * s), base + Vector3(0, 2.4 * s, -4.6 * s), 0.5 * s, 0.8 * s)
	LandmarkKits.statue_figure(lm, "Bronze", base + Vector3(0, 6.4 * s, 0), 5.6 * s)

## Winged Victory driving four horses abreast (gilded bronze), 10.8 m.
static func _quadriga(lm: LandmarkMesh, base: Vector3) -> void:
	lm.box("Marble", base + Vector3(0, 0.6, 0), Vector3(12.0, 1.2, 6.0))
	lm.lathe("Gold", base + Vector3(0, 1.2, -1.2), PackedVector2Array([Vector2(1.6, 0), Vector2(1.8, 1.2),
		Vector2(1.6, 2.4), Vector2(0.0, 2.4)]), 10, 1.0, 0.8)
	for k in 4:
		var x := -4.2 + 2.8 * float(k)
		var hb := base + Vector3(x, 3.0, 1.4)
		SEuUtil.blob(lm, "Gold", hb, 0.65, 0.9, 1.7, Vector3.ZERO, false, 5, 8)
		lm.beam("Gold", hb + Vector3(0, 0.4, 1.2), hb + Vector3(0, 2.0, 2.2), 0.6, 0.8)
		lm.box("Gold", hb + Vector3(0, 2.1, 2.6), Vector3(0.45, 0.6, 1.0), Basis(Vector3.RIGHT, 0.4))
		for lz in [-1.2, 1.2]:
			lm.beam("Gold", hb + Vector3(0, -0.3, float(lz)), hb + Vector3(0, -1.8, float(lz) + (0.8 if float(lz) > 0.0 and k % 2 == 0 else 0.0)), 0.3, 0.3)
	LandmarkKits.statue_figure(lm, "Gold", base + Vector3(0, 3.6, -1.2), 7.0, true)
	for s in [-1.0, 1.0]:
		lm.box("Gold", base + Vector3(s * 1.4, 7.4, -1.6), Vector3(0.3, 4.4, 2.6), Basis(Vector3.BACK, s * 0.35))
