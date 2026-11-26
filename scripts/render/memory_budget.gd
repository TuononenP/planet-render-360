class_name MemoryBudget
extends RefCounted

## How much memory this device lets the app use, how close it is, and the
## world sizes that fit. iOS ends an app whose footprint reaches its limit
## and Android's low-memory killer ends the biggest app when the system
## runs short, both without a crash report, so the app keeps under a limit
## of its own: the kill line on iOS (footprint + os_proc_available_memory),
## a share of the phone's RAM on Android, of the computer's on desktop.
## PR360_MEMORY_LIMIT_MB sets the limit anywhere, to try a phone's on a
## desktop. MemoryGuard sheds memory as the footprint nears it; the tier
## sizes worlds before they are built.

const MB := 1 << 20
## Android: the share of RAM the app plans to use. The rest is the system,
## the launcher and the apps kept warm behind it.
const ANDROID_SHARE := 0.55
## Android: MemAvailable the app leaves to the system even under its share.
const ANDROID_RESERVE := 300 * MB
## Desktop: the share of RAM before the guard steps in (swap exists there,
## but a world that pages is as good as stalled), capped so high-RAM
## workstations still shed parked worlds and scratch caches.
const DESKTOP_SHARE := 0.75
const DESKTOP_MAX_LIMIT := 12 * 1024 * MB
## Desktop VRAM ceiling (bytes) so MemoryGuard engages on video-memory growth
## even when system RAM has ample headroom. Sized so a single Ultra city build
## (~4.7 GiB peak) finishes and saves cleanly while multi-world roaming sheds.
const DESKTOP_VRAM_LIMIT := 6144 * MB
## Never plan on less than this, whatever a misread counter says.
const MIN_LIMIT := 1024 * MB
const ENV_LIMIT := "PR360_MEMORY_LIMIT_MB"

## Memory tiers by the limit: T0 below a 6 GB phone (best effort), T1 a
## 6 GB phone (≈3–3.5 GB kill line), T2 an 8 GB phone, T3 12 GB phones
## and up (an Android 12 GB phone reports ~11 GB, ×0.55 ≈ 6 GB). Desktops
## are always T3: their sizes come from the GPU rule (RenderSettings),
## and MemoryGuard still watches their limit.
enum Tier { T0, T1, T2, T3 }
const TIER_FLOORS := [0, 3072 * MB, 4096 * MB, 5632 * MB]

## Per tier (index = Tier): what a world may hold.
## Stretches kept built behind a streaming camera (WorldStreamer).
const PARK_MAX := [0, 1, 2, 2]
## Fetch-only pipelines warming stretches ahead (StreamScout).
const WARM_MAX := [0, 1, 2, 2]
## Real buildings placed, as a share of the preset's count.
const BUILDING_SCALE := [0.5, 0.75, 1.0, 1.0]
## Fresh-install preset (-1: the GPU rule in RenderSettings decides).
const DEFAULT_PRESET := [0, 1, 2, -1]
## Highest preset the device may run, whatever Settings asks for.
const CEILING_PRESET := [1, 2, 3, 3]
## Whether CityDetail's raised hero-city budgets apply.
const CITY_DETAIL := [false, false, true, true]
## Largest terrain texture array side (TerrainTextures).
const TERRAIN_TEXTURE_MAX := [1024, 1024, 1024, 2048]

## Tests and tools set these instead of the device's counters (-1: read).
static var limit_override := -1
static var tier_override := -1

static var _tier := -1

## "ios", "android" or "desktop".
static func platform() -> String:
	if OS.has_feature("ios"):
		return "ios"
	if OS.has_feature("android"):
		return "android"
	return "desktop"

## The limit (bytes) for these readings; -1 inputs are unknown. Pure.
static func limit_for(plat: String, footprint: int, available: int, physical: int) -> int:
	var limit := -1
	match plat:
		"ios":
			# The kill line itself; RAM / 2 if the counter is missing.
			limit = footprint + available if footprint >= 0 and available >= 0 else physical / 2
		"android":
			limit = int(physical * ANDROID_SHARE)
			if footprint >= 0 and available >= 0:
				limit = mini(limit, footprint + available - ANDROID_RESERVE)
		_:
			limit = mini(int(physical * DESKTOP_SHARE), DESKTOP_MAX_LIMIT)
	return maxi(limit, MIN_LIMIT)

