# Command registry for Giac.jl
# Metadata, categories, discovery, and validation for GIAC commands

# ============================================================================
# CommandInfo Type
# ============================================================================

"""
    CommandInfo

Metadata about a single GIAC command.

# Fields
- `name::String`: Command name (e.g., "factor", "sin")
- `category::Symbol`: Primary category (e.g., `:algebra`, `:trigonometry`)
- `aliases::Vector{String}`: Alternative names for the command
- `doc::String`: Documentation string from GIAC help system

# Example
```julia
info = command_info(:factor)
println(info.name)      # "factor"
println(info.category)  # :algebra
```
"""
struct CommandInfo
    name::String
    category::Symbol
    aliases::Vector{String}
    doc::String
end

# ============================================================================
# Command Categories
# ============================================================================

"""
    COMMAND_CATEGORIES

Dictionary mapping category symbols to lists of command names.
Categories are based on mathematical domains.
"""
const COMMAND_CATEGORIES = Dict{Symbol, Vector{String}}(
    :trigonometry => [
        "sin", "cos", "tan", "asin", "acos", "atan", "atan2",
        "sinh", "cosh", "tanh", "asinh", "acosh", "atanh",
        "cot", "sec", "csc", "acot", "asec", "acsc",
        "sinc", "sincos"
    ],
    :calculus => [
        "diff", "integrate", "int", "limit", "series", "taylor",
        "derivative", "antiderivative", "gradient", "divergence", "curl",
        "laplacian", "hessian", "jacobian"
    ],
    :algebra => [
        "factor", "expand", "simplify", "solve", "gcd", "lcm",
        "collect", "normal", "ratnormal", "horner", "canonical_form",
        "quo", "rem", "quorem", "proot", "cfactor"
    ],
    :number_theory => [
        "ifactor", "isprime", "nextprime", "prevprime", "euler", "phi",
        "gcd", "lcm", "mod", "irem", "iquo", "isqrt", "icrt",
        "chinese", "jacobi", "legendre", "divisors", "sigma"
    ],
    :linear_algebra => [
        "det", "inv", "trace", "transpose", "tran", "eigenvalues", "eigenvectors",
        "rank", "kernel", "image", "lu", "qr", "svd", "cholesky",
        "rref", "identity", "diag", "jordanblock"
    ],
    :special_functions => [
        "gamma", "beta", "erf", "erfc", "zeta", "Ai", "Bi",
        "Si", "Ci", "Ei", "li", "digamma", "polygamma",
        "BesselJ", "BesselY", "BesselI", "BesselK"
    ],
    :polynomials => [
        "degree", "coeff", "lcoeff", "tcoeff", "coeffs", "roots",
        "pcoeff", "poly2symb", "symb2poly", "resultant", "discriminant",
        "sturm", "sturmab", "realroot"
    ],
    :combinatorics => [
        "binomial", "factorial", "perm", "comb", "fib", "fibonacci",
        "lucas", "stirling1", "stirling2", "bell", "catalan",
        "partition", "compositions"
    ],
    :statistics => [
        "mean", "variance", "stddev", "median", "quartiles",
        "covariance", "correlation", "histogram", "boxwhisker",
        "normald", "binomial_cdf", "poisson"
    ],
    :logic => [
        "and", "or", "not", "xor", "implies", "equiv",
        "true", "false", "assume", "about"
    ],
    :geometry => [
        "point", "line", "circle", "polygon", "distance",
        "midpoint", "perpendicular", "parallel", "tangent",
        "inter", "area", "perimeter"
    ],
    :other => String[]  # Populated dynamically for uncategorized commands
)

"""
    CATEGORY_LOOKUP

Reverse lookup: command name → category symbol.
Populated by `_init_command_registry()`.
"""
const CATEGORY_LOOKUP = Dict{String, Symbol}()

# ============================================================================
# Valid Commands Registry
# ============================================================================

"""
    VALID_COMMANDS

Set of all valid GIAC command names. Populated at module initialization
from `list_commands()`.
"""
const VALID_COMMANDS = Set{String}()

"""
    _init_command_registry()

Initialize the command registry at module load time.
Populates VALID_COMMANDS from list_commands() and builds CATEGORY_LOOKUP.
"""
function _init_command_registry()
    # Populate VALID_COMMANDS
    empty!(VALID_COMMANDS)
    for cmd in list_commands()
        if !isempty(cmd)
            push!(VALID_COMMANDS, cmd)
        end
    end

    # Build reverse category lookup
    empty!(CATEGORY_LOOKUP)
    for (category, commands) in COMMAND_CATEGORIES
        for cmd in commands
            CATEGORY_LOOKUP[cmd] = category
        end
    end

    @debug "Command registry initialized with $(length(VALID_COMMANDS)) commands"
