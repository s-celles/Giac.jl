# Macro definitions for Giac.jl
# Feature: 011-giac-symbol-macro

"""
    @giac_var sym...

Create symbolic variables from Julia symbols.

Creates `GiacExpr` variables in the calling scope by internally calling
`giac_eval` with the stringified symbol name. This provides a cleaner
syntax for variable declaration similar to `@variables` in Symbolics.jl.

# Examples

Single variable:
```julia
@giac_var x           # Creates x as a GiacExpr
string(x)             # "x"
x isa GiacExpr        # true
```

Multiple variables:
```julia
@giac_var x y z       # Creates x, y, z as GiacExpr variables
```

# Usage
```julia
using Giac

@giac_var x y
expr = giac_eval("x^2 + y^2")
result = giac_diff(expr, x)  # 2*x
```

# See also
- [`giac_eval`](@ref): For evaluating string expressions
"""
macro giac_var(syms...)
    # Validate at least one argument
    if isempty(syms)
        throw(ArgumentError("@giac_var requires at least one symbol argument"))
    end

    # Validate all arguments are symbols
    for sym in syms
        if !(sym isa Symbol)
            if sym isa String
                throw(ArgumentError("@giac_var arguments must be symbols, not strings. Use giac_eval(\"$sym\") instead."))
            else
                throw(ArgumentError("@giac_var arguments must be symbols, got $(typeof(sym)): $sym"))
            end
        end
    end

    # Generate assignment expressions for each symbol
    exprs = [:($(esc(sym)) = giac_eval($(string(sym)))) for sym in syms]

    # Return tuple of created variables
    result = Expr(:tuple, [esc(sym) for sym in syms]...)

    return Expr(:block, exprs..., result)
end
