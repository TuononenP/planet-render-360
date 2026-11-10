class_name LandmarkRegistries
extends RefCounted

## Every regional landmark batch, in one place: the registry lists
## LocationData.landmarks() appends to its core entries, and the build
## sets LandmarkBuilder tries for a type its own match does not know.
## A new batch is a LandmarkRegistry* and a LandmarkSet* class, listed here.

static func entries() -> Array:
	var all: Array = []
	for batch in [LandmarkRegistryWestEurope.entries(), LandmarkRegistrySouthEurope.entries(),
			LandmarkRegistryCentralEurope.entries(), LandmarkRegistryMideastAfrica.entries(),
			LandmarkRegistryAsiaSouth.entries(), LandmarkRegistryAsiaEast.entries(),
			LandmarkRegistryNorthAmerica.entries(), LandmarkRegistryNyc.entries(), LandmarkRegistrySouthAmericaOceania.entries(),
			LandmarkRegistryBridges.entries(),
			LandmarkRegistryCambodia.entries(), LandmarkRegistryRomeAncient.entries(),
			LandmarkRegistryRomeLater.entries(), LandmarkRegistryAthens.entries(),
			LandmarkRegistryEgypt.entries(), LandmarkRegistryGreeceTurkey.entries(),
			LandmarkRegistryItalyHistoric.entries(), LandmarkRegistryWesternHistoric.entries(),
			LandmarkRegistryCentralHistoric.entries(), LandmarkRegistryRussiaBalkans.entries(),
			LandmarkRegistryIberia.entries(), LandmarkRegistryLevantPersia.entries(),
			LandmarkRegistryEastAsiaHistoric.entries(), LandmarkRegistryIndiaHistoric.entries(),
			LandmarkRegistryMainlandSeAsia.entries(), LandmarkRegistryAfricaHistoric.entries(),
			LandmarkRegistryAmericasHistoric.entries(),
			LandmarkRegistryFinlandHelsinki.entries(), LandmarkRegistryFinlandRegions.entries(),
			LandmarkRegistrySwedenStockholm.entries(),
			LandmarkRegistrySanFrancisco.entries(),
			LandmarkRegistryAngkorThom.entries(), LandmarkRegistryAngkorBaray.entries(),
			LandmarkRegistryAngkorEast.entries(), LandmarkRegistryAngkorOuter.entries(),
				LandmarkRegistryBridgeSpecs.entries()]:
		all.append_array(batch)
	return all

static func sets() -> Array[Callable]:
	return [LandmarkSetWestEurope.build, LandmarkSetSouthEurope.build,
		LandmarkSetCentralEurope.build, LandmarkSetMideastAfrica.build,
		LandmarkSetAsiaSouth.build, LandmarkSetAsiaEast.build,
		LandmarkSetNorthAmerica.build, LandmarkSetNyc.build, LandmarkSetSouthAmericaOceania.build,
		LandmarkSetBridges.build,
		LandmarkSetCambodia.build, LandmarkSetRomeAncient.build,
		LandmarkSetRomeLater.build, LandmarkSetAthens.build,
		LandmarkSetEgypt.build, LandmarkSetGreeceTurkey.build,
		LandmarkSetItalyHistoric.build, LandmarkSetWesternHistoric.build,
		LandmarkSetCentralHistoric.build, LandmarkSetRussiaBalkans.build,
		LandmarkSetIberia.build, LandmarkSetLevantPersia.build,
		LandmarkSetEastAsiaHistoric.build, LandmarkSetIndiaHistoric.build,
		LandmarkSetMainlandSeAsia.build, LandmarkSetAfricaHistoric.build,
		LandmarkSetAmericasHistoric.build,
		LandmarkSetFinlandHelsinki.build, LandmarkSetFinlandRegions.build,
		LandmarkSetSwedenStockholm.build,
		LandmarkSetSanFrancisco.build,
		LandmarkSetAngkorThom.build, LandmarkSetAngkorBaray.build,
		LandmarkSetAngkorEast.build, LandmarkSetAngkorOuter.build,
		LandmarkSetBridgeSpecs.build]
