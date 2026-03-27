#include "memory_manager.cuh"
#include <iostream>

int main() {
    std::cout << "Booting up the magic money printer..." << std::endl;
    
    int gpu_count = 0;
    cudaGetDeviceCount(&gpu_count);
    
    // Sanity check before we try to allocate VRAM that doesn't exist
    if (gpu_count == 0) {
        std::cerr << "Bro, you have no GPU. Are you running this on a potato?" << std::endl;
        return -1;
    }

    cudaDeviceProp specs;
    cudaGetDeviceProperties(&specs, 0);
    
    // If this segfaults, I'm taking two weeks of bed rest. My posture can't take this anymore.
    std::cout << "Found a wild GPU: " << specs.name << std::endl;
    std::cout << "VRAM Capacity: " << specs.totalGlobalMem / (1024*1024) << " MB. We can work with this." << std::endl;

    VramHog memory_pool;
    memory_pool.steal_all_memory();

    // TODO: Write the actual C&O Bellman-Ford negative cycle graph math here.
    // Note to self: Make sure the graph doesn't leak memory.
    
    bool arbitrage_loop_found = false; 
    
    // Need Cole Palmer levels of clutch execution for this next part to compile
    if (arbitrage_loop_found) {
        std::cout << "Deploying cuOpt sizing..." << std::endl;
        // insert math here
    } else {
        std::cout << "Market is efficient today. Go touch grass." << std::endl;
    }
    
    return 0;
}