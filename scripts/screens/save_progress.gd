class_name SaveProgress
extends RefCounted

## One steady bar for Save for offline. The work has three parts with no
## shared clock (the data downloads, the world build, the write to the
## device), so each owns a slice of the bar and the bar drifts toward the
## end of the step it is in: it keeps moving through a long step, never
## reaches the next one early and never goes back.

enum Phase { DOWNLOAD, BUILD, WRITE }

const DOWNLOAD_END := 0.3
const BUILD_END := 0.85
## Share of the gap to the end of the current step closed per second.
const DRIFT := 0.1

var phase := Phase.DOWNLOAD
## Download rows finished, of `rows`.
var rows_done := 0
var rows := 1
## BuildAbort.Step the build is in.
var build_step := 0
var shown := 0.0

## The least the bar shows for where the work is.
func floor_at() -> float:
	match phase:
		Phase.DOWNLOAD:
			return DOWNLOAD_END * float(rows_done) / rows
		Phase.BUILD:
			return DOWNLOAD_END + (BUILD_END - DOWNLOAD_END) * BuildAbort.fraction_before(build_step)
	return BUILD_END

## Where the current step ends.
func ceiling_at() -> float:
	match phase:
		Phase.DOWNLOAD:
			return DOWNLOAD_END * minf(float(rows_done + 1) / rows, 1.0)
		Phase.BUILD:
			return DOWNLOAD_END + (BUILD_END - DOWNLOAD_END) * BuildAbort.fraction_before(build_step + 1)
	return 1.0

func tick(dt: float) -> void:
	shown = maxf(shown, floor_at())
	shown += (ceiling_at() - shown) * clampf(DRIFT * dt, 0.0, 1.0)

## Never 100: that is the save ending, which the outcome message says.
func percent() -> int:
	return mini(int(round(shown * 100.0)), 99)

## What the work is doing, for the line under the bar.
func phase_text() -> String:
	match phase:
		Phase.DOWNLOAD:
			return "Downloading map data"
		Phase.BUILD:
			return "Building · %s" % BuildAbort.label_of(build_step)
	return "Writing to this device"
