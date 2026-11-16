class_name LandmarkFhCrownBridge
extends RefCounted

## Kruunuvuorensilta (Crown Bridge, 2026), Finland's longest and tallest
## bridge: 1191 m of curved composite deck from Korkeasaari's Palosaari
## tip to Kruunuvuorenranta carrying two tram tracks on its north half
## and the cycle path and footway on its south edge behind a wind screen,
## hung from one 135 m white concrete pylon by 17 pairs of stays each
## way (68 cables, 90 to 257 m long) in two planes. The pylon is a
## slender needle standing through the deck's median on the artificial
## islet between Nimismies and Emäntä: two legs in line along the bridge
## forming a slim diamond, each an octagon in section, rising as a V from
## one foot on the islet,
## widest apart at the deck and merging two thirds of the way up; near
## the top (cast in lifts, the joints showing as fine lines) a tall
## rectangular opening in each end face holds the cable
## boxes, and from them the stays fan out to brackets outside both deck
## edges. Both stayed spans, 260 m each way from the pylon, stand free of
## piers; the eastern one over the channel keeps 20 m clearance. Beyond
## them both approaches rest on V piers 64 to 70 m apart.
## Built along the bridge's mapped curve (KruunuvuorensiltaLine) at yaw 0,
## y = 0 at sea level. The deck crests at 24 m over the main span, lands
## at 3.5 m on the Kruunuvuorenranta shore and 7 m on the Palosaari
## underpass, at most 5 % grade (City of Helsinki elevation model 2021
## for the landings). Span split, pier spacing and deck depth are
## estimated from photographs: no source lists them.

const STEP_M := 6.0
const DEPTH_M := 2.6
const TOP_M := 24.0
const WEST_Y := 7.0
const EAST_Y := 3.5
const ROUND_M := 3.0
const CREST_BACK_M := 30.0
const CREST_MAIN_M := 300.0
const MAIN_SPAN_M := 260.0
const BACK_SPAN_M := 260.0
const PIER_STEP_M := 70.0
## The pylon's axis, metres south of the deck centre line: in the median
## between the tramway's separator and the cycle path.
const PYLON_X := 2.6
## Where the slit between the two legs closes and the solid shaft starts.
const JOIN_M := 92.0
## The pylon is a slim diamond along the deck: its two legs rise as a V
## from one foot on the plinth, are widest apart at the deck (the slit's
## half-width SLIT_DECK there) and close again as a long A at JOIN_M.
## Its outer half-length along the deck at the plinth (x), at the knee
## in the deck (y) and at the mast top (z), and its half-thickness across
## the deck at the water (x) and the mast top (y), metres.
const LEG_OUT := Vector3(3.6, 5.0, 1.9)
const LEG_THICK := Vector2(1.6, 1.1)
const SLIT_DECK := 1.75
## The legs are eight-sided: every corner is cut back by this share of
## the leg's thickness across the deck (0.29 makes a near-regular
## octagon). Above JOIN_M the cut eases to HEAD_CHAMFER_M at the cable
## opening's sill, so the opening's side walls keep their thickness.
const CHAMFER_SHARE := 0.29
const HEAD_CHAMFER_M := 0.3
## The pylon was cast in lifts: a casting joint shows as a thin darker
## line round it every this many metres.
const LIFT_M := 4.2
## The light concrete edge band of the deck's fascia reaches this far
## below the deck top; the dark steel girder shows under it.
const FASCIA_BAND_M := 0.45
## The artificial rock islet under the pylon: half-lengths along and
## across the deck and its top over the sea, metres.
const ISLET_HALF := Vector2(30.0, 42.0)
const ISLET_TOP_M := 1.9
## The cable opening near the top, a rectangle in each end face of the
## pylon (the faces looking along the deck, where the stays enter): its
## sill and head heights and its half-width across the deck, metres. It
## frames the cable zone (kruunusillat.fi: 101 to 122 m). The steel cable
## boxes fill it SLOT_INSET_M behind each face.
const SLOT_M := Vector2(99.0, 124.0)
const SLOT_HALF := 0.65
const SLOT_INSET_M := 0.7
## The legs stand on the islet plinth at this height.
const PLINTH_TOP_M := 3.8
## The kerbed median island round the legs on the deck: its half-length
## along the deck, metres.
const ISLAND_HALF_M := 14.0
## The pier legs and the pylon's islet plinth reach this far below the
## waterline, so nothing floats and no base shows above the water.
const CAP_DEPTH_M := 4.0
const MAST_TOP_M := 131.5
const PYLON_TOP_M := 135.0
## Stay pairs per direction (kruunusillat.fi, YIT: 17 each way, one
## cable of a pair on each deck edge) and their deck reach, metres from
## the pylon; the farthest is anchored highest in the cable opening.
const STAYS_EAST := 17
const STAYS_WEST := 17
const REACH_EAST := Vector2(44.0, 236.0)
const REACH_WEST := Vector2(40.0, 214.0)
const MAST_ANCHORS := Vector2(101.0, 122.0)
## A stay's ends, metres: on the cable boxes in the opening facing its
## span, this far to its own side of the pylon's axis; at the deck on a bracket this far outside the edge (far
## enough that the straight cable clears the fence where the curving deck
## swings under it) and this far below the deck top. It ends there in a
## collar and a black anchor pipe (LandmarkFhStayAnchor).
const STAY_TOP_HALF := 0.25
const STAY_OUT_M := 1.2
const STAY_DROP_M := 0.9
## Cross-section, metres from the centre line (positive south): the
## tramway's north edge, metre-gauge tracks, the kerbed separator, the
## cycle path and footway.
const TRAM_EDGE := -7.5
const TRACKS: Array[float] = [-5.4, -1.8]
const GAUGE_HALF := 0.5
## Rail-head height over the deck top.
const RAIL_TOP_M := 0.12
const SEPARATOR := Vector2(0.3, 0.9)
## The separator: a concrete kerb this high over the deck top, carrying a
## fence of light vertical slats (SLAT_M apart) up to its top rail; and
## the tram slab's height, just under the rail heads (grooved rails
## nearly flush).
const KERB_M := 0.3
const DIVIDER_M := 1.35
const SLAT_M := 0.15
const SLAB_M := 0.1
## The footway along the south fence, metres wide: it keeps this width
## and the two-way cycle path takes the rest of the deck (about 4 m on
## the spans, more where the deck widens round the pylon).
const FOOTWAY_M := 3.0
## Catenary and lighting poles every this many deck samples.
const POLE_EVERY := 6
const POLE_FIRST := 3
## Pole top (where the Y head forks), the cantilever tube, the contact
## wires over the deck top, and the reach of each Y arm, metres.
const POLE_TOP_M := 8.2
const ARM_Y := 6.6
const WIRE_Y := 5.9
const HEAD_HALF := 3.2
## The poles stand midway between the tracks.
const POLE_X := -3.6
## South fence: fin spacing along the deck and its handrail's top over
## the deck, metres.
const FIN_STEP_M := 0.5
const FIN_RAIL_M := 1.3
## Night light, matched to night photos: the pylon washed in saturated
## blue, the stays glowing faintly blue, and the deck a warm white band
## under the poles with the handrail LED lines along both edges
## (LandmarkLights energy shares).
const PYLON_WASH := Color(0.36, 0.48, 1.0)
const PYLON_LIGHT := 2.0
const STAY_GLOW := Color("#5F7DFF")
const DECK_WARM := Color(1.0, 0.86, 0.62)
const DECK_LIGHT := 0.45
## Downlight range, metres: from the pole head (~8 m up) to the deck
## halfway to the next pole (poles 36 m apart).
const DECK_REACH_M := 22.0
## Fill light midway between poles, standing in for the handrails' LED
## lines that light the paths evenly: height over the deck (m), reach
## (m) and energy against DECK_LIGHT.
const FILL_Y_M := 4.5
const FILL_REACH_M := 16.0
const FILL_SHARE := 0.9
## Cone falloff of the deck lights: flat, so each pool is even across
## its width instead of a hot spot under the lamp.
const DECK_FALLOFF := 0.6
## Red glow of the top aviation light on the mast cap: a small spot just
## above it, aimed down, energy share and reach (m).
const BEACON_RED := Color(1.0, 0.08, 0.03)
const BEACON_GLOW := 0.5
const BEACON_REACH_M := 7.0
## Night halo radius (m) round the top aviation light and the mast's
## lower pairs; the top one glows widest, as in night photos.
const TOP_HALO_M := 9.0
## Heights (m) of the mast's paired aviation lights below the top one.
const MAST_BEACON_Y: Array[float] = [72.0, 102.0]
const MAST_HALO_M := 4.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#E3E1DA", 4.0))
	lm.use("Footing", LandmarkMaterials.pbr("rock", "#8E8B84", 3.0))
	lm.use("Girder", LandmarkMaterials.paint("#5E6367", 0.5, 0.3))
	lm.use("Track", LandmarkMaterials.pbr("concrete", "#B4B1AA", 3.0))
	lm.use("Cycle", LandmarkMaterials.pbr("asphalt", "#7C4236", 4.0))
	lm.use("Footway", LandmarkMaterials.pbr("asphalt", "#4A4B4C", 4.0))
	var marking := LandmarkMaterials.paint("#EDEDE8", 0.7, 0.0)
	lm.use("Marking", marking)
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#B0ACA3", 3.0))
	lm.use("Steel", LandmarkMaterials.paint("#B9BEC2", 0.45, 0.55))
	lm.use("Slats", _slat_material())
	var pole := LandmarkMaterials.paint("#3B4045", 0.5, 0.45)
	lm.use("Pole", pole)
	lm.use("Fitting", LandmarkMaterials.paint("#A8864E", 0.4, 0.7))
	lm.use("StayLamp", _stay_material())
	lm.use("Rail", LandmarkMaterials.paint("#4F5254", 0.35, 0.8))
	lm.use("Lamp", LandmarkMaterials.lit("#FFD892", 2.8))
	lm.use("BeaconLamp", LandmarkMaterials.lit("#FF0602", 12.0))
	var plan := _plan()
	_deck(lm, plan)
	_rails(lm, plan)
	_railings(lm, plan)
	_poles(lm, plan)
	_piers(lm)
	_pylon(lm)
	_stays(lm, LandmarkFhStayAnchor.part(pole, marking))
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, flood_spots())
	model.set_meta(LandmarkLights.HALO_META, beacon_halos())

