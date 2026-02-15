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

```julia
using Giac

# Display Julia help for a function
?help(factor)
# search: factor ifactor cfactor factorial Vector giac_factor function taylor acot acos filter macro for floor acoth acotd
# 
#   factor(args...)::GiacExpr
# 
#   Call the GIAC factor command with the given arguments.
# 
#   This is a convenience function exported for direct use. Equivalent to:
# 
#     •  giac_cmd(:factor, args...)
# 
#   See GIAC documentation for detailed usage of this command. This is available using helper functions like help(:factor) or giac_help(:factor).

# Display formatted help for a Giac command
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
#   • factor(x^4+12*x^3+54*x^2+108*x+81)

# Access help data programmatically
result = help(:sin)
result.command      # "sin"
result.description  # "Sine or Option of the convert or convertir command (id trigsin)."
result.related      # ["asin", "convert", "trigsin"]
result.examples     # ["sin(0)", "convert(cos(x)^4+sin(x)^2,sin)"]

# Get raw help as a string (for backward compatibility)
help_text = giac_help(:factor)

# List all available commands
cmds = list_commands()
println("Number of commands: ", length(cmds))  # 2215

# Get help count
println("Help entries: ", help_count())  # 2215
```

## Command Suggestions

When you mistype a command, Giac.jl automatically suggests similar commands:

```julia
using Giac

# Typo in "factor" shows suggestions
help(:factr)
# factr
# ═════
#
# Description:
#   [No help found for: factr. Did you mean: factor, ifactor, cfactor, fractr?]

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
| `help(cmd)` | Get formatted help for a command (returns `HelpResult`) |
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

### Command Access (008)

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

| Function | Description |
|----------|-------------|
| `giac_diff(f, x, n=1)` | nth derivative of f with respect to x |
| `giac_integrate(f, x)` | Indefinite integral |
| `giac_integrate(f, x, a, b)` | Definite integral from a to b |
| `giac_limit(f, x, point)` | Limit as x approaches point |
| `giac_series(f, x, point, order)` | Taylor series expansion |

### Algebra

| Function | Description |
|----------|-------------|
| `giac_factor(expr)` | Factor polynomial |
| `giac_expand(expr)` | Expand expression |
| `giac_simplify(expr)` | Simplify expression |
| `giac_solve(expr, x)` | Solve equation for x |
| `giac_gcd(a, b)` | Greatest common divisor |
