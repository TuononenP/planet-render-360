class_name FtGatoradeCenter
extends RefCounted

## Gatorade Center (Turkuhalli, 1990, 11,820-seat ice hockey & concert arena)
## + neighbouring Turku Fair Centre (Messukeskus) wing at Artukainen in true
## metres (+X ESE, +Z SSW entrance plaza, turned by yaw_deg = -31.1°):
##   - Measured from OSM way:429498762 (60.456291, 22.187080, 92.9 x 93.2 m,
##     height 40 m / LoD2 36.0 m), way:979565782 (112.1 x 91.5 m), stair towers
##     way:979565781 & way:979565783 (height 30 m), and Messukeskus way:689840057.
##   - Giant white cylindrical/oval arena bowl (diameter 94 m, eave 20.5 m,
##     shallow domed roof rising to 31.0 m) crowned by iconic external white
##     steel arched space-frame roof trusses reaching 36.0 m!
##   - Four cylindrical exterior concrete/steel vertical circulation & stair
##     towers flanking the arena perimeter (H 30.0 m).
##   - Projecting glazed semicircular entrance rotunda & main concourse atrium
##     on the +Z plaza front with illuminated arena marquee fascia.
##   - Neighbouring Turku Fair Centre (Messukeskus) exhibition hall (-X flank)
##     with sawtooth roof skylights and glazed lobby.
## Surfaces: 9 merged PBR parts (White, Concrete, Steel, Roof, AccentBlue,
## Stone, Frame, Glass, Lamp).

