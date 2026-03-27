#pragma once
#include <vector>
#include <iostream>

class VramHog;

// Standard C&O graph theory stuff. 
// If this struct gets too fat, the GPU memory transfer will bottleneck us. Keep it lean.
struct Edge {
    int source;
    int dest;
    float rate;          // The actual exchange rate
    float neg_log_weight; // The -log(rate) for Bellman-Ford magic
};

class ArbitrageGraph {
private:
    int num_nodes;
    int num_edges;
    std::vector<Edge> edges; // Living on the CPU for now until we push to VRAM

public:
    ArbitrageGraph(int nodes);
    ~ArbitrageGraph();

    void add_edge(int u, int v, float rate);
    
    // O(V*E) complexity. We will parallelize this on the GPU later so we don't get 
    // destroyed by latency during a live trading session.
    bool detect_negative_cycle(VramHog& memory_pool);
};