# Vantage review r4 — 2026-11-01 (realism v3 R-1.1 / R-1.2 / R-1.4)

`tools/capture_presets.gd --audit`, High preset, local golden hour, clear summer weather,
1280×800. Venice was re-shot after its row changed: `../vantage-r4-venice-2026-11-01/`.
Round 3 (`../vantage-r3-2026-11-01/`) holds the generic controls (old Paris pin, Setagaya,
Turku, Zermatt, Cairo) on the same code, apart from the look check's narrower wedge.
The frames stay local (review images are gitignored); `stats.json` and `audit.json` are
committed, and a rerun of the tool regenerates the images.

## Improved / regressed vs r1–r3

Improved (camera only, no build-output change apart from the underground-building parser fix):

- **Every opening look is now clear of anything right in front of it.**
  `View360.view_clearance_y` lifts the eye until every roof and mapped forest canopy within
  80 m and ±17° of the look sits below the look line (cap 150 m).
- **Alps:** the eye now clears the Harder Kulm forest; the lakes and the Jungfrau are in view.
- **Monaco:** the eye clears the Place du Palais buildings, giving the harbour and Monte-Carlo
  as in `refs/monaco/01`.
- **Dubai:** the eye moved out of a 192 m tower to open ground 850 m east. The Burj is centred,
  with a 12° upward look.
- **Big Sur:** the eye moved to the pull-out at the north end of the bridge; the coast and the
  creek are in view.
- **Banff:** the eye is lifted over the riverside woods (28 m); the Bow is in view.
- **Seoul:** the King Sejong Story hall (`level=-1`, under the square) is no longer built on top
  of it. `OsmTags.underground`, generic.
- **Venice:** the look check is off for this row (`"clear": false`); the eye is 8 m on the bridge,
  down the canal to the Salute.

Regressed: none seen.

Still wrong (Track 2):
- Tokyo's scramble renders as lawn.
- No Bixby arch.
- No Banff Springs Hotel or Gwanghwamun model.
- Grass tufts on the Trocadéro paving.
- The far city is drawn as flat prisms (Dubai, Tokyo).
- Grassy banks along the Grand Canal.

Seen once, not reproduced: in r3 the shadowed ground at golden hour rendered pure black (Rome
after London, Setagaya, Zermatt). A Rome-only run and r4 both light it (dim, sky-filled). It is
logged for the Track 2 lighting pass.

## R-1.4 look audit (report only)

`audit.json` lists each place's materials, most used first. Albedo here is the albedo colour ×
the albedo texture's mean, linear Rec.709 luma. It leaves out vertex colours (WallVariety)
and ShaderMaterials (terrain, water). Facade textures include their windows, so a facade
reads darker than its bare wall set.

Outliers against the measured ranges, summed over the 13 presets:

| material | measured | range | share of uses out of range | read |
|---|---|---|---|---|
| curtain glass (`glass:*`) | 0.29 | 0.08–0.15 | 100 % (11 places) | ~2× too bright; matches the "glass reads as render" finding |
| terracotta roofs (`roof:terracotta`, `pbr:terracotta`) | 0.08–0.15 | 0.25–0.40 | 84–100 % (10 places) | far too dark; Rome, Venice and Monaco roofs read brown-grey |
| limestone PBR set (`pbr:limestone`) | 0.24–0.26 | 0.45–0.60 | 47 % | too dark on the plain set; composed Rome facades are too bright (0.70) |
| concrete (`pbr:concrete`, `ground_storey:concrete`) | 0.07–0.28 | 0.30–0.45 | 34–44 % | too dark, worst on tinted shop storeys |
| brick (`facade:brick`) | 0.13–0.50 | 0.20–0.35 | 42 % | both ways: New York punched brick too dark, London ornate too light |

In range or unclassed:
- render facades: 0.59–0.62
- slate roofs: 0.10–0.19
- pavement: 0.21
- distant facades: 0.44

About 8,300 uses are unnamed materials (props, vegetation, landmarks); they are outside the
cache-name mapping.

**AgX vs ACES** (`<id>_agx.jpg` next to `<id>_vantage.jpg`; the mean of the 13 vantage frames is
in `stats.json`):

| tone mapper | luma | saturation | colourfulness |
|---|---|---|---|
| ACES | 0.555 | 0.307 | 0.148 |
| AgX | 0.484 | 0.289 | 0.133 |

AgX is ~13 % darker and less saturated, and its highlights roll off more softly: New York's
glare, water and sky. The stats flag several vantages as brighter or more saturated than their
reference photos (Dubai, London and New York luma; Stockholm, Monaco, Big Sur and Rome
saturation). That suggests AgX at a slightly higher exposure would sit closer to the
references.

ACES is a PRD AC-12 requirement, asserted in `render_upgrade_test` and `settings_test`, so
switching needs a PRD amendment and the owner's decision. This audit recommends trying it
first in R-2.1's colour pass.
