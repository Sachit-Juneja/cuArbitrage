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

bool ArbitrageGraph::detect_negative_cycle() {
    std::cout << "[Graph] Hunting for negative weight cycles on the GPU..." << std::endl;
    
    // 1. Allocate GPU Memory (Normally VramHog would do this, but doing it raw here for the math proof)
    Edge* d_edges;
    float* d_dist;
    bool* d_has_cycle;
    
    cudaMalloc(&d_edges, num_edges * sizeof(Edge));
    cudaMalloc(&d_dist, num_nodes * sizeof(float));
    cudaMalloc(&d_has_cycle, sizeof(bool));
    
    // 2. Initialize distances (Asset 0 is our starting capital, distance 0. Everything else is infinity)
    std::vector<float> h_dist(num_nodes, 1e9f);
    h_dist[0] = 0.0f; 
    bool h_has_cycle = false;
    
    // 3. Copy data to GPU (The bottleneck we will eventually eliminate with zero-copy)
    cudaMemcpy(d_edges, edges.data(), num_edges * sizeof(Edge), cudaMemcpyHostToDevice);
    cudaMemcpy(d_dist, h_dist.data(), num_nodes * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(d_has_cycle, &h_has_cycle, sizeof(bool), cudaMemcpyHostToDevice);
    
    // 4. Launch Config (Blocks and Threads)
    int threadsPerBlock = 256;
    int blocksPerGrid = (num_edges + threadsPerBlock - 1) / threadsPerBlock;
    
    // 5. Run Bellman-Ford V-1 times
    for (int i = 0; i < num_nodes - 1; i++) {
        bellman_ford_relax<<<blocksPerGrid, threadsPerBlock>>>(num_nodes, num_edges, d_edges, d_dist);
        cudaDeviceSynchronize(); // Wait for all threads to finish this iteration
    }
    
    // 6. One final check for the cycle
    check_negative_cycle<<<blocksPerGrid, threadsPerBlock>>>(num_edges, d_edges, d_dist, d_has_cycle);
    cudaDeviceSynchronize();
    
    // 7. Pull the result back to the CPU
    cudaMemcpy(&h_has_cycle, d_has_cycle, sizeof(bool), cudaMemcpyDeviceToHost);
    
    // 8. Clean up (Don't tell VramHog we are using cudaFree)
    cudaFree(d_edges);
    cudaFree(d_dist);
    cudaFree(d_has_cycle);
    
    return h_has_cycle;
}
