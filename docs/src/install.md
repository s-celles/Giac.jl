# Installation
## User mode installation (not yet available)

This command will install Giac.jl (when both GIAC_jll and libgiac-julia-wrapper will be published)

```julia
using Pkg
Pkg.add("Giac")  # when registered in Julia General Registry
Pkg.add(url="https://github.com/s-celles/Giac.jl")  # until unregistered
```

## Developer mode installation

### Option 1: Stub Mode (No C++ Dependencies)

For development or testing without the full GIAC library:

```julia
using Pkg
Pkg.add(url="https://github.com/s-celles/Giac.jl")
```

In stub mode, basic operations work but return placeholder values.

### Option 2: Full Integration (With GIAC 2.0.0)

### Prerequisites

- Julia 1.10+ (LTS recommended)
- C++ compiler with C++17 support
- CMake 3.15+
- GIAC 2.0.0 source

#### Step 1: Build GIAC 2.0.0

```bash
# Download GIAC
wget https://www-fourier.univ-grenoble-alpes.fr/~parisse/giac/giac_stable.tgz
tar xzf giac_stable.tgz
cd giac-2.0.0

# Configure and build
./configure --enable-shared --disable-gui --disable-pari
make -j$(nproc)
```

#### Step 2: Build libgiac-julia-wrapper

```bash
git clone https://github.com/s-celles/libgiac-julia-wrapper
cd libgiac-julia-wrapper
mkdir build && cd build
cmake .. -DGIAC_ROOT=/path/to/giac-2.0.0
make -j$(nproc)
```

#### Step 3: Set Environment

```bash
export GIAC_WRAPPER_LIB=/path/to/libgiac-julia-wrapper/build/src/libgiac_wrapper.so
export LD_LIBRARY_PATH=/path/to/giac-2.0.0/src/.libs:$LD_LIBRARY_PATH
# or
export LD_LIBRARY_PATH=$(julia -e 'using GIAC_jll; print(GIAC_jll.artifact_dir)')/lib:$LD_LIBRARY_PATH
```

### Verifying Installation

```julia
using Giac

# Check mode
println("Stub mode: ", is_stub_mode())

# If stub mode is false, full GIAC integration is working
result = giac_eval("factor(x^2 - 1)")
println(result)  # (x-1)*(x+1)
```
