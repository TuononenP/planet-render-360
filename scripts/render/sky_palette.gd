class_name SkyPalette
extends RefCounted

## Sky colour grade for AtmosphereRig: the reference-day keyframes
## (zenith, anti-sun horizon, sun-side glow) and each season's tint,
## haze, cloud shape and night sky. The keyframes are indexed by the
## equivalent hour of the reference day arc (AtmosphereRig maps the true
## solar elevation onto it), so 17:00 is the PRD golden-hour grade.

## Mid-month of each season (spring, summer, autumn, winter) in the
## northern hemisphere; the south shifts by six months.
const SEASON_MONTH := [4, 7, 10, 1]
## Per-season sky character, indexed by LocationData.Season. Summer is
## the reference grade (PRD Paris 17:00) and is the identity. Sun
## height comes from the real date (T6.2); colour tints shift hue at
## constant luminance so they hold by day and by night;
## `haze` scales clear-air extinction; `stretch` / `soft` shape the
## cloud deck; `stars`, `milky` and `milky_tilt` / `milky_yaw` (deg)
## set the night sky (summer carries the bright Milky Way core).
const SEASON_SKY := [
	# Spring: rinsed clear blue, pink-tinged low sun, building cumulus.
	{"zenith": [Color(0.26, 0.48, 0.88), 0.15],
		"horizon": [Color(0.78, 0.86, 0.94), 0.15], "glow": [Color(1.0, 0.70, 0.64), 0.18],
		"haze": 0.85, "stretch": 1.1, "soft": 0.13,
		"stars": 0.9, "milky": 0.55, "milky_tilt": 55.0, "milky_yaw": 20.0},
	# Summer: reference grade.
	{"zenith": [Color(0.24, 0.45, 0.80), 0.0],
		"horizon": [Color(0.76, 0.80, 0.86), 0.0], "glow": [Color(0.94, 0.77, 0.56), 0.0],
		"haze": 1.0, "stretch": 1.0, "soft": 0.12,
		"stars": 0.85, "milky": 1.0, "milky_tilt": 78.0, "milky_yaw": 70.0},
	# Autumn: amber low sun, damp warm haze, layered decks.
	{"zenith": [Color(0.22, 0.40, 0.74), 0.12],
		"horizon": [Color(0.86, 0.79, 0.66), 0.28], "glow": [Color(1.0, 0.56, 0.24), 0.45],
		"haze": 1.25, "stretch": 1.35, "soft": 0.17,
		"stars": 1.0, "milky": 0.8, "milky_tilt": 70.0, "milky_yaw": 125.0},
	# Winter: low pale sun, cold dry air, rose twilight, flat stratus.
	{"zenith": [Color(0.52, 0.64, 0.82), 0.25],
		"horizon": [Color(0.84, 0.87, 0.92), 0.28], "glow": [Color(1.0, 0.66, 0.66), 0.32],
		"haze": 0.8, "stretch": 1.7, "soft": 0.22,
		"stars": 1.2, "milky": 0.45, "milky_tilt": 50.0, "milky_yaw": 160.0},
]

const ZENITH := [
	[0.0, Color(0.03, 0.05, 0.12)], [5.0, Color(0.06, 0.09, 0.19)],
	[6.5, Color(0.24, 0.38, 0.62)], [8.0, Color(0.30, 0.50, 0.78)],
	[12.0, Color(0.24, 0.45, 0.80)], [16.0, Color(0.33, 0.54, 0.82)],
	[17.0, Color(0.44, 0.62, 0.82)], [18.0, Color(0.38, 0.47, 0.66)],
	[19.0, Color(0.13, 0.16, 0.31)], [20.5, Color(0.05, 0.07, 0.15)],
	[24.0, Color(0.03, 0.05, 0.12)]]
## Anti-sun horizon: the haze base. Pale blue by day, never cream.
const HORIZON := [
	[0.0, Color(0.07, 0.09, 0.16)], [5.0, Color(0.12, 0.13, 0.21)],
	[6.5, Color(0.62, 0.60, 0.66)], [8.0, Color(0.76, 0.81, 0.87)],
	[12.0, Color(0.70, 0.80, 0.91)], [16.0, Color(0.74, 0.80, 0.88)],
	[17.0, Color(0.76, 0.80, 0.86)], [18.0, Color(0.72, 0.62, 0.62)],
	[19.0, Color(0.30, 0.25, 0.33)], [20.5, Color(0.09, 0.10, 0.18)],
	[24.0, Color(0.07, 0.09, 0.16)]]
## Sun-side horizon glow: PRD #F0C48F at 17:00.
const GLOW := [
	[0.0, Color(0.08, 0.10, 0.18)], [5.0, Color(0.26, 0.19, 0.24)],
	[6.5, Color(1.00, 0.64, 0.40)], [8.0, Color(1.00, 0.84, 0.66)],
	[12.0, Color(0.96, 0.95, 0.91)], [16.0, Color(1.00, 0.88, 0.70)],
	[17.0, Color(0.94, 0.77, 0.56)], [18.0, Color(1.00, 0.55, 0.32)],
	[19.0, Color(0.52, 0.30, 0.30)], [20.5, Color(0.10, 0.11, 0.19)],
	[24.0, Color(0.08, 0.10, 0.18)]]

## Season-tinted zenith / horizon / glow at reference-day hour `key_h`.
static func colors_at(key_h: float, season: int) -> Dictionary:
	var s: Dictionary = SEASON_SKY[season]
	return {
		"zenith": tint(keyframed(key_h, ZENITH), s["zenith"][0], s["zenith"][1]),
		"horizon": tint(keyframed(key_h, HORIZON), s["horizon"][0], s["horizon"][1]),
		"glow": tint(keyframed(key_h, GLOW), s["glow"][0], s["glow"][1]),
	}

## Shifts `c` toward the hue of `target` by `w` at constant luminance,
## so a season tint never brightens the night or darkens the noon sky.
static func tint(c: Color, target: Color, w: float) -> Color:
	if w <= 0.0:
		return c
	var lum := c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
	var t_lum := target.r * 0.2126 + target.g * 0.7152 + target.b * 0.0722
	var t := target * (lum / maxf(t_lum, 1e-4))
	t.a = 1.0
	return c.lerp(t, w)

static func keyframed(hour_f: float, keys: Array) -> Color:
	for i in keys.size() - 1:
		var h0 := float(keys[i][0])
		var h1 := float(keys[i + 1][0])
		if hour_f >= h0 and hour_f <= h1:
			var t := 0.0 if h1 == h0 else (hour_f - h0) / (h1 - h0)
			return (keys[i][1] as Color).lerp(keys[i + 1][1], t)
	return keys[keys.size() - 1][1]
