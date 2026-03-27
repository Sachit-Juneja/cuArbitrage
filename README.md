# cuArbitrage 

A zero-copy, GPU-accelerated high-frequency arbitrage routing engine. Bypasses the CPU-GPU memory bottleneck using RAPIDS `libcudf`, `libcugraph`, and `cuOpt`.

Basically, I got tired of Python overhead slowing down my math, so I pushed the entire combinatorial optimization pipeline directly into VRAM.

## Why did I build this?
Standard quantitative models run batch processes on CPUs. In a highly fragmented market, by the time your CPU calculates the CVaR (Conditional Value-at-Risk) of a trade, the arbitrage window has slammed shut. 

This engine is designed to ingest data, find the negative weight cycles (arbitrage), and size the trade strictly on the GPU. No copying back and forth. 

## Benchmarks (coming soon once I fix a tiny pointer issue)
* **CPU / Python Pipeline:** Too slow.
* **cuArbitrage (C++ / CUDA):** Sub-millisecond.

## How to run
1. Have a good NVIDIA GPU. 
2. `mkdir build && cd build`
3. `cmake .. && make`
4. `./cuArbitrage`
5. Profit???