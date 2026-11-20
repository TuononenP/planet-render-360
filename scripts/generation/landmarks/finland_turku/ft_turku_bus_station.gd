class_name FtTurkuBusStation
extends RefCounted

## Turku Bus Station (Turun linja-autoasema, Harald Smedberg & Totti Sora,
## 1938) at Aninkaistensilta in true metres (+X along the long departure axis,
## -X semicircular ticket rotunda, +Z departure apron, turned by yaw_deg = 86.1°):
##   - Measured from OSM way:38659318 (60.457073, 22.268170, 64.6 x 27.3 m).
##   - Iconic 1938 Finnish Functionalist pale-ochre brick/render semicircular
##     ticket rotunda (R = 11.2 m, H = 8.4 m) with continuous curved clerestory
##     glazing, granite base, and warm illuminated interior waiting hall.
##   - Sweeping cantilevered thin white concrete departure canopy (54 m long,
##     overhanging departure bays on slender cylindrical steel/concrete columns)
##     with recessed linear platform lighting.
##   - Raised rooftop functionalist clock & illuminated "LINJA-AUTOASEMA" sign
##     beacon rising to 10.6 m above the rotunda crown.
##   - Paved granite/concrete boarding islands & curved functionalist wing wall.
## Surfaces: 8 merged PBR parts (Ochre, White, Concrete, Stone, Roof, Frame,
## Glass, Lamp).

