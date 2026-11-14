#include "memory_stats.h"

#include <godot_cpp/core/class_db.hpp>

#if defined(__APPLE__)
#include <TargetConditionals.h>
#include <mach/mach.h>
#if TARGET_OS_IPHONE
#include <os/proc.h>
#endif
#elif defined(__ANDROID__)
#include <cstdio>
#include <cstring>
#endif

namespace godot {

int64_t MemoryStats::footprint_bytes() {
#if defined(__APPLE__)
	task_vm_info_data_t info;
	mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
	if (task_info(mach_task_self(), TASK_VM_INFO, (task_info_t)&info, &count) != KERN_SUCCESS) {
		return -1;
	}
	return (int64_t)info.phys_footprint;
#elif defined(__ANDROID__)
	FILE *f = std::fopen("/proc/self/status", "r");
	if (f == nullptr) {
		return -1;
	}
	char line[256];
	int64_t kb = -1;
	while (std::fgets(line, sizeof(line), f) != nullptr) {
		if (std::strncmp(line, "VmRSS:", 6) == 0) {
			long long v = 0;
			if (std::sscanf(line + 6, "%lld", &v) == 1) {
				kb = v;
			}
			break;
		}
	}
	std::fclose(f);
	return kb < 0 ? -1 : kb * 1024;
#else
	return -1;
#endif
}

int64_t MemoryStats::available_bytes() {
#if defined(__APPLE__) && TARGET_OS_IPHONE
	return (int64_t)os_proc_available_memory();
#else
	return -1;
#endif
}

void MemoryStats::_bind_methods() {
	ClassDB::bind_static_method("MemoryStats", D_METHOD("footprint_bytes"), &MemoryStats::footprint_bytes);
	ClassDB::bind_static_method("MemoryStats", D_METHOD("available_bytes"), &MemoryStats::available_bytes);
}

} // namespace godot
