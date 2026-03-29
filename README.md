# cuArbitrage

A zero-copy, GPU-accelerated high-frequency arbitrage routing engine. Built in C++ and CUDA to bypass the CPU-GPU memory bottleneck.

## The Problem
Standard quantitative models and AI Blueprints (like NVIDIA's portfolio optimization pipeline) often rely on Python wrappers. In highly fragmented markets with thin liquidity windows, the latency penalty of copying order book data from the CPU to the GPU (`cudaMemcpy`) means the arbitrage opportunity vanishes before the math even finishes running.

## The Solution
`cuArbitrage` pushes the entire combinatorial optimization pipeline directly into VRAM using pinned mapped memory. The CPU writes data, and the GPU reads it directly over the PCIe bus—no copies, no latency spikes.

### Core Engine Architecture

1. **Zero-Copy Memory Pooling (`VramHog`):** A custom CUDA memory manager utilizing `cudaHostAllocMapped` to lock memory into physical RAM, eliminating OS paging and standard `cudaMemcpy` overhead.
   
2. **Massively Parallel Arbitrage Detection:** Translates live exchange rates into a directed graph using the $-\log(\text{rate})$ trick. Deploys a parallelized Bellman-Ford algorithm (assigning one GPU thread per edge) to hunt for negative weight cycles in microseconds.
   
3. **Risk-Constrained Execution (cuOpt Integration):** Finding the infinite money glitch is easy; sizing it safely is hard. The engine formulates execution bounds using Mean-CVaR (Conditional Value-at-Risk) constraints to maximize expected return while strictly capping tail-risk and order book slippage.

## The Proof is in the Output
*(Compiled via `nvcc` on a Tesla T4)*

```text
Booting up the magic money printer...
Found a wild GPU: Tesla T4
VRAM Capacity: 14912 MB. We can work with this.
[VramHog] Initialized. Ready to hoard memory.
[VramHog] Memory pool locked in. Zero-copy environment engaged.
[Graph] Initialized order book graph with 4 assets.
Constructing order book...
[Graph] Hunting for negative weight cycles (Zero-Copy Mode)...
[VramHog] Zero-copy buffer allocated: 48 bytes.
[VramHog] Zero-copy buffer allocated: 16 bytes.
[VramHog] Zero-copy buffer allocated: 1 bytes.
ARBITRAGE DETECTED!!!!!!! Deploying cuOpt sizing...
[cuOpt] NVIDIA cuOpt Matrix Solver Initialized.
[cuOpt] Formulating Mean-CVaR constraints for execution...
[cuOpt] Solver Converged. Optimal Volume bounds computed.
>>> EXECUTE TRADE: Routing $2438.53 through the cycle.
>>> EXPECTED SLIPPAGE BOUNDED.
[VramHog] Shutting down. Releasing hostage VRAM.
```

Build & Run
Prerequisites: Linux environment, NVIDIA GPU, CUDA Toolkit 11.x/12.x, CMake 3.20+.
```
git clone [https://github.com/Sachit-Juneja/cuArbitrage.git](https://github.com/Sachit-Juneja/cuArbitrage.git)
cd cuArbitrage
mkdir build && cd build
cmake ..
make
./cuArbitrage
```