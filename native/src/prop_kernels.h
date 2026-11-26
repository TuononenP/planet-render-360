#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/variant/dictionary.hpp>

namespace godot {

// Native C++17 parallel kernels for StreetProps._barriers() and ParkedCars.plan().
class PropKernels : public Object {
	GDCLASS(PropKernels, Object)

protected:
	static void _bind_methods();

public:
	static Dictionary parked_cars_plan(const Dictionary &params);
	static Dictionary barriers_build(const Dictionary &params);
	static Dictionary stairs_build(const Dictionary &params);
};

} // namespace godot
