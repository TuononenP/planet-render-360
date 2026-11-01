class_name BuildAbort
extends RefCounted

## Stop request for ONE world build. Set from the main thread (generation
## timeout or cancel); TerrainBuilder.build_world checks it at each stage
## boundary on the build thread. Per build, not global: a season rebuild
## running beside the generation build must neither clear nor trip it.

var requested := false
