# Singapore super-realistic: landmarks and city

> Live tracker synced with the approved implementation plan (`2026-11-25`).
> Status legend: `[x]` done and validated, `[~]` in progress, `[ ]` open.

## Tracker

- [x] SG-0.1 Clock fix (UTC+8) verified & pinned in `tests/solar_test.gd` (`SOLAR OK`)
- [x] SG-0.2 Baseline captures `singapore-r0` & `sg_lm_r0` (`visual-plan/reviews/singapore-r0-2026-11-25/`, `visual-plan/captures/sg_lm_r0/`, old MBS `10,816` tris)
- [x] SG-0.3 Height audit of `capital_sg_*_detailed.osmb` (49 named anomalies) and `far.osmb` (363 named anomalies) documented in `docs/singapore-landmark-sources.md`
- [x] SG-0.6 Sources doc `docs/singapore-landmark-sources.md` created with verified OSM IDs, footprints, bearings & heights
- [x] SG-0.7 Slot budget (`marina_bay_sands` `ultra_registry_limit: 42 / ultra_total_limit: 50`) pinned in `tests/singapore_landmarks_test.gd` (`PASSED`)
- [x] SG-1 Modular batch wiring (`LandmarkRegistrySingapore`, `SgRegBay`, `SgRegCivic`, `SgRegHeritage`, `SgTowerSpecs`, `SingaporeNotable`, `LandmarkSetSingapore`, `LandmarkSgKit`) wired in `LandmarkRegistries` & `OsmParser` — `78/78` verified
- [x] SG-2 Marina Bay Hero Icons (11 bespoke builders: `marina_bay_sands` full rebuild with curved towers + SkyPark + Shoppes + Crystal Pavilion + Apple sphere, `esplanade_singapore` durian sunshades, `merlion_park`, `singapore_flyer`, `artscience_museum`, `helix_bridge`, `fullerton_hotel` & `fullerton_waterfront`, `supertree_grove` + OCBC Skyway, `gardens_by_the_bay_domes`, `marina_barrage`)
- [x] SG-3A Civic District & Padang Core (10 bespoke builders: `national_gallery_sg`, `supreme_court_sg`, `victoria_theatre_sg`, `st_andrews_cathedral_sg`, `arts_house_parliament_sg`, `padang_ensemble_sg`, `civilian_war_memorial_sg`, `raffles_hotel_sg`, `old_hill_street_police_sg`, `asian_civilisations_museum_sg`)
- [x] SG-3B Heritage Districts, River, Cultural Ring & Sports Hub (11 bespoke builders: `sri_mariamman_temple_sg`, `buddha_tooth_relic_sg`, `thian_hock_keng_sg`, `sultan_mosque_sg`, `lau_pa_sat_sg`, `clarke_quay_sg`, `chijmes_sg`, `armenian_church_sg`, `central_fire_station_sg`, `national_museum_sg`, `national_stadium_sg`)
- [x] SG-3C Skyline Towers (`SgTowerSpecs`, 34 named towers fixing all `height=0` & under-height CBD/Marina Bay skyscrapers) + `SingaporeNotable` (20 OSM-keyed height/facade overrides)
- [x] SG-4 Bridges — bespoke `cavenagh_bridge_sg`, `anderson_bridge_sg`, `elgin_bridge_sg`, `helix_bridge`; parametric `conf: 2` Esplanade, Jubilee, Coleman, Read, Ord, Alkaff, Benjamin Sheares, Merdeka bridges (`bridge_specs_test` & `bridge_select_test` `PASSED`)
- [x] SG-5 City fabric — `ArchitectureCitiesSingapore` (`singapore_rule` + 10 new rows), 23 district circles + `FAR_DISTRICT_CITIES` in `city_styles.gd`, `"singapore"` in `CityDetail.CITIES` (`architecture_test`, `city_detail_test`, `singapore_fabric_test` `PASSED`)
- [x] SG-6 Garden City flora (`yellow_flame`, `tembusu`, `sea_almond`, `singapore` tree mix & `HeritageZones` `singapore_island`) & 3-zone Singapore water (`WaterSurface.singapore_water`, `coastal_water_test` `PASSED`)
- [x] SG-7 Streets & transport — Singapore `CarFleet` + 4 taxi liveries, `TransitVehicles` LTA/SBS/SMRT double-decker buses (`bus_mesh` parameterized by `bus_kind`), `StreetFurniture` `"sg"` family + MRT entrances, `TrainSpecs` `"singapore_mrt"` (`car_fleet_test`, `bus_stop_test`, `street_furniture_test` `PASSED`)
- [x] SG-8 Night lighting — `FLOOD_META`, `HALO_META`, and `*Lamp` rigs across all Singapore landmarks & supertalls (`landmark_lights_test` `PASSED`)
- [x] SG-9 Curated Marina Bay `PresetViews` row added (`singapore`), `assets/preset_thumbs/singapore.jpg` baked, `singapore-r1` & `singapore-r2` + `sg_lm_r1` / `sg_lm_r2` visually verified (`loft_shell` winding & `durian_shades` outward normals fixed)
- [x] Code review — `tools/check_class_size.sh` OK (`999/1000`), `host_policy_test` OK, 13 headless test suites `PASSED`
