# Tokyo and Seoul landmark batch — 2026-11-11

The batch `LandmarkRegistryTokyoSeoul` / `LandmarkSetTokyoSeoul` fills the surroundings of the Tokyo preset (Shibuya Crossing) and the Seoul preset (Gwanghwamun Square). Models use true metres and merged textured surfaces. They approximate exterior envelopes and the details that read at distance; no model has been photographically rated. Values marked *estimate* must not be presented as surveyed dimensions.

Positions, footprints, heights and bearings come from the bundled OSM snapshots, read offline: `assets/osm_snapshots/tokyo_detailed.json.gz`, `seoul_detailed.json.gz` and `seoul_poi.json.gz` (Overpass JSON). A registry site is the area centroid of the OSM footprint the model replaces. `yaw_deg` is the true bearing of the model's +X minus 90, read from the footprint's long edges.

## Shibuya (Tokyo preset: origin 35.6595,139.7005; eye 35.6590,139.7011 at 15 m, bearing 320)

| Type | Site | Height | Model | Evidence |
| --- | --- | --- | --- | --- |
| `shibuya_scramble_square` | 35.658367,139.702221, yaw −21 | 229.7 m | Podium on the 60 × 69 m footprint to 48 m, setbacks at 150 m and 200 m, Sky Gallery glazing, the Shibuya Sky roof deck with its 1.8 m glass edge, rooftop frame | OSM way 617560918 (`height=229.706`, 47 levels, glass). Setback heights and the frame are *estimates* from photographs. |
| `shibuya_hikarie` | 35.659115,139.703760, yaw −20 | 182.5 m | Deck arm, nine-storey east block, five outward-stepping podium layers to 72 m, sky-lobby band, striped office tower, crown screen | OSM way 204091879 (`height=182.5`, 34 levels) with building:parts 521569267 (tower plot, 33 levels) and 521569265 (east block, 9 levels). Layer heights and flare are *estimates*. |
| `shibuya_stream` | 35.657190,139.703151, yaw 44 | 180.0 m | Podium on the footprint to 22 m, white-gridded slab tower over its west end, crown screen | OSM way 521438304 (`height=179.95`, 35 levels). Tower plan and podium height are *estimates*. |
| `shibuya_109` | 35.659589,139.698717, no yaw | 33.6 m | Silver banded wedge on the simplified OSM outline to 30 m, the round corner tower at the east tip (towards the crossing) to 33.6 m, generic lit sign column (no logo or text) | OSM way 55895868 (`height=33.6`, 8 levels, metal). The rounded east tip of the outline fixes the tower's centre and radius (about 6.4 m). Main-block height 30 m is an *estimate*. |
| `qfront` | 35.659880,139.700363, no yaw | 45.9 m | Grey glass on the OSM outline with floor bands, a full-height generic LED screen (9–39 m) across the curved south-east face towards the crossing | OSM way 136691386 (`height=45.9`, 8 levels, glass, `building:colour=#9ba1b1`). Screen extent is an *estimate*. |

Clearance (`clear_m`) is checked against every OSM building and building:part centroid nearby: each radius removes the landmark's own footprint and parts only. Shibuya 109 keeps the Tamakyu Building (way 671085515) in its notch (18.6 m off, `clear_m` 15); Hikarie's 38 m covers its east-block part (35.8 m) and keeps the Miyamasuzaka Building (50 m).

From the preset eye, QFRONT lies ahead (bearing about 325°) and Shibuya 109 to the left (about 288°); Scramble Square (about 124°), Hikarie (about 87°) and Stream stand behind and to the right, seen when turning the view.

Not modelled: the screens of the buildings beside QFRONT, and Shibuya Mark City.

## Gwanghwamun Square and Gyeongbokgung (Seoul preset: origin 37.5728,126.9769; eye 37.5738,126.9769 at 6 m, bearing 0)

