class_name StaticCaches
extends RefCounted

## Releases process-wide static Resource / Object caches on SceneTree shutdown
## (after every scene Node has exited, before RenderingDevice::finalize and
## ObjectDB::cleanup run), eliminating exit RID and ObjectDB leak errors.

static var _exit_hooked := false

static func hook_exit(tree: SceneTree) -> void:
	if _exit_hooked or tree == null or tree.root == null:
		return
	_exit_hooked = true
	tree.root.tree_exited.connect(release_all, CONNECT_ONE_SHOT)

static func release_all() -> void:
	if DisplayServer.get_name() != "headless":
		RenderingServer.global_shader_parameter_set("street_lamp_settle", null)
		RenderingServer.global_shader_parameter_set("street_heights", null)
	SharedTexture.clear()
	SharedShader.clear()
	LandmarkImpostor.clear_view_cache()
	FacadeComposer.clear_cache()
	StoreyComposer.clear_cache()
	FacadeTextures._store.clear()
	FacadeTextures._store_order.clear()
	FacadeTextures._store_used.clear()
	FacadeMaterials._facade_mats.clear()
	FacadeMaterials._facade_texs.clear()
	FacadeMaterials._facade_cache.clear()
	FacadeMaterials._blank_cache.clear()
	FacadeMaterials._family_first.clear()
	FacadeMaterials._ground_cache.clear()
	FacadeMaterials._distant_mats.clear()
	FacadeMaterials._distant_roof_mats.clear()
	FacadeMaterials._glass_mats.clear()
	FacadeMaterials._roof_mats.clear()
	MaterialLibrary._set_images.clear()
	MaterialLibrary._set_texs.clear()
	MaterialLibrary._pbr_mats.clear()
	MaterialLibrary._leaf_mats_by_season.clear()
	MaterialLibrary._slate_mat = null
	MaterialLibrary._detail_tex = null
	MaterialLibrary._leaf_tex = null
	MaterialLibrary._leaf_card_tex = null
	MaterialLibrary._roof_mats.clear()
	MaterialLibrary._ground_mats.clear()
	MaterialLibrary._shore_mat = null
	PbrTextures._raw_images.clear()
	PbrTextures._stage.clear()
	PbrTextures._rank_of.clear()
	TerrainTextures._arrays.clear()
	FoliageTextures._textures.clear()
	RoadSurface._texs.clear()
	RoadSurface._mat = null
	RoadSurface._paved_shader = null
	FacadeShader._photos.clear()
	FacadeShader._shader = null
	LandmarkMaterials._cache.clear()
	LandmarkMaterials._texs.clear()
	LandmarkMaterials._glass_shaders.clear()
	LandmarkMaterials._window_glass_shaders.clear()
	AircraftModel._glb_cache.clear()
	AircraftModel._mesh_cache.clear()
	AircraftModel._mat_cache.clear()
	AircraftModel._shadow_cache.clear()
	AircraftModel._disc_mesh = null
	AircraftModel._cabin_texs.clear()
	VesselMaterials._cache.clear()
	VesselMaterials._panel_tex = null
	VesselPrototypes._meshes.clear()
	ShipLights._cache.clear()
	ShipPaint._cache.clear()
	ParkedCars._meshes.clear()
	StreetFurniture._meshes.clear()
	StreetFurniture._shadow_quad = null
	BeachDressing._meshes.clear()
	BeachDressing._shadow_quad = null
	UtilityPoles._meshes.clear()
	UtilityPoles._mats.clear()
	GroundCover._mats.clear()
	RoofClutter._mats.clear()
	ReliefKit._mats.clear()
	BuildingTrim._mats.clear()
	PartyWalls._fire_mats.clear()
	FountainWater._basin_mats.clear()
	FountainKit._mist_quad = null
	PlinthStyle._body = null
	PlinthStyle._coping = null
	PlinthStyle._body_calm = null
	PlinthStyle._coping_calm = null
	ShoreBankMesh._abutment_mat = null
	ShoreBankMesh._deck_mat = null
	StreetSnow._shader = null
	WaterSurface._mats.clear()
	RoadPaint._mat = null
	RoadPaint._shader = null
	RoadPaint._dashes.clear()
	QuayBuilder._stone_mats.clear()
	StockholmQuay._materials.clear()
	RailBuilder._mats.clear()
	VegetationBuilder._card_mesh = null
	TerrainBuilder._unit_box = null
	TreeSpecies._grey.clear()
	StreetGlow._settle_tex = null
	RoofSnow._overlay = null
	RoofSnow._wet_overlay = null
	Precipitation._shader = null
	Precipitation._contrast_shader = null
	Precipitation._veil_shader = null
	Precipitation._drift_shader = null
	StreetLights._halo_mesh = null
	Icicles._mesh = null
	Icicles._mat = null
	AmbientLife._bird_mat = null
	AmbientLife._smoke_mat = null
	AmbientLife._bird_geo = null
	AmbientLife._smoke_quad = null
	PlaceThumb._textures.clear()
	UiIcon._cache.clear()
	Brand._cache.clear()
	UiTheme._font_cache.clear()
	SettlementMap._last = null
	SettlementMap._last_key.clear()
	RailDecks._last = null
	RailDecks._last_ground = null
	RailDecks._last_rails = []
	BridgeLandings._idx_surf = null
	BridgeLandings._idx_ends.clear()
	BridgeLandings._idx_segs.clear()
	HarbourTraffic._plan_for.clear()
	HarbourTraffic._plan_cached.clear()
	QuayMoorings._scope.clear()
	MalarShips._plan.clear()
	MeshArrays._held.clear()
	BuildingBasement._mats.clear()
	BuildingDetail._mats.clear()
	CarPaint._paint = null
	CarPaint._shadow = null
	FacadeLiteShader._shader = null
	FountainWater._flow_mat = null
	FountainWater._foam_mat = null
	FountainWater._mist_mat = null
	FountainWater._flow_fallback = null
	FountainWater._foam_fallback = null
	LandmarkShader._shader = null
	LandmarkShader._swapped.clear()
	RoadBuilder._mats.clear()
	RoadBuilder._stone_deck = null
	RoadDecals._cover = null
	RoadDecals._grate = null
	RoadDecals._litter = null
	RooflineDetail._mats.clear()
	StreetProps._lamp_meshes.clear()
	StreetProps._fence_tex = null
	StreetProps._chainlink_tex = null
	StreetProps._mats.clear()
	TreeImpostor._tex.clear()
	TreeMeshLibrary._bufs.clear()
	TreeMeshLibrary._meshes.clear()
	TreeMeshLibrary._mats.clear()
	TreeMeshLibrary._shader_leaf = null
	TreeMeshLibrary._shader_imp = null
	VegetationBuilder._canopy_mesh = null
	VegetationBuilder._card_mats_by_season.clear()
	CarModel._meshes.clear()
	CarModel._materials.clear()
	TramModel._meshes.clear()
	TramModel._materials.clear()
	TramBoards._materials.clear()
	TransitVehicles._bus_meshes.clear()
	TransitVehicles._shadows.clear()
	TukTukModel._meshes.clear()
	WaterWakes._wake_mat = null
	WaterWakes._collar_mat = null
	GodrayShader._rays_shader = null
	GodrayShader._overlay_shader = null
	Precipitation._drift_shader = null
	SharedShader._by_code.clear()
	PrivacyHero._disc = null
	VideoScaler._shader = null
	AccentSun.refresh = Callable()
	AccentSun._tween = null
	PostpassGate._busy = null
	PostpassGate._queue.clear()
	FarSurface._shader = null
	ShoreRailings._white_mat = null
	RealityMeshKit._cache.clear()
	LandmarkSfAlcatrazSurface._material = null
	BuildingMasses.end_build()
	OsmParseCache.clear()
	ClimateFetcher.clear_static_caches()
	FarCityFetcher.clear_static_caches()
	LandcoverFetcher._inflight.clear()
	HelsinkiLod2._decoded.clear()
	HelsinkiLod2._decoded_order.clear()
	TurkuLod2Meshes._decoded.clear()
	TurkuLod2Meshes._decoded_order.clear()
	CityOpenData._decoded.clear()
	CogFetcher._tiles.clear()
	CogFetcher._tile_order.clear()
	CogFetcher._metadata.clear()
	CogFetcher._meta_loading.clear()
	MapPack._shared.clear()
	FarSurface._shader = null
	FacadeLiteShader._shader = null
	LandmarkShader._shader = null
	LandmarkShader._swapped.clear()
	TreeMeshLibrary._bufs.clear()
	TreeMeshLibrary._meshes.clear()
	TreeMeshLibrary._mats.clear()
	TreeMeshLibrary._shader_leaf = null
	TreeMeshLibrary._shader_imp = null
	FountainWater._flow_mat = null
	FountainWater._foam_mat = null
	FountainWater._mist_mat = null
	FountainWater._flow_fallback = null
	FountainWater._foam_fallback = null
	BuildingBasement._mats.clear()
	ShoreRailings._white_mat = null
	SkyKit._mats.clear()
	WaterWakes._wake_mat = null
	WaterWakes._collar_mat = null
	RoadDecals._cover = null
	RoadDecals._grate = null
	RoadDecals._litter = null
	MeshArrays._held.clear()
	RealityMeshKit._cache.clear()
	StreetProps._fence_tex = null
	StreetProps._chainlink_tex = null
	StreetProps._mats.clear()
	CarPaint._paint = null
	CarPaint._shadow = null
	BuildingDetail._mats.clear()
	TramModel._meshes.clear()
	TukTukModel._meshes.clear()
	CarModel._meshes.clear()
	RoadBuilder._mats.clear()
	LandmarkSfAlcatrazSurface._material = null
	FtSuomenJoutsen._nameplate_mat = null

## Sheds rebuildable CPU/GPU caches when MemoryGuard enters TIGHT or CRITICAL.
static func trim_for_pressure(level: int) -> void:
	if level < MemoryGuard.Level.TIGHT:
		return
	PbrTextures._raw_images.clear()
	FacadeComposer.clear_cache()
	StoreyComposer.clear_cache()
	OsmParseCache.clear()
	LandmarkImpostor.clear_view_cache()
	if level >= MemoryGuard.Level.CRITICAL:
		MaterialLibrary._set_images.clear()
		HelsinkiLod2._decoded.clear()
		HelsinkiLod2._decoded_order.clear()
		TurkuLod2Meshes._decoded.clear()
		TurkuLod2Meshes._decoded_order.clear()
		CityOpenData._decoded.clear()
		CogFetcher._tiles.clear()
		CogFetcher._tile_order.clear()
		LandmarkShader._swapped.clear()
