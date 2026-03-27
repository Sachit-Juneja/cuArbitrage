#include "memory_manager.cuh"

VramHog::VramHog() {
    std::cout << "[VramHog] Initialized. Ready to hoard memory." << std::endl;
}

VramHog::~VramHog() {
    std::cout << "[VramHog] Shutting down. Releasing hostage VRAM." << std::endl;
}

void VramHog::steal_all_memory() {
    // We are using native CUDA Memory Pools (CUDA 11.2+) to pre-allocate.
    // This bypasses the RAPIDS librmm dependency overhead for now but gives the same speed.
    cudaMemPool_t pool;
    cudaError_t status = cudaDeviceGetDefaultMemPool(&pool, 0);
    
    if (status != cudaSuccess) {
        std::cerr << "[VramHog] Panic: Failed to grab the memory pool." << std::endl;
        return;
    }
    
    // Set the release threshold to max so the GPU never gives the memory back to the OS 
    // until the program dies. Pure greed. Pure speed.
    uint64_t threshold = UINT64_MAX; 
    cudaMemPoolSetAttribute(pool, cudaMemPoolAttrReleaseThreshold, &threshold);
    
    std::cout << "[VramHog] Memory pool locked in. Zero-copy environment engaged." << std::endl;
}