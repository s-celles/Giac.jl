# Tables.jl interface implementation for Giac.jl
# Feature: 025-tables-compatibility
#
# Provides Tables.jl compatibility for:
# - GiacMatrix: Row/column access, schema, DataFrame/CSV integration
# - HelpResult: Single-row table with command documentation
# - CommandsTable: Cached collection of all GIAC command help

using Tables

# ============================================================================
# GiacMatrix Tables.jl Support Types
# ============================================================================

"""
    GiacMatrixRows

Row iterator for GiacMatrix Tables.jl interface.

Used internally by `Tables.rows(matrix)` to provide row-wise iteration.
"""
struct GiacMatrixRows
    matrix::GiacMatrix
    names::NTuple{N, Symbol} where N
end

"""
    GiacMatrixRow

Single row representation for GiacMatrix Tables.jl interface.

Provides access to row values via `Tables.getcolumn`.
"""
struct GiacMatrixRow
    matrix::GiacMatrix
    row::Int
    names::NTuple{N, Symbol} where N
end

"""
    GiacMatrixColumns

Column accessor for GiacMatrix Tables.jl interface.

Used internally by `Tables.columns(matrix)` to provide column-wise access.
"""
struct GiacMatrixColumns
    matrix::GiacMatrix
    names::NTuple{N, Symbol} where N
end

# ============================================================================
# HelpResult Tables.jl Support Types
# ============================================================================

"""
    HelpResultRows

Single-row iterator for HelpResult Tables.jl interface.

Used internally by `Tables.rows(help_result)` to provide row-wise iteration.
"""
struct HelpResultRows
    result::HelpResult
end

"""
    HelpResultRow

Single row representation for HelpResult Tables.jl interface.

Provides access to help fields via `Tables.getcolumn`.
"""
struct HelpResultRow
    result::HelpResult
end

# ============================================================================
# CommandsTable Types
# ============================================================================

"""
    CommandRow

Named tuple type for CommandsTable rows.

# Fields
- `command::String`: Command name
- `category::String`: Category (e.g., "algebra", "trigonometry", "other")
- `description::String`: Command description
- `related::String`: Comma-separated related commands
- `examples::String`: Semicolon-separated examples
"""
const CommandRow = NamedTuple{
    (:command, :category, :description, :related, :examples),
    Tuple{String, String, String, String, String}
}

"""
    CommandsTable

Cached collection of all GIAC command help as Tables.jl source.

Created by `commands_table()`. Contains pre-collected help information
for all available GIAC commands.

# Example
```julia
using DataFrames

ct = commands_table()
df = DataFrame(ct)
filter(row -> row.category == "algebra", df)
```
"""
struct CommandsTable
    rows::Vector{CommandRow}
end

"""
Module-level cache for CommandsTable.

Initialized to `nothing`, populated on first `commands_table()` call.
"""
const _commands_table_cache = Ref{Union{Nothing, CommandsTable}}(nothing)

# ============================================================================
# Helper Functions
# ============================================================================

"""
    _generate_column_names(n::Int) -> NTuple{N, Symbol}

Generate column names `:col1`, `:col2`, ..., `:colN` for a matrix with n columns.
"""
function _generate_column_names(n::Int)
    return ntuple(i -> Symbol("col$i"), n)
end

"""
    _cell_to_value(expr::GiacExpr)

Convert a GiacExpr cell value to a Julia type for table representation.

Returns the string representation of the expression.
"""
function _cell_to_value(expr::GiacExpr)
    return string(expr)
end

"""
    _serialize_related(related::Vector{String}) -> String

Serialize the `related` field as a comma-separated string.

# Example
```julia
_serialize_related(["ifactor", "partfrac", "normal"])
# "ifactor, partfrac, normal"
```
"""
function _serialize_related(related::Vector{String})::String
    return join(related, ", ")
end

"""
    _serialize_examples(examples::Vector{String}) -> String

Serialize the `examples` field as a semicolon-separated string.

# Example
```julia
_serialize_examples(["factor(x^4-1)", "factor(x^4-4,sqrt(2))"])
# "factor(x^4-1); factor(x^4-4,sqrt(2))"
```
"""
function _serialize_examples(examples::Vector{String})::String
    return join(examples, "; ")
