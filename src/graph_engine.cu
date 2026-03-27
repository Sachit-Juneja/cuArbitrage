#include "graph_engine.cuh"
#include <cmath>

// --- CUDA KERNELS ---

// I definitely did not write this atomic float CAS loop from scratch. 
// Praise the StackOverflow gods. It stops threads from overwriting each other.
__device__ float atomicMinFloat(float* address, float val) {
    int* address_as_int = (int*)address;
    int old = *address_as_int, assumed;
    while (val < __int_as_float(old)) {
        assumed = old;
        old = atomicCAS(address_as_int, assumed, __float_as_int(val));
    }
    return __int_as_float(old);
}

// Every thread handles one edge. Massive parallel relaxation.
__global__ void bellman_ford_relax(int num_nodes, int num_edges, Edge* edges, float* dist) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < num_edges) {
        int u = edges[i].source;
        int v = edges[i].dest;
        float weight = edges[i].neg_log_weight;
        
        if (dist[u] != 1e9f) {
            atomicMinFloat(&dist[v], dist[u] + weight);
        }
    }
}

// The final pass. If we can STILL relax an edge after V-1 iterations, 
// we have a negative weight cycle (infinite money glitch).
__global__ void check_negative_cycle(int num_edges, Edge* edges, float* dist, bool* has_cycle) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < num_edges) {
        int u = edges[i].source;
        int v = edges[i].dest;
        float weight = edges[i].neg_log_weight;
        
        if (dist[u] != 1e9f && dist[u] + weight < dist[v]) {
            *has_cycle = true; // Ring the alarm
        }
    }
}

// --- CPU HOST CODE ---

ArbitrageGraph::ArbitrageGraph(int nodes) {
    num_nodes = nodes;
    num_edges = 0;
    std::cout << "[Graph] Initialized order book graph with " << nodes << " assets." << std::endl;
}

ArbitrageGraph::~ArbitrageGraph() {
    // Vector cleans itself up.
}

void ArbitrageGraph::add_edge(int u, int v, float rate) {
    Edge e;
    e.source = u;
    e.dest = v;
    e.rate = rate;
    // The core math trick: converting multiplication > 1 into addition < 0
    e.neg_log_weight = -std::log(rate); 
    
    edges.push_back(e);
    num_edges++;
}

// Notice we now pass VramHog by reference
bool ArbitrageGraph::detect_negative_cycle(VramHog& memory_pool) {
    std::cout << "[Graph] Hunting for negative weight cycles (Zero-Copy Mode)..." << std::endl;
    
    Edge *h_edges, *d_edges;
    float *h_dist, *d_dist;
    bool *h_has_cycle, *d_has_cycle;
    
    // 1. Ask VramHog for shared memory pointers instead of using cudaMalloc
    memory_pool.allocate_zero_copy(&h_edges, &d_edges, num_edges);
    memory_pool.allocate_zero_copy(&h_dist, &d_dist, num_nodes);
    memory_pool.allocate_zero_copy(&h_has_cycle, &d_has_cycle, 1);
    
    // 2. CPU writes directly to the shared memory
    for(int i = 0; i < num_edges; i++) {
        h_edges[i] = edges[i]; 
    }
    for(int i = 0; i < num_nodes; i++) {
        h_dist[i] = 1e9f;
    }
    h_dist[0] = 0.0f; 
    *h_has_cycle = false;
    
    // NO CUDAMEMCPY HERE. The GPU can already see the data we just wrote.
    
    // 3. Launch Config
    int threadsPerBlock = 256;
    int blocksPerGrid = (num_edges + threadsPerBlock - 1) / threadsPerBlock;
    
    // 4. Fire the GPU Kernels
    for (int i = 0; i < num_nodes - 1; i++) {
        bellman_ford_relax<<<blocksPerGrid, threadsPerBlock>>>(num_nodes, num_edges, d_edges, d_dist);
        cudaDeviceSynchronize();
    }
    
    check_negative_cycle<<<blocksPerGrid, threadsPerBlock>>>(num_edges, d_edges, d_dist, d_has_cycle);
    cudaDeviceSynchronize();
    
    // 5. Read the result directly from the shared pointer
    bool cycle_found = *h_has_cycle;
    
    // 6. Clean up
    memory_pool.free_zero_copy(h_edges);
    memory_pool.free_zero_copy(h_dist);
    memory_pool.free_zero_copy(h_has_cycle);
    
    return cycle_found;
}
