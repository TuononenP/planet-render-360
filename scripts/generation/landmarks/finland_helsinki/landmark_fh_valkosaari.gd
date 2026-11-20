extends RefCounted

## Valkosaari, the Nyländska Jaktklubben (NJK) clubhouse of 1900, a Jugend
## timber villa on the islet in front of Kaivopuisto. Frame: origin at the
## centre of the building footprint (OSM way 115475357, 24.5 x 27.2 m), the
## harbour (marina) front on +Z; registry yaw 42 lays +Z toward the
## south-west, to the marina piers.
##
## What the photographs show (visual-plan/refs/landmarks/valkosaari_pavilion/):
## a cream-rendered ground floor on a granite plinth with round-headed
## windows, a white timber upper floor with ribbons of glazing and a
## veranda, a steep hipped roof of pale-green copper in standing seams,
## a front gable with a sunburst fan in its tympanum, a white lantern
## tower on the ridge with a gallery rail and a green copper cap, and
## round bay turrets with domed copper caps and spires at the two front
## corners.
##
## Measured from OSM: the footprint box. The old registry point lay 130 m
## from the building, so lat/lon, yaw and height changed. Estimated from
## the photographs: floor heights (4.6 m + 4.0 m), roof rise 6.2 m, tower
## and cap (top about 25 m with the 2 m rock), turret size, window counts.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const K = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_g_kit.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "valkosaari_pavilion", "name": "Valkosaari Pavilion", "lat": 60.161245, "lon": 24.964126,
	"radius_m": 1500.0, "wiki_title": "Valkosaari", "height_m": 25.7, "clear_m": 20.0,
	"yaw_deg": 42.0, "kind": "Pavilion",
	"aliases": ["valkosaari pavilion", "valkosaari njk", "blekholmen paviljong"]}

const HW := 11.0
const HD := 11.0
const PLINTH := 1.0
const F1 := 4.6
const EAVE := 8.8
const RISE := 5.8
const BASE := 2.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#E6D4AC", 3.0))
	lm.use("Timber", LandmarkMaterials.pbr("wood", "#EEEBE0", 2.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#F7F4EA", 2.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8E877F", 3.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#79B39A", 2.0, 0.45, 0.35))
	lm.use("Window", LandmarkMaterials.glass("#2B3640"))
	lm.use("Rock", LandmarkMaterials.pbr("rock", "#8C7E78", 4.0))
	lm.use("Deck", LandmarkMaterials.pbr("wood", "#A78A66", 1.2))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE2A8", 0.8))
	K.ledge(lm, "Rock", 22.0, 22.0, BASE)
	var y0 := BASE
	_body(lm, y0)
	_front(lm, y0)
	_roof(lm, y0)
	_tower(lm, y0)
	_turrets(lm, y0)
	_jetty(lm)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 1.0, 22.0), Vector3(0.0, 7.0, HD), 45.0, 0.9, 42.0, Color(1.0, 0.88, 0.7)],
		[Vector3(-18.0, 1.0, 14.0), Vector3(-6.0, 12.0, 0.0), 40.0, 0.7, 42.0, Color(1.0, 0.88, 0.7)],
		[Vector3(18.0, 1.0, 14.0), Vector3(6.0, 12.0, 0.0), 40.0, 0.7, 42.0, Color(1.0, 0.88, 0.7)]])

## Plinth, cream ground floor with round-headed windows, the white upper floor.
static func _body(lm: LandmarkMesh, y0: float) -> void:
	U.blk(lm, "Granite", 0.0, y0, 0.0, 2.0 * HW + 0.5, PLINTH, 2.0 * HD + 0.5)
	U.blk(lm, "Plaster", 0.0, y0 + PLINTH, 0.0, 2.0 * HW, F1 - PLINTH, 2.0 * HD)
	U.blk(lm, "Trim", 0.0, y0 + F1 - 0.35, 0.0, 2.0 * HW + 0.4, 0.35, 2.0 * HD + 0.4)
	U.blk(lm, "Timber", 0.0, y0 + F1, 0.0, 2.0 * HW - 0.8, EAVE - F1, 2.0 * HD - 0.8)
	U.blk(lm, "Trim", 0.0, y0 + EAVE - 0.4, 0.0, 2.0 * HW + 0.2, 0.4, 2.0 * HD + 0.2)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(f))
		var out: Vector3 = b * Vector3(0, 0, 1)
		var rt: Vector3 = b * Vector3(1, 0, 0)
		var half := HD if f % 2 == 0 else HW
		var span := half - 2.2
		var a: Vector3 = rt * -span
		var c: Vector3 = rt * span
		var n := 5 if f % 2 == 0 else 5
		K.row(lm, "Window", a + out * half + Vector3(0, y0, 0), c + out * half + Vector3(0, y0, 0), out, PLINTH + 0.6, n, 1.3, 2.7, true)
		# Upper floor: tall glazed bays with white frames.
		var up := span - 0.6
		K.row(lm, "Window", rt * -up + out * (half - 0.4) + Vector3(0, y0, 0), rt * up + out * (half - 0.4) + Vector3(0, y0, 0), out,
			F1 + 0.5, 6, 1.5, 2.8, false)
		# String course under the upper windows.
		FhP.band(lm, "Trim", a + out * (half - 0.4) + Vector3(0, y0, 0), c + out * (half - 0.4) + Vector3(0, y0, 0), out,
			y0 + F1 + 0.1, 0.2, 0.15)

