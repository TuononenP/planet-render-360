class_name DetailDrift
extends RefCounted

## Near detail follows the camera. A world builds its near detail — facade
## relief, roof trim, rooftop plant, full facade materials — in rings
## around one eye (View360.spawn_xz: a preset's curated eye, else the
## centre), not around wherever the camera goes later. A camera that flies
## off and stops 800 m away looks at plain boxes in shared materials there,
## though the world reaches well past it. WorldStreamer only recentres near
## the detailed square's edge; this rule adds the other trigger: a camera
## standing still for STILL_S, far enough from the eye that the buildings
## around it fall outside the relief ring, gets a world centred on itself.

## Seconds the camera must stand still first: a pause to look, not a turn
## mid-flight.
const STILL_S := 3.0
## Share of the preset's relief ring (FacadeRelief.radius_m) the camera
## may stray from the eye: past it, buildings beside the camera are past
## the ring.
const RING_SHARE := 0.6
## Never rebuild for less than this (m): walkers on High stop often.
const MIN_DRIFT_M := 200.0

## How far (m) the camera may stand from the detail eye on `preset`.
static func drift_m(preset: int) -> float:
	return maxf(FacadeRelief.radius_m(preset) * RING_SHARE, MIN_DRIFT_M)

## Whether a camera at `pos` (metres, the live world's frame), still for
## `still_s` seconds, wants its world rebuilt around it: `eye` is the
## live world's detail eye.
static func wanted(pos: Vector2, eye: Vector2, still_s: float, preset: int) -> bool:
	return still_s >= STILL_S and pos.distance_to(eye) > drift_m(preset) * WorldScale.metres_to_units()
