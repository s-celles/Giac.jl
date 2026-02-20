# Symbolic mathematical constants for GIAC (053-symbolic-pi-constant)
# Provides pi, e, i as GiacExpr values instead of Julia's native constants

module Constants

"""
    Giac.Constants

A submodule providing symbolic mathematical constants as GiacExpr values.

These constants preserve their symbolic form in expressions, unlike Julia's
native constants which evaluate to floating-point approximations when used
with GiacExpr.

# Available Constants

- `pi`: The circle constant π (ratio of circumference to diameter)
- `e`: Euler's number ℯ (base of natural logarithm)
- `i`: The imaginary unit √(-1)

# Usage

```julia
using Giac
using Giac.Constants: pi, e, i

# Symbolic pi in expressions
x = giac_eval("x")
expr = 2 * pi * x
# Output: GiacExpr: 2*pi*x  (stays symbolic!)

# Compare with Base.pi (evaluates to float)
expr2 = 2 * Base.pi * x
# Output: GiacExpr: 6.283185307179586*x  (float!)

# Euler's formula
euler = e^(i * pi)
# Output: GiacExpr: -1
```

# Why Use This Module?

When you write `2 * Base.pi * giac_expr`, Julia's `Base.pi` (an `Irrational`)
is converted to a float before multiplication. This module provides symbolic
constants that remain symbolic throughout computations.

# Note

Constants are NOT exported from the main `Giac` module to avoid shadowing
Julia's `Base.pi`. You must explicitly import them:

```julia
# Option 1: Qualified access
Giac.Constants.pi

# Option 2: Selective import
using Giac.Constants: pi, e, i

# Option 3: Import all
using Giac.Constants
```
"""
Constants

using ..Giac: GiacExpr, giac_eval

# Storage for constants (initialized at runtime by Giac.__init__)
const _pi = Ref{GiacExpr}()
const _e = Ref{GiacExpr}()
const _i = Ref{GiacExpr}()

"""
    SymbolicConstant

A wrapper type that holds a reference to a GiacExpr and supports arithmetic operations.
This allows module constants to be initialized at runtime while still supporting
`2 * pi` syntax without requiring `[]` access.
"""
struct SymbolicConstant
    ref::Ref{GiacExpr}
end

# Convert SymbolicConstant to GiacExpr for operations
Base.convert(::Type{GiacExpr}, c::SymbolicConstant) = c.ref[]

# Make SymbolicConstant behave like GiacExpr in most contexts
Base.string(c::SymbolicConstant) = string(c.ref[])
Base.show(io::IO, c::SymbolicConstant) = show(io, c.ref[])
Base.show(io::IO, ::MIME"text/plain", c::SymbolicConstant) = show(io, MIME("text/plain"), c.ref[])

# Arithmetic operators: SymbolicConstant with GiacExpr
Base.:+(a::SymbolicConstant, b::GiacExpr) = a.ref[] + b
Base.:+(a::GiacExpr, b::SymbolicConstant) = a + b.ref[]
Base.:-(a::SymbolicConstant, b::GiacExpr) = a.ref[] - b
Base.:-(a::GiacExpr, b::SymbolicConstant) = a - b.ref[]
Base.:-(a::SymbolicConstant) = -(a.ref[])
Base.:*(a::SymbolicConstant, b::GiacExpr) = a.ref[] * b
Base.:*(a::GiacExpr, b::SymbolicConstant) = a * b.ref[]
Base.:/(a::SymbolicConstant, b::GiacExpr) = a.ref[] / b
Base.:/(a::GiacExpr, b::SymbolicConstant) = a / b.ref[]
Base.:^(a::SymbolicConstant, b::GiacExpr) = a.ref[] ^ b
Base.:^(a::GiacExpr, b::SymbolicConstant) = a ^ b.ref[]

