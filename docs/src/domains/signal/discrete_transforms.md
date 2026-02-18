# Discrete-Time Signal Transforms

This page documents discrete-time signal processing functions in Giac.jl.

## Z-Transform

The Z-transform is a mathematical tool for analyzing discrete-time signals and systems. GIAC provides two commands for computing Z-transforms, available via `Giac.Commands`:

- `ztrans(expr, n, z)` - Computes the unilateral Z-transform
- `invztrans(expr, z, n)` - Computes the inverse Z-transform

### Mathematical Definition

The unilateral Z-transform of a discrete sequence x[n] is defined as:

```math
X(z) = \sum_{n=0}^{\infty} x[n] \cdot z^{-n}
```

### Basic Usage

```julia
using Giac
using Giac.Commands: ztrans, invztrans

# Declare symbolic variables
@giac_var n z a

# Z-transform of a geometric sequence a^n
X = ztrans(a^n, n, z)
# Returns -z/(a-z) which is equivalent to z/(z-a)

# Z-transform of unit step (constant 1)
X_step = ztrans(1, n, z)
# Returns z/(z-1)

# Z-transform of ramp sequence n
X_ramp = ztrans(n, n, z)
# Returns z/(z-1)^2
```

### Inverse Z-Transform

```julia
using Giac
using Giac.Commands: invztrans

@giac_var n z a

# Inverse Z-transform of z/(z-1) → unit step
x_step = invztrans(z/(z-1), z, n)
# Returns 1

# Inverse Z-transform of z/(z-a) → exponential
x_exp = invztrans(z/(z-a), z, n)
# Returns a^n

# Inverse Z-transform of z/(z-1)^2 → ramp
x_ramp = invztrans(z/(z-1)^2, z, n)
# Returns n
```

### Round-Trip Verification

The Z-transform and inverse Z-transform are mathematical inverses:

```julia
using Giac
using Giac.Commands: ztrans, invztrans, simplify

@giac_var n z a

# Verify: invztrans(ztrans(a^n)) = a^n
original = a^n
transformed = ztrans(original, n, z)
recovered = invztrans(transformed, z, n)
simplified = simplify(recovered)
# Result: a^n
```

### Common Z-Transform Pairs

| Time Domain x[n] | Z-Domain X(z) | Region of Convergence |
|------------------|---------------|----------------------|
| `1` (unit step)  | `z/(z-1)`     | \|z\| > 1            |
| `n` (ramp)       | `z/(z-1)²`    | \|z\| > 1            |
| `a^n`            | `z/(z-a)`     | \|z\| > \|a\|        |
| `n·a^n`          | `az/(z-a)²`   | \|z\| > \|a\|        |

### Using invoke_cmd

You can also use `invoke_cmd` directly:

```julia
using Giac

@giac_var n z a

# Using invoke_cmd
invoke_cmd(:ztrans, a^n, n, z)
invoke_cmd(:invztrans, z/(z-a), z, n)
```

### Notes

1. **Equivalent Forms**: GIAC may return `-z/(a-z)` instead of `z/(z-a)`. These are algebraically equivalent.

2. **Variable Declaration**: Always declare `n` and `z` as symbolic variables using `@giac_var` before using them in transforms.

3. **Simplification**: Use `simplify` from `Giac.Commands` to reduce results to canonical form.

## See Also

- [Continuous-Time Transforms](continuous_transforms.md) - Laplace transforms for continuous-time signals
- [Calculus Operations](../../mathematics/calculus.md) - Integration, differentiation, and limits
- [GIAC Z-Transform Documentation](https://www-fourier.univ-grenoble-alpes.fr/~parisse/giac/doc/en/cascmd_en/cascmd_en467.html) - Official GIAC documentation
