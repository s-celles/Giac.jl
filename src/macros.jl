# Macro definitions for Giac.jl
# Feature: 011-giac-symbol-macro
# Feature: 012-giac-several-var

# Helper functions for @giac_several_vars

"""
    _needs_separator(dims) -> Bool

Check if any dimension exceeds 9, requiring underscore separators in variable names.
When any dimension > 9, indices could be >= 10 and need separators for clarity.
"""
function _needs_separator(dims)
    return any(d -> d > 9, dims)
end

"""
    _format_indices(base::Symbol, indices::Tuple, needs_sep::Bool) -> Symbol

Generate a variable name from base name and indices.
If needs_sep is true, uses underscore separators (e.g., `a_1_10_3`).
Otherwise, concatenates indices directly (e.g., `a123`).
"""
function _format_indices(base::Symbol, indices::Tuple, needs_sep::Bool)
    if needs_sep
        return Symbol(base, "_", join(indices, "_"))
    else
        return Symbol(base, join(indices))
    end
end

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

"""
    @giac_several_vars base dims...

Create multiple indexed symbolic variables for N-dimensional tensors.

This macro generates multiple `GiacExpr` variables in the calling scope
with names formed from a base name and indices. It supports any number
of dimensions and returns a tuple of all created variables.

# Arguments
- `base`: Symbol - The base name for variables (e.g., `a`, `coeff`, `α`)
- `dims...`: Integer literals - Dimensions of the tensor (1 or more)

# Returns
- `Tuple{GiacExpr...}`: A tuple containing all created variables in lexicographic order

# Naming Convention
- If all dimensions ≤ 9: indices are concatenated directly (e.g., `a123`)
- If any dimension > 9: underscore separators are used (e.g., `a_1_10_3`)

# Examples

1D vector:
```julia
@giac_several_vars a 3
# Creates: a1, a2, a3 and returns (a1, a2, a3)
a1 + a2 + a3  # Symbolic sum

# Capture return value
vars = @giac_several_vars c 4
length(vars)  # 4
```

2D matrix:
```julia
result = @giac_several_vars m 2 3
# Creates: m11, m12, m13, m21, m22, m23
# Returns: (m11, m12, m13, m21, m22, m23)
length(result)  # 6
```

3D tensor:
```julia
@giac_several_vars t 2 2 2
# Creates: t111, t112, t121, t122, t211, t212, t221, t222
# Returns tuple of 8 variables
```

Large dimensions (separator used):
```julia
@giac_several_vars b 2 10 3
# Creates: b_1_1_1, b_1_1_2, ..., b_2_10_3
```

Unicode base names:
```julia
@giac_several_vars α 2
# Creates: α1, α2
```

Edge cases:
```julia
@giac_several_vars x 0     # Returns empty tuple ()
@giac_several_vars y 1     # Creates y1, returns (y1,)
@giac_several_vars z 2 0   # Returns empty tuple (0 in any dim)
```

# See also
- [`@giac_var`](@ref): For creating single symbolic variables
- [`giac_eval`](@ref): For evaluating string expressions
"""
macro giac_several_vars(base, dims...)
    # Validate base name is a symbol
    if !(base isa Symbol)
        throw(ArgumentError("First argument must be a symbol (base name), got $(typeof(base)): $base"))
    end

    # Validate at least one dimension is provided
    if isempty(dims)
        throw(ArgumentError("At least one dimension required"))
    end

    # Validate all dimensions are integers and non-negative
    for d in dims
        if !(d isa Integer)
            throw(ArgumentError("Dimensions must be integer literals, got $(typeof(d)): $d"))
        end
        if d < 0
            throw(ArgumentError("Dimensions must be non-negative, got $d"))
        end
    end

    # If any dimension is 0, generate no variables, return empty tuple
    if any(d -> d == 0, dims)
        return :(())
    end

    # Determine if we need underscore separators
    needs_sep = _needs_separator(dims)

    # Generate all index combinations using Iterators.product
    # Reverse ranges so that Iterators.product gives row-major order (last dim varies fastest)
    # Then reverse each tuple back to original dimension order
    ranges = reverse([1:d for d in dims])
    index_combinations = (reverse(t) for t in Iterators.product(ranges...))

    # Generate assignment expressions for each variable
    exprs = Expr[]
    varnames = Symbol[]
    for indices in index_combinations
        varname = _format_indices(base, indices, needs_sep)
        push!(varnames, varname)
        push!(exprs, :($(esc(varname)) = giac_eval($(string(varname)))))
    end

    # Return tuple of created variables
    result = Expr(:tuple, [esc(v) for v in varnames]...)
    return Expr(:block, exprs..., result)
end