# Arithmetic operators: SymbolicConstant with SymbolicConstant
Base.:+(a::SymbolicConstant, b::SymbolicConstant) = a.ref[] + b.ref[]
Base.:-(a::SymbolicConstant, b::SymbolicConstant) = a.ref[] - b.ref[]
Base.:*(a::SymbolicConstant, b::SymbolicConstant) = a.ref[] * b.ref[]
Base.:/(a::SymbolicConstant, b::SymbolicConstant) = a.ref[] / b.ref[]
Base.:^(a::SymbolicConstant, b::SymbolicConstant) = a.ref[] ^ b.ref[]

# Arithmetic operators: SymbolicConstant with Number
Base.:+(a::SymbolicConstant, b::Number) = a.ref[] + convert(GiacExpr, b)
Base.:+(a::Number, b::SymbolicConstant) = convert(GiacExpr, a) + b.ref[]
Base.:-(a::SymbolicConstant, b::Number) = a.ref[] - convert(GiacExpr, b)
Base.:-(a::Number, b::SymbolicConstant) = convert(GiacExpr, a) - b.ref[]
Base.:*(a::SymbolicConstant, b::Number) = a.ref[] * convert(GiacExpr, b)
Base.:*(a::Number, b::SymbolicConstant) = convert(GiacExpr, a) * b.ref[]
Base.:/(a::SymbolicConstant, b::Number) = a.ref[] / convert(GiacExpr, b)
Base.:/(a::Number, b::SymbolicConstant) = convert(GiacExpr, a) / b.ref[]
Base.:^(a::SymbolicConstant, b::Number) = a.ref[] ^ convert(GiacExpr, b)
Base.:^(a::Number, b::SymbolicConstant) = convert(GiacExpr, a) ^ b.ref[]
Base.:^(a::SymbolicConstant, b::Integer) = a.ref[] ^ b

# Comparison operators
Base.:(==)(a::SymbolicConstant, b::GiacExpr) = a.ref[] == b
Base.:(==)(a::GiacExpr, b::SymbolicConstant) = a == b.ref[]
Base.:(==)(a::SymbolicConstant, b::SymbolicConstant) = a.ref[] == b.ref[]
Base.:(==)(a::SymbolicConstant, b::Number) = a.ref[] == convert(GiacExpr, b)
Base.:(==)(a::Number, b::SymbolicConstant) = convert(GiacExpr, a) == b.ref[]

# Equation operator (~)
Base.:~(a::SymbolicConstant, b::GiacExpr) = a.ref[] ~ b
Base.:~(a::GiacExpr, b::SymbolicConstant) = a ~ b.ref[]
Base.:~(a::SymbolicConstant, b::SymbolicConstant) = a.ref[] ~ b.ref[]
Base.:~(a::SymbolicConstant, b::Number) = a.ref[] ~ convert(GiacExpr, b)
Base.:~(a::Number, b::SymbolicConstant) = convert(GiacExpr, a) ~ b.ref[]

"""
    pi

The circle constant π as a symbolic GiacExpr.

# Example
```julia
using Giac
using Giac.Constants: pi

2 * pi  # Returns GiacExpr: 2*pi (symbolic, not float!)
sin(pi) # Returns GiacExpr: 0 (exact)
```
"""
const pi = SymbolicConstant(_pi)

"""
    e

Euler's number ℯ (base of natural logarithm) as a symbolic GiacExpr.

# Example
```julia
using Giac
using Giac.Constants: e

log(e)    # Returns GiacExpr: 1 (exact)
e^2       # Returns GiacExpr: e^2 (symbolic)
```
"""
const e = SymbolicConstant(_e)

"""
    i

The imaginary unit √(-1) as a symbolic GiacExpr.

# Example
```julia
using Giac
using Giac.Constants: i, pi, e

i^2           # Returns GiacExpr: -1
e^(i * pi)    # Returns GiacExpr: -1 (Euler's formula)
```
"""
const i = SymbolicConstant(_i)

# Export the constants
export pi, e, i

"""
    _init_constants()

Internal function to initialize the Constants module's symbolic values.
Called by Giac.__init__() after GIAC library is initialized.
"""
function _init_constants()
    _pi[] = giac_eval("pi")
    _e[] = giac_eval("e")
    _i[] = giac_eval("i")
end

end # module Constants