end

# ============================================================================
# Discovery Functions
# ============================================================================

"""
    search_commands(pattern::String) -> Vector{String}

Search for commands matching a string prefix.

# Arguments
- `pattern::String`: Prefix to match

# Returns
- `Vector{String}`: List of matching command names, sorted alphabetically

# Example
```julia
search_commands("sin")  # Returns ["sin", "sinc", "sincos", "sinh", ...]
```
"""
function search_commands(pattern::String)::Vector{String}
    results = String[]
    for cmd in VALID_COMMANDS
        if startswith(cmd, pattern)
            push!(results, cmd)
        end
    end
    return sort(results)
end

"""
    search_commands(pattern::Regex) -> Vector{String}

Search for commands matching a regular expression.

# Arguments
- `pattern::Regex`: Regular expression to match

# Returns
- `Vector{String}`: List of matching command names, sorted alphabetically

# Example
```julia
search_commands(r"^a.*n\$")  # Returns commands starting with 'a' and ending with 'n'
```
"""
function search_commands(pattern::Regex)::Vector{String}
    results = String[]
    for cmd in VALID_COMMANDS
        if occursin(pattern, cmd)
            push!(results, cmd)
        end
    end
    return sort(results)
end

"""
    list_categories() -> Vector{Symbol}

List all available command categories.

# Returns
- `Vector{Symbol}`: Category names, sorted alphabetically

# Example
```julia
cats = list_categories()
# [:algebra, :calculus, :combinatorics, :geometry, ...]
```
"""
function list_categories()::Vector{Symbol}
    return sort(collect(keys(COMMAND_CATEGORIES)))
end

"""
    commands_in_category(category::Symbol) -> Vector{String}

Get all commands in a specific category.

# Arguments
- `category::Symbol`: Category name (e.g., `:trigonometry`, `:algebra`)

# Returns
- `Vector{String}`: List of command names in the category, sorted alphabetically

# Throws
- `ArgumentError`: If the category does not exist

# Example
```julia
trig = commands_in_category(:trigonometry)
# ["acos", "asin", "atan", "cos", "sin", "tan", ...]
```
"""
function commands_in_category(category::Symbol)::Vector{String}
    if !haskey(COMMAND_CATEGORIES, category)
        valid_cats = join(sort(collect(keys(COMMAND_CATEGORIES))), ", ")
        throw(ArgumentError("Unknown category: $category. Valid categories: $valid_cats"))
    end
    return sort(copy(COMMAND_CATEGORIES[category]))
end

"""
    command_info(cmd::Symbol) -> Union{CommandInfo, Nothing}

Get metadata about a specific command.

# Arguments
- `cmd::Symbol`: Command name

# Returns
- `CommandInfo`: Metadata about the command
- `nothing`: If the command is not found

# Example
```julia
info = command_info(:factor)
if info !== nothing
    println(info.name)      # "factor"
    println(info.category)  # :algebra
end
```
"""
function command_info(cmd::Symbol)::Union{CommandInfo, Nothing}
    cmd_str = string(cmd)

    if cmd_str ∉ VALID_COMMANDS && !isempty(VALID_COMMANDS)
        return nothing
    end

    # Lookup category
    category = get(CATEGORY_LOOKUP, cmd_str, :other)

    # Get documentation from GIAC help system
    doc = giac_help(cmd)

    return CommandInfo(cmd_str, category, String[], doc)
end

"""
    giac_help(cmd::Union{Symbol, String}) -> String

Get GIAC help text for a command.

# Arguments
- `cmd`: Command name as Symbol or String

# Returns
- `String`: Help text from GIAC, or empty string if not found

# Example
```julia
help = giac_help(:factor)
println(help)  # "factor(Expr) - Factor a polynomial..."
```
"""
function giac_help(cmd::Union{Symbol, String})::String
    cmd_str = string(cmd)

    if is_stub_mode()
        return ""
    end

    # Use giac_eval to get help
    try
        result = with_giac_lock() do
            giac_eval("help($cmd_str)")
        end
        return string(result)
    catch
        return ""
    end
end