## White stays by day: built with no glow of their own, so they stay
## plain white wherever nothing follows the night. Where the hero is
## dressed ("Lamp" parts follow the night) they glow faintly blue after
## dark, as the lit cable fans do over the water.
static func _stay_material() -> StandardMaterial3D:
	var m := LandmarkMaterials.paint("#F1F2F0", 0.4, 0.2).duplicate() as StandardMaterial3D
	m.emission_enabled = true
	m.emission = STAY_GLOW
	m.emission_energy_multiplier = 0.0
	m.set_meta(LandmarkLights.NIGHT_GLOW_META, 0.35)
	return m

## Light grey slats with see-through gaps: a stripe mask repeating every
## SLAT_M along the deck (strip UV v runs in metres along it), both sides
## drawn.
static func _slat_material() -> StandardMaterial3D:
	var img := Image.create(2, 8, false, Image.FORMAT_RGBA8)
	for y in 8:
		var a := 1.0 if y < 5 else 0.0
		for x in 2:
			img.set_pixel(x, y, Color(1, 1, 1, a))
	# Mipmapped: from afar the stripes average to a solid light fence.
	img.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("#C9CCCE")
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	m.uv1_scale = Vector3(1.0, 1.0 / SLAT_M, 1.0)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.metallic = 0.4
	m.roughness = 0.45
	return m

## Length of the deck centre line, metres.
static func length_m() -> float:
	var cum := _cumulative()
	return cum[cum.size() - 1]

## Arc length of the pylon along the centre line.
static func pylon_s() -> float:
	var cum := _cumulative()
	var c := KruunuvuorensiltaLine.CENTRE
	var best := INF
	var found := 0.0
	for i in c.size() - 1:
		var a := Vector2(c[i].x, c[i].y)
		var b := Vector2(c[i + 1].x, c[i + 1].y)
		var q := Geometry2D.get_closest_point_to_segment(KruunuvuorensiltaLine.PYLON_XZ, a, b)
		var d := q.distance_to(KruunuvuorensiltaLine.PYLON_XZ)
		if d < best:
			best = d
			found = cum[i] + a.distance_to(q)
	return found

## Deck top over the sea at arc length s: ramps from both landings that
## meet the crest over the main span, rounded into vertical curves.
static func deck_y(s: float) -> float:
	var sp := pylon_s()
	var total := length_m()
	var west := WEST_Y + (TOP_M - WEST_Y) * s / (sp - CREST_BACK_M)
	var east := EAST_Y + (TOP_M - EAST_Y) * (total - s) / (total - sp - CREST_MAIN_M)
	return _smin(_smin(west, east), TOP_M)

## Centre (x, z) and half-width at arc length s.
static func at(s: float) -> Vector3:
	var cum := _cumulative()
	var c := KruunuvuorensiltaLine.CENTRE
	s = clampf(s, 0.0, cum[cum.size() - 1])
	for i in c.size() - 1:
		if s <= cum[i + 1] or i == c.size() - 2:
			var f := (s - cum[i]) / maxf(cum[i + 1] - cum[i], 0.001)
			return c[i].lerp(c[i + 1], clampf(f, 0.0, 1.0))
	return c[c.size() - 1]

## Rail-head centre of track `track` (a TRACKS offset, metres south of
## the centre line) at arc length s, model-local metres: where _rails
## lays it, shared with the trams that ride it (BridgeTramDeck).
static func rail_point(s: float, track: float) -> Vector3:
	var c := at(s)
	var t := heading(s)
	return Vector3(c.x - t.y * track, deck_y(s) + RAIL_TOP_M, c.y + t.x * track)

## Unit heading (x, z) at arc length s.
static func heading(s: float) -> Vector2:
	var a := at(s - 1.0)
	var b := at(s + 1.0)
	return Vector2(b.x - a.x, b.y - a.y).normalized()

## Arc length at each centre point.
static func _cumulative() -> PackedFloat32Array:
	var c := KruunuvuorensiltaLine.CENTRE
	var cum := PackedFloat32Array([0.0])
	for i in range(1, c.size()):
		cum.append(cum[i - 1] + Vector2(c[i].x, c[i].y).distance_to(Vector2(c[i - 1].x, c[i - 1].y)))
	return cum