const FOUND := -1.8
const TOP_M := 10.6

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	_build_rotunda_and_body(lm)
	_build_departure_canopy(lm)
	_build_rooftop_clock_and_sign(lm)
	lm.commit(model)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("Ochre", LandmarkMaterials.pbr("render", "#DEC89A", 2.8))
	lm.use("White", LandmarkMaterials.pbr("render", "#F1EDE3", 2.6))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#C5C0B6", 2.8))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#827E78", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#4C5155", 2.5))
	lm.use("Frame", LandmarkMaterials.paint("#2A3036", 0.42, 0.58))
	lm.use("Glass", LandmarkMaterials.glass("#243644"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE6AE", 1.6))

static func _build_rotunda_and_body(lm: LandmarkMesh) -> void:
	# Raised concrete/granite boarding apron & plinth (64 x 26 m).
	LandmarkFrKit.rect(lm, "Stone", -32.0, 32.0, -13.0, 13.0, FOUND, 0.45)
	# Semicircular/cylindrical 1938 ticket rotunda at -X (cx = -19.5, R = 10.8 m, H = 8.4 m).
	var rc := Vector3(-19.5, 0.45, 0.0)
	lm.frustum("Stone", Vector3(rc.x, FOUND, rc.z), 11.1, 11.1, 1.35 - FOUND, 28)
	lm.frustum("Ochre", Vector3(rc.x, 1.35, rc.z), 10.8, 10.8, 2.25, 28)
	# Continuous curved panoramic ticket-hall glazing band (y = 3.6..6.8).
	lm.frustum("Glass", Vector3(rc.x, 3.6, rc.z), 10.55, 10.55, 3.2, 28)
	lm.frustum("Lamp", Vector3(rc.x, 3.8, rc.z), 10.0, 10.0, 2.8, 24)
	# Curved mullions around the rotunda glass drum.
	for k in 20:
		var a := TAU * float(k) / 20.0
		var mx := rc.x + cos(a) * 10.68
		var mz := rc.z + sin(a) * 10.68
		lm.beam("Frame", Vector3(mx, 3.55, mz), Vector3(mx, 6.85, mz), 0.16, 0.16)
	# Crisp overhanging white functionalist cornice & rotunda roof slab.
	lm.frustum("White", Vector3(rc.x, 6.8, rc.z), 11.4, 11.4, 1.25, 28)
	lm.frustum("Roof", Vector3(rc.x, 8.05, rc.z), 10.9, 10.9, 0.35, 28)
	# Rectangular ochre-render waiting hall & café/office wing extending +X (-19.5..18.0, z = -7.6..7.6).
	LandmarkFrKit.rect(lm, "Stone", -19.5, 18.2, -7.8, 7.8, FOUND, 1.35)
	LandmarkFrKit.rect(lm, "Ochre", -19.5, 18.0, -7.6, 7.6, 1.35, 6.9)
	LandmarkFrKit.rect(lm, "White", -19.5, 18.4, -8.0, 8.0, 6.9, 7.65)
	LandmarkFrKit.rect(lm, "Roof", -19.2, 18.0, -7.6, 7.6, 7.65, 7.95)
	# Long functionalist strip windows along both sides of the central hall.
	for sz: float in [-7.66, 7.66]:
		var s := signf(sz)
		LandmarkFrKit.rect(lm, "Glass", -10.5, 16.2, sz - 0.08, sz + 0.08, 2.4, 5.8)
		LandmarkFrKit.rect(lm, "Lamp", -9.8, 15.4, sz - 0.40 * s, sz - 0.20 * s, 2.6, 5.5)
		for k in 12:
			var mx := lerpf(-10.2, 16.0, float(k) / 11.0)
			lm.box("Frame", Vector3(mx, 4.1, sz + 0.06 * s), Vector3(0.14, 3.45, 0.18))

static func _build_departure_canopy(lm: LandmarkMesh) -> void:
	# Sweeping cantilevered white functionalist departure canopy wrapping +X and both bus flanks.
	# Main cantilevered wing canopy extending out to x = +31.5 and z = -12.8..+12.8.
	LandmarkFrKit.rect(lm, "White", -14.0, 31.2, -12.6, 12.6, 4.25, 4.80)
	LandmarkFrKit.rect(lm, "Roof", -13.6, 30.8, -12.2, 12.2, 4.80, 4.98)
	# Rounded semicircular canopy prow at the +X end (cx = 31.0, R = 12.6 m).
	lm.frustum("White", Vector3(24.0, 4.25, 0.0), 12.6, 12.6, 0.55, 24)
	lm.frustum("Roof", Vector3(24.0, 4.80, 0.0), 12.2, 12.2, 0.18, 24)
	# Warm recessed linear departure bay lighting strips under the canopy eaves.
	for sz: float in [-10.2, 10.2]:
		LandmarkFrKit.rect(lm, "Lamp", -12.0, 29.0, sz - 0.35, sz + 0.35, 4.14, 4.26)
	# Slender cylindrical functionalist canopy columns along both departure bays.
	for sz: float in [-10.6, 10.6]:
		for k in 9:
			var px := lerpf(-11.0, 29.0, float(k) / 8.0)
			lm.frustum("Concrete", Vector3(px, 0.45, sz), 0.24, 0.24, 3.85, 10)
	# Central spine columns in the open +X bus bay (x = 18..31).
	for k in 3:
		var px := lerpf(21.0, 30.0, float(k) / 2.0)
		lm.frustum("Concrete", Vector3(px, 0.45, 0.0), 0.28, 0.28, 3.85, 10)

static func _build_rooftop_clock_and_sign(lm: LandmarkMesh) -> void:
	# Raised functionalist rooftop beacon & illuminated clock above the rotunda (reaches 10.6 m).
	var rx := -19.5
	lm.frustum("White", Vector3(rx, 8.4, 0.0), 3.6, 3.6, 1.35, 20)
	lm.frustum("Roof", Vector3(rx, 9.75, 0.0), 3.4, 3.4, 0.22, 20)
	# Illuminated neon-style sign band wrapping the rotunda parapet.
	lm.frustum("Lamp", Vector3(rx, 8.6, 0.0), 3.72, 3.72, 0.65, 20)
	# Double-sided rooftop clock pylon rising to 10.6 m.
	lm.beam("Frame", Vector3(rx - 4.0, 8.2, 0.0), Vector3(rx - 4.0, 10.55, 0.0), 0.18, 0.18)
	lm.disc("Frame", Vector3(rx - 4.0, 9.6, 0.0), Vector3(1, 0, 0), 0.95, 16)
	lm.disc("Lamp", Vector3(rx - 4.08, 9.6, 0.0), Vector3(-1, 0, 0), 0.80, 16)
	lm.disc("Lamp", Vector3(rx - 3.92, 9.6, 0.0), Vector3(1, 0, 0), 0.80, 16)

static func _set_night_floods(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-34.0, 2.0, 0.0), Vector3(-28.0, 5.8, 0.0), 60.0, 0.85, 36.0, Color(1.0, 0.88, 0.66)],
		[Vector3(-12.0, 2.0, 18.0), Vector3(-12.0, 5.5, 8.0), 58.0, 0.80, 34.0, Color(1.0, 0.88, 0.66)],
		[Vector3(14.0, 2.0, 18.0), Vector3(14.0, 4.5, 10.0), 60.0, 0.70, 34.0, Color(1.0, 0.90, 0.72)],
	])
