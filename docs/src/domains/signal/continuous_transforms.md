# Continuous-Time Signal Transforms

This page documents continuous-time signal processing functions in Giac.jl.

## Laplace Transform

The Laplace transform is a mathematical tool for analyzing continuous-time signals and systems. GIAC provides two commands for computing Laplace transforms, available via `Giac.Commands`:

- `laplace(expr, t, s)` - Computes the unilateral Laplace transform
- `ilaplace(expr, s, t)` - Computes the inverse Laplace transform

### Mathematical Definition

The unilateral Laplace transform of a continuous function f(t) is defined as:

```math
F(s) = \int_0^{\infty} f(t) \cdot e^{-st} \, dt
```

### Basic Usage

```julia
using Giac
using Giac.Commands: laplace, ilaplace

# Declare symbolic variables
@giac_var t s a

# Laplace transform of exponential decay exp(-a*t)
F = laplace(exp(-a*t), t, s)
# Returns 1/(a+s) which is equivalent to 1/(s+a)

# Laplace transform of unit step (constant 1)
F_step = laplace(1, t, s)
# Returns 1/s

# Laplace transform of ramp function t
F_ramp = laplace(t, t, s)
# Returns 1/s^2

# Laplace transform of t^2
F_t2 = laplace(t^2, t, s)
# Returns 2/s^3
```

### Inverse Laplace Transform

```julia
using Giac
using Giac.Commands: ilaplace

@giac_var t s a

# Inverse Laplace transform of 1/s → unit step
f_step = ilaplace(1/s, s, t)
# Returns 1

# Inverse Laplace transform of 1/(s+a) → exponential
f_exp = ilaplace(1/(s+a), s, t)
# Returns exp(-a*t)

# Inverse Laplace transform of 1/s^2 → ramp
f_ramp = ilaplace(1/s^2, s, t)
# Returns t
```

### Round-Trip Verification

The Laplace transform and inverse Laplace transform are mathematical inverses:

```julia
using Giac
using Giac.Commands: laplace, ilaplace, simplify

@giac_var t s a

# Verify: ilaplace(laplace(exp(-a*t))) = exp(-a*t)
original = exp(-a*t)
transformed = laplace(original, t, s)
recovered = ilaplace(transformed, s, t)
simplified = simplify(recovered)
# Result: exp(-a*t)
```

### Common Laplace Transform Pairs

| Time Domain f(t) | S-Domain F(s) | Region of Convergence |
|------------------|---------------|----------------------|
| `1` (unit step)  | `1/s`         | Re(s) > 0            |
| `t` (ramp)       | `1/s²`        | Re(s) > 0            |
| `t^n`            | `n!/s^(n+1)`  | Re(s) > 0            |
| `exp(-a*t)`      | `1/(s+a)`     | Re(s) > -Re(a)       |
| `sin(w*t)`       | `w/(s²+w²)`   | Re(s) > 0            |
| `cos(w*t)`       | `s/(s²+w²)`   | Re(s) > 0            |
| `t·exp(-a*t)`    | `1/(s+a)²`    | Re(s) > -Re(a)       |

### Using invoke_cmd

You can also use `invoke_cmd` directly:

```julia
using Giac

@giac_var t s a

# Using invoke_cmd
invoke_cmd(:laplace, exp(-a*t), t, s)
invoke_cmd(:ilaplace, 1/(s+a), s, t)
```

### Notes

1. **Unilateral Transform**: GIAC uses the unilateral Laplace transform (integration from t=0 to infinity), which is standard for causal systems.

2. **Variable Declaration**: Always declare `t` and `s` as symbolic variables using `@giac_var` before using them in transforms.

3. **Simplification**: Use `simplify` from `Giac.Commands` to reduce results to canonical form.

## See Also

- [Discrete-Time Transforms](discrete_transforms.md) - Z-transform and inverse Z-transform
- [Calculus Operations](../math/calculus.md) - Integration, differentiation, and limits
- [GIAC Laplace Documentation](https://www-fourier.univ-grenoble-alpes.fr/~parisse/giac/doc/en/cascmd_en/cascmd_en466.html) - Official GIAC documentation