static func _smin(a: float, b: float) -> float:
	return 0.5 * (a + b - sqrt((a - b) * (a - b) + ROUND_M * ROUND_M))

## Deck samples every STEP_M: arc length, centre (x, z), half-width,
## deck top and the lateral unit vector (pointing south of the heading).
static func _plan() -> Dictionary:
	var total := length_m()
	var n := ceili(total / STEP_M)
	var s := PackedFloat32Array()
	var p := PackedVector3Array()
	var lat := PackedVector3Array()
	for k in n + 1:
		var sk := total * float(k) / n
		var c := at(sk)
		var t := heading(sk)
		s.append(sk)
		p.append(Vector3(c.x, deck_y(sk), c.y))
		lat.append(Vector3(-t.y, 0.0, t.x))
	var h := PackedFloat32Array()
	for k in n + 1:
		h.append(at(s[k]).z)
	return {"s": s, "p": p, "lat": lat, "h": h}

## Point of sample i at lateral offset `o` (base + edge * half-width)
## and dy over the deck top.
static func _sp(plan: Dictionary, i: int, o: Vector2, dy: float) -> Vector3:
	var h: float = plan["h"][i]
	var off := o.x + o.y * h
	return (plan["p"][i] as Vector3) + (plan["lat"][i] as Vector3) * off + Vector3.UP * dy

## Ribbon along the whole deck between section points (a, ya) and (b, yb)
## facing `out` (lateral, up).
static func _strip(lm: LandmarkMesh, plan: Dictionary, key: String, a: Vector2, ya: float, b: Vector2,
		yb: float, out: Vector2) -> void:
	var s: PackedFloat32Array = plan["s"]
	for i in s.size() - 1:
		var nrm := ((plan["lat"][i] as Vector3) * out.x + Vector3.UP * out.y).normalized()
		lm.quad(key, _sp(plan, i, a, ya), _sp(plan, i, b, yb), _sp(plan, i + 1, b, yb), _sp(plan, i + 1, a, ya),
			nrm, Vector2(0.0, -s[i]))

## Deck box (steel edge girders under the concrete slab, a sloped soffit)
## and the surfaces on it.
static func _deck(lm: LandmarkMesh, plan: Dictionary) -> void:
	var e := Vector2(0.0, 1.0)
	var w := Vector2(0.0, -1.0)
	var lip := 0.25
	# Fascias, soffit chamfers and soffit.
	# Each fascia: the light concrete edge band over the dark steel girder.
	_strip(lm, plan, "Concrete", w, lip, w, -FASCIA_BAND_M, Vector2(-1, 0))
	_strip(lm, plan, "Girder", w, -FASCIA_BAND_M, w, -1.0, Vector2(-1, 0))
	_strip(lm, plan, "Girder", w, -1.0, Vector2(1.8, -1.0), -DEPTH_M, Vector2(-1, -1.1))
	_strip(lm, plan, "Girder", Vector2(1.8, -1.0), -DEPTH_M, Vector2(-1.8, 1.0), -DEPTH_M, Vector2(0, -1))
	_strip(lm, plan, "Girder", Vector2(-1.8, 1.0), -DEPTH_M, e, -1.0, Vector2(1, -1.1))
	_strip(lm, plan, "Girder", e, -1.0, e, -FASCIA_BAND_M, Vector2(1, 0))
	_strip(lm, plan, "Concrete", e, -FASCIA_BAND_M, e, lip, Vector2(1, 0))
	# Edge beams.
	_strip(lm, plan, "Concrete", w, lip, Vector2(0.3, -1.0), lip, Vector2(0, 1))
	_strip(lm, plan, "Concrete", Vector2(0.3, -1.0), lip, Vector2(0.3, -1.0), 0.15, Vector2(1, 0))
	_strip(lm, plan, "Concrete", Vector2(-0.3, 1.0), lip, e, lip, Vector2(0, 1))
	_strip(lm, plan, "Concrete", Vector2(-0.3, 1.0), 0.05, Vector2(-0.3, 1.0), lip, Vector2(-1, 0))
	# North service strip, the tramway's light concrete slab, the
	# separator (a slat fence on a kerb), the two-way cycle path with its
	# dashed centre line and the asphalt footway along the fence.
	_strip(lm, plan, "Paving", Vector2(0.3, -1.0), 0.15, Vector2(TRAM_EDGE, 0.0), 0.15, Vector2(0, 1))
	_strip(lm, plan, "Paving", Vector2(TRAM_EDGE, 0.0), 0.15, Vector2(TRAM_EDGE, 0.0), SLAB_M, Vector2(1, 0))
	_strip(lm, plan, "Track", Vector2(TRAM_EDGE, 0.0), SLAB_M, Vector2(SEPARATOR.x, 0.0), SLAB_M, Vector2(0, 1))
	var sx := Vector2(SEPARATOR.x, 0.0)
	var sy := Vector2(SEPARATOR.y, 0.0)
	_strip(lm, plan, "Concrete", sx, SLAB_M, sx, KERB_M, Vector2(-1, 0))
	_strip(lm, plan, "Concrete", sx, KERB_M, sy, KERB_M, Vector2(0, 1))
	_strip(lm, plan, "Concrete", sy, KERB_M, sy, 0.05, Vector2(1, 0))
	# The slat fence on the kerb: one double-sided panel whose stripe
	# texture (period SLAT_M along the deck) cuts the gaps, under a flat
	# top rail.
	var mid := (sx + sy) * 0.5
	_strip(lm, plan, "Slats", mid, KERB_M, mid, DIVIDER_M - 0.05, Vector2(-1, 0))
	var ri := mid - Vector2(0.06, 0.0)
	var ro := mid + Vector2(0.06, 0.0)
	_strip(lm, plan, "Steel", ri, DIVIDER_M - 0.06, ri, DIVIDER_M, Vector2(-1, 0))
	_strip(lm, plan, "Steel", ri, DIVIDER_M, ro, DIVIDER_M, Vector2(0, 1))
	_strip(lm, plan, "Steel", ro, DIVIDER_M, ro, DIVIDER_M - 0.06, Vector2(1, 0))
	# The cycle path's south edge, kept FOOTWAY_M + the edge beam off the
	# south edge (offsets are x + edge * half-width, see _sp).
	var ce := Vector2(-0.3 - FOOTWAY_M, 1.0)
	_strip(lm, plan, "Cycle", sy, 0.05, ce, 0.05, Vector2(0, 1))
	var lane := (sy + ce) * 0.5
	var sp := pylon_s()
	for i in (plan["s"] as PackedFloat32Array).size() - 1:
		# No centre line where the pylon's island narrows the path.
		if absf(float(plan["s"][i]) - sp) < ISLAND_HALF_M + STEP_M:
			continue
		var a := _sp(plan, i, lane, 0.06)
		var b := a.lerp(_sp(plan, i + 1, lane, 0.06), 0.3)
		var l: Vector3 = (plan["lat"][i] as Vector3) * 0.06
		lm.quad("Marking", a - l, a + l, b + l, b - l, Vector3.UP)
	# A solid white line parts the cycle path from the footway, level with it.
	_strip(lm, plan, "Marking", ce - Vector2(0.15, 0.0), 0.06, ce, 0.06, Vector2(0, 1))
	_strip(lm, plan, "Footway", ce, 0.05, Vector2(-0.3, 1.0), 0.05, Vector2(0, 1))
	# Abutments under both ends and the Palosaari underpass wall.
	var total := length_m()
	for s: float in [0.0, 18.3, total]:
		var c := at(s)
		var t := heading(s)
		var y := deck_y(s) - DEPTH_M
		var basis := Basis(Vector3(t.x, 0, t.y), Vector3.UP, Vector3(-t.y, 0, t.x))
		var along := 2.0 if s > 1.0 and s < total - 1.0 else 6.0
		lm.box("Concrete", Vector3(c.x, (y - 1.0) * 0.5, c.y), Vector3(along, y + 1.0, c.z * 2.0 + 0.6), basis)

