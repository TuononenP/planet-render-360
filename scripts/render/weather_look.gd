class_name WeatherLook
extends RefCounted

## What the live weather does to the light (AtmosphereRig) and to the
## rain / snow particles (ViewConditions), from the Open-Meteo WMO code
## and cloud cover. One dictionary per state:
##
## - `visibility_m`: meteorological visibility (0 = clear-air haze only);
##   fog density is Koschmieder's 3 / V, so heavy rain is murkier than
##   light rain and fog murkier still.
## - `sun_dim` / `shadow_opacity` / `ambient_gain`: under cloud the
##   direct beam weakens and shadows soften while the diffuse sky takes
##   over the lighting.
## - `exposure_lift`: a gentle eye adaptation so storms stay readable.
## - `cloud_darken` / `cloud_tint`: storm decks are lower, darker and
##   faintly blue-green underneath.
## - `precip` / `intensity`: particle kind and strength (0..1).
## - `storm` / `hail`: thunderstorm (LightningRig) and its hail variant.

const STORM_CODES := [95, 96, 99]
## code -> [precip, intensity, visibility_m]
const STATES := {
	45: ["none", 0.0, 600.0], 48: ["none", 0.0, 400.0],
	51: ["rain", 0.2, 6000.0], 53: ["rain", 0.35, 4000.0], 55: ["rain", 0.5, 3000.0],
	56: ["rain", 0.25, 5000.0], 57: ["rain", 0.5, 3000.0],
	61: ["rain", 0.35, 10000.0], 63: ["rain", 0.6, 5000.0], 65: ["rain", 0.9, 2000.0],
	66: ["rain", 0.4, 8000.0], 67: ["rain", 0.8, 3000.0],
	80: ["rain", 0.4, 9000.0], 81: ["rain", 0.65, 4500.0], 82: ["rain", 0.95, 1800.0],
	71: ["snow", 0.3, 3000.0], 73: ["snow", 0.6, 1200.0], 75: ["snow", 0.9, 600.0],
	77: ["snow", 0.25, 3000.0], 85: ["snow", 0.5, 1800.0], 86: ["snow", 0.85, 700.0],
	95: ["rain", 0.7, 3000.0], 96: ["rain", 0.85, 1500.0], 99: ["rain", 0.95, 1500.0],
}
## Fog visibility below which the scene counts as foggy (denser
## volumetric medium, no sun shafts).
const FOGGY_BELOW_M := 2000.0

static func for_code(code: int, cover_pct: float) -> Dictionary:
	var cover := clampf(cover_pct / 100.0, 0.0, 1.0)
	var row: Array = STATES.get(code, ["none", 0.0, 0.0])
	var precip := str(row[0])
	var inten := float(row[1])
	var vis := float(row[2])
	var storm := code in STORM_CODES
	var fog := code == 45 or code == 48
	var overcast := smoothstep(0.5, 1.0, cover)
	# Precipitation implies a thick deck even when the cover lags.
	if precip != "none" or fog:
		overcast = maxf(overcast, 0.6 + 0.4 * inten)
	var look := {
		"code": code,
		"precip": precip,
		"intensity": inten,
		"visibility_m": vis,
		"storm": storm,
		"hail": code == 96 or code == 99,
		"sun_dim": lerpf(1.0, 0.55, cover) * (1.0 - 0.35 * inten) * (0.6 if fog else 1.0),
		"shadow_opacity": lerpf(1.0, 0.4, overcast) * (1.0 - 0.5 * inten) * (0.3 if fog else 1.0),
		"ambient_gain": 1.0 + 0.3 * overcast + (0.15 if fog else 0.0),
		"exposure_lift": (0.12 if storm else 0.0) + 0.06 * inten,
		"cloud_darken": 0.55 if storm else (0.3 * inten if precip == "rain" else 0.0),
		"cloud_tint": Color(0.82, 0.93, 0.92) if storm else Color(1, 1, 1),
	}
	return look

static func is_foggy(look: Dictionary) -> bool:
	var vis := float(look.get("visibility_m", 0.0))
	return vis > 0.0 and vis < FOGGY_BELOW_M

## Extinction per metre: clear-air `haze_per_m` or the weather's
## visibility, whichever is murkier.
static func fog_per_m(look: Dictionary, haze_per_m: float) -> float:
	var vis := float(look.get("visibility_m", 0.0))
	return maxf(haze_per_m, 3.0 / vis) if vis > 0.0 else haze_per_m

## Rain / snow particle dressing by intensity: emitted share of the
## particle budget, fall acceleration, quad size and alpha.
static func particle_params(look: Dictionary) -> Dictionary:
	var inten := float(look.get("intensity", 0.0))
	if str(look.get("precip", "none")) == "snow":
		return {"amount_ratio": lerpf(0.3, 1.0, inten), "gravity": lerpf(-2.5, -4.5, inten),
			"size": Vector2.ONE * lerpf(0.10, 0.18, inten), "alpha": lerpf(0.65, 0.85, inten)}
	return {"amount_ratio": lerpf(0.25, 1.0, inten), "gravity": lerpf(-18.0, -26.0, inten),
		"size": Vector2(lerpf(0.03, 0.06, inten), lerpf(0.35, 0.65, inten)),
		"alpha": lerpf(0.30, 0.55, inten)}