## Front gable on +Z with its sunburst fan, doorway and the balcony.
static func _front(lm: LandmarkMesh, y0: float) -> void:
	var zf := HD
	U.blk(lm, "Timber", 0.0, y0 + F1, zf + 0.9, 9.0, EAVE - F1 + 0.2, 1.8)
	lm.gable("Copper", Vector3(0.0, y0 + EAVE + 0.2, zf + 0.9), 9.4, 2.0, 4.6, Basis(), 0.25, "Timber")
	# Sunburst fan in the tympanum.
	var c := Vector3(0.0, y0 + EAVE + 1.3, zf + 1.95)
	for k in 9:
		var a := PI * float(k) / 8.0
		lm.beam("Trim", c, c + Vector3(cos(a) * 1.5, sin(a) * 1.5, 0.0), 0.12, 0.08)
	lm.disc("Window", c + Vector3(0, 0.0, 0.0), Vector3(0, 0, 1), 0.35, 10)
	# Entrance with steps and a veranda deck.
	U.blk(lm, "Deck", 0.0, y0 + PLINTH, zf + 2.2, 10.0, 0.15, 2.4)
	U.steps(lm, "Granite", Vector3(0.0, y0 - 0.2, zf + 3.4), Vector3(0, 0, 1), 5.0, 0.4, 0.2, 5)
	FhP.win_row(lm, "Trim", "Window", Vector3(0.0, y0, zf + 1.85), Vector3(0.0, y0, zf + 1.85), Vector3(0, 0, 1), y0 + PLINTH + 0.3, 1, 1.8, 3.2, true, 0.12)
	# Upper balcony rail.
	for k in 11:
		var x := -4.5 + float(k) * 0.9
		lm.beam("Trim", Vector3(x, y0 + F1, zf + 1.85), Vector3(x, y0 + F1 + 1.0, zf + 1.85), 0.05, 0.05)
	lm.beam("Trim", Vector3(-4.5, y0 + F1 + 1.0, zf + 1.85), Vector3(4.5, y0 + F1 + 1.0, zf + 1.85), 0.07, 0.07)

static func _roof(lm: LandmarkMesh, y0: float) -> void:
	K.hip(lm, "Copper", 0.0, 0.0, y0 + EAVE, 2.0 * HW, 2.0 * HD, RISE, 3.0, 0.6)

## Lantern tower on the ridge, white with a railed gallery and a green cap.
static func _tower(lm: LandmarkMesh, y0: float) -> void:
	var ty := y0 + EAVE + RISE - 0.4
	U.blk(lm, "Timber", 0.0, ty, 0.0, 3.4, 3.4, 3.4)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(f))
		var out: Vector3 = b * Vector3(0, 0, 1)
		FhP.win_row(lm, "Trim", "Window", out * 1.7, out * 1.7, out, ty + 0.8, 1, 0.9, 1.6, true, 0.1)
	U.blk(lm, "Trim", 0.0, ty + 3.4, 0.0, 4.4, 0.3, 4.4)
	for i in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(i))
		var p0: Vector3 = b * Vector3(-2.1, ty + 3.7, 2.1)
		var p1: Vector3 = b * Vector3(2.1, ty + 3.7, 2.1)
		lm.beam("Trim", p0 + Vector3(0, 0.9, 0), p1 + Vector3(0, 0.9, 0), 0.07, 0.07)
		for k in 6:
			var p := p0.lerp(p1, float(k) / 5.0)
			lm.beam("Trim", p, p + Vector3(0, 0.9, 0), 0.05, 0.05)
	U.blk(lm, "Timber", 0.0, ty + 3.7, 0.0, 2.6, 1.6, 2.6)
	lm.lathe("Copper", Vector3(0, ty + 5.3, 0), PackedVector2Array([Vector2(1.9, 0), Vector2(1.65, 0.3), Vector2(1.9, 0.9),
		Vector2(1.2, 1.6), Vector2(0.55, 2.3), Vector2(0.15, 3.1), Vector2(0.0, 3.4)]), 12)
	lm.beam("Copper", Vector3(0, ty + 8.7, 0), Vector3(0, ty + 9.5, 0), 0.06, 0.06)

## Round bay turrets at the two front corners, domed in green copper.
static func _turrets(lm: LandmarkMesh, y0: float) -> void:
	for s in [-1.0, 1.0]:
		var cx: float = s * (HW - 0.2)
		var cz: float = HD - 0.2
		lm.frustum("Plaster", Vector3(cx, y0 + PLINTH, cz), 2.6, 2.6, F1 - PLINTH, 14)
		lm.frustum("Timber", Vector3(cx, y0 + F1, cz), 2.5, 2.5, EAVE - F1 + 0.8, 14)
		for f in 5:
			var a := -PI * 0.25 + PI * 0.25 * float(f)
			var out := Vector3(sin(a) * s, 0, cos(a))
			FhP.win_row(lm, "Trim", "Window", Vector3(cx, y0, cz) + out * 2.52, Vector3(cx, y0, cz) + out * 2.52, out, y0 + F1 + 0.7, 1, 1.0, 2.4, false, 0.08)
		K.turret(lm, "Timber", "Copper", cx, cz, y0 + EAVE + 0.8, 2.5, 0.2, 4.2, 3.2, 14)

## The jetty along the front.
static func _jetty(lm: LandmarkMesh) -> void:
	U.blk(lm, "Deck", 0.0, 1.0, 22.0, 3.4, 0.3, 16.0)
	for k in 8:
		for s in [-1.0, 1.0]:
			lm.box("Granite", Vector3(s * 1.5, 0.5, 14.5 + float(k) * 2.0), Vector3(0.25, 1.0, 0.25))