## Metre-gauge rails on both tracks: a raised head with its two sides.
static func _rails(lm: LandmarkMesh, plan: Dictionary) -> void:
	for track in TRACKS:
		for side: float in [-1.0, 1.0]:
			var o: float = track + side * GAUGE_HALF
			_strip(lm, plan, "Rail", Vector2(o - 0.04, 0.0), RAIL_TOP_M, Vector2(o + 0.04, 0.0), RAIL_TOP_M, Vector2(0, 1))
			_strip(lm, plan, "Rail", Vector2(o - 0.04, 0.0), 0.0, Vector2(o - 0.04, 0.0), RAIL_TOP_M, Vector2(-1, 0))
			_strip(lm, plan, "Rail", Vector2(o + 0.04, 0.0), RAIL_TOP_M, Vector2(o + 0.04, 0.0), 0.0, Vector2(1, 0))

## North railing (posts, a top rail, dense vertical bars) and the south fin fence,
## each with an LED strip under its handrail: they wash the paths and
## read from afar as two glowing lines along the curve.
static func _railings(lm: LandmarkMesh, plan: Dictionary) -> void:
	var north := Vector2(0.15, -1.0)
	var count: int = (plan["s"] as PackedFloat32Array).size()
	for i in count:
		var foot := _sp(plan, i, north, 0.25)
		lm.beam("Steel", foot, foot + Vector3.UP * 1.2, 0.12, 0.12)
		if i == count - 1:
			continue
		lm.beam("Steel", _sp(plan, i, north, 1.45), _sp(plan, i + 1, north, 1.45), 0.08, 0.08)
	# Dense vertical bars between the posts, as on the separator.
	_strip(lm, plan, "Slats", north, 0.3, north, 1.41, Vector2(1, 0))
	_fins(lm, plan)
	for rail: Array in [[1.0, FIN_RAIL_M - 0.17, 0.45, 0.31], [-1.0, 1.4, 0.21, 0.09]]:
		var edge: float = rail[0]
		var y: float = rail[1]
		var inner := Vector2(-float(rail[2]) * edge, edge)
		var outer := Vector2(-float(rail[3]) * edge, edge)
		_strip(lm, plan, "Lamp", inner, y, outer, y, Vector2(0, -1))
		_strip(lm, plan, "Lamp", inner, y, inner, y + 0.07, Vector2(-edge, 0))
		_strip(lm, plan, "Lamp", outer, y, outer, y + 0.07, Vector2(edge, 0))

## The south fence: light flat fins every FIN_STEP_M, slanted along the
## deck, in an S profile: from the kerb they lean in over the walkway,
## steepen up to the handrail, then curve back out over the water above
## it (two-sided panels, no edges, to stay in budget).
static func _fins(lm: LandmarkMesh, plan: Dictionary) -> void:
	var s: PackedFloat32Array = plan["s"]
	var edge := Vector2(-0.15, 1.0)
	for i in s.size() - 1:
		var a0 := _sp(plan, i, edge, 0.25)
		var a1 := _sp(plan, i + 1, edge, 0.25)
		var t := (a1 - a0).normalized()
		var lat: Vector3 = plan["lat"][i]
		var w := t * 0.06
		# In over the walkway, steeper up to the handrail, then back out.
		var rises: Array[Vector3] = [-lat * 0.16 + t * 0.08 + Vector3.UP * 0.5,
			-lat * 0.06 + t * 0.1 + Vector3.UP * (FIN_RAIL_M - 0.75),
			lat * 0.3 + t * 0.08 + Vector3.UP * 0.22]
		var n := maxi(1, roundi((s[i + 1] - s[i]) / FIN_STEP_M))
		for k in n:
			var a := a0.lerp(a1, float(k) / float(n))
			for rise in rises:
				var b := a + rise
				var nrm := rise.cross(t).normalized()
				lm.quad("Steel", a - w, a + w, b + w, b - w, -nrm)
				lm.quad("Steel", a + w, a - w, b - w, b + w, nrm)
				a = b
	# Handrail: a flat bar along the fins' inner face at the bend, its
	# sides and soffit.
	var hi := Vector2(-0.52, 1.0)
	var ho := Vector2(-0.24, 1.0)
	_strip(lm, plan, "Steel", hi, FIN_RAIL_M - 0.1, hi, FIN_RAIL_M, Vector2(-1, 0))
	_strip(lm, plan, "Steel", hi, FIN_RAIL_M, ho, FIN_RAIL_M, Vector2(0, 1))
	_strip(lm, plan, "Steel", ho, FIN_RAIL_M, ho, FIN_RAIL_M - 0.1, Vector2(1, 0))
	_strip(lm, plan, "Steel", ho, FIN_RAIL_M - 0.1, hi, FIN_RAIL_M - 0.1, Vector2(0, -1))

## Deck samples carrying a catenary pole (none round the pylon).
static func _pole_samples(plan: Dictionary) -> PackedInt32Array:
	var sp := pylon_s()
	var s: PackedFloat32Array = plan["s"]
	var out := PackedInt32Array()
	for i in range(POLE_FIRST, s.size() - 1, POLE_EVERY):
		if absf(s[i] - sp) >= 15.0:
			out.append(i)
	return out

## Combined catenary and lighting poles between the two tracks, feeding
## both: an anthracite pole on a footing block; a cantilever tube out
## over each track, each half braced by a tie from higher up, with a
## registration arm down to each contact wire and brass insulators; and a
## Y head whose upswept arms carry LED luminaires over both tracks.
static func _poles(lm: LandmarkMesh, plan: Dictionary) -> void:
	var x := POLE_X
	var last := -1
	for i in _pole_samples(plan):
		var lat: Vector3 = plan["lat"][i]
		var foot := _sp(plan, i, Vector2(x, 0.0), SLAB_M)
		lm.box("Footing", foot + Vector3.UP * 0.12, Vector3(0.45, 0.24, 0.45), Basis(Vector3.UP.cross(lat), Vector3.UP, lat))
		var top := foot + Vector3.UP * (POLE_TOP_M - SLAB_M)
		lm.beam("Pole", foot, top, 0.3, 0.22, lat)
		# Cantilever: out over both tracks, each half tied from higher up
		# the pole, an insulator at the pole.
		var ends: Array[float] = [TRACKS[0] - 1.0, TRACKS[1] + 1.0]
		lm.beam("Pole", _sp(plan, i, Vector2(ends[0], 0.0), ARM_Y), _sp(plan, i, Vector2(ends[1], 0.0), ARM_Y), 0.08)
		for end in ends:
			lm.beam("Pole", _sp(plan, i, Vector2(x, 0.0), ARM_Y + 0.9), _sp(plan, i, Vector2(lerpf(x, end, 0.7), 0.0), ARM_Y), 0.06)
			lm.box("Fitting", _sp(plan, i, Vector2(x + signf(end - x) * 0.35, 0.0), ARM_Y), Vector3(0.14, 0.14, 0.3), Basis(), 0.0)
		for track in TRACKS:
			var hang := _sp(plan, i, Vector2(track + signf(x - track) * 0.7, 0.0), ARM_Y)
			lm.box("Fitting", hang - Vector3.UP * 0.1, Vector3(0.1, 0.2, 0.1), Basis(), 0.0)
			lm.beam("Pole", hang, _sp(plan, i, Vector2(track, 0.0), WIRE_Y + 0.05), 0.04)
		# Y head: two arms rising half a metre to their tips, a lit bar
		# under the outer part of each.
		for end: float in [x - HEAD_HALF, x + HEAD_HALF]:
			var arm_tip := _sp(plan, i, Vector2(end, 0.0), POLE_TOP_M + 0.5)
			lm.beam("Pole", top, arm_tip, 0.16, 0.1)
			lm.beam("Lamp", top.lerp(arm_tip, 0.45) - Vector3.UP * 0.07, arm_tip - Vector3.UP * 0.07, 0.12, 0.03)
		if last >= 0:
			for track in TRACKS:
				lm.beam("Rail", _sp(plan, last, Vector2(track, 0.0), WIRE_Y), _sp(plan, i, Vector2(track, 0.0), WIRE_Y),
					0.05, 0.05)
		last = i

