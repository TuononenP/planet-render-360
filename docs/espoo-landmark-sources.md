# Espoo hero landmark geometry

Reviewed 2026-11-03. Geometry uses true metres and the existing photographic
material library. The buildings represent the completed historic architecture;
current construction scaffolding is not modelled.

| Type | Position / footprint | Distinctive geometry and dimensional confidence |
| --- | --- | --- |
| `otaniemi_chapel` | OSM way [4266572](https://www.openstreetmap.org/way/4266572), centre 60.18939, 24.83731. Long walls run approximately 16.4 degrees east of north. | Brick side walls, timber roof structure, south glass altar, external cross, enclosed approach court, open timber bell frame. Hall footprint approx. 16 by 23 m from OSM; roof and belfry heights are photo estimates (6.2 and 8 m). |
| `aalto_university_main` | OSM building part 1094327789 at 60.18635, 24.82982, auditorium pin 60.18629, 24.82999. | Dark brick campus wings and open courts, copper fan auditorium and curved outdoor stepped theatre. Auditorium fan approximately 27 m across from OSM; campus wings are simplified. Roof height 21.1 m is an estimate, not a surveyed dimension. |
| `tapiola_church` | OSM way [10051865](https://www.openstreetmap.org/way/10051865); sanctuary at 60.17774, 24.80959, 15.8 degree panel axes. | Sanctuary cube, low courtyard parish wings, exposed concrete panel joints, high strip windows and separate low entrance/bell portal. Sanctuary footprint approx. 25 m square from OSM. Height 16.7 m is a photo estimate. |
| `tapiola_central_tower` | OSM way [8057475](https://www.openstreetmap.org/way/8057475), 60.17700, 24.80464, model long axis yaw −74.6 degrees. | 13 storeys, enamel panel grid and continuous window bands, recessed rooftop restaurant. City source gives 49 m; footprint approximately 28 by 18 m follows OSM, minor lobby projections simplified. |
| `weegee` | OSM way [129693803](https://www.openstreetmap.org/way/129693803), 60.17861, 24.79417; long axis yaw −131.6 degrees. | Original printing house's eight modules, eight circular ventilation pylons and radial roof stays, glass upper storey. City source specifies 27 by 27 m structural modules, 3 m diameter pylons and a 4 m projection above the roof. Roof level 10 m is an estimate. The later school extension is outside the model. |

Primary architectural sources:

- [Aalto University, Architecture on campus](https://www.aalto.fi/en/campus/architecture-on-aalto-universitys-campus): Undergraduate Centre completed 1964; protected Alvar Aalto building.
- [Alvar Aalto Foundation, Espoo campus](https://visit.alvaraalto.fi/en/destinations/espoo/): separate courtyard wings and stepped auditorium; red brick, black granite, copper.
- [Aalto University, Otaniemi architecture](https://www.aalto.fi/fi/uutiset/otaniemen-arkkitehtuurin-merkkiteoksia): chapel's timber roof and glazed south altar with outdoor cross.
- [Espoo parishes, Tapiola architecture](https://www.espoonseurakunnat.fi/kirkot-ja-tilat/kirkot/tapiolan-kirkko/arkkitehtuuri): Ruusuvuori's concrete church, completed 1965, expanded 1992.
- [City of Espoo, WeeGee history and architecture](https://www.espoo.fi/en/history-and-architecture-weegee-house): 1964/1967 printing house, modular roof structure and ventilation pylons.
- [City of Espoo, Keskustorni illumination](https://www.sttinfo.fi/tiedote/69844995/espoon-tapiolan-keskustornin-julkisivuun-heijastetaan-suuri-mediataideteos?publisherId=3385): Ervi's 1961 tower, 49 m and 13 floors.
- [Aalto University entrance plan](https://www.aalto.fi/sites/default/files/2022-05/Otakaari_1_Otsv%C3%A4ngen_1.pdf): connected wing/courtyard layout.

OSM geometry was retrieved from `api.openstreetmap.org/api/0.6/map` and
`/way/8057475/full` on the review date (Overpass was unavailable). OSM contributors,
[ODbL](https://www.openstreetmap.org/copyright). Registry heights explicitly marked
as estimates above need visual calibration against the final terrain captures.

Validation: `tests/espoo_hero_landmarks_test.gd` checks registry heights, clearance,
finite vertices, 1k–150k triangles, merged material parts and textured materials.
