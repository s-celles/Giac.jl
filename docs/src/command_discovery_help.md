# Command Discovery and Help
## Command Discovery

```julia
using Giac

# Search for commands by prefix
search_commands("sin")        # ["sin", "sinc", "sinh", ...]

# Search with regex
search_commands(r"^a.*n$")    # Commands starting with 'a' and ending with 'n'

# Search by description (find commands by what they do)
search_commands_by_description("polynomial")  # Commands related to polynomials
search_commands_by_description("matrix", n=5) # Limit to 5 results

# Get command metadata
info = command_info(:factor)
info.name                     # "factor"
info.category                 # :algebra

# List available categories
list_categories()             # [:trigonometry, :calculus, :algebra, ...]

# Get commands in a category
commands_in_category(:trigonometry)  # ["sin", "cos", "tan", "asin", ...]
commands_in_category(:calculus)      # ["diff", "integrate", "limit", ...]
commands_in_category(:algebra)       # ["factor", "expand", "simplify", ...]
```

## Help System

Use Julia's native help system to get documentation for GIAC commands:

```julia
using Giac
using Giac.Commands: factor, sin

# Use Julia's native help system (recommended)
?factor
#   factor(expr::GiacInput, args...)
#
#   GIAC command: `factor`
#
#   Factorizes a polynomial.
#
#   # Related Commands
#   - `ifactor`
#   - `partfrac`
#   - `normal`
#
#   # Examples (GIAC syntax)
#   factor(x^4-1)
#   factor(x^4-4,sqrt(2))

# Or use @doc macro
@doc factor

# For programmatic access to raw help text
help_text = giac_help(:factor)

# List all available commands
cmds = list_commands()
println("Number of commands: ", length(cmds))  # 2215

# Get help count
println("Help entries: ", help_count())  # 2215
```

!!! note "Internal help() Function"
    The `help(:cmd)` function is no longer exported. Use `?cmd` for interactive help
    or `giac_help(:cmd)` for programmatic access to raw help text.

## Command Suggestions

When you mistype a command, Giac.jl automatically suggests similar commands:

```julia
using Giac

# Get suggestions programmatically
suggest_commands(:factr)        # ["factor", "cfactor", "ifactor", ...]
suggest_commands(:integrat)     # ["integrate", "integral", ...]

# Configure number of suggestions
get_suggestion_count()          # 4 (default)
set_suggestion_count(6)         # Show more suggestions

# Get suggestions with edit distances
Giac.suggest_commands_with_distances(:factr)
# [("factor", 1), ("cfactor", 2), ("ifactor", 2), ...]
```

The suggestion system uses Levenshtein edit distance with an adaptive threshold based on input length.

### Command Discovery & Help

| Function | Description |
|----------|-------------|
| `?cmd` | View help in REPL (after importing cmd from Giac.Commands) |
| `giac_help(cmd)` | Get raw help text as a string |
| `list_commands()` | List all available GIAC commands |
| `help_count()` | Number of commands in help database |
| `search_commands(pattern)` | Search commands by prefix or regex |
| `command_info(cmd)` | Get CommandInfo with name, category, aliases |
| `list_categories()` | List all command categories |
| `commands_in_category(cat)` | List commands in a category |
| `suggest_commands(input)` | Suggest similar commands for mistyped input |
| `set_suggestion_count(n)` | Set number of suggestions (default: 4) |
| `get_suggestion_count()` | Get current suggestion count |
| `search_commands_by_description(query; n=20)` | Search commands by help text keywords |

### Command Access

| Function | Description |
|----------|-------------|
| `available_commands()` | List all commands starting with ASCII letters |
| `exportable_commands()` | List commands safe to export (no Julia conflicts) |
| `is_valid_command(name)` | Check if a command name is valid |
| `conflict_reason(cmd)` | Get why a command conflicts (`:keyword`, `:builtin`, etc.) |
| `JULIA_CONFLICTS` | Set of commands that conflict with Julia |
| `reset_conflict_warnings!()` | Reset conflict warning tracker (for testing) |

### Types

| Type | Description |
|------|-------------|
| `GiacExpr` | Symbolic expression type |
| `GiacMatrix` | Symbolic matrix type |
| `GiacContext` | Evaluation context |
| `HelpResult` | Parsed help information with `.command`, `.description`, `.related`, `.examples` fields |
| `CommandInfo` | Command metadata with `.name`, `.category`, `.aliases`, `.doc` fields |

### Calculus

Use `Giac.Commands` or `invoke_cmd`:

| Function | Description |
|----------|-------------|
| `Giac.Commands.diff(f, x)` | Derivative of f with respect to x |
| `Giac.Commands.integrate(f, x)` | Indefinite integral |
| `invoke_cmd(:diff, f, x, n)` | nth derivative of f with respect to x |
| `invoke_cmd(:integrate, f, x, a, b)` | Definite integral from a to b |
| `invoke_cmd(:limit, f, x, point)` | Limit as x approaches point |
| `invoke_cmd(:series, f, x, point, order)` | Taylor series expansion |

### Algebra

Use `Giac.Commands` or `invoke_cmd`:

| Function | Description |
|----------|-------------|
| `Giac.Commands.factor(expr)` | Factor polynomial |
| `Giac.Commands.expand(expr)` | Expand expression |
| `Giac.Commands.simplify(expr)` | Simplify expression |
| `Giac.Commands.solve(expr, x)` | Solve equation for x |
| `Giac.Commands.gcd(a, b)` | Greatest common divisor |
