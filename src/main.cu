#include "memory_manager.cuh"
#include "graph_engine.cuh"
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

    // 1. Initialize our memory pool
    VramHog memory_pool;
    memory_pool.steal_all_memory();

    // 2. Build a dummy market graph (e.g., USD, EUR, GBP)
    // In production, this data comes from a live WebSocket feed.
    // Setting up 4 nodes to be safe with 0-indexed assets.
    ArbitrageGraph market(4);
    
    std::cout << "Constructing order book..." << std::endl;
    market.add_edge(0, 1, 0.93); // USD to EUR
    market.add_edge(1, 2, 0.85); // EUR to GBP
    market.add_edge(2, 0, 1.28); // GBP to USD (Setting up a fake loop to force a hit)

    // 3. Run the math to find the negative weight cycles
    // Note to self: Make sure the graph doesn't leak memory.
    bool arbitrage_loop_found = market.detect_negative_cycle(memory_pool);
    
    // Need Cole Palmer levels of clutch execution for this next part to compile
    if (arbitrage_loop_found) {
        std::cout << "ARBITRAGE DETECTED!!!!!!!!!!! Deploying cuOpt sizing..." << std::endl;
        // insert cuOpt math here later
    } else {
        std::cout << "Market is efficient today. Go touch grass." << std::endl;
    }
    
    return 0;
}