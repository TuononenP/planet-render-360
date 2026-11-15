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

#if defined(__ANDROID__)
// Sum of the kB values on the lines starting with `a` (and `b`, when given)
// in a /proc file, or -1 when the file or the `a` line is missing.
static int64_t sum_kb(const char *path, const char *a, const char *b) {
	FILE *f = std::fopen(path, "r");
	if (f == nullptr) {
		return -1;
	}
	char line[256];
	int64_t total = -1;
	const size_t la = std::strlen(a);
	const size_t lb = b != nullptr ? std::strlen(b) : 0;
	while (std::fgets(line, sizeof(line), f) != nullptr) {
		long long v = 0;
		if (std::strncmp(line, a, la) == 0 && std::sscanf(line + la, "%lld", &v) == 1) {
			total = (total < 0 ? 0 : total) + v;
		} else if (b != nullptr && total >= 0 && std::strncmp(line, b, lb) == 0
				&& std::sscanf(line + lb, "%lld", &v) == 1) {
			total += v;
		}
	}
	std::fclose(f);
	return total;
}
#endif

int64_t MemoryStats::footprint_bytes() {
#if defined(__APPLE__)
	task_vm_info_data_t info;
	mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
	if (task_info(mach_task_self(), TASK_VM_INFO, (task_info_t)&info, &count) != KERN_SUCCESS) {
		return -1;
	}
	return (int64_t)info.phys_footprint;
#elif defined(__ANDROID__)
	// Pss (+ SwapPss) is what the low-memory killer weighs: shared pages
	// count once per sharer and zram-swapped pages still count. VmRSS
	// (older kernels without smaps_rollup) over-counts shared pages.
	int64_t pss = sum_kb("/proc/self/smaps_rollup", "Pss:", "SwapPss:");
	if (pss >= 0) {
		return pss * 1024;
	}
	int64_t rss = sum_kb("/proc/self/status", "VmRSS:", nullptr);
	return rss < 0 ? -1 : rss * 1024;
#else
	return -1;
#endif
}

int64_t MemoryStats::available_bytes() {
#if defined(__APPLE__) && TARGET_OS_IPHONE
	return (int64_t)os_proc_available_memory();
#elif defined(__ANDROID__)
	// The system's reclaimable memory: Android sets no per-app limit, the
	// low-memory killer acts as this runs out.
	int64_t kb = sum_kb("/proc/meminfo", "MemAvailable:", nullptr);
	return kb < 0 ? -1 : kb * 1024;
#else
	return -1;
#endif
}

void MemoryStats::_bind_methods() {
	ClassDB::bind_static_method("MemoryStats", D_METHOD("footprint_bytes"), &MemoryStats::footprint_bytes);
	ClassDB::bind_static_method("MemoryStats", D_METHOD("available_bytes"), &MemoryStats::available_bytes);
}

} // namespace godot
