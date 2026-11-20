extends RefCounted

## Korkeasaari's "Kupla" (Bubble) lookout tower, the zoo island's observation
## tower of 2002 (Ville Harju's thesis design, a timber-built organic
## sphere about 10 m high; fi.wikipedia list of lookout towers). The earlier
## row here was a 25 m four-post timber frame drawn from memory, which no
## source supports; it is replaced by this documented form.
##
## The only Commons view in hand (korkeasaari_lookout_tower/front.jpg, a
## distant shot across the bay) shows a lattice sphere on a low concrete
## terrace crowning the rock hill. Modelled: a 3.6 m plinth with a stair, and
## a spiral stair and an open sphere of timber ribs (eight meridians, five parallels) 3.3 m in
## radius whose top lands at 10.5 m, with a deck inside it.
##
## Not verified: the sphere's rib count and colours, the plinth, and the
## position. OSM has no mapped tower here (the zoo polygon and Mustikkamaa
## bridge only); the registry point (60.1772, 24.985) is kept and may be off
## by tens of metres.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const ENTRY := {"type": "korkeasaari_lookout_tower", "name": "Korkeasaari Lookout Tower", "lat": 60.1772, "lon": 24.985,
	"radius_m": 1500.0, "wiki_title": "Korkeasaari Zoo", "height_m": 10.5, "clear_m": 12.0,
	"kind": "Tower", "aliases": ["korkeasaari lookout tower", "korkeasaaren näkötorni", "högholmen utsiktstorn",
		"korkeasaari kupla", "kupla lookout tower"]}

const R := 3.3
const CY := 7.2
const MERIDIANS := 8
const PARALLELS := 5

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Rib", LandmarkMaterials.pbr("wood", "#9A7B54", 1.2))
	lm.use("Deck", LandmarkMaterials.pbr("wood", "#B4956A", 1.2))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#9C9A94", 3.0))
	lm.use("Rail", LandmarkMaterials.paint("#3A3D3F", 0.5, 0.5))
	# Concrete plinth with a stair on its south side.
	lm.frustum("Concrete", Vector3.ZERO, 4.2, 3.9, 3.6, 24)
	U.steps(lm, "Concrete", Vector3(0, 0, 3.8), Vector3(0, 0, 1), 2.4, 0.4, 0.45, 8)
	lm.frustum("Deck", Vector3(0, 3.6, 0), 3.7, 3.7, 0.15, 24)
	# A spiral stair up to the sphere's floor round a central post.
	lm.beam("Rib", Vector3(0, 3.7, 0), Vector3(0, CY, 0), 0.3)
	for k in 16:
		var a := TAU * 1.25 * float(k) / 16.0
		lm.box("Deck", Vector3(cos(a) * 1.6, 3.8 + (CY - 3.8) * float(k) / 16.0, sin(a) * 1.6), Vector3(1.0, 0.12, 0.5), Basis(Vector3.UP, -a), 0.0)
	# Floor of the sphere at the plinth level, a mid deck, a rail ring.
	lm.frustum("Deck", Vector3(0, CY - 0.1, 0), 3.0, 3.0, 0.2, 20)
	# Meridian ribs.
	var seg := 14
	for m in MERIDIANS:
		var az := TAU * float(m) / float(MERIDIANS)
		var prev := Vector3.ZERO
		for k in range(seg + 1):
			var el := -PI * 0.5 * 0.62 + (PI * 0.5 * 0.62 + PI * 0.5) * float(k) / float(seg)
			var p := Vector3(cos(el) * cos(az) * R, CY + sin(el) * R, cos(el) * sin(az) * R)
			if k > 0:
				lm.beam("Rib", prev, p, 0.16)
			prev = p
	# Parallel rings.
	for j in PARALLELS:
		var el := -0.5 + (PI * 0.5 + 0.5 - 0.15) * float(j) / float(PARALLELS - 1)
		var r := cos(el) * R
		var y := CY + sin(el) * R
		var prev := Vector3(r, y, 0)
		for k in range(1, 25):
			var a := TAU * float(k) / 24.0
			var p := Vector3(cos(a) * r, y, sin(a) * r)
			lm.beam("Rib", prev, p, 0.13)
			prev = p
	# Rail along the deck edge.
	var prev := Vector3(3.0, CY + 1.0, 0)
	for k in range(1, 21):
		var a := TAU * float(k) / 20.0
		var p := Vector3(cos(a) * 3.0, CY + 1.0, sin(a) * 3.0)
		lm.beam("Rail", prev, p, 0.05)
		prev = p
	lm.commit(model)
