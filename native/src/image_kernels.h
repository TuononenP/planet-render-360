#pragma once

#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/classes/ref.hpp>

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
};

} // namespace godot
