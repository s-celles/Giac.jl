# Differential Equations

Giac.jl provides symbolic solving of ordinary differential equations (ODEs) using GIAC's `desolve` command. The package includes a `D` operator following SciML/ModelingToolkit conventions for expressing derivatives naturally.

## The D Operator

The `D` operator provides a clean, Julian syntax for expressing derivatives:

```julia
using Giac
using Giac.Commands: desolve

@giac_var t u(t)

# Create derivative expressions
D(u)        # First derivative u'
D(D(u))     # Second derivative u'' (chained)
D(u, 2)     # Second derivative u'' (direct)
D(u, 3)     # Third derivative u'''
```

### Comparison with Raw Syntax

| D Operator | Raw GIAC | Description |
|------------|----------|-------------|
| `D(u)` | `diff(u, t)` | First derivative |
| `D(D(u))` | `diff(diff(u, t), t)` | Second derivative (chained) |
| `D(u, 2)` | `diff(u, t, 2)` | Second derivative (direct) |
| `D(u)(0) ~ 1` | `"u'(0)=1"` | Initial condition for u'(0) |

## First-Order ODEs

### Basic Example

Solve `τu' + u = U₀` with initial condition `u(0) = 1`:

```julia
using Giac
using Giac.Commands: desolve

@giac_var t u(t) tau U0

# Define ODE: τu' + u = U₀
ode = tau * D(u) + u ~ U0

# Initial condition: u(0) = 1
initial = u(0) ~ 1

# Solve
result = desolve([ode, initial], t, :u)
# Returns: U0+(-U0+1)*exp(-t/tau)
```

### RC Circuit Example

```julia
@giac_var t V(t) R C Vs

# Capacitor voltage ODE: RC·V' + V = Vs
ode = R * C * D(V) + V ~ Vs
initial = V(0) ~ 0

result = desolve([ode, initial], t, :V)
# Returns: Vs*(1-exp(-t/(R*C)))
```

## Second-Order ODEs

### Harmonic Oscillator

Solve `u'' + u = 0` with `u(0) = 1`, `u'(0) = 0`:

```julia
using Giac
using Giac.Commands: desolve

@giac_var t u(t)

# Define ODE using chained D
ode = D(D(u)) + u ~ 0

# Initial conditions
u0 = u(0) ~ 1      # u(0) = 1
du0 = D(u)(0) ~ 0  # u'(0) = 0

# Solve
result = desolve([ode, u0, du0], t, :u)
# Returns: cos(t)
```

### Alternative Syntax with D(u, 2)

```julia
# Same ODE using direct order specification
ode = D(u, 2) + u ~ 0
result = desolve([ode, u(0) ~ 1, D(u)(0) ~ 0], t, :u)
# Returns: cos(t)
```

### Damped Oscillator

Solve `u'' + 2ζω₀u' + ω₀²u = 0`:

```julia
@giac_var t u(t) zeta omega0

ode = D(u, 2) + 2*zeta*omega0*D(u) + omega0^2*u ~ 0
result = desolve([ode, u(0) ~ 1, D(u)(0) ~ 0], t, :u)
```

## Third-Order ODEs

Solve `y''' - y = 0` with `y(0) = 1`, `y'(0) = 1`, `y''(0) = 1`:

```julia
using Giac
using Giac.Commands: desolve

@giac_var t y(t)

# Define ODE
ode = D(y, 3) - y ~ 0

# Initial conditions
y0 = y(0) ~ 1
dy0 = D(y)(0) ~ 1
d2y0 = D(y, 2)(0) ~ 1

# Solve
result = desolve([ode, y0, dy0, d2y0], t, :y)
# Returns: exp(t)
```

## Using D in ODE Expressions

The `D` operator supports arithmetic operations, making it natural to build ODE expressions:

```julia
@giac_var t u(t) a b c

# Build complex ODE expressions
ode1 = D(D(u)) + a*D(u) + b*u ~ c
ode2 = D(u, 2) - 4*D(u) + 4*u ~ 0

# Combine with other GiacExpr
forcing = sin(t)
ode3 = D(D(u)) + u ~ forcing
```

## Important Notes

### Function Name as Symbol

When calling `desolve`, pass the function name as a **Symbol** (`:u`, `:y`) rather than the function expression (`u`, `y`):

```julia
# Correct
desolve([ode, u(0) ~ 1], t, :u)

# Incorrect - GIAC expects just the name, not u(t)
desolve([ode, u(0) ~ 1], t, u)  # May not work as expected
```

### Initial Conditions with D

The `D(u)(0)` syntax creates an unevaluated derivative condition that GIAC interprets correctly:

```julia
D(u)(0) ~ 1      # Creates "u'(0)=1" for GIAC
D(u, 2)(0) ~ 0   # Creates "u''(0)=0" for GIAC
```

### Systems of ODEs

GIAC can solve systems of first-order ODEs:

```julia
@giac_var t x(t) y(t)

# dx/dt = y, dy/dt = -x
sys = [D(x) ~ y, D(y) ~ -x]
initial = [x(0) ~ 1, y(0) ~ 0]

# Solve as a system (pass both variables)
result = desolve([sys..., initial...], t, [:x, :y])
```

## Limitations

- **ODEs only**: GIAC's `desolve` is designed for ordinary differential equations. For PDEs, consider Symbolics.jl + MethodOfLines.jl or other specialized packages.
- **Symbolic solutions**: `desolve` finds closed-form analytical solutions when possible. For numerical solutions of ODEs, use DifferentialEquations.jl.

## API Reference

```@docs
D
DerivativeExpr
DerivativePoint
DerivativeCondition
```
