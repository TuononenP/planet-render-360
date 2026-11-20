extends RefCounted

## Clarion Hotel Helsinki (Haahtela architects / Anttinen Oiva, 2016), the
## chequered grey hotel on Jätkäsaari's Hietalahti quay. Origin at the hotel
## entry (OSM way 441505566); the outlines of the two 16-storey towers
## (building:part ways 458878736 and 458878737) and the atrium between them
## are in LandmarkFhInnerFootprints, yaw 0.
##
## From the Commons photos (visual-plan/refs/landmarks/clarion_hotel/):
## - Two slab towers on a glazed podium carried on V-shaped pilotis, joined by
##   a blue glass atrium that rises almost to the lower roof.
## - The facade is a diagonal chequer of three tones: pale panels, mid-grey
##   panels and recessed blue-grey windows, shifting one bay a storey; the
##   panels are folded, which the model shows as a proud mid-grey tile.
## - The taller south tower ends in a dark glazed sky-bar band, the lit
##   "CLARION HOTEL HELSINKI" sign and a plant storey; the north tower is
##   about 12 m lower and carries the rooftop pool's glass box.
##
## Measured: footprints, the 78 m published height (City LoD2 reads 72.2 m).
## Estimated: the 66 m north roof, the 9.2 m podium deck, storey pitch,
## the three tones and the sign position.

const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")
const I = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_inner_footprints.gd")

const ENTRY := {"type": "clarion_hotel", "skyline": true, "name": "Clarion Hotel Helsinki", "lat": 60.159757, "lon": 24.922101,
	"radius_m": 5000.0, "wiki_title": "Clarion Hotel Helsinki", "height_m": 78.0, "clear_m": 14.0,
	"clear_offsets_m": [[-1.0, 16.0], [-1.0, -18.0], [-2.0, 34.0], [-2.0, 46.0]],
	"kind": "Hotel", "aliases": ["clarion hotel helsinki", "clarion hotel", "clarion jätkäsaari",
		"hotel clarion helsinki"]}

const CLARION_M := 78.0
const CLARION_LOW_M := 66.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Panel", LandmarkMaterials.pbr("concrete", "#D9DBDA", 2.0))
	lm.use("Mid", LandmarkMaterials.pbr("concrete", "#8E959A", 2.0))
	lm.use("Dark", LandmarkMaterials.paint("#3C474F", 0.55, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#2D4250"))
	lm.use("Atrium", LandmarkMaterials.glass("#3F6F86"))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#BDB8AE", 3.0))
	lm.use("Roof", LandmarkMaterials.paint("#55595A", 0.8))
	lm.use("Lamp", LandmarkMaterials.lit("#FFF1CF", 1.0))
	var podium := I.outline("clarion_hotel")
	var deck := 9.2
	lm.poly_prism("Glass", F.offset(podium, -0.4), 0.0, deck - 0.6)
	lm.poly_prism("Concrete", podium, deck - 0.6, deck)
	var south := W._poly(I.CLARION_SOUTH)
	var north := W._poly(I.CLARION_NORTH)
	for t: Array in [[south, CLARION_M - 8.0], [north, CLARION_LOW_M - 2.0]]:
		var poly: PackedVector2Array = t[0]
		var top: float = t[1]
		_pilotis(lm, F.offset(poly, -0.6), deck)
		lm.poly_prism("Panel", poly, deck, top)
		_checker(lm, poly, deck, top, 1.6, 3.8)
	# The sky bar's dark glass storey, its lit sign and the plant storeys.
	lm.poly_prism("Dark", F.offset(south, 0.05), CLARION_M - 8.0, CLARION_M - 4.0)
	W.ribs(lm, "Mid", south, CLARION_M - 8.0, CLARION_M - 4.0, 1.6, 0.12, 0.12)
	lm.poly_prism("Panel", south, CLARION_M - 4.0, CLARION_M)
	lm.poly_prism("Roof", F.offset(south, -0.4), CLARION_M - 0.3, CLARION_M - 0.1)
	_sign(lm, south, CLARION_M - 2.6)
	# The rooftop pool's glass box on the lower tower.
	lm.poly_prism("Roof", F.offset(north, -0.4), CLARION_LOW_M - 2.0, CLARION_LOW_M - 1.8)
	lm.poly_prism("Glass", F.offset(north, -3.0), CLARION_LOW_M - 2.0, CLARION_LOW_M)
	var atrium := W._poly(I.CLARION_ATRIUM)
	lm.poly_prism("Atrium", atrium, deck, CLARION_LOW_M - 3.0)
	W.ribs(lm, "Dark", atrium, deck, CLARION_LOW_M - 3.0, 1.6, 0.08, 0.1)
	lm.commit(model, "Clarion_")

## Slanted pilotis: pairs of posts leaning together under the tower foot.
static func _pilotis(lm: LandmarkMesh, poly: PackedVector2Array, deck: float) -> void:
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var n := int(a.distance_to(b) / 6.0)
		for k in n + 1:
			var p := a.lerp(b, float(k) / float(maxi(n, 1)))
			var out := W.outward(poly, a, b)
			var q := p - out * 0.9
			lm.beam("Concrete", Vector3(p.x + out.x * 0.5, 0.0, p.y + out.y * 0.5), Vector3(q.x, deck, q.y), 0.5)

## Diagonal chequer of three tones over the shaft: recessed windows, proud
## mid-grey fold tiles and plain pale panels, shifting a bay a storey.
static func _checker(lm: LandmarkMesh, poly: PackedVector2Array, y0: float, y1: float, bay: float,
		pitch: float) -> void:
	var rows := int((y1 - y0) / pitch)
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var n := int(a.distance_to(b) / bay)
		if n < 2:
			continue
		var along := (b - a).normalized()
		var out := W.outward(poly, a, b)
		var out3 := Vector3(out.x, 0, out.y)
		var w := a.distance_to(b) / float(n)
		var basis := Basis(Vector3.UP, atan2(-along.y, along.x))
		for r in rows:
			for k in n:
				var tone := (k + r + i) % 3
				var c := a + along * (w * (float(k) + 0.5))
				var yc := y0 + pitch * (float(r) + 0.5)
				if tone == 0:
					lm.box("Mid", Vector3(c.x, yc, c.y) + out3 * 0.05, Vector3(w * 0.96, pitch * 0.96, 0.1), basis, 0.0)
				elif tone == 1:
					var hw := w * 0.36
					var p0 := c - along * hw + out * 0.04
					var p1 := c + along * hw + out * 0.04
					var yb := yc - pitch * 0.36
					var yt := yc + pitch * 0.36
					lm.quad("Glass", Vector3(p0.x, yb, p0.y), Vector3(p1.x, yb, p1.y), Vector3(p1.x, yt, p1.y),
						Vector3(p0.x, yt, p0.y), out3)

## The sign band: a row of lit blocks across the south face of the tower.
static func _sign(lm: LandmarkMesh, poly: PackedVector2Array, y: float) -> void:
	var best := 0
	var best_len := 0.0
	for i in poly.size():
		var l := poly[i].distance_to(poly[(i + 1) % poly.size()])
		if l > best_len:
			best_len = l
			best = i
	var a := poly[best]
	var b := poly[(best + 1) % poly.size()]
	var along := (b - a).normalized()
	var out := W.outward(poly, a, b)
	var basis := Basis(Vector3.UP, atan2(-along.y, along.x))
	for k in 18:
		var c := a.lerp(b, (float(k) + 0.5) / 18.0) + out * 0.12
		lm.box("Lamp", Vector3(c.x, y, c.y), Vector3(0.55, 0.9, 0.08), basis, 0.0)
