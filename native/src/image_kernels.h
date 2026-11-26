#pragma once

#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/variant/array.hpp>

namespace godot {

// Image work the composers repeat per texture, byte-identical with the
// engine call it replaces.
class ImageKernels : public Object {
	GDCLASS(ImageKernels, Object)

protected:
	static void _bind_methods();

public:
	// Image.fix_alpha_edges: each clear texel (alpha < 20) takes the
	// colour of the nearest solid one within 4 texels, ties going to the
	// first in row order. Texels with no solid one near are skipped
	// whole, and the rest stop at their first hit, nearest first.
	static void fix_alpha_edges(const Ref<Image> &image);
	// HsyCanopy.compose: L8 canopy heights from 4 RGBA band images + optional L8 CHM.
	static Ref<Image> hsy_canopy_compose(const Array &bands, const Ref<Image> &chm, int size);
	// HsyCover.overlay: R8 class overlay with optional replacement mask.
	static Ref<Image> r8_overlay(const Ref<Image> &base, const Ref<Image> &top, const Array &replace);
};

} // namespace godot
