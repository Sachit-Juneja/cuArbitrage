#pragma once
#include <iostream>
#include <vector>

struct CyclePath {
    int nodes[10]; // Hardcoding max cycle length to 10 to avoid dynamic allocation hell
    int length;
    float bottleneck_liquidity;
};

class cuOptWrapper {
public:
    cuOptWrapper();
    ~cuOptWrapper();
    
    // Calculates the maximum safe volume using the CVaR constraint
    float calculate_optimal_sizing(CyclePath cycle, float max_tail_risk_gamma);
};