## The tier a limit falls in. Pure.
static func tier_for(limit: int) -> int:
	var t := Tier.T0
	for i in TIER_FLOORS.size():
		if limit >= TIER_FLOORS[i]:
			t = i
	return t

## The limit now, in bytes. On Android it falls while other apps take
## memory; on iOS it is the fixed kill line. `footprint`: one already read
## (reading it costs a /proc walk on Android), else read here.
static func limit_bytes(footprint := -1) -> int:
	if limit_override > 0:
		return limit_override
	var env := OS.get_environment(ENV_LIMIT)
	if env.is_valid_int() and int(env) > 0:
		return int(env) * MB
	var fp := footprint if footprint >= 0 else MemoryLog.footprint()
	return limit_for(platform(), fp, available_bytes(), physical_bytes())

## Bytes left before the limit (never below 0).
static func headroom_bytes(footprint := -1) -> int:
	var fp := footprint if footprint >= 0 else MemoryLog.footprint()
	return maxi(limit_bytes(fp) - fp, 0)

## Video memory as a share of the desktop VRAM ceiling (0.0 in headless or mobile).
static func vram_usage() -> float:
	if platform() != "desktop" or DisplayServer.get_name() == "headless":
		return 0.0
	var vram := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED)
	return float(vram) / float(DESKTOP_VRAM_LIMIT) if vram > 0 else 0.0

## The footprint as a share of the limit (1.0 = at the limit).
## Live desktop readings take the higher of RAM and VRAM pressure.
static func usage(footprint := -1) -> float:
	var fp := footprint if footprint >= 0 else MemoryLog.footprint()
	var ram := float(fp) / float(maxi(limit_bytes(fp), 1))
	return maxf(ram, vram_usage()) if footprint < 0 else ram

## The device's tier, read once: it sizes every world this session, so a
## brief squeeze from another app must not change it mid-session.
static func tier() -> int:
	if tier_override >= 0:
		return tier_override
	if _tier < 0:
		var simulated := limit_override > 0 or OS.get_environment(ENV_LIMIT).is_valid_int()
		_tier = Tier.T3 if platform() == "desktop" and not simulated else tier_for(_stable_limit())
	return _tier

## The limit with nothing else running: Android's share of RAM rather than
## what MemAvailable says right now.
static func _stable_limit() -> int:
	if limit_override > 0 or OS.get_environment(ENV_LIMIT).is_valid_int():
		return limit_bytes()
	if platform() == "android":
		return limit_for("android", -1, -1, physical_bytes())
	return limit_bytes()

## Bytes the OS still gives the app (iOS) or the system has (Android); -1
## where unknown.
static func available_bytes() -> int:
	var b := -1
	if ClassDB.class_exists("MemoryStats"):
		b = int(ClassDB.class_call_static("MemoryStats", "available_bytes"))
	if b < 0 and platform() == "android":
		# A native build from before MemAvailable: Godot reads the same line.
		b = int(OS.get_memory_info().get("available", -1))
	return b

static func physical_bytes() -> int:
	return int(OS.get_memory_info().get("physical", -1))

## The highest preset this device runs.
static func ceiling_preset() -> int:
	return CEILING_PRESET[tier()]

## `preset` held to the device's ceiling.
static func cap_preset(preset: int) -> int:
	return mini(preset, ceiling_preset())

## "limit 3,300 MB, headroom 1,200 MB, tier T1" for the memory log.
static func summary(footprint := -1) -> String:
	var fp := footprint if footprint >= 0 else MemoryLog.footprint()
	var limit := limit_bytes(fp)
	return "limit %s MB, headroom %s MB, tier T%d" % [UiTheme.grouped(limit / MB),
		UiTheme.grouped(maxi(limit - fp, 0) / MB), tier()]
