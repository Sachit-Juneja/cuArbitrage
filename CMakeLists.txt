cmake_minimum_required(VERSION 3.20)

# I don't actually fully understand CMake, I just copied this from my MacTensor repo and prayed.
project(cuArbitrage LANGUAGES CXX CUDA)

# Forcing C++17 because enterprise SWE code is usually stuck in the dark ages and I want to feel modern.
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD 17)

include_directories(${CMAKE_SOURCE_DIR}/include)

# Please find CUDA. Please.
find_package(CUDAToolkit REQUIRED)

add_executable(cuArbitrage 
    src/main.cu 
)

# Linking CUDA. If this fails, it's an NVIDIA problem, not a me problem.
target_link_libraries(cuArbitrage PRIVATE CUDA::cudart)