## Pier positions along the deck: none under either stayed span; the
## anchor pier closing each of them, then the approach piers beyond.
static func pier_s() -> PackedFloat32Array:
	var sp := pylon_s()
	var total := length_m()
	var out := PackedFloat32Array()
	var s := sp - BACK_SPAN_M
	while s > 40.0:
		out.append(s)
		s -= PIER_STEP_M
	s = sp + MAIN_SPAN_M
	while s < total - 25.0:
		out.append(s)
		s += 64.0
	return out

## V piers, as in photos: a steel-clad solid block rises out of the water
## (no plinth), its sides already leaning out with the V's flare; from its
## top the V notch opens and two broad square legs splay up straight into
## the soffit. The taller the pier, the lower (as a share of its height)
## the notch starts, so the tall ones read as a more open V. The anchor
## piers closing the two stayed spans are heavier.
static func _piers(lm: LandmarkMesh) -> void:
	var anchors: Array[float] = [pylon_s() + MAIN_SPAN_M, pylon_s() - BACK_SPAN_M]
	for s in pier_s():
		var c := at(s)
		var t := heading(s)
		var t3 := Vector3(t.x, 0, t.y)
		var n3 := Vector3(-t.y, 0, t.x)
		var base := Vector3(c.x, 0.0, c.y)
		var y1 := deck_y(s) - DEPTH_M + 0.2
		var grow := 1.3 if absf(s - anchors[0]) < 1.0 or absf(s - anchors[1]) < 1.0 else 1.0
		var tall := clampf((y1 - 6.0) / 14.0, 0.0, 1.0)
		# The legs meet the deck near its edges, just inside where the
		# soffit (1.8 m in from each edge) turns up into its chamfers.
		var top := c.z - 2.0
		_v_pier(lm, base, t3 * 1.7 * grow, n3, -CAP_DEPTH_M, y1 * lerpf(0.4, 0.3, tall), y1, top * 0.55, top,
			top * 0.38)

## V pier in the plane across the deck (`n3`), `half_t` thick each way
## along it. Its outer sides run straight from `foot` half-width at the
## water to `top` at y1. Below `yn` it is one solid steel-clad block
## (reaching down to y0 under the water); above, the notch opens from its
## tip on the block to `gap` half-width at y1, parting the two legs.
static func _v_pier(lm: LandmarkMesh, base: Vector3, half_t: Vector3, n3: Vector3, y0: float, yn: float, y1: float,
		foot: float, top: float, gap: float) -> void:
	var t := half_t.normalized()
	var ht := half_t.length()
	var out := func(y: float) -> float: return maxf(0.5, foot + (top - foot) * y / y1)
	# The clad block: a box flaring with the wall, all four sides and top.
	var lip := 0.08
	var a0: float = float(out.call(y0)) + lip
	var a1: float = float(out.call(yn)) + lip
	var b := ht + lip
	var lo: Array[Vector3] = [base + Vector3.UP * y0 + n3 * a0 + t * b, base + Vector3.UP * y0 - n3 * a0 + t * b,
		base + Vector3.UP * y0 - n3 * a0 - t * b, base + Vector3.UP * y0 + n3 * a0 - t * b]
	var hi: Array[Vector3] = [base + Vector3.UP * yn + n3 * a1 + t * b, base + Vector3.UP * yn - n3 * a1 + t * b,
		base + Vector3.UP * yn - n3 * a1 - t * b, base + Vector3.UP * yn + n3 * a1 - t * b]
	for i in 4:
		var j := (i + 1) % 4
		var mid := (lo[i] + lo[j] + hi[i] + hi[j]) * 0.25 - base
		var nrm := Vector3(mid.x, 0.0, mid.z).normalized()
		if i == 0 or i == 2:
			nrm = t if i == 0 else -t
		lm.quad("Steel", lo[i], lo[j], hi[j], hi[i], nrm)
	lm.quad("Steel", hi[0], hi[1], hi[2], hi[3], Vector3.UP)
	# The two legs, each a four-sided slab from the block's top to the
	# soffit: inner foot at the notch tip, outer edge on the flare.
	var p := func(x: float, y: float) -> Vector3: return base + n3 * x + Vector3.UP * y
	for side: float in [-1.0, 1.0]:
		var ring: Array[Vector2] = [Vector2(0.0, yn), Vector2(side * float(out.call(yn)), yn),
			Vector2(side * top, y1), Vector2(side * gap, y1)]
		for f: float in [-1.0, 1.0]:
			var o := half_t * f
			lm.quad("Concrete", p.call(ring[0].x, ring[0].y) + o, p.call(ring[1].x, ring[1].y) + o,
				p.call(ring[2].x, ring[2].y) + o, p.call(ring[3].x, ring[3].y) + o, t * f)
		# Outer side and the notch face (the top meets the soffit, the
		# bottom sits on the block).
		for e: Array in [[1, 2], [3, 0]]:
			var u: Vector2 = ring[e[0]]
			var v: Vector2 = ring[e[1]]
			var nrm := (n3 * (v.y - u.y) - Vector3.UP * (v.x - u.x)).normalized() * side
			lm.quad("Concrete", p.call(u.x, u.y) - half_t, p.call(v.x, v.y) - half_t, p.call(v.x, v.y) + half_t,
				p.call(u.x, u.y) + half_t, nrm)
	# A round steel tie rod across the notch, a little under the soffit,
	# its ends set into the legs' inner faces.
	var yr := y1 - maxf(1.2, (y1 - yn) * 0.16)
	var xr := gap * (yr - yn) / (y1 - yn) + 0.3
	_rod(lm, p.call(-xr, yr), p.call(xr, yr), 0.28)

