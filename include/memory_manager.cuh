#pragma once // #ifndef is for boomers

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
};