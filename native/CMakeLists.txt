cmake_minimum_required(VERSION 3.17)

# Native build kernels (GDExtension). tools/build_native.sh configures
# and builds this for macOS, iOS and Android and writes the
# .gdextension next to the libraries in native/bin.
project(planet_render LANGUAGES CXX)

set(GODOTCPP_API_VERSION "4.7" CACHE STRING "")
add_subdirectory(godot-cpp)

add_library(planet_render SHARED
	src/register_types.cpp
	src/far_kernels.cpp
	src/far_kernels.h
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
	# The kernels must round exactly like GDScript: no fused multiply-add.
	COMPILE_OPTIONS "-ffp-contract=off"
	LIBRARY_OUTPUT_DIRECTORY "$<1:${OUTPUT_DIR}>"
	RUNTIME_OUTPUT_DIRECTORY "$<1:${OUTPUT_DIR}>"
	PREFIX "lib"
	OUTPUT_NAME "planet_render${GODOTCPP_SUFFIX}"
)
