# Macro definitions for Giac.jl
# Feature: 011-giac-symbol-macro

"""
    @giac sym...

Create symbolic variables from Julia symbols.

Creates `GiacExpr` variables in the calling scope by internally calling
`giac_eval` with the stringified symbol name. This provides a cleaner
syntax for variable declaration similar to `@variables` in Symbolics.jl.

# Examples

Single variable:
```julia
@giac x           # Creates x as a GiacExpr
string(x)         # "x"
x isa GiacExpr    # true
```

Multiple variables:
```julia
@giac x y z       # Creates x, y, z as GiacExpr variables
```

# Usage
```julia
using Giac

@giac x y
expr = giac_eval("x^2 + y^2")
result = giac_diff(expr, x)  # 2*x
```

# See also
- [`giac_eval`](@ref): For evaluating string expressions
"""
macro giac(syms...)
    # T029: Validate at least one argument
    if isempty(syms)
        throw(ArgumentError("@giac requires at least one symbol argument"))
    end

    # T030-T031: Validate all arguments are symbols
    for sym in syms
        if !(sym isa Symbol)
            if sym isa String
                throw(ArgumentError("@giac arguments must be symbols, not strings. Use giac_eval(\"$sym\") instead."))
            else
                throw(ArgumentError("@giac arguments must be symbols, got $(typeof(sym)): $sym"))
            end
        end
    end

    # Generate assignment expressions for each symbol
    exprs = [:($(esc(sym)) = giac_eval($(string(sym)))) for sym in syms]

    # Return tuple of created variables
    result = Expr(:tuple, [esc(sym) for sym in syms]...)

    return Expr(:block, exprs..., result)
end
