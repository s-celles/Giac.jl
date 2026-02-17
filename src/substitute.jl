# Substitute function for GiacExpr (028-substitute-mechanism)
# Provides Symbolics.jl-compatible substitute(expr, Dict(...)) interface

# ============================================================================
# Internal Helper Functions
# ============================================================================

"""
    _build_subst_command(expr_str::String, vars::Vector{String}, vals::Vector{String}) -> String

Build GIAC subst command string for evaluation.

Internal function that constructs the appropriate GIAC syntax:
- Single variable: `subst(expr, var, val)`
- Multiple variables: `subst(expr, [v1,v2,...], [val1,val2,...])`

# Arguments
- `expr_str`: String representation of the expression
- `vars`: Vector of variable name strings
- `vals`: Vector of value strings

# Returns
- `String`: GIAC command ready for evaluation
"""
function _build_subst_command(expr_str::String, vars::Vector{String}, vals::Vector{String})::String
    if length(vars) != length(vals)
        throw(ArgumentError("Number of variables ($(length(vars))) must match number of values ($(length(vals)))"))
    end

    if length(vars) == 0
        # Empty substitution - return expression unchanged
        return expr_str
    elseif length(vars) == 1
        # Single variable: subst(expr, var, val)
        return "subst($(expr_str), $(vars[1]), $(vals[1]))"
    else
        # Multiple variables: subst(expr, [vars], [vals])
        vars_list = "[" * join(vars, ",") * "]"
        vals_list = "[" * join(vals, ",") * "]"
        return "subst($(expr_str), $(vars_list), $(vals_list))"
    end
end

# ============================================================================
# Public API: substitute function
# ============================================================================

"""
    substitute(expr::GiacExpr, dict::AbstractDict{<:GiacExpr}) -> GiacExpr

Substitute variables in a symbolic expression according to a dictionary mapping.

Performs simultaneous substitution of all variables in `dict`. The original
expression is not modified.

# Arguments
- `expr::GiacExpr`: The expression to transform
- `dict::AbstractDict`: Mapping from variables (GiacExpr) to replacement values

# Returns
- `GiacExpr`: New expression with substitutions applied

# Examples
```julia
@giac_var x y
expr = x^2 + y
substitute(expr, Dict(x => 2))        # Returns: 4 + y
substitute(expr, Dict(x => 2, y => 3)) # Returns: 7
substitute(expr, Dict(x => y, y => x)) # Swaps x and y: y^2 + x
```

# See also
- [`invoke_cmd`](@ref): Lower-level command invocation
- [`@giac_var`](@ref): Create symbolic variables
"""
function substitute(expr::GiacExpr, dict::AbstractDict{<:GiacExpr})::GiacExpr
    # Handle empty Dict - return original expression unchanged
    if isempty(dict)
        return expr
    end

    # Convert Dict to parallel arrays of variable and value strings
    vars = String[]
    vals = String[]

    for (var, val) in dict
        push!(vars, string(var))
        push!(vals, _arg_to_giac_string(val))
    end

    # Build and execute the GIAC subst command
    expr_str = string(expr)
    cmd_str = _build_subst_command(expr_str, vars, vals)

    return with_giac_lock() do
        giac_eval(cmd_str)
    end
end

"""
    substitute(expr::GiacExpr, pair::Pair{<:GiacExpr}) -> GiacExpr

Substitute a single variable using Pair syntax.

Convenience method equivalent to `substitute(expr, Dict(pair))`.

# Examples
```julia
@giac_var x
substitute(x + 1, x => 5)  # Returns: 6
```

# See also
- [`substitute(::GiacExpr, ::AbstractDict)`](@ref): Full Dict-based substitution
"""
function substitute(expr::GiacExpr, pair::Pair{<:GiacExpr})::GiacExpr
    return substitute(expr, Dict(pair))
end

# ============================================================================
# GiacMatrix Support: Element-wise Substitution
# ============================================================================

"""
    substitute(m::GiacMatrix, dict::AbstractDict{<:GiacExpr}) -> GiacMatrix

Substitute variables in each element of a symbolic matrix.

Performs element-wise substitution, applying the same variable mappings
to every element of the matrix. Returns a new matrix with the same dimensions.

# Arguments
- `m::GiacMatrix`: The matrix to transform
- `dict::AbstractDict`: Mapping from variables (GiacExpr) to replacement values

# Returns
- `GiacMatrix`: New matrix with substitutions applied element-wise

# Examples
```julia
@giac_var x y
M = GiacMatrix([x+1 2*x; y x*y])
substitute(M, Dict(x => 2))        # Returns matrix with x=2 substituted
substitute(M, Dict(x => 2, y => 3)) # Returns fully numeric matrix
```

# See also
- [`substitute(::GiacExpr, ::AbstractDict)`](@ref): Scalar expression substitution
"""
function substitute(m::GiacMatrix, dict::AbstractDict{<:GiacExpr})::GiacMatrix
    # Handle empty Dict - return a copy of the matrix
    if isempty(dict)
        # Create a new matrix with the same elements
        result = Matrix{Any}(undef, m.rows, m.cols)
        for i in 1:m.rows
            for j in 1:m.cols
                result[i, j] = m[i, j]
            end
        end
        return GiacMatrix(result)
    end

    # Apply substitute element-wise
    result = Matrix{Any}(undef, m.rows, m.cols)
    for i in 1:m.rows
        for j in 1:m.cols
            result[i, j] = substitute(m[i, j], dict)
        end
    end

    return GiacMatrix(result)
end

"""
    substitute(m::GiacMatrix, pair::Pair{<:GiacExpr}) -> GiacMatrix

Substitute a single variable in each element of a matrix using Pair syntax.

Convenience method equivalent to `substitute(m, Dict(pair))`.

# Examples
```julia
@giac_var x
M = GiacMatrix([x 2*x; x+1 x^2])
substitute(M, x => 3)  # Returns: [[3, 6], [4, 9]]
```

# See also
- [`substitute(::GiacMatrix, ::AbstractDict)`](@ref): Full Dict-based matrix substitution
"""
function substitute(m::GiacMatrix, pair::Pair{<:GiacExpr})::GiacMatrix
    return substitute(m, Dict(pair))
end
