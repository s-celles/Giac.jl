# Giac.jl

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.18642707.svg)](https://doi.org/10.5281/zenodo.18642707)

A Julia wrapper for the [GIAC](https://www-fourier.univ-grenoble-alpes.fr/~parisse/giac.html) computer algebra system.

## Features

- **Dynamic Command Invocation**: Access all 2200+ GIAC commands via `invoke_cmd(:cmd, args...)`
- **Commands Submodule**: All ~2000+ commands available via `Giac.Commands` for clean namespace
- **TempApi Submodule**: Simplified function names (`diff`, `factor`, etc.) via `Giac.TempApi`
- **Method Syntax**: Call commands as methods: `expr.factor()`, `expr.diff(x)`
- **Expression Evaluation**: Parse and evaluate mathematical expressions
- **Arithmetic Operations**: +, -, *, /, ^, unary negation, equality
- **Calculus**: Differentiation, integration, limits, series expansion
- **Algebra**: Factorization, expansion, simplification, equation solving, GCD
- **Linear Algebra**: Matrix determinant, inverse, trace, transpose
- **Command Discovery**: Search commands, browse by category, built-in `help(:cmd)`
- **Base Extensions**: Use `sin(expr)`, `cos(expr)`, `exp(expr)` with GiacExpr
- **Type Conversion**: Convert results to Julia native types (Int64, Float64, Rational)
- **Symbolics.jl Integration**: Bidirectional conversion with Symbolics.jl

## Installation

### Option 1: Stub Mode (No C++ Dependencies)

For development or testing without the full GIAC library:

```julia
using Pkg
Pkg.add(url="https://github.com/s-celles/Giac.jl")
```

In stub mode, basic operations work but return placeholder values.

### Option 2: Full Integration (With GIAC 2.0.0)

#### Prerequisites

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
```

## Quick Start

```julia
using Giac

# Check mode
println("Stub mode: ", is_stub_mode())

# Basic evaluation
result = giac_eval("2 + 3")        # 5
factored = giac_eval("factor(x^2 - 1)")  # (x-1)*(x+1)

# Arithmetic
@giac x
@giac y
println(x + y)   # x+y
println(x * y)   # x*y
println(x ^ 2)   # x^2

# Calculus
f = giac_eval("x^3")
df = giac_diff(f, x)               # 3*x^2
F = giac_integrate(f, x)           # x^4/4
f = giac_eval("sin(x)/x")
lim = giac_limit(f, x, giac_eval("0"))  # 1

# Algebra
giac_factor(giac_eval("x^2 - 1"))      # (x-1)*(x+1)
giac_expand(giac_eval("(x+1)^3"))      # x^3+3*x^2+3*x+1
giac_simplify(giac_eval("(x^2-1)/(x-1)"))  # x+1
giac_solve(giac_eval("x^2 - 4"), x)    # list[-2,2]

# Convert to Julia types
to_julia(giac_eval("42"))    # 42::Int64
to_julia(giac_eval("3/4"))   # 3//4::Rational{Int64}
```

## Dynamic Command Invocation

Call any of GIAC's 2200+ commands dynamically:

```julia
using Giac

@giac x
expr = giac_eval("x^2 - 1")

# Function syntax with invoke_cmd (works for ALL commands)
result = invoke_cmd(:factor, expr)           # (x-1)*(x+1)
deriv = invoke_cmd(:diff, expr, x)           # 2*x
integral = invoke_cmd(:integrate, expr, x)   # x^3/3-x

# Method syntax on GiacExpr (equivalent to invoke_cmd)
result = expr.factor()                     # (x-1)*(x+1)
deriv = expr.diff(x)                       # 2*x

# Chaining methods
result = giac_eval("(x+1)^3").expand().simplify()

# Natural Julia syntax with Base extensions
@giac y
sin(y)         # sin(y)
cos(y)         # cos(y)
exp(y)         # exp(y)
log(y)         # ln(y)
sqrt(y)        # sqrt(y)
sin(y) + cos(y)  # sin(y)+cos(y)
```

## Commands Submodule

Giac.jl provides **three ways** to access GIAC's 2200+ commands via the `Giac.Commands` submodule:

### 1. Qualified Access (Cleanest Namespace - ToDo - not yet implemented)

Access commands via `Giac.Commands.commandname`:

```julia
using Giac

@giac x
expr = giac_eval("x^2 - 1")

# Access commands via Giac.Commands
Giac.Commands.factor(expr)          # (x-1)*(x+1)
Giac.Commands.expand(giac_eval("(x+1)^2"))  # x^2+2*x+1
Giac.Commands.diff(expr, x)         # 2*x
Giac.Commands.integrate(expr, x)    # x^3/3-x
Giac.Commands.ifactor(giac_eval("120"))  # 2^3*3*5
```

### 2. Selective Import (Recommended - ToDo - not yet implemented)

Import specific commands you need:

```julia
using Giac
using Giac.Commands: factor, expand, diff, integrate

@giac x
expr = giac_eval("x^2 - 1")

# Direct function syntax (no prefix needed)
factor(expr)              # (x-1)*(x+1)
expand(giac_eval("(x+1)^2"))  # x^2+2*x+1
diff(expr, x)             # 2*x
integrate(expr, x)        # x^3/3-x
```

### 3. Full Import (Interactive Use)

Import all ~2000+ commands for interactive exploration:

```julia
using Giac
using Giac.Commands  # Imports ALL exportable commands

@giac x
factor(giac_eval("x^2 - 1"))    # (x-1)*(x+1)
ifactor(giac_eval("120"))       # 2^3*3*5
nextprime(giac_eval("100"))     # 101
airy_ai(giac_eval("0"))         # Airy function

# Discover available commands
exportable_commands()            # ~2000+ command names
```

### invoke_cmd for ALL Commands

For commands that conflict with Julia (like `sin`, `cos`, `eval`, `det`), use `invoke_cmd`:

```julia
using Giac

# Conflicting commands must use invoke_cmd
invoke_cmd(:eval, giac_eval("2+3"))      # 5
invoke_cmd(:sin, giac_eval("pi/6"))      # 1/2
invoke_cmd(:det, giac_eval("[[1,2],[3,4]]"))  # -2
invoke_cmd(:sum, giac_eval("k"), giac_eval("k"), giac_eval("1"), giac_eval("10"))  # 55

# invoke_cmd works for ANY command
invoke_cmd(:factor, giac_eval("x^2-1"))  # (x-1)*(x+1)
```

## TempApi Submodule

The `Giac.TempApi` submodule provides convenience functions with simplified names for the most common symbolic computation operations. These are wrappers around the `giac_*` functions.

```julia
using Giac.TempApi: diff, expand, factor, integrate, limit, simplify, solve
#Overlapping with Julia: eval, include, 
@giac x a b
diff(x^2, x)  # 2*x
expand((a+b)^2)  # a^2+b^2+2*a*b
factor(x^2-1)  # (x-1)*(x+1)
integrate(x^2, x)  # x^3/3
integrate(x^2, x, 0, 1)  # returns
    // ∫ ~= 0.333333333333
    GiacExpr: 1/3
limit(sin(x)/x, x, giac_eval("0"))  # 1
simplify(a + b - a)  # b
solve(x^2 - 1)
solve(x^2 - 1, x)  # list[-1,1]
```

### Available Functions

| TempApi Function | Delegates To | Description |
|-----------------|--------------|-------------|
| `diff(expr, var, n=1)` | `giac_diff` | Differentiate expression |
| `integrate(expr, var)` | `giac_integrate` | Indefinite integral |
| `integrate(expr, var, a, b)` | `giac_integrate` | Definite integral |
| `limit(expr, var, point)` | `giac_limit` | Compute limit |
| `factor(expr)` | `giac_factor` | Factor polynomial |
| `expand(expr)` | `giac_expand` | Expand expression |
| `simplify(expr)` | `giac_simplify` | Simplify expression |
| `solve(expr, var)` | `giac_solve` | Solve equation |

### Usage Patterns

```julia
using Giac

# 1. Full import (interactive use)
using Giac.TempApi

@giac x
expr = giac_eval("x^2 - 1")

diff(expr, x)           # 2*x
factor(expr)            # (x-1)*(x+1)
integrate(expr, x)      # x^3/3-x
limit(giac_eval("sin(x)/x"), x, giac_eval("0"))  # 1

# 2. Selective import (recommended)
using Giac.TempApi: diff, factor

diff(expr, x)    # Works
factor(expr)     # Works

# 3. Qualified access
Giac.TempApi.diff(expr, x)
Giac.TempApi.factor(expr)
```

### Comparison: TempApi vs giac_* vs Commands

| Pattern | Import | Usage | Best For |
|---------|--------|-------|----------|
| TempApi | `using Giac.TempApi` | `diff(expr, x)` | Clean, simple names for common operations |
| giac_* | `using Giac` | `giac_diff(expr, x)` | Main module, explicit prefixes |
| Commands | `using Giac.Commands` | `diff(expr, x)` | Access to ALL 2200+ GIAC commands |

**Note**: Both TempApi and Commands export `diff`, `factor`, etc. Use selective imports to avoid conflicts, or choose one submodule based on your needs.

### Commands That Conflict with Julia

Some GIAC commands have the same name as Julia built-ins. These are **not exported** from `Giac.Commands` to avoid shadowing Julia's functions:

| Category | Conflicting Commands |
|----------|---------------------|
| Keywords | `if`, `for`, `while`, `end`, `in`, `or`, `and`, `not` |
| Builtins | `eval`, `float`, `sum`, `prod`, `collect`, `abs`, `sign` |
| Math | `sin`, `cos`, `tan`, `exp`, `log`, `sqrt`, `gcd`, `lcm` |
| LinearAlgebra | `det`, `inv`, `trace`, `rank`, `transpose`, `norm` |
| Statistics | `mean`, `median`, `var`, `std` |

Use `invoke_cmd(:name, args...)` for these commands. A warning is shown on first use to remind you:

```julia
invoke_cmd(:eval, giac_eval("2+3"))
# ┌ Warning: GIAC command 'eval' conflicts with Julia (builtin).
# │ Use invoke_cmd(:eval, args...) to call it.
```

## Command Discovery

```julia
using Giac

# Search for commands by prefix
search_commands("sin")        # ["sin", "sinc", "sinh", ...]

# Search with regex
search_commands(r"^a.*n$")    # Commands starting with 'a' and ending with 'n'

# Search by description (find commands by what they do)
search_commands_by_description("polynomial")  # Commands related to polynomials
search_commands_by_description("matrix", n=5) # Limit to 5 results

# Get command metadata
info = command_info(:factor)
info.name                     # "factor"
info.category                 # :algebra

# List available categories
list_categories()             # [:trigonometry, :calculus, :algebra, ...]

# Get commands in a category
commands_in_category(:trigonometry)  # ["sin", "cos", "tan", "asin", ...]
commands_in_category(:calculus)      # ["diff", "integrate", "limit", ...]
commands_in_category(:algebra)       # ["factor", "expand", "simplify", ...]
```

## Help System

```julia
using Giac

# Display Julia help for a function
?help(factor)
# search: factor ifactor cfactor factorial Vector giac_factor function taylor acot acos filter macro for floor acoth acotd
# 
#   factor(args...)::GiacExpr
# 
#   Call the GIAC factor command with the given arguments.
# 
#   This is a convenience function exported for direct use. Equivalent to:
# 
#     •  giac_cmd(:factor, args...)
# 
#   See GIAC documentation for detailed usage of this command. This is available using helper functions like help(:factor) or giac_help(:factor).

# Display formatted help for a Giac command
help(:factor)
# factor
# ══════
#
# Description:
#   Factorizes a polynomial.
#
# Related:
#   ifactor, partfrac, normal
#
# Examples:
#   • factor(x^4-1)
#   • factor(x^4-4,sqrt(2))
#   • factor(x^4+12*x^3+54*x^2+108*x+81)

# Access help data programmatically
result = help(:sin)
result.command      # "sin"
result.description  # "Sine or Option of the convert or convertir command (id trigsin)."
result.related      # ["asin", "convert", "trigsin"]
result.examples     # ["sin(0)", "convert(cos(x)^4+sin(x)^2,sin)"]

# Get raw help as a string (for backward compatibility)
help_text = giac_help(:factor)

# List all available commands
cmds = list_commands()
println("Number of commands: ", length(cmds))  # 2215

# Get help count
println("Help entries: ", help_count())  # 2215
```

## Command Suggestions

When you mistype a command, Giac.jl automatically suggests similar commands:

```julia
using Giac

# Typo in "factor" shows suggestions
help(:factr)
# factr
# ═════
#
# Description:
#   [No help found for: factr. Did you mean: factor, ifactor, cfactor, fractr?]

# Get suggestions programmatically
suggest_commands(:factr)        # ["factor", "cfactor", "ifactor", ...]
suggest_commands(:integrat)     # ["integrate", "integral", ...]

# Configure number of suggestions
get_suggestion_count()          # 4 (default)
set_suggestion_count(6)         # Show more suggestions

# Get suggestions with edit distances
Giac.suggest_commands_with_distances(:factr)
# [("factor", 1), ("cfactor", 2), ("ifactor", 2), ...]
```

The suggestion system uses Levenshtein edit distance with an adaptive threshold based on input length.

## Linear Algebra

```julia
using Giac, LinearAlgebra

A = GiacMatrix([1 2; 3 4])
det(A)        # -2
tr(A)         # 5
inv(A)        # inverse matrix
transpose(A)  # transposed matrix

# Symbolic matrix
B = GiacMatrix([[giac_eval("a"), giac_eval("b")],
                [giac_eval("c"), giac_eval("d")]])
det(B)  # a*d-b*c
```

## Symbolics.jl Integration

```julia
using Giac, Symbolics

@variables x y
giac_expr = to_giac(x^2 + 2*x + 1)
factored = giac_factor(giac_expr)  # (x+1)^2
sym_result = to_symbolics(factored)  # Num: (1+x)^2
```

## API Reference

### Core Functions

| Function | Description |
|----------|-------------|
| `giac_eval(expr)` | Evaluate a GIAC expression string |
| `invoke_cmd(cmd, args...)` | Invoke any GIAC command dynamically |
| `is_stub_mode()` | Check if running without GIAC library |
| `to_julia(expr)` | Convert GiacExpr to Julia type |

### Command Discovery & Help

| Function | Description |
|----------|-------------|
| `help(cmd)` | Get formatted help for a command (returns `HelpResult`) |
| `giac_help(cmd)` | Get raw help text as a string |
| `list_commands()` | List all available GIAC commands |
| `help_count()` | Number of commands in help database |
| `search_commands(pattern)` | Search commands by prefix or regex |
| `command_info(cmd)` | Get CommandInfo with name, category, aliases |
| `list_categories()` | List all command categories |
| `commands_in_category(cat)` | List commands in a category |
| `suggest_commands(input)` | Suggest similar commands for mistyped input |
| `set_suggestion_count(n)` | Set number of suggestions (default: 4) |
| `get_suggestion_count()` | Get current suggestion count |
| `search_commands_by_description(query; n=20)` | Search commands by help text keywords |

### Command Access (008)

| Function | Description |
|----------|-------------|
| `available_commands()` | List all commands starting with ASCII letters |
| `exportable_commands()` | List commands safe to export (no Julia conflicts) |
| `is_valid_command(name)` | Check if a command name is valid |
| `conflict_reason(cmd)` | Get why a command conflicts (`:keyword`, `:builtin`, etc.) |
| `JULIA_CONFLICTS` | Set of commands that conflict with Julia |
| `reset_conflict_warnings!()` | Reset conflict warning tracker (for testing) |

### Types

| Type | Description |
|------|-------------|
| `GiacExpr` | Symbolic expression type |
| `GiacMatrix` | Symbolic matrix type |
| `GiacContext` | Evaluation context |
| `HelpResult` | Parsed help information with `.command`, `.description`, `.related`, `.examples` fields |
| `CommandInfo` | Command metadata with `.name`, `.category`, `.aliases`, `.doc` fields |

### Calculus

| Function | Description |
|----------|-------------|
| `giac_diff(f, x, n=1)` | nth derivative of f with respect to x |
| `giac_integrate(f, x)` | Indefinite integral |
| `giac_integrate(f, x, a, b)` | Definite integral from a to b |
| `giac_limit(f, x, point)` | Limit as x approaches point |
| `giac_series(f, x, point, order)` | Taylor series expansion |

### Algebra

| Function | Description |
|----------|-------------|
| `giac_factor(expr)` | Factor polynomial |
| `giac_expand(expr)` | Expand expression |
| `giac_simplify(expr)` | Simplify expression |
| `giac_solve(expr, x)` | Solve equation for x |
| `giac_gcd(a, b)` | Greatest common divisor |

### Linear Algebra

| Function | Description |
|----------|-------------|
| `GiacMatrix(array)` | Create symbolic matrix |
| `det(M)` | Determinant |
| `inv(M)` | Inverse |
| `tr(M)` | Trace |
| `transpose(M)` | Transpose |

## License

MIT License

## Related Projects

- [GIAC](https://www-fourier.univ-grenoble-alpes.fr/~parisse/giac.html) - The underlying computer algebra system
- [libgiac-julia-wrapper](https://github.com/s-celles/libgiac-julia-wrapper) - CxxWrap bindings for GIAC
- [CxxWrap.jl](https://github.com/JuliaInterop/CxxWrap.jl) - C++ wrapper generator for Julia