| Type | Site | Height | Model | Evidence |
| --- | --- | --- | --- | --- |
| `king_sejong_statue` | 37.5729184,126.9769125, faces south | 10.4 m | Granite pedestal 4.2 m with bronze panels; seated gilded figure 6.2 m tall, 4.3 m wide, book in the left hand, right hand raised, winged crown; armillary sphere, sundial and rain gauge in front | OSM node 3841809527 (seoul_poi, `direction=180`). Statue 6.2 m × 4.3 m: https://en.wikipedia.org/wiki/Statue_of_King_Sejong_(Gwanghwamun). Pedestal height 4.2 m is an *estimate* (not given there). |
| `yi_sun_sin_statue` | 37.5709682,126.9769505, faces south | 17.0 m | Stepped granite base and 10.5 m pillar pedestal; standing armoured figure 6.5 m with a sword point-down; turtle ship on its stone in front | OSM node 2653074012 (`direction=180`). Statue 6.5 m on a 10.5 m pedestal, 17 m in all: https://en.wikipedia.org/wiki/Statue_of_Admiral_Yi_Sun-sin. |
| `gyeongbokgung_walls` | 37.575937,126.9769 (7 m south of the core Gwanghwamun site), no yaw | 4.0 m | Front walls west and east of Gwanghwamun: footing, coursed granite, plastered band, tiled coping with ridge roll, piers at bends | OSM ways 279963627 (city_wall, west), 236942292 and 370282518 (`height=4`, east, round the cut corner towards Dongsipjagak). Course heights are *estimates*. |
| `heungnyemun` | 37.576954,126.976905, yaw 2 | 15.0 m | Two-storey 3 × 2-bay gate on a granite platform with stairs | OSM building:part 1203368739 (`min_height=2`, `height=11.5`) and its roof parts (lower roof to 8.5 m, upper roof 11.5–14 m: ways 1203368735–38, 772263049/50, 822154092/94). The ridge sits at 13.8 m; the chimi take it to 15 m (*estimate*). |
| `geunjeongjeon` | 37.578334,126.976958 (centre of the cloister), yaw 2 | 27.8 m | Throne hall (5 × 5 bays, two storeys, paljak roof) on the two-tier woldae with balustrades, stairs and cauldrons; royal path between the rank stones; the double cloister with Geunjeongmun, Sajeongmun, Wolhwamun and Ilhwamun | Hall: OSM way 170199428 (38 × 29 m, at model (2.0, −23.3)) and building:parts 1569283607–60 (plinth 0.5–1 m, columns to 5.63 m and 11.99 m, skirt roof 7.34–10.5 m, upper eaves 14.24 m, ridge 25.38 m). Woldae: retaining walls 381956884/85 (55 m and 46 m wide); tier heights 1.3 m + 1.1 m are *estimates*, so the 27.8 m total is 25.4 m (OSM) + 2.4 m. Cloister: way 279961015 (outer ring about 117 × 135 m). Gates: 279958876 (Geunjeongmun), 381956863 (Sajeongmun); Geunjeongmun's 13.5 m is an *estimate*. |

The palace grid runs 2° clockwise of north (footprint edges bear 92° and 2°), hence `yaw_deg` 2 for the palace models. Geunjeongjeon clears with `clear_m` 14 round its centre and the `clear_offsets_m` subsites over the hall, Geunjeongmun and Sajeongmun; Sajeongjeon (21 m from the nearest subsite), Cheonchujeon, Manchunjeon and Gyejodang stay. Heungnyemun's 14 m clears the gate and its roof parts only.

From the preset eye, Gwanghwamun is ahead (about 240 m) with the walls either side, Heungnyemun and Geunjeongjeon behind it on the axis; both statues stand behind the eye (Sejong about 100 m south, Yi Sun-sin about 320 m south), seen when turning the view.

The palace walls end where OSM ends them, inside the core Gwanghwamun model's platform. That model stands on the OSM gatehouse centre (way 170199440, 37.575928,126.976817); until 2026-11-12 it stood about 7 m east and 7 m north of it.

The Joseon roof, dancheong bracket, rafter, lattice and column pieces live in `LandmarkKoreanRoof`, shared by Gwanghwamun, Heungnyemun, Geunjeongmun, the side gates and Geunjeongjeon.