end

"""
    _get_category(cmd::String) -> String

Get the category for a command from CATEGORY_LOOKUP, defaulting to "other".
"""
function _get_category(cmd::String)::String
    cmd_sym = Symbol(cmd)
    category = get(CATEGORY_LOOKUP, cmd_sym, :other)
    return string(category)
end

# ============================================================================
# Schema Constants
# ============================================================================

"""
Fixed schema for HelpResult and CommandsTable.
"""
const HELP_RESULT_SCHEMA = Tables.Schema(
    (:command, :category, :description, :related, :examples),
    (String, String, String, String, String)
)

# ============================================================================
# GiacMatrix Tables.jl Interface
# ============================================================================

# Core interface declarations
Tables.istable(::Type{<:GiacMatrix}) = true
Tables.rowaccess(::Type{<:GiacMatrix}) = true
Tables.columnaccess(::Type{<:GiacMatrix}) = true

"""
    Tables.schema(m::GiacMatrix)

Return the schema for a GiacMatrix with auto-generated column names.
"""
function Tables.schema(m::GiacMatrix)
    names = _generate_column_names(m.cols)
    types = ntuple(_ -> Any, m.cols)
    return Tables.Schema(names, types)
end

"""
    Tables.rows(m::GiacMatrix)

Return a row iterator for the GiacMatrix.
"""
function Tables.rows(m::GiacMatrix)
    names = _generate_column_names(m.cols)
    return GiacMatrixRows(m, names)
end

"""
    Tables.columns(m::GiacMatrix)

Return a column accessor for the GiacMatrix.
"""
function Tables.columns(m::GiacMatrix)
    names = _generate_column_names(m.cols)
    return GiacMatrixColumns(m, names)
end

# ============================================================================
# GiacMatrixRows Iteration
# ============================================================================

Base.length(rows::GiacMatrixRows) = rows.matrix.rows
Base.eltype(::Type{<:GiacMatrixRows}) = GiacMatrixRow

function Base.iterate(rows::GiacMatrixRows, state::Int=1)
    if state > rows.matrix.rows
        return nothing
    end
    row = GiacMatrixRow(rows.matrix, state, rows.names)
    return (row, state + 1)
end

# ============================================================================
# GiacMatrixRow Tables.jl Interface
# ============================================================================

function Tables.getcolumn(row::GiacMatrixRow, i::Int)
    return _cell_to_value(row.matrix[row.row, i])
end

function Tables.getcolumn(row::GiacMatrixRow, nm::Symbol)
    # Parse column name like :col1 -> 1
    nm_str = string(nm)
    if startswith(nm_str, "col")
        i = parse(Int, nm_str[4:end])
        return _cell_to_value(row.matrix[row.row, i])
    end
    throw(ArgumentError("Unknown column name: $nm"))
end

Tables.columnnames(row::GiacMatrixRow) = row.names

# ============================================================================
# GiacMatrixColumns Tables.jl Interface
# ============================================================================

function Tables.getcolumn(cols::GiacMatrixColumns, i::Int)
    m = cols.matrix
    return [_cell_to_value(m[r, i]) for r in 1:m.rows]
end

function Tables.getcolumn(cols::GiacMatrixColumns, nm::Symbol)
    nm_str = string(nm)
    if startswith(nm_str, "col")
        i = parse(Int, nm_str[4:end])
        return Tables.getcolumn(cols, i)
    end
    throw(ArgumentError("Unknown column name: $nm"))
end

Tables.columnnames(cols::GiacMatrixColumns) = cols.names

# ============================================================================
# HelpResult Tables.jl Interface
# ============================================================================

Tables.istable(::Type{HelpResult}) = true
Tables.rowaccess(::Type{HelpResult}) = true

Tables.schema(::HelpResult) = HELP_RESULT_SCHEMA

function Tables.rows(hr::HelpResult)
    return HelpResultRows(hr)
end

# ============================================================================
# HelpResultRows Iteration
# ============================================================================

