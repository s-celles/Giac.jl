# Package Architecture

This page explains the internal structure of Giac.jl, helping developers understand how the package is organized and how components interact.

## Overview

Giac.jl wraps the GIAC computer algebra system (C++) for use in Julia. The package uses CxxWrap.jl for C++/Julia interoperability and provides a Julia-native API.

```mermaid
graph TB
    subgraph Julia_User_Code["Julia User Code"]
        A[User Code]
    end

    subgraph Giac_jl_Package["Giac.jl Package"]
        B["api.jl (High-level API)"]
        C["commands.jl (giac_cmd)"]
        D["wrapper.jl (CxxWrap)"]
        E["types.jl (GiacExpr)"]
    end

    subgraph External_Libraries["External Libraries"]
        F["libgiac-julia-wrapper"]
        G["libgiac (GIAC CAS)"]
    end

    A --> B
    A --> C
    B --> D
    C --> D
    D --> F
    F --> G
    E -.-> D
```

## Source File Reference

| File | Purpose | Key Exports | Dependencies |
|------|---------|-------------|--------------|
| `Giac.jl` | Main module entry point | `Giac` module | All other files |
| `types.jl` | Type definitions | `GiacExpr`, `GiacContext`, `GiacMatrix`, `GiacError` | None |
| `wrapper.jl` | CxxWrap bindings, Tier 1/2 functions | `_giac_eval_string`, `_giac_*_tier1` | types.jl |
| `api.jl` | High-level Julia API | `giac_eval`, `to_julia` | wrapper.jl, types.jl |
| `commands.jl` | Command invocation, Base extensions | `giac_cmd`, `Base.sin(::GiacExpr)` | wrapper.jl, types.jl |
| `Commands.jl` | Commands submodule | `invoke_cmd`, ~2000 command functions | commands.jl |
| `command_registry.jl` | Command discovery | `VALID_COMMANDS`, `suggest_commands` | None |
| `namespace_commands.jl` | Namespace-specific commands | Namespace command helpers | command_registry.jl |
| `operators.jl` | Arithmetic operators | `+`, `-`, `*`, `/`, `^` for GiacExpr | types.jl |
| `macros.jl` | User convenience macros | `@giac_var`, `@giac_several_vars` | api.jl |
| `utils.jl` | Helper utilities | Internal utilities | None |
| `TempApi.jl` | Temporary API submodule | TempApi functions | api.jl |

## Module Initialization

When `using Giac` is executed, the following initialization sequence occurs:

```mermaid
sequenceDiagram
    participant User
    participant Giac.jl
    participant wrapper.jl
    participant GiacCxxBindings
    participant libgiac

    User->>Giac.jl: using Giac
    Giac.jl->>Giac.jl: include all source files
    Giac.jl->>wrapper.jl: __init__()
    wrapper.jl->>GiacCxxBindings: init_giac_library()
    GiacCxxBindings->>libgiac: Load shared library (RTLD_GLOBAL)
    libgiac-->>GiacCxxBindings: Library loaded
    GiacCxxBindings-->>wrapper.jl: Ready
    wrapper.jl->>Giac.jl: Create DEFAULT_CONTEXT
    Giac.jl->>Giac.jl: _init_command_registry()
    Giac.jl->>Commands.jl: Commands.__init__()
    Commands.jl->>Commands.jl: Generate ~2000 command functions
    Commands.jl-->>User: Ready to use
```

### What Happens in `__init__()`

1. **Library Loading**: `init_giac_library()` loads the C++ wrapper library with `RTLD_GLOBAL` flag to ensure proper symbol resolution
2. **Context Creation**: Creates `DEFAULT_CONTEXT`, the global evaluation context
3. **Command Registry**: Initializes the registry of valid GIAC commands
4. **Commands Module**: Dynamically generates wrapper functions for all GIAC commands

## Type System

Giac.jl defines four core types for working with GIAC:

```mermaid
classDiagram
    class GiacExpr {
        +Ptr~Cvoid~ ptr
        +finalizer()
        +show()
        +getproperty()
    }

    class GiacContext {
        +Ptr~Cvoid~ ptr
        +ReentrantLock lock
        +finalizer()
    }

    class GiacMatrix {
        +Ptr~Cvoid~ ptr
        +Int rows
        +Int cols
        +finalizer()
        +getindex()
    }

    class GiacError {
        +String message
        +Symbol category
    }

    GiacExpr --> GiacContext : uses
    GiacMatrix --> GiacExpr : contains
```

### GiacExpr

The primary type representing a GIAC expression. Wraps a pointer to a C++ `giac::gen` object.

```julia
mutable struct GiacExpr
    ptr::Ptr{Cvoid}
end
```

- **Automatic memory management**: Uses Julia's finalizer to free C++ memory
- **Method-style syntax**: Supports `expr.factor()` which translates to `giac_cmd(:factor, expr)`
- **Display**: Implements `show` for text and LaTeX output

### GiacContext

Evaluation context managing computation state.

```julia
mutable struct GiacContext
    ptr::Ptr{Cvoid}
    lock::ReentrantLock
end
```

- **Thread safety**: Contains a `ReentrantLock` for concurrent access
- **Configuration**: Holds computation settings (precision, assumptions, etc.)

### GiacMatrix

Symbolic matrix type with dimension tracking.

```julia
mutable struct GiacMatrix
    ptr::Ptr{Cvoid}
    rows::Int
    cols::Int
end
```

- **Indexing**: Supports `m[i,j]` returning a `GiacExpr`
- **Construction**: Can be created from Julia arrays or symbolically

### GiacError

Exception type for GIAC-related errors.

```julia
struct GiacError <: Exception
    message::String
    category::Symbol  # :parse, :eval, :type, :memory
end
```

## Data Flow

A typical function call flows through the package like this:

```mermaid
flowchart LR
    A["User: sin(x)"] --> B{GiacExpr?}
    B -->|Yes| C[commands.jl]
    B -->|No| D[Julia Base]
    C --> E{Tier 1?}
    E -->|Yes| F["wrapper.jl (_giac_sin_tier1)"]
    E -->|No| G[giac_cmd]
    F --> H[C++ wrapper]
    G --> I[String evaluation]
    H --> J[libgiac]
    I --> J
    J --> K["Result: GiacExpr"]
```

## File Dependencies

Understanding which files depend on which helps when making changes:

```mermaid
graph TD
    A[types.jl] --> B[wrapper.jl]
    A --> C[operators.jl]
    B --> D[api.jl]
    B --> E[commands.jl]
    D --> F[macros.jl]
    E --> G[Commands.jl]
    H[command_registry.jl] --> E
    H --> I[namespace_commands.jl]
    D --> J[TempApi.jl]

    K[Giac.jl] --> A
    K --> B
    K --> C
    K --> D
    K --> E
    K --> F
    K --> G
    K --> H
    K --> I
    K --> J
```

## Where to Make Changes

| Change Type | Files to Modify |
|-------------|-----------------|
| Add a new high-performance function | `wrapper.jl` (Tier 1), `commands.jl` (Base extension) |
| Add a new type | `types.jl` |
| Extend an existing command | `commands.jl` or `Commands.jl` |
| Add a new macro | `macros.jl` |
| Modify operator behavior | `operators.jl` |
| Change initialization | `Giac.jl` (`__init__`) or `wrapper.jl` |
| Add API documentation | docstrings in relevant file |

## See Also

- [Performance Tiers](tier-system.md) - Deep dive into the tier system
- [Adding Functions](contributing.md) - Step-by-step contribution guide
- [Memory Management](memory.md) - How memory is managed
