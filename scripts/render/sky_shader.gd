class_name SkyShader
extends RefCounted

## The sky dome GLSL for AtmosphereRig: Rayleigh-ish gradient, sun
## disc/halo, FBM cloud deck, twilight band, stars and moon. Kept as
## one string constant so the rig file stays readable.
const CODE := """
shader_type sky;

uniform vec3 zenith_color : source_color = vec3(0.50, 0.66, 0.80);
uniform vec3 horizon_color : source_color = vec3(0.86, 0.84, 0.80);
uniform vec3 glow_color : source_color = vec3(0.96, 0.76, 0.52);
uniform vec3 ground_color : source_color = vec3(0.42, 0.38, 0.33);
uniform vec3 cloud_lit : source_color = vec3(0.95, 0.85, 0.70);
uniform vec3 cloud_shade : source_color = vec3(0.55, 0.58, 0.64);
uniform float glow_amount = 1.0;
uniform float sun_disc = 1.0;
uniform float cloud_cover = 0.3;
uniform float overcast = 0.0;
uniform int octaves = 5;
// 0..3 by tier: High and Ultra add a cirrus veil, edge erosion and a
// short light march toward the sun.
uniform int cloud_quality = 2;
uniform float drift = 0.0;
uniform vec2 wind = vec2(0.8, 0.6);
// Season shape of the deck: stretch along the wind (1 = cumulus heaps,
// >1 = flatter stratiform sheets) and edge softness.
uniform float cloud_stretch = 1.0;
uniform float cloud_soft = 0.12;
// True sun direction, kept after sunset (LIGHT0 becomes the moon) so
// the dusk glow and Earth's shadow stay where the sun went down.
uniform vec3 solar_dir = vec3(0.0, 0.2, -1.0);
uniform float twilight = 0.0;
uniform float night_amount = 0.0;
uniform float star_gain = 1.0;
uniform float milky_gain = 1.0;
uniform vec3 milky_normal = vec3(0.0, 0.2, 0.98);
uniform float moon = 0.0;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float hash3(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float vnoise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(mix(hash3(i), hash3(i + vec3(1, 0, 0)), u.x),
			mix(hash3(i + vec3(0, 1, 0)), hash3(i + vec3(1, 1, 0)), u.x), u.y),
		mix(mix(hash3(i + vec3(0, 0, 1)), hash3(i + vec3(1, 0, 1)), u.x),
			mix(hash3(i + vec3(0, 1, 1)), hash3(i + vec3(1, 1, 1)), u.x), u.y), u.z);
}

// Star field: one jittered point per lit cell, a steep magnitude curve
// so most stars are faint and a handful bright. `dens` thickens it
// inside the Milky Way.
vec3 stars(vec3 d, float dens) {
	vec3 p = d * 260.0;
	vec3 cell = floor(p);
	float h = hash3(cell);
	float cut = 0.972 - 0.02 * dens;
	if (h < cut) {
		return vec3(0.0);
	}
	vec3 c = cell + 0.5 + (vec3(hash3(cell + 1.7), hash3(cell + 3.1), hash3(cell + 5.3)) - 0.5) * 0.6;
	float mag = pow((h - cut) / (1.0 - cut), 4.0);
	float s = smoothstep(0.42, 0.0, length(p - c)) * (0.12 + 2.2 * mag);
	return s * mix(vec3(0.72, 0.80, 1.0), vec3(1.0, 0.86, 0.70), hash3(cell + 9.1));
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

// Normalised FBM; `low` returns the 2-octave base for cheap lighting.
float fbm(vec2 p, int n, out float low) {
	float v = 0.0;
	float a = 0.5;
	float norm = 0.0;
	low = 0.5;
	mat2 r = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	for (int i = 0; i < 6; i++) {
		if (i >= n) {
			break;
		}
		v += a * vnoise(p);
		norm += a;
		if (i == 1) {
			low = v / norm;
		}
		p = r * p * 2.03 + vec2(17.1, 5.3);
		a *= 0.5;
	}
	return v / norm;
}

float fbm2(vec2 p) {
	mat2 r = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	return (0.5 * vnoise(p) + 0.25 * vnoise(r * p * 2.03 + vec2(17.1, 5.3))) / 0.75;
}

void sky() {
	vec3 d = EYEDIR;
	float y = d.y;
	float hy = max(y, 0.0);
	// LIGHT0 is the sun by day and the moon by night.
	vec3 sun_dir = LIGHT0_DIRECTION;
	float mu = dot(d, sun_dir);
	float m = max(mu, 0.0);
	float smu = dot(d, solar_dir);
	float sm = max(smu, 0.0);

	// Rayleigh-ish: optical depth grows toward the horizon, so the
	// pale band is thin and the zenith keeps its blue.
	vec3 col = mix(horizon_color, zenith_color, pow(hy, 0.35));
	// Warm sun-side band (golden hour) and Mie-ish halo.
	float side = pow(smu * 0.5 + 0.5, 3.0);
	float band = exp(-hy * 9.0);
	col = mix(col, glow_color, clamp(band * side * glow_amount, 0.0, 1.0));
	col += glow_color * (pow(sm, 24.0) * 0.12 + pow(sm, 400.0) * 0.5) * glow_amount;
	// Sun glare: a tight bright core and a wide soft aureole in the sun's
	// own light, under the clouds (they cover it where they are thick).
	col += LIGHT0_COLOR * LIGHT0_ENERGY * sun_disc
		* (pow(m, 1400.0) * 1.2 + pow(m, 150.0) * 0.16 + pow(m, 14.0) * 0.018 + pow(m, 3.0) * 0.004);
	if (twilight > 0.001) {
		// Opposite the low sun: Earth's shadow (blue-grey band on the
		// horizon) under the pink Belt of Venus.
		float anti = pow(max(-dot(normalize(d.xz + vec2(1e-4)), normalize(solar_dir.xz + vec2(1e-4))), 0.0), 1.5);
		float shadow = exp(-hy * 16.0) * smoothstep(-0.02, 0.01, y);
		float belt = exp(-pow((hy - 0.15) / 0.08, 2.0));
		col = mix(col, col * vec3(0.52, 0.58, 0.78), shadow * anti * twilight * 0.65);
		col += vec3(0.62, 0.32, 0.40) * belt * anti * twilight * 0.55;
	}
	if (night_amount > 0.001 && !AT_CUBEMAP_PASS) {
		// Milky Way: a soft great-circle band with dusty 3D-noise
		// structure; stars thicken inside it. Atmospheric extinction
		// fades both toward the horizon.
		float mw = dot(d, milky_normal);
		float lane = exp(-mw * mw * 26.0);
		float dust = vnoise3(d * 9.0) * 0.6 + vnoise3(d * 23.0 + 4.0) * 0.4;
		float rift = 1.0 - 0.55 * exp(-mw * mw * 400.0) * smoothstep(0.4, 0.7, dust);
		vec3 night_sky = vec3(0.50, 0.55, 0.72) * lane * (0.25 + 0.75 * dust) * rift * 0.07 * milky_gain;
		night_sky += stars(d, lane * milky_gain) * star_gain;
		// The moon washes out faint stars around it.
		night_sky *= 1.0 - 0.7 * pow(m, 6.0) * moon;
		col += night_sky * night_amount * smoothstep(0.0, 0.22, y) * (1.0 - overcast);
	}
	// Below the horizon: haze first (aerial perspective samples here),
	// darkening to ground bounce only well below the horizon line.
	col = mix(col, ground_color, smoothstep(-0.12, -0.6, y));

	float alpha = 0.0;
	if (y > -0.02) {
		bool hq = !AT_CUBEMAP_PASS && cloud_quality >= 2;
		vec2 wd = normalize(wind);
		vec2 wn = vec2(-wd.y, wd.x);
		if (hq && overcast < 0.95) {
			// Cirrus: a thin, high, wind-combed veil above the deck,
			// brightest toward the sun. Drawn first, so cumulus covers it.
			vec2 cu = d.xz / (y + 0.04) * 0.55;
			cu = wd * dot(cu, wd) * 0.22 + wn * dot(cu, wn) * 1.6 + wind * drift * 0.4;
			cu += 0.6 * vec2(vnoise(cu * 0.5 + 3.1), vnoise(cu * 0.5 + 9.7));
			float cl;
			float ci = smoothstep(0.56, 0.86, fbm(cu, 4, cl));
			ci *= 0.32 * (1.0 - overcast) * smoothstep(0.02, 0.25, y) * (0.35 + 0.65 * cloud_cover);
			vec3 cic = mix(cloud_lit, vec3(1.0), 0.35) + LIGHT0_COLOR * pow(m, 4.0) * 0.5;
			col = mix(col, cic, ci);
		}
		// Dome projection keeps the horizon finite and compresses the
		// deck into a band toward the horizon, like a real cloud layer.
		vec2 uv = d.xz / (y + 0.10) * 1.3;
		// Stratiform seasons: the noise is stretched along the wind.
		uv = wd * (dot(uv, wd) / cloud_stretch) + wn * dot(uv, wn) + wind * drift;
		// Low-frequency domain warp breaks the FBM into billowed
		// heaps instead of uniform streaks (two extra lookups).
		uv += 0.45 * vec2(vnoise(uv * 0.35), vnoise(uv * 0.35 + vec2(7.3, 2.1))) - 0.225;
		int n = AT_CUBEMAP_PASS ? 2 : octaves;
		float low;
		float den = fbm(uv, n, low);
		// Value-noise FBM clusters around 0.5, so cover maps onto a
		// narrow threshold range to give the matching sky fraction.
		float thr = 0.5 + (0.5 - cloud_cover) * 0.36;
		if (hq) {
			// Billowed edges: fine noise erodes the thin margins only,
			// so heaps get cauliflower rims instead of blurred blobs.
			float ero = vnoise(uv * 7.0 + wind * drift * 0.6) * 0.65 + vnoise(uv * 17.0) * 0.35;
			den -= (ero - 0.5) * 0.07 * (1.0 - smoothstep(thr, thr + 0.2, den));
		}
		float c = smoothstep(thr - 0.02, thr + cloud_soft, den);
		// Overcast: the gaps close into a continuous grey deck.
		c = max(c, overcast * (0.80 + 0.20 * den));
		// Light marched toward the sun through the deck: Beer's law on
		// the density met on the way, plus the cheap low-vs-sunward
		// gradient. Thick cores go dark, sunward flanks bright.
		vec2 sxz = normalize(sun_dir.xz + vec2(1e-4)) * 0.09;
		float toward = fbm2(uv + sxz);
		float lit = clamp(0.5 + (low - toward) * 5.0, 0.0, 1.0);
		if (hq) {
			float od = max(toward - thr, 0.0);
			od += max(fbm2(uv + sxz * 2.2) - thr, 0.0);
			od += max(fbm2(uv + sxz * 3.6) - thr, 0.0);
			float beer = exp(-od * 7.0);
			// Powder: thin cloud lit from behind still looks dark at its edge.
			float powder = 1.0 - exp(-max(den - thr, 0.0) * 18.0);
			lit = clamp(mix(lit, beer * mix(1.0, powder, 0.4), 0.6), 0.0, 1.0);
		}
		float thick = smoothstep(thr, thr + 0.3, den);
		vec3 cc = mix(cloud_shade, cloud_lit, lit * (1.0 - 0.55 * thick));
		// Silver lining: thin cloud edges near the sun glow.
		cc += LIGHT0_COLOR * pow(m, 6.0) * (1.0 - thick) * 0.6 * (1.0 - overcast);
		// Distant clouds sink into the horizon haze.
		cc = mix(cc, mix(horizon_color, glow_color, band * side * glow_amount), exp(-hy * 9.0) * 0.65);
		alpha = c * smoothstep(-0.01, 0.10, y) * 0.96;
		col = mix(col, cc, alpha);
	}
	// Sun disc (~0.8 deg) behind the clouds.
	float disc = smoothstep(0.99985, 0.99994, mu);
	col += LIGHT0_COLOR * LIGHT0_ENERGY * disc * sun_disc * 6.0 * (1.0 - alpha);
	if (moon > 0.001) {
		// Moon: a mottled disc (maria) with a cool halo that also
		// brightens thin cloud near it.
		vec3 t = normalize(cross(sun_dir, vec3(0.0, 1.0, 0.0)) + vec3(1e-4));
		vec2 q = vec2(dot(d, t), dot(d, cross(t, sun_dir))) / 0.0155;
		float maria = vnoise3(vec3(q * 2.6, 1.3)) * 0.6 + vnoise3(vec3(q * 6.0, 7.1)) * 0.4;
		vec3 face = vec3(0.93, 0.94, 0.98) * (0.62 + 0.45 * smoothstep(0.35, 0.65, maria));
		col += face * disc * 1.5 * moon * (1.0 - 0.95 * alpha);
		col += vec3(0.50, 0.58, 0.78) * (pow(m, 90.0) * 0.12 + pow(m, 10.0) * 0.035) * moon;
	}
	COLOR = col;
}
"""