Base.length(::HelpResultRows) = 1
Base.eltype(::Type{HelpResultRows}) = HelpResultRow

function Base.iterate(rows::HelpResultRows, state::Int=1)
    if state > 1
        return nothing
    end
    return (HelpResultRow(rows.result), 2)
end

# ============================================================================
# HelpResultRow Tables.jl Interface
# ============================================================================

function Tables.getcolumn(row::HelpResultRow, i::Int)
    hr = row.result
    if i == 1
        return hr.command
    elseif i == 2
        return _get_category(hr.command)
    elseif i == 3
        return hr.description
    elseif i == 4
        return _serialize_related(hr.related)
    elseif i == 5
        return _serialize_examples(hr.examples)
    else
        throw(BoundsError("Column index $i out of bounds (1-5)"))
    end
end

function Tables.getcolumn(row::HelpResultRow, nm::Symbol)
    hr = row.result
    if nm === :command
        return hr.command
    elseif nm === :category
        return _get_category(hr.command)
    elseif nm === :description
        return hr.description
    elseif nm === :related
        return _serialize_related(hr.related)
    elseif nm === :examples
        return _serialize_examples(hr.examples)
    else
        throw(ArgumentError("Unknown column name: $nm"))
    end
end

Tables.columnnames(::HelpResultRow) = (:command, :category, :description, :related, :examples)

# ============================================================================
# CommandsTable Tables.jl Interface
# ============================================================================

Tables.istable(::Type{CommandsTable}) = true
Tables.rowaccess(::Type{CommandsTable}) = true

Tables.schema(::CommandsTable) = HELP_RESULT_SCHEMA

Tables.rows(ct::CommandsTable) = ct.rows

# ============================================================================
# CommandsTable Collection and Caching
# ============================================================================

"""
    _collect_all_commands() -> CommandsTable

Collect help information for all GIAC commands into a CommandsTable.

This function iterates over all valid commands, retrieves their help,
and constructs CommandRow entries. Commands without help documentation
are included with empty description/related/examples fields.

# Returns
- `CommandsTable`: Collection of all command help information
"""
function _collect_all_commands()::CommandsTable
    rows = CommandRow[]

    # Get all valid commands (including operators)
    for cmd_sym in VALID_COMMANDS
        cmd_str = string(cmd_sym)

        try
            hr = help(cmd_sym)

            # Include all commands, even those without help
            description = hr.description
            if startswith(description, "[No help found")
                description = ""
            end

            row = CommandRow((
                command = hr.command,
                category = _get_category(hr.command),
                description = description,
                related = _serialize_related(hr.related),
                examples = _serialize_examples(hr.examples)
            ))
            push!(rows, row)
        catch e
            @debug "Skipping command $cmd_str: $e"
        end
    end

    # Sort by command name
    sort!(rows, by = r -> r.command)

    return CommandsTable(rows)
end

"""
    commands_table() -> CommandsTable

Return a Tables.jl-compatible collection of all GIAC command help.

Results are cached after the first call for performance. Use
`clear_commands_cache!()` to invalidate the cache.

# Example
```julia
using DataFrames

# Get all commands as DataFrame
df = DataFrame(commands_table())

# Filter by category
algebra_cmds = filter(row -> row.category == "algebra", df)

# Export to CSV
using CSV
CSV.write("giac_commands.csv", commands_table())
```

# See also
- [`clear_commands_cache!`](@ref): Invalidate the cache
- [`help`](@ref): Get help for a single command
"""
function commands_table()::CommandsTable
    if _commands_table_cache[] === nothing
        _commands_table_cache[] = _collect_all_commands()
    end
    return _commands_table_cache[]
end

"""
    clear_commands_cache!()

Clear the cached CommandsTable, forcing re-collection on next `commands_table()` call.

# Example
```julia
ct1 = commands_table()  # Collects all commands
clear_commands_cache!()
ct2 = commands_table()  # Re-collects all commands
```

# See also
- [`commands_table`](@ref): Get the commands table
"""
function clear_commands_cache!()
    _commands_table_cache[] = nothing
    return nothing
end
