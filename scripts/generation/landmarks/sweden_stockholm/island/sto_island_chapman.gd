class_name StoIslandChapman
extends RefCounted

## af Chapman (1888, Whitehaven, now a hostel and landmark at Skeppsholmen),
## the white full-rigged steel ship moored at the west quay (Västra
## Brobänken). True metres, +X bow, y = 0 at the waterline, origin at the
## hull's centre; registry yaw 79 turns the bow to bearing 169 and puts the
## quay on the port (-Z) side. `base: "water"`, so the keel (5 m draught)
## dips below y = 0.
##
## From the photos (visual-plan/refs/landmarks/af_chapman/):
## - Hull: 68 m between the raked stem and the counter stern, 9.45 m beam,
##   3.8 m freeboard rising to the bow and stern, gleaming white topsides, a
##   dark boot and bottom, a white painted-port band under the rail with a
##   black port every 2.7 m, solid bulwarks with a teak rail, stern windows.
## - Bows: a long bowsprit and jib-boom with furled headsails, dolphin
##   striker and gilt trailboard scrolls; anchors hung on both bows.
## - Deck: a low white deckhouse and galley, hatches, winches and vents,
##   four white lifeboats on cradles between the main and mizzen masts.
## - Rig: see StoIslandRig (three masts, 15 yards, stays and shrouds).
## - Mooring: four hawsers to the quay, a gangway amidships to the quay.
## Hull dressing is TallShipDetails; the rig is built here as it is a
## full-rigged ship, not the barque that class rigs by default.
## Surfaces (11): Hull, Boot, Deck, Mast, Sail, Dark, Steel, White, Glass,
## Gilt, Lamp.

const SPEC := {
	"length": 68.0, "beam": 9.45, "freeboard": 3.8, "draft": 5.0,
	"entry": 0.3, "bow_pow": 1.7, "stern_w": 0.5, "flare": 0.1, "deadrise": 0.0,
	"stern_round": 1.0, "stern_tail": 0.14, "bow_rise": 1.2, "stern_rise": 0.9,
	"stem_rake": 3.4, "stern_rake": 1.7, "keel_lift": 0.9, "boot_m": 0.4, "lod": 0,
}
## Quay edge z (port side) and the quay top above the water.
const QUAY_Z := -6.2
const QUAY_Y := 0.9

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	HullLoft.loft(lm, SPEC, {"hull": "Hull", "boot": "Boot", "bottom": "Boot", "deck": "Deck"})
	var jib := TallShipDetails.build(lm, SPEC, {"ultra": true, "masts": false}, float(SPEC["freeboard"]) + 0.02, 44.0)
	StoIslandRig.build(lm, SPEC, jib)
	_lifeboats(lm)
	_mooring(lm)
	_gangway(lm)
	lm.commit(model)
	_floods(model)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("Hull", LandmarkMaterials.paint("#F1EFE8", 0.45, 0.10))
	lm.use("Boot", LandmarkMaterials.paint("#202A36", 0.58, 0.10))
	lm.use("Deck", LandmarkMaterials.pbr("wood", "#9A7A52", 2.4, 0.72))
	lm.use("Mast", LandmarkMaterials.paint("#E4D4A4", 0.5, 0.12))
	lm.use("Sail", LandmarkMaterials.pbr("render", "#EEEADB", 2.0, 0.88))
	lm.use("Dark", LandmarkMaterials.paint("#1E2226", 0.5, 0.4))
	lm.use("Steel", LandmarkMaterials.paint("#5E666B", 0.5, 0.5))
	lm.use("White", LandmarkMaterials.paint("#F3F1EB", 0.5, 0.08))
	lm.use("Glass", LandmarkMaterials.glass("#22303A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Lamp", LandmarkMaterials.lit("#FFE8BC", 1.5))

## Four clinker lifeboats on cradles abaft the main mast, two a side.
static func _lifeboats(lm: LandmarkMesh) -> void:
	var boat := {"length": 6.2, "beam": 2.0, "freeboard": 0.7, "draft": 0.35, "double_ended": true,
		"entry": 0.35, "end_width": 0.08, "boot_m": 0.1, "lod": 1}
	for bx: float in [-8.5, -15.5]:
		var deck := HullLoft.sheer(SPEC, bx)
		for s: float in [-1.0, 1.0]:
			var bz := s * 2.6
			lm.box("Deck", Vector3(bx, deck + 0.3, bz), Vector3(5.2, 0.12, 1.4), Basis(), 0.0)
			for dx: float in [-1.8, 1.8]:
				lm.box("Deck", Vector3(bx + dx, deck + 0.15, bz), Vector3(0.3, 0.3, 1.5), Basis(), 0.0)
			HullLoft.loft(lm, boat, {"hull": "White", "boot": "White", "bottom": "White", "deck": "Deck"},
				Vector3(bx, deck + 0.78, bz))
			for dx: float in [-1.0, 1.0]:
				VesselForms.davit(lm, Vector3(bx + dx * 2.4, deck, s * 3.9), 2.2, -0.9 * s)

## Hawsers: bow, forward spring, after spring and stern lines to the quay.
static func _mooring(lm: LandmarkMesh) -> void:
	var legs := [[27.0, 31.0], [14.0, 19.0], [-12.0, -17.0], [-28.0, -33.0]]
	for leg in legs:
		var hx: float = leg[0]
		var hull := Vector3(hx, HullLoft.sheer(SPEC, hx) + 0.9, -(HullLoft.half(SPEC, hx) - 0.1))
		var bollard := Vector3(float(leg[1]), QUAY_Y, QUAY_Z - 1.3)
		VesselEquipment.line(lm, hull, bollard, 0.35, 0.05)
		lm.lathe("Dark", bollard - Vector3(0, 0.0, 0), PackedVector2Array([Vector2(0.22, 0), Vector2(0.18, 0.25),
			Vector2(0.24, 0.45)]), 8)

## Visitor gangway from the deck amidships down to the quay.
static func _gangway(lm: LandmarkMesh) -> void:
	var deck := HullLoft.sheer(SPEC, 3.0)
	var p0 := Vector3(3.0, deck + 0.1, -4.5)
	var p1 := Vector3(3.0, QUAY_Y + 0.05, QUAY_Z - 1.3)
	lm.beam("Deck", p0, p1, 1.2, 0.14, Vector3.UP)
	for dz: float in [-0.65, 0.65]:
		lm.beam("White", p0 + Vector3(dz, 1.0, 0), p1 + Vector3(dz, 1.0, 0), 0.06, 0.06)
		for k in 5:
			var q := p0.lerp(p1, float(k) / 4.0) + Vector3(dz, 0, 0)
			lm.beam("White", q, q + Vector3(0, 1.0, 0), 0.05, 0.05)

## The ship is lit at night: warm washes on the three masts and the hull.
static func _floods(model: Node3D) -> void:
	var warm := Color(1.0, 0.9, 0.72)
	var spots: Array = []
	for m: Array in StoIslandRig.MASTS:
		var mx: float = float(SPEC["length"]) * float(m[0])
		spots.append([Vector3(mx, 6.0, -5.0), Vector3(mx, float(m[1]) * 0.6, 0.0), 50.0, 0.85, float(m[1]) + 4.0, warm])
	spots.append([Vector3(0.0, 2.0, -15.0), Vector3(0.0, 4.0, -4.0), 68.0, 0.75, 40.0, warm])
	model.set_meta(LandmarkLights.FLOOD_META, spots)
