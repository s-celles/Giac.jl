# Tables.jl Compatibility

Giac.jl provides full [Tables.jl](https://github.com/JuliaData/Tables.jl) compatibility, enabling seamless integration with the Julia data ecosystem including DataFrames.jl and CSV.jl.

## GiacMatrix to DataFrame

Convert symbolic matrices to DataFrames for analysis and export:

```julia
using Giac
using DataFrames

# Create a numeric matrix
m = GiacMatrix([1 2 3; 4 5 6])

# Convert to DataFrame
df = DataFrame(m)
# 2×3 DataFrame
#  Row │ col1    col2    col3
#      │ String  String  String
# ─────┼────────────────────────
#    1 │ 1       2       3
#    2 │ 4       5       6
```

### Symbolic Matrices

Symbolic values are converted to strings:

```julia
@giac_var x y
m = GiacMatrix([x y; x+1 y+1])

df = DataFrame(m)
# 2×2 DataFrame
#  Row │ col1    col2
#      │ String  String
# ─────┼────────────────
#    1 │ x       y
#    2 │ x+1     y+1
```

## Row and Column Access

Access data using the Tables.jl interface:

```julia
# Row iteration
for row in Tables.rows(m)
    println(Tables.getcolumn(row, :col1))
end

# Column access
cols = Tables.columns(m)
first_col = Tables.getcolumn(cols, :col1)  # Vector of values
```

## CSV Export

Export matrices directly to CSV files:

```julia
using CSV

m = GiacMatrix(giac_eval("[[1,2,3],[4,5,6]]"))
CSV.write("matrix.csv", m)
```

## Command Help as Tables

### Single Command Help

Convert help information for a single command to a table:

```julia
using Giac
using DataFrames

hr = Giac.help(:factor)  # Returns structured HelpResult (unexported; for raw text use giac_help(:factor))
df = DataFrame(hr)
# 1×5 DataFrame
#  Row │ command  category  description  related           examples
#      │ String   String    String       String            String
# ─────┼──────────────────────────────────────────────────────────────
#    1 │ factor   algebra   ...          ifactor, partfrac ...
```

!!! tip "Interactive Help"
    For interactive help, use Julia's native help system:
    ```julia
    using Giac.Commands: factor
    ?factor  # Shows GIAC documentation in REPL
    ```

### All Commands Table

Get a table of all ~2000 GIAC commands with documentation:

```julia
using DataFrames

ct = commands_table()
df = DataFrame(ct)
# ~2000×5 DataFrame with columns:
# - command: Command name
# - category: Category (algebra, calculus, etc.)
# - description: Command description
# - related: Related commands (comma-separated)
# - examples: Usage examples (semicolon-separated)
```

### Filtering Commands

Use DataFrame operations to filter and search commands:

```julia
using DataFrames

df = DataFrame(commands_table())

# Find all algebra commands
algebra_cmds = filter(row -> row.category == "algebra", df)

# Search by description
factor_cmds = filter(row -> occursin("factor", lowercase(row.description)), df)
```

### Caching

The commands table is cached for performance. To refresh:

```julia
clear_commands_cache!()
ct = commands_table()  # Fresh collection
```

## Table of Functions

| Function | Description |
|----------|-------------|
| `Tables.istable(GiacMatrix)` | Returns `true` |
| `Tables.rows(m::GiacMatrix)` | Row iterator |
| `Tables.columns(m::GiacMatrix)` | Column accessor |
| `Tables.schema(m::GiacMatrix)` | Column names and types |
| `Tables.istable(HelpResult)` | Returns `true` |
| `Tables.rows(hr::HelpResult)` | Single-row iterator |
| `commands_table()` | All commands as table |
| `clear_commands_cache!()` | Clear commands cache |

## API Reference

```@docs
commands_table
clear_commands_cache!
CommandsTable
```