const FOUND := -2.0
const TOP_M := 36.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	_build_arena_bowl(lm)
	_build_external_roof_trusses(lm)
	_build_entrance_and_messukeskus(lm)
	lm.commit(model)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("White", LandmarkMaterials.pbr("render", "#F0EFEA", 3.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#C5C3BC", 2.8))
	lm.use("Steel", LandmarkMaterials.paint("#DCE1E6", 0.38, 0.58))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#6E757D", 2.8, 0.50, 0.45))
	lm.use("AccentBlue", LandmarkMaterials.paint("#1F4E8C", 0.42, 0.30))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#7F7D78", 2.5))
	lm.use("Frame", LandmarkMaterials.paint("#2A3038", 0.42, 0.60))
	lm.use("Glass", LandmarkMaterials.glass("#223848"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE8BC", 1.5))

static func _build_arena_bowl(lm: LandmarkMesh) -> void:
	# Circular concrete plaza plinth & lower arena concourse drum (R = 49.5 m, y = FOUND..8.2 m).
	lm.frustum("Stone", Vector3(0.0, FOUND, 0.0), 52.0, 51.5, 1.2 - FOUND, 36)
	lm.frustum("Concrete", Vector3(0.0, 1.2, 0.0), 49.2, 49.2, 7.2, 36)
	# Upper white fluted cylindrical arena bowl (R = 46.5 m, y = 8.4..21.2 m).
	lm.frustum("White", Vector3(0.0, 8.4, 0.0), 46.5, 47.0, 12.8, 36)
	# Continuous recessed upper concourse clerestory glass band around the bowl (y = 14.5..17.6).
	lm.frustum("Glass", Vector3(0.0, 14.5, 0.0), 47.12, 47.12, 3.1, 36)
	lm.frustum("Lamp", Vector3(0.0, 14.8, 0.0), 46.6, 46.6, 2.5, 32)
	# Crisp white roof-ring fascia & shallow domed arena roof (21.2..30.8 m).
	lm.frustum("White", Vector3(0.0, 21.0, 0.0), 47.8, 47.8, 1.4, 36)
	lm.lathe("Roof", Vector3(0.0, 22.2, 0.0), PackedVector2Array([
		Vector2(47.2, 0.0),
		Vector2(42.0, 3.2),
		Vector2(30.0, 6.2),
		Vector2(15.0, 8.0),
		Vector2(0.0, 8.6),
	]), 36)
	# Rhythmic exterior white precast vertical ribs around the drum.
	for k in 24:
		var a := TAU * float(k) / 24.0
		var rx := cos(a) * 47.3
		var rz := sin(a) * 47.3
		lm.beam("White", Vector3(rx, 8.4, rz), Vector3(rx, 22.0, rz), 0.75, 0.95)
	# Four cylindrical external stair & service towers flanking the bowl (H = 29.5 m, OSM h=30).
	for a: float in [0.55, PI - 0.55, PI + 0.55, TAU - 0.55]:
		var tx := cos(a) * 49.8
		var tz := sin(a) * 49.8
		lm.frustum("White", Vector3(tx, FOUND, tz), 4.6, 4.6, 29.0 - FOUND, 18)
		lm.frustum("AccentBlue", Vector3(tx, 28.4, tz), 4.75, 4.75, 0.95, 18)
		lm.frustum("Roof", Vector3(tx, 29.35, tz), 4.4, 4.4, 0.35, 18)
		lm.beam("Glass", Vector3(tx + cos(a) * 4.62, 3.0, tz + sin(a) * 4.62),
			Vector3(tx + cos(a) * 4.62, 27.5, tz + sin(a) * 4.62), 1.4, 0.20)

static func _build_external_roof_trusses(lm: LandmarkMesh) -> void:
	# Signature giant external white steel arched roof trusses spanning over the dome to 36.0 m!
	var truss_z := [-19.0, 0.0, 19.0]
	for tz: float in truss_z:
		var span_half := sqrt(maxf(100.0, 46.8 * 46.8 - tz * tz))
		var arch_peak := TOP_M if absf(tz) < 1.0 else 33.8
		var segs := 14
		var prev_lo := Vector3.ZERO
		var prev_hi := Vector3.ZERO
		for i in segs + 1:
			var t := float(i) / float(segs)
			var x := lerpf(-span_half, span_half, t)
			var arc := sin(PI * t)
			var y_lo := 22.2 + (arch_peak - 25.4) * arc
			var y_hi := 24.4 + (arch_peak - 24.4) * arc
			var cur_lo := Vector3(x, y_lo, tz)
			var cur_hi := Vector3(x, y_hi, tz)
			if i > 0:
				lm.beam("Steel", prev_lo, cur_lo, 0.55, 0.55)
				lm.beam("Steel", prev_hi, cur_hi, 0.65, 0.65)
				lm.beam("Steel", prev_lo, cur_hi, 0.32, 0.32)
				lm.beam("Steel", prev_hi, cur_lo, 0.32, 0.32)
			lm.beam("Steel", cur_lo, cur_hi, 0.36, 0.36)
			prev_lo = cur_lo
			prev_hi = cur_hi
		# Heavy triangular steel abutment piers anchoring each truss into the outer drum.
		for sx: float in [-1.0, 1.0]:
			var ax := span_half * sx
			lm.beam("Steel", Vector3(ax + 3.2 * sx, 8.4, tz), Vector3(ax, 24.4, tz), 1.2, 1.2)
			lm.beam("Concrete", Vector3(ax + 3.4 * sx, FOUND, tz), Vector3(ax + 3.2 * sx, 8.6, tz), 1.8, 1.8)
	# Longitudinal steel tie-beams linking the three external roof trusses.
	for lx: float in [-22.0, 0.0, 22.0]:
		var ly := 31.8 if absf(lx) < 1.0 else 29.8
		lm.beam("Steel", Vector3(lx, ly - 1.2, -19.0), Vector3(lx, ly, 0.0), 0.42, 0.42)
		lm.beam("Steel", Vector3(lx, ly, 0.0), Vector3(lx, ly - 1.2, 19.0), 0.42, 0.42)

static func _build_entrance_and_messukeskus(lm: LandmarkMesh) -> void:
	# Glazed main entrance rotunda & ticket concourse facing +Z (x = -24..24, z = 44..62).
	LandmarkFrKit.rect(lm, "Stone", -26.0, 26.0, 42.0, 62.0, FOUND, 1.2)
	LandmarkFrKit.rect(lm, "Glass", -22.0, 22.0, 45.0, 58.0, 1.2, 12.2)
	LandmarkFrKit.rect(lm, "Lamp", -20.0, 20.0, 46.5, 56.5, 1.6, 11.4)
	LandmarkFrKit.rect(lm, "White", -24.5, 24.5, 44.0, 61.5, 12.2, 13.8)
	LandmarkFrKit.rect(lm, "AccentBlue", -24.8, 24.8, 60.8, 61.7, 12.4, 13.6)
	for k in 11:
		var mx := lerpf(-21.5, 21.5, float(k) / 10.0)
		lm.box("Frame", Vector3(mx, 6.7, 58.08), Vector3(0.24, 11.0, 0.28))
	# Neighbouring Turku Fair Centre (Messukeskus) exhibition hall on -X flank (-118..-56, z = -34..32).
	LandmarkFrKit.rect(lm, "Stone", -119.0, -55.0, -35.0, 33.0, FOUND, 1.0)
	LandmarkFrKit.rect(lm, "White", -118.0, -56.0, -34.0, 32.0, 1.0, 12.4)
	LandmarkFrKit.rect(lm, "AccentBlue", -118.4, -55.6, -34.4, 32.4, 11.8, 12.8)
	LandmarkFrKit.rect(lm, "Roof", -117.6, -56.4, -33.6, 31.6, 12.4, 12.9)
	# Sawtooth skylight ridges across the Messukeskus exhibition hall roof.
	for k in 4:
		var sz := lerpf(-24.0, 24.0, float(k) / 3.0)
		lm.gable("Roof", Vector3(-87.0, 12.9, sz), 11.0, 58.0, 2.4, Basis(Vector3.UP, PI * 0.5), 0.25, "White")
		LandmarkFrKit.rect(lm, "Glass", -114.0, -60.0, sz + 4.8, sz + 5.2, 13.0, 14.8)
	# Glazed Messukeskus front lobby (+Z).
	LandmarkFrKit.rect(lm, "Glass", -104.0, -70.0, 31.9, 32.2, 1.4, 9.6)
	LandmarkFrKit.rect(lm, "Lamp", -102.0, -72.0, 31.0, 31.5, 1.8, 9.0)

static func _set_night_floods(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.5, 72.0), Vector3(0.0, 12.0, 56.0), 64.0, 0.85, 52.0, Color(0.94, 0.96, 1.0)],
		[Vector3(60.0, 2.5, 0.0), Vector3(44.0, 18.0, 0.0), 60.0, 0.75, 48.0, Color(0.95, 0.96, 1.0)],
		[Vector3(0.0, 22.0, -38.0), Vector3(0.0, 34.0, 0.0), 66.0, 0.80, 56.0, Color(0.90, 0.94, 1.0)],
		[Vector3(-87.0, 2.5, 44.0), Vector3(-87.0, 8.0, 32.0), 62.0, 0.70, 42.0, Color(1.0, 0.92, 0.78)],
	])