## Round steel rod of radius `r` from `a` to `b` (eight sides, smooth
## normals, open ends).
static func _rod(lm: LandmarkMesh, a: Vector3, b: Vector3, r: float) -> void:
	var axis := (b - a).normalized()
	var u := axis.cross(Vector3.UP).normalized()
	var v := axis.cross(u).normalized()
	for i in 8:
		var a0 := TAU * i / 8.0
		var a1 := TAU * (i + 1) / 8.0
		var n0 := u * cos(a0) + v * sin(a0)
		var n1 := u * cos(a1) + v * sin(a1)
		var w := r * a0
		lm.tri("Steel", a + n0 * r, b + n0 * r, b + n1 * r, n0, n0, n1, Vector2(w, 0), Vector2(w, 1), Vector2(w + r, 1))
		lm.tri("Steel", a + n0 * r, b + n1 * r, a + n1 * r, n0, n1, n1, Vector2(w, 0), Vector2(w + r, 1), Vector2(w + r, 0))

## The pylon's frame: its axis at sea level (in the median, PYLON_X south
## of the deck centre line) and the unit vectors along (t3) and across
## (n3) the deck.
static func pylon_frame() -> Array:
	var sp := pylon_s()
	var c := at(sp)
	var t := heading(sp)
	var t3 := Vector3(t.x, 0, t.y)
	var n3 := Vector3(-t.y, 0, t.x)
	return [Vector3(c.x, 0.0, c.y) + n3 * PYLON_X, t3, n3]

## Height of the diamond's knee, where the legs are widest apart: inside
## the deck box, so the bend never shows.
static func pylon_knee_y() -> float:
	return deck_y(pylon_s()) - DEPTH_M * 0.5

## The pylon's section at height y, metres: its outer half-length along
## the deck (x), the half-width of the slit between its legs (y: nothing
## on the plinth, widest at the knee, nothing again from JOIN_M up) and
## its half-thickness across the deck (z). Each piece is linear in y, so every face is flat.
static func pylon_section(y: float) -> Vector3:
	var yk := pylon_knee_y()
	var g := 0.0
	var a := 0.0
	if y <= yk:
		var f := clampf((y - PLINTH_TOP_M) / (yk - PLINTH_TOP_M), 0.0, 1.0)
		g = SLIT_DECK * f
		a = lerpf(LEG_OUT.x, LEG_OUT.y, f)
	else:
		g = SLIT_DECK * maxf(0.0, (JOIN_M - y) / (JOIN_M - yk))
		a = lerpf(LEG_OUT.y, LEG_OUT.z, clampf((y - yk) / (MAST_TOP_M - yk), 0.0, 1.0))
	return Vector3(a, g, lerpf(LEG_THICK.x, LEG_THICK.y, y / MAST_TOP_M))

## How far the pylon's corners are cut back at height y, metres: a share
## of the legs' thickness up to JOIN_M, easing above it to the head's
## smaller cut at the cable opening's sill.
static func pylon_chamfer(y: float) -> float:
	var legs := CHAMFER_SHARE * 2.0 * pylon_section(minf(y, JOIN_M)).z
	return lerpf(legs, HEAD_CHAMFER_M, clampf((y - JOIN_M) / (SLOT_M.x - JOIN_M), 0.0, 1.0))

## Eight corners at height y round the rectangle t0..t1 along the deck by
## n0..n1 across it (metres about the pylon's axis, frame `fr`), its two
## corners on the n0 side cut back by `ca` and those on the n1 side by `cb`.
static func _ring(fr: Array, y: float, t0: float, t1: float, n0: float, n1: float, ca: float,
		cb: float) -> PackedVector3Array:
	var o: Vector3 = (fr[0] as Vector3) + Vector3.UP * y
	var out := PackedVector3Array()
	for p: Vector2 in [Vector2(t0 + ca, n0), Vector2(t1 - ca, n0), Vector2(t1, n0 + ca), Vector2(t1, n1 - cb),
			Vector2(t1 - cb, n1), Vector2(t0 + cb, n1), Vector2(t0, n1 - cb), Vector2(t0, n0 + ca)]:
		out.append(o + (fr[1] as Vector3) * p.x + (fr[2] as Vector3) * p.y)
	return out

## The pylon's whole eight-sided outline at height y, `grow` metres proud.
static func _body_ring(fr: Array, y: float, grow: float = 0.0) -> PackedVector3Array:
	var q := pylon_section(y) + Vector3(grow, 0.0, grow)
	var c := pylon_chamfer(y)
	return _ring(fr, y, -q.x, q.x, -q.z, q.z, c, c)

## The outline at height y of the leg on the `side` (along the deck) of
## the slit: its inner face on the slit, its outer face on the pylon's
## outline, all four corners cut.
static func _leg_ring(fr: Array, y: float, side: float, grow: float = 0.0) -> PackedVector3Array:
	var q := pylon_section(y)
	var c := pylon_chamfer(y)
	return _ring(fr, y, minf(side * q.y, side * q.x) - grow, maxf(side * q.y, side * q.x) + grow, -q.z - grow,
		q.z + grow, c, c)

## The outline at height y of the wall on the `side` (across the deck) of
## the cable opening, its outer corners cut.
static func _wall_ring(fr: Array, y: float, side: float, grow: float = 0.0) -> PackedVector3Array:
	var q := pylon_section(y) + Vector3(grow, 0.0, grow)
	if side > 0.0:
		return _ring(fr, y, -q.x, q.x, SLOT_HALF, q.z, 0.0, HEAD_CHAMFER_M)
	return _ring(fr, y, -q.x, q.x, -q.z, -SLOT_HALF, HEAD_CHAMFER_M, 0.0)

## Casting joints: a thin darker band round the pylon every LIFT_M, on
## each leg, the shaft and the opening's walls (none inside the deck).
static func _lift_joints(lm: LandmarkMesh, fr: Array) -> void:
	var yd := deck_y(pylon_s())
	var y := PLINTH_TOP_M + LIFT_M
	while y < MAST_TOP_M - 1.0:
		var lo := y - 0.04
		var hi := y + 0.04
		if y > yd - DEPTH_M - 0.3 and y < yd + 0.5:
			pass
		elif y < JOIN_M:
			for side: float in [-1.0, 1.0]:
				_prism(lm, "Track", _leg_ring(fr, lo, side, 0.02), _leg_ring(fr, hi, side, 0.02))
		elif hi < SLOT_M.x or lo > SLOT_M.y:
			_prism(lm, "Track", _body_ring(fr, lo, 0.02), _body_ring(fr, hi, 0.02))
		elif lo > SLOT_M.x and hi < SLOT_M.y:
			for side: float in [-1.0, 1.0]:
				_prism(lm, "Track", _wall_ring(fr, lo, side, 0.02), _wall_ring(fr, hi, side, 0.02))
		y += LIFT_M

## The artificial rock islet the pylon stands on: a low irregular mound,
## its sloping shore running under the water and its top nearly flat.
static func _islet(lm: LandmarkMesh, fr: Array) -> void:
	var base: Vector3 = fr[0]
	var n := 22
	var shore := PackedVector3Array()
	var brow := PackedVector3Array()
	for i in n:
		var a := TAU * i / n
		var r := 1.0 + 0.16 * sin(3.0 * a + 1.0) + 0.09 * sin(5.0 * a + 2.3)
		var dir: Vector3 = (fr[1] as Vector3) * cos(a) * ISLET_HALF.x + (fr[2] as Vector3) * sin(a) * ISLET_HALF.y
		shore.append(base + dir * r - Vector3.UP * 1.5)
		brow.append(base + dir * r * 0.8 + Vector3.UP * (ISLET_TOP_M - 0.4))
	var top := base + Vector3.UP * ISLET_TOP_M
	for i in n:
		var j := (i + 1) % n
		var out := (shore[i] + shore[j] - base * 2.0).normalized()
		lm.quad("Footing", shore[i], shore[j], brow[j], brow[i], (out + Vector3.UP * 1.5).normalized())
		lm.tri("Footing", brow[i], brow[j], top, Vector3.UP, Vector3.UP, Vector3.UP,
			Vector2(brow[i].x, brow[i].z), Vector2(brow[j].x, brow[j].z), Vector2(top.x, top.z))

