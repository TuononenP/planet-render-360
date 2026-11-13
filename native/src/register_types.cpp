#include "city_kernels.h"
#include "earcut_kernels.h"
#include "far_kernels.h"
#include "ground_kernels.h"
#include "image_kernels.h"
#include "landmark_kernels.h"
#include "mass_kernels.h"
#include "merge_kernels.h"
#include "mvt_kernels.h"
#include "party_index.h"
#include "quad_sink.h"
#include "ribbon_draper.h"
#include "roof_kernels.h"
#include "shore_kernels.h"
#include "shore_mesh.h"
#include "shore_patch_kernel.h"
#include "tint_kernels.h"
#include "shore_evidence_kernels.h"

#include <gdextension_interface.h>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

using namespace godot;

static void initialize(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	GDREGISTER_CLASS(CityKernels);
	GDREGISTER_CLASS(EarcutKernels);
	GDREGISTER_CLASS(FarKernels);
	GDREGISTER_CLASS(GroundKernels);
	GDREGISTER_CLASS(ImageKernels);
	GDREGISTER_CLASS(LandmarkKernels);
	GDREGISTER_CLASS(MassKernels);
	GDREGISTER_CLASS(MergeKernels);
	GDREGISTER_CLASS(MvtKernels);
	GDREGISTER_CLASS(PartyIndex);
	GDREGISTER_CLASS(QuadSink);
	GDREGISTER_CLASS(RibbonDraper);
	GDREGISTER_CLASS(RoofKernels);
	GDREGISTER_CLASS(ShoreKernels);
	GDREGISTER_CLASS(ShoreMesh);
	GDREGISTER_CLASS(ShoreSampler);
	GDREGISTER_CLASS(ShoreDomainIndex);
	GDREGISTER_CLASS(ShoreEvidenceIndex);
	GDREGISTER_CLASS(ShorePatchKernel);
	GDREGISTER_CLASS(TintKernels);
}

static void uninitialize(ModuleInitializationLevel p_level) {
}

extern "C" {
GDExtensionBool GDE_EXPORT planet_render_init(GDExtensionInterfaceGetProcAddress p_get_proc_address,
		const GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization) {
	GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
	init_obj.register_initializer(initialize);
	init_obj.register_terminator(uninitialize);
	init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
	return init_obj.init();
}
}
