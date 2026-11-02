class_name LandmarkNaSkyscrapers
extends RefCounted

## Four skyscrapers in true metres: Chicago's Willis Tower, New York's
## Chrysler Building and Flatiron Building, San Francisco's Transamerica
## Pyramid. Manhattan's two are built in the street grid (the registry
## turns them 29°).

const WILLIS_TIP_M := 527.3
const WILLIS_ROOF_M := 442.1
const WILLIS_TUBE_M := 22.9
const CHRYSLER_TIP_M := 318.9
const CHRYSLER_CROWN_M := 198.0
const FLATIRON_TOP_M := 87.0
const FLATIRON_STOREY_M := 3.95
const TRANS_PYRAMID_M := 205.0
const TRANS_TIP_M := 260.0
const TRANS_ARCADE_M := 16.0

## Willis Tower (1973, SOM): nine 22.9 m square tubes of black anodised
## aluminium and bronze glass bundled 3 x 3, dropping out as it rises
## (two end at the 50th floor, two at the 66th, three at the 90th) until
## two reach the 442 m roof; every tube face divided by the projecting
## mullion fins at 1.52 m (five 4.6 m column bays), louvred belt-truss
## bands at the mechanical floors (29-31, 64-66, 88-90), the four glass
## boxes of the Skydeck Ledge on the 103rd floor's west face, the
## rooftop plant, and the two white antennas to 527.3 m.
static func willis_tower(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Tower", LandmarkMaterials.paint("#1D1F22", 0.4, 0.6))
	lm.use("Glass", LandmarkMaterials.glass("#2B2620"))
	lm.use("Mast", LandmarkMaterials.paint("#CFD2D4", 0.4, 0.6))
	lm.use("Base", LandmarkMaterials.pbr("stone", "#6D6A64", 4.0))
	# Tube tops by row (north to south) and column (west to east).
	var tops := [[202.0, WILLIS_ROOF_M, 266.0], [357.0, WILLIS_ROOF_M, 357.0],
		[266.0, 357.0, 202.0]]
	var span := WILLIS_TUBE_M
	var bands := [[114.0, 124.0], [256.0, 266.0], [347.0, 357.0]]
	for j in 3:
		for i in 3:
			var h: float = tops[j][i]
			var c := Vector3((i - 1) * span, 0, (j - 1) * span)
			lm.box("Glass", c + Vector3(0, h * 0.5, 0), Vector3(span - 0.2, h, span - 0.2))
			lm.box("Tower", c + Vector3(0, h - 1.5, 0), Vector3(span + 0.3, 3.0, span + 0.3))
			lm.box("Tower", c + Vector3(0, 3.0, 0), Vector3(span + 0.2, 6.0, span + 0.2))
			for q in 4:
				var r := Basis(Vector3.UP, PI * 0.5 * q)
				# Outer faces only: inner ones meet the neighbouring tube.
				var nb := Vector3(r * Vector3(0, 0, 1))
				var ni := i + roundi(nb.x)
				var nj := j + roundi(nb.z)
				var inner := ni >= 0 and ni < 3 and nj >= 0 and nj < 3
				var y0 := 6.0
				if inner:
					y0 = float(tops[nj][ni])
					if y0 >= h - 4.0:
						continue
				var fh := h - 3.0 - y0
				for k in 16:
					var x := -span * 0.5 + span * float(k) / 15.0
					lm.box("Tower", c + r * Vector3(x, y0 + fh * 0.5, span * 0.5), Vector3(0.22, fh, 0.5), r, 0.0)
				# Belt trusses: a louvred black band at each mechanical level.
				for band in bands:
					var b0: float = band[0]
					var b1: float = band[1]
					if b1 + 4.0 > h or b0 < y0:
						continue
					lm.box("Tower", c + r * Vector3(0, (b0 + b1) * 0.5, span * 0.5 - 0.1), Vector3(span, b1 - b0, 0.4), r)
					for l in 5:
						lm.box("Tower", c + r * Vector3(0, b0 + 1.0 + 2.0 * l, span * 0.5 + 0.35), Vector3(span, 0.25, 0.5), r, 0.0)
	# Skydeck Ledge: four glass boxes out from the west face at 412 m.
	for z in [-14.0, -8.0, 0.0, 6.0]:
		var p := Vector3(-span * 0.5 - 0.9, 412.0, z)
		lm.box("Glass", p + Vector3(0, 1.6, 0), Vector3(1.3, 3.1, 3.0))
		lm.box("Mast", p + Vector3(0, 0.0, 0), Vector3(1.4, 0.12, 3.1), Basis(), 0.0)
	# Rooftop plant and the two antennas.
	for k in 2:
		var c := Vector3(0, WILLIS_ROOF_M, -span * float(k))
		lm.box("Tower", c + Vector3(0, 2.0, 0), Vector3(16.0, 4.0, 16.0))
	lm.box("Base", Vector3(0, 0.5, 0), Vector3(84.0, 1.0, 84.0))
	var ants := [[Vector3(-6.0, WILLIS_ROOF_M + 4.0, 0.0), WILLIS_TIP_M],
		[Vector3(6.0, WILLIS_ROOF_M + 4.0, -span), WILLIS_TIP_M - 7.0]]
	for a in ants:
		var base: Vector3 = a[0]
		var prof := PackedVector2Array([Vector2(1.7, 0.0), Vector2(1.0, 35.0),
			Vector2(0.15, float(a[1]) - base.y)])
		lm.lathe("Mast", base, prof, 8)
		for y in [8.0, 18.0, 28.0, 40.0, 52.0, 64.0]:
			LandmarkNaParts.ring(lm, "Mast", base + Vector3(0, y, 0), LandmarkNaParts.radius_at(prof, y) + 0.15,
				0.3, 0.6, 8)
		for y in [12.0, 34.0]:
			lm.frustum("Mast", base + Vector3(0, y, 0), 2.6, 2.6, 0.3, 8)
	lm.commit(model)

## Chrysler Building (1930, William Van Alen): the white-and-grey brick
## tower in its setbacks to the 61st floor, every storey of punched
## windows between dark brick piers, the winged radiator-cap ornaments
## at the 31st floor corners and the eagle gargoyles at the 61st, then
## the stainless-steel crown of seven receding sunburst arches on each
## face with their triangular windows, and the 38 m needle (Vertex) to
## 318.9 m.
static func chrysler_building(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#C9C3B6", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#D2CBBB", 3.0))
	lm.use("Steel", LandmarkMaterials.paint("#C9CFD4", 0.22, 0.9))
	lm.use("Glass", LandmarkMaterials.glass("#3A4349"))
	lm.use("Dark", LandmarkMaterials.pbr("brick", "#5A5A5C", 3.0))
	# [y0, y1, half-width] stacked masses.
	var masses := [[0.0, 30.0, 29.0], [30.0, 58.0, 25.0], [58.0, 120.0, 21.0],
		[120.0, 184.0, 17.5], [184.0, CHRYSLER_CROWN_M, 15.0]]
	var storey := 3.66
	for m in masses:
		var y0: float = m[0]
		var y1: float = m[1]
		var hw: float = m[2]
		var skin := 0.3
		lm.box("Brick", Vector3(0, (y0 + y1) * 0.5, 0), Vector3(hw * 2.0 - skin * 2.0, y1 - y0, hw * 2.0 - skin * 2.0))
		var bays := floori(hw * 2.0 / 3.0)
		for q in 4:
			var r := Basis(Vector3.UP, PI * 0.5 * q)
			var n := r * Vector3(0, 0, 1)
			var right := r * Vector3(-1, 0, 0)
			var o := n * (hw - skin) - right * hw + Vector3(0, y0, 0)
			var rows := floori((y1 - y0 - 1.2) / storey)
			LandmarkDetail.pierced_face(lm, "Brick", "Glass", o, right, n, hw * 2.0, y1 - y0 - 1.2, bays, rows,
				Vector2(1.5, 2.2), 0.9, storey, skin)
			# Dark brick piers between the window columns, white spandrels.
			var basis := Basis(right, Vector3.UP, n)
			for k in bays + 1:
				lm.box("Dark", o + right * (hw * 2.0 * float(k) / float(bays)) + n * (skin + 0.05)
					+ Vector3(0, (y1 - y0) * 0.5, 0), Vector3(0.5, y1 - y0 - 1.2, 0.1), basis, 0.0)
			lm.box("Trim", Vector3(0, y1 - 0.6, 0) + n * (hw + 0.2), Vector3(hw * 2.0 + 1.2, 1.2, 0.6), r)
	# Radiator-cap ornaments on the 31st floor corners (the setback at 120 m
	# carries the hubcap frieze; caps stand at 58 m on the lower setback).
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := Vector3(sx * 21.0, 120.0 - 1.0, sz * 21.0)
			var d := Vector3(sx, 0, sz).normalized()
			lm.lathe("Steel", p - d * 0.2, PackedVector2Array([Vector2(0.5, 0.0), Vector2(0.7, 0.8), Vector2(0.4, 1.8),
				Vector2(0.0, 2.2)]), 8)
			for s in [-1.0, 1.0]:
				var w := d.cross(Vector3.UP) * float(s)
				lm.tri("Steel", p + Vector3(0, 1.0, 0), p + w * 2.6 + Vector3(0, 1.8, 0) + d * 0.6,
					p + w * 2.2 + Vector3(0, 0.6, 0) + d * 0.6, d, d, d, Vector2.ZERO, Vector2(2.6, 0), Vector2(2.2, -1.0))
				lm.tri("Steel", p + Vector3(0, 1.0, 0), p + w * 2.2 + Vector3(0, 0.6, 0) + d * 0.6,
					p + w * 2.6 + Vector3(0, 1.8, 0) + d * 0.6, -d, -d, -d, Vector2.ZERO, Vector2(2.6, 0), Vector2(2.2, -1.0))
	# Eagle gargoyles on the 61st floor corners.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := Vector3(sx * 14.6, CHRYSLER_CROWN_M - 1.5, sz * 14.6)
			var d := Vector3(sx, 0, sz).normalized()
			lm.beam("Steel", p, p + d * 4.2 + Vector3(0, 1.2, 0), 1.6, 1.2)
			lm.lathe("Steel", p + d * 4.6 + Vector3(0, 1.0, 0), PackedVector2Array([Vector2(0.0, 0.0),
				Vector2(0.6, 0.3), Vector2(0.55, 0.9), Vector2(0.0, 1.3)]), 8)
			lm.beam("Steel", p + d * 4.9 + Vector3(0, 1.6, 0), p + d * 5.8 + Vector3(0, 1.2, 0), 0.3, 0.25)
			for s in [-1.0, 1.0]:
				var w := d.cross(Vector3.UP) * float(s)
				lm.beam("Steel", p + d * 2.4 + Vector3(0, 0.8, 0), p + d * 2.0 + w * 2.2 + Vector3(0, 1.4, 0), 0.9, 0.2)
	_chrysler_crown(lm)
	lm.commit(model)

## The crown above the 61st floor: a receding square core with, on each
## face, seven stacked stainless arches (smaller and higher in turn),
## each ringed with triangular sunburst windows; then the Vertex.
static func _chrysler_crown(lm: LandmarkMesh) -> void:
	var y0 := CHRYSLER_CROWN_M
	var hws := [13.5, 12.0, 10.5, 9.0, 7.5, 6.0, 4.5, 3.0]
	for i in 7:
		var y := y0 + 12.0 * i
		var r0: float = hws[i]
		var r1: float = hws[i + 1]
		# Core block of the tier, set back to the next arch's width above.
		lm.box("Steel", Vector3(0, y + 6.0, 0), Vector3(r0 * 2.0 - 1.0, 12.0, r0 * 2.0 - 1.0))
		for q in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * q)
			var n := b * Vector3(0, 0, 1)
			var fz := r0 - 0.4
			var ctr := Vector3(0, y + 12.0 - r0 * 0.75, 0) + n * fz
			# The arch: a steel band on a semicircle spanning the face.
			var prev := ctr + b.x * r0 * -1.0
			for k in 12:
				var t := PI - PI * float(k + 1) / 12.0
				var p := ctr + b.x * cos(t) * r0 + Vector3(0, sin(t) * r0 * 0.75, 0)
				lm.beam("Steel", prev + n * 0.3, p + n * 0.3, 0.8, 0.6, n)
				prev = p
			# Sunburst: triangular windows radiating under the arch.
			var nw := 7
			for k in nw:
				var t := PI * (float(k) + 0.5) / float(nw)
				var dir := b.x * cos(t) + Vector3(0, sin(t) * 0.75, 0)
				var tip := ctr + dir * r0 * 0.88 + n * 0.45
				var half := dir.cross(n).normalized()
				var foot := ctr + dir * r0 * 0.38 + n * 0.45
				lm.tri("Glass", foot + half * r0 * 0.13, foot - half * r0 * 0.13, tip, n, n, n,
					Vector2.ZERO, Vector2(r0 * 0.26, 0), Vector2(r0 * 0.13, -r0 * 0.5))
			# Below the arch, vertical steel ribs down to the tier's foot.
			for k in 5:
				var x := -r0 * 0.8 + r0 * 1.6 * float(k) / 4.0
				lm.box("Steel", Vector3(0, y + (12.0 - r0 * 0.75) * 0.5, 0) + n * (fz + 0.25) + b.x * x,
					Vector3(0.3, 12.0 - r0 * 0.75, 0.3), b, 0.0)
		lm.box("Steel", Vector3(0, y + 11.6, 0), Vector3(r1 * 2.0 + 1.0, 0.8, r1 * 2.0 + 1.0))
	var needle := CHRYSLER_CROWN_M + 84.0
	lm.lathe("Steel", Vector3(0, needle, 0), PackedVector2Array([Vector2(3.0, 0.0), Vector2(2.0, 10.0),
		Vector2(1.0, 22.0), Vector2(0.15, CHRYSLER_TIP_M - needle)]), 8)
	for k in 4:
		LandmarkNaParts.ring(lm, "Steel", Vector3(0, needle + 2.0 + 5.0 * k, 0), 2.8 - 0.35 * k, 0.4, 0.4, 8)

## Transamerica Pyramid (1972, William Pereira): the white quartz-clad
## four-sided pyramid narrowing from 53 m to 14 m over 205 m with every
## one of its 48 floors of windows set in real openings, the arcade of
## inclined truss legs round the glazed lobby at its foot, the elevator
## and stair wings rising vertically from the 29th floor on the east and
## west faces, and the 64 m aluminium-clad spire to 260 m.
static func transamerica_pyramid(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("limestone", "#E9E6DD", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#3B4750"))
	lm.use("Spire", LandmarkMaterials.paint("#D8DCDF", 0.3, 0.8))
	lm.use("Base", LandmarkMaterials.pbr("stone", "#8E8A82", 4.0))
	lm.use("Light", LandmarkMaterials.lit("#F2E6C8", 0.5))
	var hw_at := func(y: float) -> float: return 26.5 - 19.5 * y / TRANS_PYRAMID_M
	# Mass inset behind the window skin, from the arcade up.
	var skin := 0.4
	lm.spire("Concrete", Vector3(0, TRANS_ARCADE_M, 0), hw_at.call(TRANS_ARCADE_M) - skin,
		TRANS_PYRAMID_M - TRANS_ARCADE_M, 7.0 - skin)
	var storey := (TRANS_PYRAMID_M - TRANS_ARCADE_M - 4.0) / 44.0
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * q)
		var y := TRANS_ARCADE_M
		while y + storey <= TRANS_PYRAMID_M - 4.0:
			_trans_floor(lm, r, y, storey, hw_at.call(y), hw_at.call(y + storey), skin, q % 2 == 1 and y > 106.0)
			y += storey
	# Elevator (east) and stair (west) wings from the 29th floor.
	for s in [-1.0, 1.0]:
		lm.box("Concrete", Vector3(s * 10.5, 160.5, 0), Vector3(12.0, 103.0, 8.0))
		for k in 24:
			lm.box("Glass", Vector3(s * 10.5, 112.0 + 4.0 * k, 4.02), Vector3(0.8, 1.6, 0.06), Basis(), 0.0)
			lm.box("Glass", Vector3(s * 10.5, 112.0 + 4.0 * k, -4.02), Vector3(0.8, 1.6, 0.06), Basis(), 0.0)
	# Arcade: glazed lobby set back behind the inclined legs.
	var lb: float = hw_at.call(TRANS_ARCADE_M) - 4.0
	lm.box("Glass", Vector3(0, TRANS_ARCADE_M * 0.5, 0), Vector3(lb * 2.0, TRANS_ARCADE_M, lb * 2.0))
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * q)
		var top_hw: float = hw_at.call(TRANS_ARCADE_M)
		lm.box("Concrete", r * Vector3(0, TRANS_ARCADE_M - 1.0, top_hw - 0.6), Vector3(top_hw * 2.0, 2.0, 1.4), r)
		var nleg := 8
		for k in nleg + 1:
			var x := -top_hw + top_hw * 2.0 * float(k) / float(nleg)
			var foot := r * Vector3(x * 0.98, 0.6, 26.5 - 0.6)
			var head_l := r * Vector3(x - top_hw / float(nleg), TRANS_ARCADE_M - 2.0, top_hw - 0.6)
			var head_r := r * Vector3(x + top_hw / float(nleg), TRANS_ARCADE_M - 2.0, top_hw - 0.6)
			if k > 0:
				lm.beam("Concrete", foot, head_l, 1.0, 1.0)
			if k < nleg:
				lm.beam("Concrete", foot, head_r, 1.0, 1.0)
	# Spire: aluminium panels, the lit crown light near the top.
	var sb := Vector3(0, TRANS_PYRAMID_M, 0)
	lm.spire("Spire", sb, 7.0, TRANS_TIP_M - TRANS_PYRAMID_M, 0.3)
	for k in 6:
		var y := 6.0 + 8.0 * k
		var hw := 7.0 - 6.7 * y / (TRANS_TIP_M - TRANS_PYRAMID_M)
		lm.spire("Spire", sb + Vector3(0, y, 0), hw + 0.15, 0.4, hw + 0.13)
	var ly := 46.0
	var lw := 7.0 - 6.7 * ly / (TRANS_TIP_M - TRANS_PYRAMID_M)
	lm.spire("Light", sb + Vector3(0, ly, 0), lw + 0.05, 2.0, lw - 0.25)
	lm.box("Base", Vector3(0, 0.3, 0), Vector3(62.0, 0.6, 62.0))
	lm.commit(model)

## One floor of a pyramid face (turned by r, facing +Z before the turn):
## a spandrel band, then piers between real window openings with their
## reveals and glass, on the face sloping from half-width hw0 at y to
## hw1 at y + h. `wing` leaves the middle clear for a wing.
static func _trans_floor(lm: LandmarkMesh, r: Basis, y: float, h: float, hw0: float, hw1: float, skin: float,
		wing: bool) -> void:
	var slope := (hw0 - hw1) / h
	var n := (r * Vector3(0, slope, 1.0)).normalized()
	var P := func(x: float, yy: float, d: float) -> Vector3:
		var hw := hw0 - slope * (yy - y)
		return r * Vector3(x * (hw - skin) / maxf(hw0 - skin, 0.01), yy, hw - skin + d)
	var sp := h * 0.45
	var wy0 := y + sp
	var wy1 := y + h
	# Spandrel band across the face.
	lm.quad("Concrete", P.call(-hw0, y, skin), P.call(hw0, y, skin), P.call(hw0, wy0, skin),
		P.call(-hw0, wy0, skin), n)
	var count := maxi(4, floori(hw0 * 2.0 / 2.3))
	var pitch := hw0 * 2.0 / float(count)
	var ww := pitch * 0.62
	var px := -hw0
	for i in count:
		var cx := -hw0 + pitch * (float(i) + 0.5)
		if wing and absf(cx) < 4.6:
			continue
		var x0 := cx - ww * 0.5
		var x1 := cx + ww * 0.5
		lm.quad("Concrete", P.call(px, wy0, skin), P.call(x0, wy0, skin), P.call(x0, wy1, skin), P.call(px, wy1, skin), n)
		lm.quad("Concrete", P.call(x0, wy0, skin), P.call(x0, wy0, 0.0), P.call(x0, wy1, 0.0), P.call(x0, wy1, skin),
			r * Vector3(1, 0, 0))
		lm.quad("Concrete", P.call(x1, wy0, 0.0), P.call(x1, wy0, skin), P.call(x1, wy1, skin), P.call(x1, wy1, 0.0),
			r * Vector3(-1, 0, 0))
		lm.quad("Concrete", P.call(x0, wy0, 0.0), P.call(x0, wy0, skin), P.call(x1, wy0, skin), P.call(x1, wy0, 0.0),
			Vector3.UP)
		lm.quad("Concrete", P.call(x0, wy1, skin), P.call(x1, wy1, skin), P.call(x1, wy1, 0.0), P.call(x0, wy1, 0.0),
			Vector3.DOWN)
		lm.quad("Glass", P.call(x0, wy0, 0.03), P.call(x1, wy0, 0.03), P.call(x1, wy1, 0.03), P.call(x0, wy1, 0.03), n)
		px = x1
	lm.quad("Concrete", P.call(px, wy0, skin), P.call(hw0, wy0, skin), P.call(hw0, wy1, skin), P.call(px, wy1, skin), n)

## Flatiron Building (1902, Daniel Burnham): the 87 m wedge on its
## triangular block, 60.2 m along Fifth Avenue (east), 65.4 m along
## Broadway and 26 m on 22nd Street, its prow rounded at the north end.
## Three rusticated limestone storeys, the transitional fourth with its
## frieze, the terracotta shaft with every storey of windows in real
## openings and the three shallow oriel bays on each long front, the
## three-storey capital, string courses and the deep projecting cornice,
## and the one-storey cowcatcher shop in front of the prow.
static func flatiron(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Limestone", LandmarkMaterials.pbr("limestone", "#D6CFBF", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E1DACB", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2F3A40"))
	lm.use("Metal", LandmarkMaterials.paint("#4A4F4C", 0.5, 0.5))
	# Corners: prow (north), Fifth Ave/22nd St (SE), Broadway/22nd St (SW).
	var prow := Vector2(14.0, -32.2)
	var se := Vector2(14.0, 28.0)
	var sw := Vector2(-12.0, 28.0)
	# The prow is rounded off about 2 m wide between the two fronts.
	var on_broadway := prow + (sw - prow).normalized() * 1.8
	var raw := PackedVector2Array([prow + Vector2(-0.25, 0.7), prow + Vector2(0.0, 1.6), se, sw, on_broadway])
	var c := (prow + se + sw) / 3.0
	var poly := PackedVector2Array()
	for p in raw:
		poly.append(p - c)
	var skin := 0.35
	var core := _grow(poly, -skin)
	lm.poly_prism("Limestone", core, 0.0, FLATIRON_TOP_M - 3.0)
	# The three long fronts with real window openings.
	var fronts := [[poly[1], poly[2]], [poly[2], poly[3]], [poly[3], poly[4]]]
	for f in fronts:
		var a: Vector2 = f[0]
		var b: Vector2 = f[1]
		var length := a.distance_to(b)
		var dir := (b - a) / length
		var nn := Vector2(dir.y, -dir.x)
		if nn.dot((a + b) * 0.5) < 0.0:
			nn = -nn
		var right := Vector3(dir.x, 0, dir.y)
		var n := Vector3(nn.x, 0, nn.y)
		var o := Vector3(a.x, 0, a.y) - n * skin
		var bays := floori(length / 3.1)
		LandmarkDetail.pierced_face(lm, "Limestone", "Glass", o, right, n, length, FLATIRON_STOREY_M * 3.0, bays, 3,
			Vector2(1.6, 2.4), 0.9, FLATIRON_STOREY_M, skin)
		LandmarkDetail.pierced_face(lm, "Trim", "Glass", o + Vector3(0, FLATIRON_STOREY_M * 3.0, 0), right, n, length,
			FLATIRON_TOP_M - 3.0 - FLATIRON_STOREY_M * 3.0, bays, 19, Vector2(1.3, 2.3), 0.8, FLATIRON_STOREY_M, skin)
		var basis := Basis(right, Vector3.UP, n)
		# Rusticated base joints, string courses, the 4th-storey frieze.
		for k in 5:
			lm.box("Limestone", o + right * length * 0.5 + n * (skin + 0.02) + Vector3(0, 1.4 + 2.0 * k, 0),
				Vector3(length, 0.08, 0.08), basis, 0.0)
		for y in [FLATIRON_STOREY_M * 3.0, FLATIRON_STOREY_M * 4.0, FLATIRON_STOREY_M * 18.0]:
			lm.box("Trim", o + right * length * 0.5 + n * (skin + 0.2) + Vector3(0, y, 0),
				Vector3(length + 0.6, 0.5, 0.45), basis, 0.0)
		# Oriel bays: three shallow bays on the long fronts, storeys 6-17.
		if length > 40.0:
			for k in 3:
				var t := 0.22 + 0.28 * float(k)
				var oc := o + right * length * t + n * (skin + 0.45)
				var y0 := FLATIRON_STOREY_M * 5.0
				var y1 := FLATIRON_STOREY_M * 17.0
				lm.box("Trim", oc + Vector3(0, (y0 + y1) * 0.5, 0), Vector3(4.6, y1 - y0, 0.9), basis)
				for s in 3:
					var yy := y0 + FLATIRON_STOREY_M * (float(s) * 4.0 + 1.5)
					lm.box("Trim", oc + Vector3(0, yy, 0) + n * 0.5, Vector3(4.8, 0.35, 0.3), basis, 0.0)
				for st in 12:
					var yy := y0 + FLATIRON_STOREY_M * (float(st) + 0.55)
					lm.box("Glass", oc + Vector3(0, yy, 0) + n * 0.46, Vector3(3.0, 2.0, 0.04), basis, 0.0)
		# Cornice: a deep moulded cornice with dentils over the capital.
		LandmarkDetail.cornice(lm, "Trim", Vector3(a.x, FLATIRON_TOP_M - 3.0, a.y), Vector3(b.x, FLATIRON_TOP_M - 3.0, b.y),
			n, 1.8, true)
	lm.poly_prism("Trim", _grow(poly, 0.3), FLATIRON_TOP_M - 1.2, FLATIRON_TOP_M)
	# Attic set back on the roof.
	lm.poly_prism("Limestone", _grow(poly, -3.0), FLATIRON_TOP_M - 3.0, FLATIRON_TOP_M - 0.2)
	# The prow: three sash windows a storey round its narrow point.
	var pv := Vector3(poly[0].x, 0, poly[0].y)
	for st in 18:
		lm.box("Glass", pv + Vector3(-0.3, FLATIRON_STOREY_M * (float(st) + 4.0) + 1.6, -0.45),
			Vector3(1.0, 2.2, 0.06), Basis(Vector3.UP, 0.4), 0.0)
	# Cowcatcher shop in front of the prow.
	lm.box("Limestone", pv + Vector3(-1.5, 2.0, -3.0), Vector3(3.6, 4.0, 7.6), Basis(Vector3.UP, 0.4))
	lm.box("Metal", pv + Vector3(-1.5, 4.15, -3.0), Vector3(3.9, 0.3, 7.9), Basis(Vector3.UP, 0.4), 0.0)
	lm.commit(model)

static func _grow(poly: PackedVector2Array, by: float) -> PackedVector2Array:
	var out: Array = Geometry2D.offset_polygon(poly, by, Geometry2D.JOIN_MITER)
	return out[0]
