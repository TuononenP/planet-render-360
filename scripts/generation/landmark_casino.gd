class_name LandmarkCasino
extends RefCounted

## Monte Carlo Casino (Garnier's Belle Époque front) in true metres: a
## cream stone block under verdigris copper mansards, its arched upper
## windows between paired columns; on the sea side (+Z, over the
## terraces) the Salle Garnier front between two square towers with
## pavilion roofs and lanterns, and on the square side (−Z) the entrance
## pavilion with its clock under the central copper cupola.

const TOP_M := 34.0
const BLOCK := Vector3(80.0, 18.0, 46.0)

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#E9DFC8", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F3ECDC", 2.5))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E9C88", 2.0, 0.55, 0.3))
	lm.use("Windows", LandmarkMaterials.glass("#2C3438"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var hx := BLOCK.x * 0.5
	var hz := BLOCK.z * 0.5
	lm.box("Stone", Vector3(0, BLOCK.y * 0.5, 0), BLOCK)
	lm.box("Trim", Vector3(0, BLOCK.y + 0.5, 0), BLOCK + Vector3(1.2, 1.0 - BLOCK.y, 1.2))
	# Mansard: steep lower slope then a low cap, copper.
	lm.lathe("Copper", Vector3(0, BLOCK.y + 1.0, 0), PackedVector2Array([Vector2(sqrt(2.0), 0),
		Vector2(sqrt(2.0) * 0.86, 4.5), Vector2(sqrt(2.0) * 0.7, 6.0)]), 4, hx, hz, PI * 0.25, false)
	# Arched windows and paired columns on the long fronts.
	for s in [-1.0, 1.0]:
		for k in 11:
			var x := -hx + 5.0 + 7.0 * k
			var z: float = s * (hz + 0.12)
			lm.box("Windows", Vector3(x, 3.6, z), Vector3(2.4, 4.4, 0.2))
			lm.box("Windows", Vector3(x, 11.0, z), Vector3(2.6, 5.0, 0.2))
			lm.disc("Windows", Vector3(x, 13.5, z + s * 0.01), Vector3(0, 0, s), 1.3, 12)
			for c in [-1.0, 1.0]:
				lm.lathe("Trim", Vector3(x + 3.5 + c * 0.6, 8.0, s * (hz + 0.6)),
					PackedVector2Array([Vector2(0.38, 0), Vector2(0.32, 9.2)]), 8)
		lm.box("Trim", Vector3(0, 7.6, s * (hz + 0.5)), Vector3(BLOCK.x, 0.8, 1.0))
	for s in [-1.0, 1.0]:
		for k in 6:
			var z := -hz + 4.0 + 7.6 * k
			lm.box("Windows", Vector3(s * (hx + 0.12), 11.0, z), Vector3(0.2, 5.0, 2.6))
	# Sea front: the two towers with pavilion roofs, lanterns and finials.
	for s in [-1.0, 1.0]:
		var tc := Vector3(s * (hx - 5.0), 0, hz - 3.0)
		lm.box("Stone", tc + Vector3(0, 13.0, 0), Vector3(10.0, 26.0, 10.0))
		lm.box("Trim", tc + Vector3(0, 26.4, 0), Vector3(11.0, 0.8, 11.0))
		for f in 4:
			var r := Basis(Vector3.UP, PI * 0.5 * f)
			lm.box("Windows", tc + r * Vector3(0, 21.5, 5.1), Vector3(2.2, 5.2, 0.2), r)
			lm.disc("Gilt", tc + r * Vector3(0, 25.0, 5.12), r * Vector3(0, 0, 1), 0.9, 12)
		lm.lathe("Copper", tc + Vector3(0, 26.8, 0), PackedVector2Array([Vector2(7.4, 0),
			Vector2(5.6, 2.6), Vector2(2.2, 4.6)]), 4, 1.0, 1.0, PI * 0.25, false)
		lm.frustum("Copper", tc + Vector3(0, 31.4, 0), 1.4, 1.2, 1.2, 8)
		lm.frustum("Gilt", tc + Vector3(0, 32.6, 0), 0.4, 0.05, TOP_M - 32.6, 6)
	# Sea terrace with its balustrade.
	lm.box("Trim", Vector3(0, 0.4, hz + 9.0), Vector3(BLOCK.x + 10.0, 0.8, 18.0))
	lm.box("Trim", Vector3(0, 1.3, hz + 17.6), Vector3(BLOCK.x + 10.0, 1.0, 0.6))
	# Square side: entrance pavilion, clock and the copper cupola.
	var ec := Vector3(0, 0, -hz - 2.0)
	lm.box("Stone", ec + Vector3(0, 12.0, 0), Vector3(22.0, 24.0, 6.0))
	lm.box("Windows", ec + Vector3(0, 4.5, -3.1), Vector3(6.0, 7.0, 0.2))
	lm.disc("Gilt", ec + Vector3(0, 19.0, -3.12), Vector3(0, 0, -1), 1.6, 16)
	lm.disc("Trim", ec + Vector3(0, 19.0, -3.15), Vector3(0, 0, -1), 1.3, 16)
	lm.gable("Trim", ec + Vector3(0, 24.0, -2.0), 22.0, 2.0, 3.0, Basis(), 0.4, "Stone")
	for k in 4:
		lm.lathe("Trim", ec + Vector3(-7.5 + 5.0 * k, 0, -3.6),
			PackedVector2Array([Vector2(0.55, 0), Vector2(0.48, 14.0)]), 10)
	lm.frustum("Stone", Vector3(0, BLOCK.y + 1.0, -hz + 8.0), 6.0, 6.0, 4.0, 12)
	lm.lathe("Copper", Vector3(0, BLOCK.y + 5.0, -hz + 8.0), PackedVector2Array([Vector2(6.4, 0),
		Vector2(6.0, 2.0), Vector2(4.6, 4.4), Vector2(2.4, 6.0), Vector2(0.0, 6.6)]), 16)
	lm.frustum("Gilt", Vector3(0, BLOCK.y + 11.6, -hz + 8.0), 0.3, 0.05, 2.0, 6)
	lm.commit(model)
