#pragma once
#include <iostream>
#include <cuda_runtime.h>

// Wrapping the RAPIDS memory manager so I don't nuke my RAM
class VramHog {
public:
    VramHog();
    ~VramHog();
    
    // Officially called "initialize_memory_pool" for the recruiters, 
    // but we all know what this really does.
    void steal_all_memory(); 
    
    // The actual zero-copy magic
    // Allocates memory that both the CPU and GPU can look at simultaneously
    template <typename T>
    void allocate_zero_copy(T** host_ptr, T** device_ptr, size_t num_elements) {
        size_t bytes = num_elements * sizeof(T);
        
        // cudaHostAllocMapped forces the OS to lock this memory into physical RAM (no paging)
        // and maps it into the GPU's address space. 
        cudaHostAlloc((void**)host_ptr, bytes, cudaHostAllocMapped);
        cudaHostGetDevicePointer((void**)device_ptr, *host_ptr, 0);
        
        std::cout << "[VramHog] Zero-copy buffer allocated: " << bytes << " bytes." << std::endl;
    }

    template <typename T>
    void free_zero_copy(T* host_ptr) {
        cudaFreeHost(host_ptr);
    }
};
