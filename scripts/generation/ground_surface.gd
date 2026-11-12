class_name GroundSurface
extends RefCounted

## What the ground shows at a point, as the terrain shader paints it: the
## extent class map (GroundMaterial.class_map, ids in GroundMaterial.ID)
## kept on the CPU. Placers ask it so nothing stands on ground painted as
## road, paving, a pitch or sand, whatever their own masks say. Built once
## per GroundTruth (GroundTruth.surface) and shared with the terrain
## material, so the two can never disagree. Unmapped ground is 0: there
## the shader lets the photo decide, and so do the placers' photo rules.

## Hard ground nothing grows on (GrassCarpet's hard() ids): building,
## road, paving, water, path.
const HARD: Array[int] = [1, 2, 3, 15, 16]
## Ground no synthetic tree or grass is planted on: hard ground plus
## pitch, sand, rock, quarry and glacier.
const NO_PLANTING: Array[int] = [1, 2, 3, 9, 11, 12, 13, 14, 15, 16]
## Ground even a measured tree (canopy raster) cannot stand on: a street
## tree grows out of paving, but not out of a carriageway, a pitch, a
## track bed, water, a quarry or a glacier.
const NO_TREES: Array[int] = [1, 2, 9, 13, 14, 15, 16]

var image: Image
var _bytes: PackedByteArray
var _n := 1
var _extent := 1.0

func _init(map: Image) -> void:
	image = map
	var img := map
	if img.get_format() != Image.FORMAT_R8:
		img = map.duplicate() as Image
		img.convert(Image.FORMAT_R8)
	_bytes = img.get_data()
	_n = img.get_width()
	_extent = WorldScale.detailed_extent_units()

## Class id painted at world XZ (units); 0 outside the extent.
func class_at(x: float, z: float) -> int:
	var i := int(floor((x / _extent + 0.5) * float(_n)))
	var j := int(floor((z / _extent + 0.5) * float(_n)))
	if i < 0 or j < 0 or i >= _n or j >= _n:
		return 0
	return _bytes[j * _n + i]

## Whether XZ, or any of four probes `margin_u` units away, is painted
## with one of `ids`.
func hard_at(x: float, z: float, margin_u: float = 0.0, ids: Array[int] = HARD) -> bool:
	if class_at(x, z) in ids:
		return true
	if margin_u <= 0.0:
		return false
	return class_at(x + margin_u, z) in ids or class_at(x - margin_u, z) in ids \
		or class_at(x, z + margin_u) in ids or class_at(x, z - margin_u) in ids
