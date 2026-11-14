class_name StreetLights
extends RefCounted

## Real light from the street lamps (desktop Ultra, Phase 5 of the Ultra
## pass). StreetProps places a lamppost every 25 m; here the nearest
## MAX_LIGHTS of them also get a light: an omni under each lantern head, a
## downward spot under each cobra-head arm. Shadowless, faded out by
## distance so only the street around the eye pays, off by day, and
## driven at night by CityLights.apply. Colour follows the region:
## sodium orange where it still lines the streets, warm LED in the
## lantern towns, neutral LED elsewhere.

const META := "street_light"
const MAX_LIGHTS := 320
## Light energy at full night (Godot units, not physical).
const ENERGY := 3.0
const LANTERN_RANGE_M := 14.0
const SPOT_RANGE_M := 20.0
const SPOT_ANGLE_DEG := 62.0
const FADE_BEGIN_M := 170.0
const FADE_LENGTH_M := 60.0
## Lamp heads in the lamp meshes' own metres (StreetProps._lamp_mesh).
const LANTERN_HEAD := Vector3(0.0, 4.1, 0.0)
const COBRA_HEAD := Vector3(1.85, 8.0, 0.0)
## Spot heads of the regional arm styles (the rest use COBRA_HEAD).
## "span": a Nordic luminaire hung on a span wire over the street
## (OverheadWires), its transform already at the lamp.
const HEADS := {"span": Vector3.ZERO, "post_top": Vector3(0, 4.4, 0), "nyc_f": Vector3(1.45, 7.0, 0), "nyc_crook": Vector3(1.45, 5.2, 0), "cobra": Vector3(2.6, 8.85, 0.0), "utility": Vector3(1.15, 5.58, 0.0)}
const SODIUM_REGIONS := ["eastern_europe", "middle_east", "south_asia", "latin_america",
	"sub_saharan_africa"]

static func colour_for(style: String, region: String) -> Color:
	if region in SODIUM_REGIONS:
		return Color(1.0, 0.62, 0.30)   # ~2000 K high-pressure sodium
	if style == "lantern" or style == "heritage":
		return Color(1.0, 0.78, 0.52)   # ~2700 K warm LED / gas look
	return Color(1.0, 0.90, 0.78)       # ~4000 K LED

## Adds the lights for `placed` (StreetProps: style -> lamp transforms)
## under one "StreetLights" node of `root`. Returns the number added.
## Later calls (the span-wire lamps) join the same node and share its
## MAX_LIGHTS budget with the lamps already there.
static func add(root: Node3D, placed: Dictionary, region: String, m2u: float, centre: Vector2 = Vector2.ZERO) -> int:
	var all: Array = []
	for style in placed:
		for xf in (placed[style] as Array):
			var t: Transform3D = xf
			all.append([(Vector2(t.origin.x, t.origin.z) - centre).length_squared(), t, str(style)])
	if all.is_empty():
		return 0
	all.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var holder := root.get_node_or_null("StreetLights") as Node3D
	var fresh := holder == null
	if fresh:
		holder = Node3D.new()
		holder.name = "StreetLights"
	var before := holder.get_child_count()
	for i in mini(all.size(), MAX_LIGHTS - before):
		var t: Transform3D = all[i][1]
		var style: String = all[i][2]
		var light: Light3D
		if style == "lantern" or style == "heritage":
			var omni := OmniLight3D.new()
			omni.omni_range = LANTERN_RANGE_M * m2u
			omni.omni_attenuation = 1.3
			omni.position = t * LANTERN_HEAD
			light = omni
		else:
			var spot := SpotLight3D.new()
			spot.spot_range = SPOT_RANGE_M * m2u
			spot.spot_angle = SPOT_ANGLE_DEG
			spot.spot_attenuation = 0.9
			# SpotLight3D shines down its -Z; turn that to -Y.
			spot.transform = Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), t * (HEADS.get(style, COBRA_HEAD) as Vector3))
			light = spot
		light.light_color = colour_for(style, region)
		light.light_energy = 0.0
		light.shadow_enabled = false
		light.distance_fade_enabled = true
		light.distance_fade_begin = FADE_BEGIN_M * m2u
		light.distance_fade_length = FADE_LENGTH_M * m2u
		light.visible = false
		light.set_meta(META, ENERGY)
		holder.add_child(light)
	if fresh:
		root.add_child(holder)
	return holder.get_child_count() - before

## Night share `amount` (CityLights.amount_for) on one marked light.
static func apply(light: Light3D, amount: float) -> void:
	light.light_energy = float(light.get_meta(META)) * amount
	light.visible = amount > 0.02
