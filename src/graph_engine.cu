#include "graph_engine.cuh"
#include <cmath> // For std::log

ArbitrageGraph::ArbitrageGraph(int nodes) {
    num_nodes = nodes;
    num_edges = 0;
    std::cout << "[Graph] Initialized order book graph with " << nodes << " assets." << std::endl;
}

ArbitrageGraph::~ArbitrageGraph() {
    // std::vector cleans itself up, thank god. One less memory leak to worry about.
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
    std::cout << "[Graph] Hunting for negative weight cycles (free money)..." << std::endl;
    
    // TODO: Write the parallel Bellman-Ford algorithm using CUDA here.
    // For now, let's just pretend we found one so we can wire up the rest of the engine.
    
    return true; // We are manifesting a profitable market today.
}