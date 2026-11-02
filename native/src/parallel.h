#pragma once

#include <algorithm>
#include <atomic>
#include <thread>
#include <vector>

namespace godot {

// fn(i) for i in [0, n) on every core; each index writes only its own
// output, so the result does not depend on which thread ran it.
template <typename F>
void parallel_for(int n, const F &fn) {
	int threads = std::max(1, std::min<int>((int)std::thread::hardware_concurrency(), n));
	if (threads == 1) {
		for (int i = 0; i < n; i++) {
			fn(i);
		}
		return;
	}
	std::atomic<int> next{ 0 };
	auto run = [&]() {
		for (int i = next.fetch_add(1); i < n; i = next.fetch_add(1)) {
			fn(i);
		}
	};
	std::vector<std::thread> pool;
	pool.reserve(threads - 1);
	for (int t = 1; t < threads; t++) {
		pool.emplace_back(run);
	}
	run();
	for (std::thread &t : pool) {
		t.join();
	}
}

} // namespace godot
