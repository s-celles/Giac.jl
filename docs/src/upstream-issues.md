# Upstream Issues

This document tracks known issues in upstream dependencies that affect Giac.jl functionality.

## SymbolicUtils.jl - Display Error with Negative Symbolic Coefficients

**Status**: Open  
**Affects**: `to_symbolics` display in REPL  
**Upstream Package**: [SymbolicUtils.jl](https://github.com/JuliaSymbolics/SymbolicUtils.jl)  
**First Observed**: 2026-02-20  
**Issue** https://github.com/JuliaSymbolics/SymbolicUtils.jl/issues/864

### Description

When displaying Symbolics expressions containing negative symbolic coefficients like `-sqrt(2)`, the REPL throws a `TypeError` because `SymbolicUtils` attempts to evaluate a symbolic boolean expression as a literal boolean.

### Reproduction (with Giac.jl)

```julia
using Giac
using Symbolics

result = giac_eval("factor(x^8-1)")
# GiacExpr: (x-1)*(x+1)*(x^2+1)*(x^2+(-sqrt(2))*x+1)*(x^2+sqrt(2)*x+1)

sym = to_symbolics(result)
# Error showing value of type Num:
# TypeError: non-boolean (SymbolicUtils.BasicSymbolic{Bool}) used in boolean context
```

### Minimal Reproduction (without Giac.jl)

```julia
using Symbolics
using Symbolics.SymbolicUtils

@variables x

# Create -sqrt(2) using Symbolics.term
sqrt2 = Symbolics.term(sqrt, 2)
neg_sqrt2 = Symbolics.term(*, -1, sqrt2)

# These work fine:
println(Symbolics.wrap(neg_sqrt2))       # -sqrt(2)
neg_sqrt2_x = Symbolics.term(*, neg_sqrt2, Symbolics.unwrap(x))
println(Symbolics.wrap(neg_sqrt2_x))     # (-sqrt(2))*x

# Create a SUM with the negative symbolic coefficient
expr = Symbolics.term(+, 1, neg_sqrt2_x);

# Try to display the SUM - FAILS
println(Symbolics.wrap(expr))  # TypeError: non-boolean (SymbolicUtils.BasicSymbolic{Bool}) used in boolean context
```

The bug is triggered by **any negative symbolic coefficient in a sum expression**, not just specific representations like `2^(1//2)` vs `sqrt(2)`.

### Root Cause

The error occurs in `SymbolicUtils/src/types.jl` in the `remove_minus` function (approximately line 1254):

```julia
function remove_minus(t)
    # This fails when t contains symbolic expressions like -sqrt(2)
    # because (-(2^(1//2))) < 0 returns a symbolic Bool, not a literal Bool
    if t < 0
        ...
    end
end
```

The comparison `t < 0` returns a `SymbolicUtils.BasicSymbolic{Bool}` instead of a `Bool` when `t` is a symbolic expression.

### Impact on Giac.jl

- **Conversion works correctly**: `to_symbolics` successfully converts the expression
- **Only display fails**: The error only occurs when the REPL tries to `show` the result
- **Workaround**: Assign to a variable and use the result without displaying it

```julia
# This works:
sym = to_symbolics(result)
typeof(sym)  # Num
Symbolics.unwrap(sym)  # Works fine

# Use in computation works:
@variables y
expr = sym + y  # Works
```

### Affected Versions

- SymbolicUtils.jl: Observed with version in Symbolics.jl 7.x
- Julia: 1.10+, 1.12+

### Technical Details

The bug is triggered when displaying sum expressions that contain negative symbolic coefficients (like `-sqrt(2)*x`). The `remove_minus` function in SymbolicUtils tries to evaluate `t < 0` where `t` is the extracted coefficient (e.g., `-sqrt(2)`). Since this comparison returns a `BasicSymbolic{Bool}` instead of a literal `Bool`, the `if` statement fails with a TypeError.

The issue affects any symbolic expression that cannot be evaluated to a numeric literal at display time.

### Workarounds

1. **Avoid displaying complex factored expressions directly**:
   ```julia
   sym = to_symbolics(result)  # Don't let REPL display
   # Use sym in subsequent computations
   ```

2. **Work with the underlying expression**:
   ```julia
   # This may fail:
   # string(sym)

   # Instead, work with the underlying expression:
   Symbolics.unwrap(sym)
   ```

3. **Suppress display in scripts**:
   ```julia
   sym = to_symbolics(result);  # Semicolon suppresses REPL output
   # Continue with computation
   ```

### Upstream Fix

A fix should be submitted to SymbolicUtils.jl to handle symbolic expressions in `remove_minus` and related display functions. The fix should check if the result of comparison is symbolic before using it in a boolean context.

**Suggested fix for `remove_minus` in SymbolicUtils/src/types.jl:**

```julia
function remove_minus(t)
    # Handle the case where t is a symbolic expression
    comparison = t < 0
    if comparison isa Bool
        if comparison
            # t is a negative literal number
            ...
        end
    else
        # comparison is symbolic - cannot determine sign at display time
        # Return t unchanged or handle gracefully
        return (false, t)
    end
end
```

### References

- SymbolicUtils.jl repository: https://github.com/JuliaSymbolics/SymbolicUtils.jl
- Related code: `src/types.jl`, functions `remove_minus`, `show_add`, `show_mul`
