cmake_minimum_required(VERSION 3.17)

# Native build kernels (GDExtension). tools/build_native.sh configures
# and builds this for macOS, iOS and Android and writes the
# .gdextension next to the libraries in native/bin.
project(planet_render LANGUAGES CXX)

set(GODOTCPP_API_VERSION "4.7" CACHE STRING "")
# The kernels must round exactly like GDScript: no fused multiply-add,
# also in godot-cpp's own Vector2 maths (length, normalize, rotated).
add_compile_options(-ffp-contract=off)
add_subdirectory(godot-cpp)

add_library(planet_render SHARED
	src/register_types.cpp
	src/city_kernels.cpp
	src/city_kernels.h
	src/earcut_kernels.cpp
	src/earcut_kernels.h
	src/far_kernels.cpp
	src/far_kernels.h
	src/far_sampling.h
	src/ground_kernels.cpp
	src/ground_kernels.h
	src/image_kernels.cpp
	src/image_kernels.h
	src/roof_kernels.cpp
	src/roof_kernels.h
	src/mass_kernels.cpp
	src/mass_kernels.h
	src/merge_kernels.cpp
	src/merge_kernels.h
	src/mvt_kernels.cpp
	src/mvt_kernels.h
	src/party_index.cpp
	src/party_index.h
	src/quad_sink.cpp
	src/quad_sink.h
	src/ribbon_draper.cpp
	src/ribbon_draper.h
	src/shore_kernels.cpp
	src/shore_kernels.h
	src/shore_mesh.cpp
	src/shore_mesh.h
	src/shore_patch_kernel.cpp
	src/shore_patch_kernel.h
	src/shore_evidence_kernels.cpp
	src/shore_evidence_kernels.h
	src/parallel.h
)
target_link_libraries(planet_render PRIVATE godot-cpp)
get_target_property(GODOTCPP_SUFFIX godot-cpp GODOTCPP_SUFFIX)

set(OUTPUT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/bin")
set_target_properties(planet_render PROPERTIES
	CXX_STANDARD 17
	CXX_EXTENSIONS OFF
	CXX_VISIBILITY_PRESET ${GODOTCPP_SYMBOL_VISIBILITY}
	POSITION_INDEPENDENT_CODE ON
	LIBRARY_OUTPUT_DIRECTORY "$<1:${OUTPUT_DIR}>"
	RUNTIME_OUTPUT_DIRECTORY "$<1:${OUTPUT_DIR}>"
	PREFIX "lib"
	OUTPUT_NAME "planet_render${GODOTCPP_SUFFIX}"
)
