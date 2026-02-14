# Command registry for Giac.jl
# Metadata, categories, discovery, and validation for GIAC commands

# ============================================================================
# HelpResult Type (004-formatted-help-output)
# ============================================================================

"""
    HelpResult

A structured representation of parsed GIAC command help information.

# Fields
- `command::String`: The command name being documented
- `description::String`: Description text from GIAC help
- `related::Vector{String}`: List of related command names
- `examples::Vector{String}`: List of individual example expressions

# Example
```julia
result = help(:factor)
result.command      # "factor"
result.description  # "Factorizes a polynomial."
result.related      # ["ifactor", "partfrac", "normal"]
result.examples     # ["factor(x^4-1)", "factor(x^4-4,sqrt(2))", ...]
```

# See also
- [`help`](@ref): Get formatted help for a command
- [`giac_help`](@ref): Get raw help string
"""
struct HelpResult
    command::String
    description::String
    related::Vector{String}
    examples::Vector{String}
end

# ============================================================================
# HelpResult Display Methods (004-formatted-help-output)
# ============================================================================

"""
    Base.show(io::IO, ::MIME"text/plain", result::HelpResult)

Formatted multi-line display for REPL and notebooks.
"""
function Base.show(io::IO, ::MIME"text/plain", result::HelpResult)
    # Command name with Unicode underline
    println(io, result.command)
    println(io, repeat('═', length(result.command)))
    println(io)

    # Description section
    if isempty(result.description)
        println(io, "Description:")
        println(io, "  [No description available]")
    else
        println(io, "Description:")
        println(io, "  ", result.description)
    end

    # Related section (omit if empty)
    if !isempty(result.related)
        println(io)
        println(io, "Related:")
        println(io, "  ", join(result.related, ", "))
    end

    # Examples section (omit if empty)
    if !isempty(result.examples)
        println(io)
        println(io, "Examples:")
        for ex in result.examples
            println(io, "  • ", ex)
        end
    end
end

"""
    Base.show(io::IO, result::HelpResult)

Compact single-line representation.
"""
function Base.show(io::IO, result::HelpResult)
    print(io, "HelpResult(:$(result.command), $(length(result.related)) related, $(length(result.examples)) examples)")
end

# ============================================================================
# HelpResult Parsing (004-formatted-help-output)
# ============================================================================

"""
    _parse_help(raw::String, cmd::String) -> HelpResult

Parse raw GIAC help text into a structured HelpResult.

# Arguments
- `raw`: Raw help text from GIAC
- `cmd`: Command name (for the result)

# Returns
- `HelpResult` with parsed fields

# Parsing Algorithm
1. Extract "Description: ..." line
2. Extract "Related: ..." line and split by ", "
3. Extract "Examples:" section and split by ";"
"""
function _parse_help(raw::String, cmd::String)::HelpResult
    description = ""
    related = String[]
    examples = String[]

    if isempty(raw)
        return HelpResult(cmd, description, related, examples)
    end

    lines = split(raw, '\n')

    for (i, line) in enumerate(lines)
        line_str = String(line)

        # Extract description
        if startswith(line_str, "Description: ")
            description = strip(line_str[14:end])
        # Extract related commands
        elseif startswith(line_str, "Related: ")
            related_str = strip(line_str[10:end])
            if !isempty(related_str)
                related = [strip(r) for r in split(related_str, ",")]
                # Filter out empty entries
                related = filter(!isempty, related)
            end
        # Extract examples
        elseif startswith(line_str, "Examples:")
            # Examples may be on the same line or following lines
            examples_text = strip(line_str[10:end])
            # Also gather any following lines
            for j in (i+1):length(lines)
                next_line = strip(String(lines[j]))
                if !isempty(next_line) && !startswith(next_line, "Description:") && !startswith(next_line, "Related:")
                    examples_text *= next_line
                end
            end
            # Split by semicolon
            if !isempty(examples_text)
                examples = [strip(e) for e in split(examples_text, ";")]
                # Filter out empty entries
                examples = filter(!isempty, examples)
            end
            break  # We've processed examples, which is typically last
        end
    end

    return HelpResult(cmd, description, related, examples)
end

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
        raw_str = string(result)
        # Clean up the string: remove outer quotes and unescape
        return _clean_help_string(raw_str)
    catch
        return ""
    end
end

"""
    _clean_help_string(s::String) -> String

Clean up a GIAC help string by removing outer quotes and unescaping.
"""
function _clean_help_string(s::String)::String
    # Remove outer quotes if present
    if startswith(s, '"') && endswith(s, '"') && length(s) >= 2
        s = s[2:end-1]
    end
    # Unescape common escape sequences
    s = replace(s, "\\n" => "\n")
    s = replace(s, "\\\"" => "\"")
    s = replace(s, "\\\\" => "\\")
    return s
end

"""
    help(cmd::Union{Symbol, String}) -> HelpResult

Get formatted help for a GIAC command.

Returns a `HelpResult` struct containing parsed help information. The result
auto-displays formatted output in the REPL, and provides programmatic access
to individual fields.

# Arguments
- `cmd`: Command name as Symbol or String

# Returns
- `HelpResult`: Structured help information with fields:
  - `command`: Command name
  - `description`: Description text
  - `related`: Vector of related command names
  - `examples`: Vector of example expressions

# Example
```julia
using Giac

# View formatted help (auto-displays)
help(:factor)
# factor
# ══════
#
# Description:
#   Factorizes a polynomial.
#
# Related:
#   ifactor, partfrac, normal
#
# Examples:
#   • factor(x^4-1)
#   • factor(x^4-4,sqrt(2))

# Access help data programmatically
result = help(:factor)
result.description  # "Factorizes a polynomial."
result.examples     # ["factor(x^4-1)", "factor(x^4-4,sqrt(2))", ...]
```

# See also
- [`giac_help`](@ref): Returns raw help string
- [`HelpResult`](@ref): The return type
"""
function help(cmd::Union{Symbol, String})::HelpResult
    cmd_str = string(cmd)
    help_text = giac_help(cmd)

    if isempty(help_text)
        if is_stub_mode()
            return HelpResult(cmd_str, "[Help not available in stub mode]", String[], String[])
        else
            return HelpResult(cmd_str, "[No help found for: $cmd_str]", String[], String[])
        end
    end

    return _parse_help(help_text, cmd_str)
end
