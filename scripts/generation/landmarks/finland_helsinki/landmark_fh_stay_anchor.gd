class_name LandmarkFhStayAnchor
extends RefCounted

## The deck end of a Kruunuvuorensilta stay, as in photos: the white
## cable stops at a wide black collar just under the edge band, and a
## thicker black anchor pipe hangs from it along the cable's line, ending
## flat in a cream ring and a short dark boot. Built once in its own frame
## (+Y along the cable, y = 0 at the pipe's lower end) and placed on every
## cable; a drum closes only the ends that can be seen, to stay in the
## bridge's triangle budget.

## Pipe, collar, ring and boot, metres: radii and heights in the part's
## frame. The collar narrows towards the cable; the pipe's top end hides
## inside it.
const PIPE_R := 0.19
const PIPE_TOP := 1.5
const COLLAR := Vector2(1.45, 1.9)
const COLLAR_R := Vector2(0.28, 0.22)
const RING_R := 0.12
const RING_LOW := -0.12
const BOOT_R := 0.075
const BOOT_LOW := -0.3
## The pipe's lower end sits this far below the stay's low point, along
## the cable, so the collar lands just under the edge band.
const TAIL_M := 1.3

## The part in its own frame. `dark` and `light` are the bridge's own
## materials for the "Pole" and "Marking" surfaces it merges into.
static func part(dark: Material, light: Material) -> LandmarkMesh:
	var p := LandmarkMesh.new()
	p.use("Pole", dark)
	p.use("Marking", light)
	_drum(p, "Pole", 0.0, PIPE_TOP, PIPE_R, PIPE_R, 8, true, false)
	_drum(p, "Pole", COLLAR.x, COLLAR.y, COLLAR_R.x, COLLAR_R.y, 8, true, true)
	_drum(p, "Marking", RING_LOW, 0.0, RING_R, RING_R, 6, false, false)
	_drum(p, "Pole", BOOT_LOW, RING_LOW, BOOT_R, BOOT_R, 6, true, false)
	return p

## Puts `anchor` on the cable through `low`, the cable's direction `along`
## (unit, pointing up the cable) being the part's +Y.
static func place(lm: LandmarkMesh, anchor: LandmarkMesh, low: Vector3, along: Vector3) -> void:
	var x := along.cross(Vector3.UP if absf(along.y) < 0.99 else Vector3.RIGHT).normalized()
	lm.merge(anchor, Transform3D(Basis(x, along, x.cross(along)), low - along * TAIL_M))

## Where the white cable starts: the top of the collar.
static func cable_start(low: Vector3, along: Vector3) -> Vector3:
	return low + along * (COLLAR.y - TAIL_M)

## Round drum on +Y from y0 (radius r0) to y1 (radius r1), smooth sides;
## `cap_lo` and `cap_hi` close its ends with a flat disc.
static func _drum(p: LandmarkMesh, key: String, y0: float, y1: float, r0: float, r1: float, sides: int,
		cap_lo: bool, cap_hi: bool) -> void:
	var lean := (r0 - r1) / (y1 - y0)
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		var d0 := Vector3(cos(a0), 0.0, sin(a0))
		var d1 := Vector3(cos(a1), 0.0, sin(a1))
		var n0 := (d0 + Vector3.UP * lean).normalized()
		var n1 := (d1 + Vector3.UP * lean).normalized()
		var lo0 := d0 * r0 + Vector3.UP * y0
		var lo1 := d1 * r0 + Vector3.UP * y0
		var hi0 := d0 * r1 + Vector3.UP * y1
		var hi1 := d1 * r1 + Vector3.UP * y1
		var u0 := r0 * a0
		var u1 := r0 * a1
		p.tri(key, lo0, lo1, hi1, n0, n1, n1, Vector2(u0, -y0), Vector2(u1, -y0), Vector2(u1, -y1))
		p.tri(key, lo0, hi1, hi0, n0, n1, n0, Vector2(u0, -y0), Vector2(u1, -y1), Vector2(u0, -y1))
		if cap_lo:
			p.tri(key, Vector3.UP * y0, lo0, lo1, Vector3.DOWN, Vector3.DOWN, Vector3.DOWN,
				Vector2.ZERO, Vector2(d0.x, d0.z) * r0, Vector2(d1.x, d1.z) * r0)
		if cap_hi:
			p.tri(key, Vector3.UP * y1, hi0, hi1, Vector3.UP, Vector3.UP, Vector3.UP,
				Vector2.ZERO, Vector2(d0.x, d0.z) * r1, Vector2(d1.x, d1.z) * r1)