## Side faces between two rings of eight corners (an uncut corner, two
## corners at one point, makes no face).
static func _prism(lm: LandmarkMesh, key: String, r0: PackedVector3Array, r1: PackedVector3Array) -> void:
	var mid := Vector3.ZERO
	for i in 8:
		mid += (r0[i] + r1[i]) / 16.0
	for i in 8:
		var j := (i + 1) % 8
		if r0[i].is_equal_approx(r0[j]) and r1[i].is_equal_approx(r1[j]):
			continue
		var nrm := (r0[j] - r0[i]).cross(r1[i] - r0[i]).normalized()
		if nrm.dot((r0[i] + r0[j] + r1[i] + r1[j]) * 0.25 - mid) < 0.0:
			nrm = -nrm
		lm.quad(key, r0[i], r0[j], r1[j], r1[i], nrm)

## Flat face closing a ring of eight corners, facing `nrm`.
static func _ring_cap(lm: LandmarkMesh, key: String, r: PackedVector3Array, nrm: Vector3) -> void:
	lm.quad(key, r[0], r[1], r[2], r[3], nrm)
	lm.quad(key, r[0], r[3], r[4], r[7], nrm)
	lm.quad(key, r[4], r[5], r[6], r[7], nrm)

## The pylon, a slender needle through the deck's median: a plinth on the
## islet; two eight-sided legs in line along the deck, splaying as a V
## from one foot on the plinth to the knee inside the deck and closing
## again to JOIN_M; the solid eight-sided shaft above them, with the
## cable opening in both end faces near the top; red aviation lights and
## the lightning rod at 135 m. It stands on a rock islet.
static func _pylon(lm: LandmarkMesh) -> void:
	var fr := pylon_frame()
	var base: Vector3 = fr[0]
	var t3: Vector3 = fr[1]
	var n3: Vector3 = fr[2]
	var basis := Basis(t3, Vector3.UP, n3)
	# The concrete plinth stands on the rock islet and reaches down to the
	# seabed.
	lm.box("Track", base, Vector3(14.0, 8.0, 7.0), basis, 0.0)
	_islet(lm, fr)
	# Each leg: its inner face on the slit, its outer face on the pylon's
	# outline, all four corners cut. At JOIN_M the slit has closed, so the
	# two legs' tops fill the shaft's base.
	var yk := pylon_knee_y()
	for side: float in [-1.0, 1.0]:
		_prism(lm, "Concrete", _leg_ring(fr, PLINTH_TOP_M, side), _leg_ring(fr, yk, side))
		_prism(lm, "Concrete", _leg_ring(fr, yk, side), _leg_ring(fr, JOIN_M, side))
	# The solid shaft from the legs up to the opening's sill (its top
	# face); a wall on each side across the deck leaves the opening between
	# them, filled behind both end faces by the steel cable boxes; the cap
	# closes it, with its soffit.
	var join := _body_ring(fr, JOIN_M)
	var sill_ring := _body_ring(fr, SLOT_M.x)
	var head_ring := _body_ring(fr, SLOT_M.y)
	var top_ring := _body_ring(fr, MAST_TOP_M)
	_prism(lm, "Concrete", join, sill_ring)
	_ring_cap(lm, "Concrete", join, Vector3.DOWN)
	_ring_cap(lm, "Concrete", sill_ring, Vector3.UP)
	_prism(lm, "Concrete", head_ring, top_ring)
	_ring_cap(lm, "Concrete", head_ring, Vector3.DOWN)
	_ring_cap(lm, "Concrete", top_ring, Vector3.UP)
	var sill := pylon_section(SLOT_M.x)
	var cap := pylon_section(SLOT_M.y)
	_taper(lm, "Steel", base + Vector3.UP * SLOT_M.x, t3, n3, Vector2(sill.x - SLOT_INSET_M, SLOT_HALF),
		Vector2(cap.x - SLOT_INSET_M, SLOT_HALF), SLOT_M.y - SLOT_M.x)
	for side: float in [-1.0, 1.0]:
		_prism(lm, "Concrete", _wall_ring(fr, SLOT_M.x, side), _wall_ring(fr, SLOT_M.y, side))
	_lift_joints(lm, fr)
	lm.box("Steel", base + Vector3.UP * (MAST_TOP_M + 0.4), Vector3(1.4, 0.8, 1.4), basis)
	lm.beam("Steel", base + Vector3.UP * (MAST_TOP_M + 0.8), base + Vector3.UP * PYLON_TOP_M, 0.2, 0.2)
	# Red aviation obstacle lights: on the top and on both narrow ends of
	# the pylon. Pure red at a high energy: red carries little luminance,
	# so it needs this much to read as a bright red point rather than dull
	# orange.
	lm.box("BeaconLamp", base + Vector3.UP * (MAST_TOP_M + 1.3), Vector3(1.8, 1.0, 1.8), basis, 0.0)
	for y: float in MAST_BEACON_Y:
		for side: float in [-1.0, 1.0]:
			lm.box("BeaconLamp", base + t3 * side * (pylon_section(y).x + 0.2) + Vector3.UP * y, Vector3(0.5, 0.8, 0.9),
				basis, 0.0)
	_island(lm)

## The kerbed median island round the pylon's legs: a lozenge on the cycle
## path's north edge against the separator, as wide as the pylon plus a
## margin, tapering to nothing at both ends.
static func _island(lm: LandmarkMesh) -> void:
	var sp := pylon_s()
	var wide := PYLON_X + pylon_section(deck_y(sp)).z + 0.3 - SEPARATOR.y
	var n := 14
	var prev_in := Vector3.ZERO
	var prev_out := Vector3.ZERO
	var down := Vector3.UP * (KERB_M - 0.05)
	for k in n + 1:
		var s := sp - ISLAND_HALF_M + 2.0 * ISLAND_HALF_M * k / n
		var c := at(s)
		var t := heading(s)
		var lat := Vector3(-t.y, 0.0, t.x)
		var w := wide * clampf((ISLAND_HALF_M - absf(s - sp)) / 6.0, 0.0, 1.0)
		var p_in := Vector3(c.x, deck_y(s) + KERB_M, c.y) + lat * SEPARATOR.y
		var p_out := p_in + lat * w
		if k > 0:
			lm.quad("Concrete", prev_in, prev_out, p_out, p_in, Vector3.UP)
			lm.quad("Concrete", prev_out, prev_out - down, p_out - down, p_out, lat)
		prev_in = p_in
		prev_out = p_out

## Night floodlights of the white pylon (LandmarkLights.FLOOD_META,
## model metres): four off the deck edges beside the pylon washing it up
## to its top in blue, two on the islet plinth lighting the legs below
## and above the deck; then the warm white downlights of the deck.
static func flood_spots() -> Array:
	var sp := pylon_s()
	var c := at(sp)
	var fr := pylon_frame()
	var base: Vector3 = fr[0]
	var t3: Vector3 = fr[1]
	var n3: Vector3 = fr[2]
	var deck := Vector3(c.x, 0.0, c.y)
	var yd := deck_y(sp)
	var out: Array = []
	for along: float in [-1.0, 1.0]:
		for side: float in [-1.0, 1.0]:
			out.append([deck + t3 * along * 10.0 + n3 * side * (c.z + 6.0) + Vector3.UP * (yd + 1.0),
				base + Vector3.UP * 100.0, 22.0, PYLON_LIGHT, 160.0, PYLON_WASH])
		out.append([base + t3 * along * 14.0 + Vector3.UP * 4.5, base + Vector3.UP * 50.0, 40.0, PYLON_LIGHT * 0.65,
			160.0, PYLON_WASH])
	# Warm white downlights under every pole's Y head, on the tramway and the
	# paths beside it; each reaches DECK_REACH_M so neighbouring pools
	# meet halfway between the poles and the deck has no dark gaps. The
	# spots cast no shadows, so on the low approaches the reach stops a
	# metre above the water instead of pooling on the sea under the deck.
	var plan := _plan()
	var poles := _pole_samples(plan)
	for k in poles.size():
		var i := poles[k]
		var head := _sp(plan, i, Vector2(POLE_X, 0.0), POLE_TOP_M - 0.2)
		out.append([head, _sp(plan, i, Vector2(POLE_X + 0.5, 0.0), 0.0), 70.0, DECK_LIGHT,
			minf(DECK_REACH_M, head.y - 1.0), DECK_WARM, DECK_FALLOFF])
		# Midway fill: the even glow of the handrail lines between poles.
		if k + 1 < poles.size():
			var mid := (i + poles[k + 1]) / 2
			var fill := _sp(plan, mid, Vector2(POLE_X, 0.0), FILL_Y_M)
			out.append([fill, _sp(plan, mid, Vector2(POLE_X + 0.5, 0.0), 0.0), 75.0, DECK_LIGHT * FILL_SHARE,
				minf(FILL_REACH_M, fill.y - 1.0), DECK_WARM, DECK_FALLOFF])
	# The top aviation light's red glow over the mast cap.
	out.append([base + Vector3.UP * (PYLON_TOP_M + 2.0), base + t3 * 0.5 + Vector3.UP * MAST_TOP_M, 60.0,
		BEACON_GLOW, BEACON_REACH_M, BEACON_RED])
	return out

## Red night halos round the aviation lights (LandmarkLights.HALO_META,
## model metres): a wide one on the top, smaller ones on both narrow ends
## of the pylon at 72 m and 102 m.
static func beacon_halos() -> Array:
	var fr := pylon_frame()
	var base: Vector3 = fr[0]
	var t3: Vector3 = fr[1]
	var out: Array = [[base + Vector3.UP * (MAST_TOP_M + 1.3), TOP_HALO_M, BEACON_RED]]
	for y: float in MAST_BEACON_Y:
		for side: float in [-1.0, 1.0]:
			out.append([base + t3 * side * (pylon_section(y).x + 0.5) + Vector3.UP * y, MAST_HALO_M, BEACON_RED])
	return out

## Both ends of the stay at deck arc length `s`, anchored `ym` up the
## pylon, on the deck edge `side` (-1 north, 1 south): [on the cable
## boxes in the opening of the end face towards it, on its bracket
## outside the deck edge], model metres.
static func stay_ends(s: float, ym: float, side: float) -> Array:
	var fr := pylon_frame()
	var d := at(s)
	var dt := heading(s)
	var dn := Vector3(-dt.y, 0, dt.x)
	var along := signf(s - pylon_s()) * (pylon_section(ym).x - SLOT_INSET_M)
	return [(fr[0] as Vector3) + (fr[1] as Vector3) * along + (fr[2] as Vector3) * side * STAY_TOP_HALF + Vector3.UP * ym,
		Vector3(d.x, deck_y(s) - STAY_DROP_M, d.y) + dn * side * (d.z + STAY_OUT_M)]

## Every stay pair as [deck arc length, height on the pylon]: fanning
## both ways along the curve, the farthest anchored highest.
static func stay_pairs() -> Array:
	var sp := pylon_s()
	var out: Array = []
	for dir: float in [1.0, -1.0]:
		var count := STAYS_EAST if dir > 0.0 else STAYS_WEST
		var reach := REACH_EAST if dir > 0.0 else REACH_WEST
		for k in count:
			var f := float(k) / (count - 1)
			out.append([sp + dir * lerpf(reach.x, reach.y, f), lerpf(MAST_ANCHORS.x, MAST_ANCHORS.y, f)])
	return out

## Stays in two planes: every pair runs from the cable boxes in the
## opening of the pylon's end face towards it, near the top, down to
## brackets standing off both edge girders, outside the
## fences. Each cable ends on its bracket in a collar and a dark anchor pipe.
static func _stays(lm: LandmarkMesh, anchor: LandmarkMesh) -> void:
	for pair: Array in stay_pairs():
		var s: float = pair[0]
		var d := at(s)
		var dt := heading(s)
		var dn := Vector3(-dt.y, 0, dt.x)
		for side: float in [-1.0, 1.0]:
			var ends := stay_ends(s, float(pair[1]), side)
			var top: Vector3 = ends[0]
			var low: Vector3 = ends[1]
			var along := (top - low).normalized()
			# The white cable ends in a black collar by the edge band's lower
			# edge; the anchor pipe hangs from it below the deck edge.
			LandmarkFhStayAnchor.place(lm, anchor, low, along)
			lm.beam("StayLamp", LandmarkFhStayAnchor.cable_start(low, along), top, 0.22, 0.22)
			# A slim steel rib from under the girder out to the pipe.
			var rib := low - Vector3.UP * 0.15
			lm.beam("Girder", rib - dn * side * (STAY_OUT_M + 1.0), rib - dn * side * 0.1, 0.3, 0.5, Vector3(dt.x, 0, dt.y))

## Four-sided prism from a rectangle at `base` (half-sizes h0 along t
## and n) up `h` metres to one of half-sizes h1, with a top cap.
static func _taper(lm: LandmarkMesh, key: String, base: Vector3, t: Vector3, n: Vector3, h0: Vector2,
		h1: Vector2, h: float) -> void:
	var st: Array[float] = [-1.0, 1.0, 1.0, -1.0]
	var sn: Array[float] = [-1.0, -1.0, 1.0, 1.0]
	var top := base + Vector3.UP * h
	for i in 4:
		var j := (i + 1) % 4
		var a := base + t * st[i] * h0.x + n * sn[i] * h0.y
		var b := base + t * st[j] * h0.x + n * sn[j] * h0.y
		var c := top + t * st[j] * h1.x + n * sn[j] * h1.y
		var d := top + t * st[i] * h1.x + n * sn[i] * h1.y
		lm.quad(key, a, b, c, d, (t * (st[i] + st[j]) + n * (sn[i] + sn[j])).normalized())
	lm.quad(key, top + t * -h1.x + n * -h1.y, top + t * h1.x + n * -h1.y, top + t * h1.x + n * h1.y,
		top + t * -h1.x + n * h1.y, Vector3.UP)
