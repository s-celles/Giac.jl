# Held command display for Giac.jl (055-held-cmd-display)
# Provides HeldCmd type for unevaluated command display with LaTeX rendering

# ============================================================================
# HeldCmd Type Definition
# ============================================================================

"""
    HeldCmd

Represents an unevaluated GIAC command with its arguments.

A `HeldCmd` stores a command name and arguments without executing the command.
It provides rich display (LaTeX for notebooks, plain text for terminal) and
can be executed later via [`release`](@ref).

# Fields
- `cmd::Symbol`: GIAC command name (e.g., `:integrate`, `:diff`)
- `args::Tuple`: Original arguments, preserved as-is from `hold_cmd` call

# Specialized LaTeX Rendering
The following commands render with standard mathematical notation:
- `integrate`: `∫ f dx`
- `diff`: `d/dx f` (Leibniz notation)
- `laplace`: `ℒ{f}(s)`
- `invlaplace`: `ℒ⁻¹{F}(t)`
- `ztransform`: `𝒵{f}(z)`
- `invztransform`: `𝒵⁻¹{F}(n)`

All other commands use generic function-call notation.

# Examples
```julia
using Giac
using Giac.Commands: hold_cmd, release

@giac_var x
h = hold_cmd(:integrate, x^2, x)  # Creates HeldCmd, no execution
display(h)                          # Renders ∫ x² dx in notebooks
result = release(h)                 # Executes: returns x³/3
```

# See also
- [`hold_cmd`](@ref): Create a HeldCmd
- [`release`](@ref): Execute a HeldCmd
- [`invoke_cmd`](@ref): Direct command execution
"""
struct HeldCmd
    cmd::Symbol
    args::Tuple
end

# ============================================================================
# Argument LaTeX Rendering Helper
# ============================================================================

"""
    _arg_to_latex(arg) -> String

Convert a single argument to its LaTeX representation for use in HeldCmd display.

For GiacExpr, delegates to GIAC's `latex()` command. For other types, produces
a simple string representation suitable for LaTeX.
"""
function _arg_to_latex(arg::GiacExpr)::String
    latex_result = invoke_cmd(:latex, arg)
    latex_str = string(latex_result)
    # GIAC's latex() returns strings with surrounding quotes — strip them
    if length(latex_str) > 2 && latex_str[1] == '"' && latex_str[end] == '"'
        return latex_str[2:end-1]
    end
    return string(arg)
end

function _arg_to_latex(arg::Symbol)::String
    return string(arg)
end

function _arg_to_latex(arg::Number)::String
    return string(arg)
end

function _arg_to_latex(arg::String)::String
    return "\\text{" * arg * "}"
end

function _arg_to_latex(arg::AbstractVector)::String
    elements = [_arg_to_latex(x) for x in arg]
    return "[" * join(elements, ", ") * "]"
end

function _arg_to_latex(arg::GiacMatrix)::String
    # Render matrix as LaTeX using GIAC's latex() on the underlying expression
    latex_result = invoke_cmd(:latex, arg)
    latex_str = string(latex_result)
    if length(latex_str) > 2 && latex_str[1] == '"' && latex_str[end] == '"'
        return latex_str[2:end-1]
    end
    return string(arg.ptr)
end

function _arg_to_latex(arg)::String
    return string(arg)
end

# ============================================================================
# Specialized LaTeX Renderers
# ============================================================================

# integrate(expr, var) → \int expr \, dvar
# integrate(expr, var, a, b) → \int_a^b expr \, dvar
function _latex_integrate(io::IO, args::Tuple)
    if length(args) >= 4
        # Definite integral: integrate(expr, var, lower, upper)
        expr_latex = _arg_to_latex(args[1])
        var_latex = _arg_to_latex(args[2])
        lower_latex = _arg_to_latex(args[3])
        upper_latex = _arg_to_latex(args[4])
        print(io, "\\int_{", lower_latex, "}^{", upper_latex, "} ", expr_latex, " \\, d", var_latex)
    elseif length(args) >= 2
        expr_latex = _arg_to_latex(args[1])
        var_latex = _arg_to_latex(args[2])
        print(io, "\\int ", expr_latex, " \\, d", var_latex)
    elseif length(args) == 1
        expr_latex = _arg_to_latex(args[1])
        print(io, "\\int ", expr_latex)
    else
        print(io, "\\int")
    end
end

# diff(expr, var) → \frac{d}{dvar} expr
# diff(expr, var, n) → \frac{d^n}{dvar^n} expr
function _latex_diff(io::IO, args::Tuple)
    if length(args) >= 3
        expr_latex = _arg_to_latex(args[1])
        var_latex = _arg_to_latex(args[2])
        order = args[3]
        order_str = _arg_to_latex(order)
        print(io, "\\frac{d^{", order_str, "}}{d", var_latex, "^{", order_str, "}} ", expr_latex)
    elseif length(args) >= 2
        expr_latex = _arg_to_latex(args[1])
        var_latex = _arg_to_latex(args[2])
        print(io, "\\frac{d}{d", var_latex, "} ", expr_latex)
    elseif length(args) == 1
        expr_latex = _arg_to_latex(args[1])
        print(io, "\\frac{d}{d?} ", expr_latex)
    end
end

# laplace/ztransform(expr, source, target) → \mathcal{S}\left\{expr\right\}(target)
function _latex_transform(io::IO, symbol::String, args::Tuple)
    if length(args) >= 3
        expr_latex = _arg_to_latex(args[1])
        target_latex = _arg_to_latex(args[3])
        print(io, "\\mathcal{", symbol, "}\\left\\{", expr_latex, "\\right\\}(", target_latex, ")")
    elseif length(args) >= 1
        expr_latex = _arg_to_latex(args[1])
        print(io, "\\mathcal{", symbol, "}\\left\\{", expr_latex, "\\right\\}")
    else
        print(io, "\\mathcal{", symbol, "}")
    end
end

# invlaplace/invztransform(expr, source, target) → \mathcal{S}^{-1}\left\{expr\right\}(target)
function _latex_inv_transform(io::IO, symbol::String, args::Tuple)
    if length(args) >= 3
        expr_latex = _arg_to_latex(args[1])
        target_latex = _arg_to_latex(args[3])
        print(io, "\\mathcal{", symbol, "}^{-1}\\left\\{", expr_latex, "\\right\\}(", target_latex, ")")
    elseif length(args) >= 1
        expr_latex = _arg_to_latex(args[1])
        print(io, "\\mathcal{", symbol, "}^{-1}\\left\\{", expr_latex, "\\right\\}")
    else
        print(io, "\\mathcal{", symbol, "}^{-1}")
    end
end

# Generic fallback: \mathrm{cmdname}\left(arg1, arg2, ...\right)
function _latex_generic(io::IO, held::HeldCmd)
    print(io, "\\mathrm{", string(held.cmd), "}")
    if !isempty(held.args)
        arg_strs = [_arg_to_latex(a) for a in held.args]
        print(io, "\\left(", join(arg_strs, ", "), "\\right)")
    else
        print(io, "()")
    end
end

# ============================================================================
# Display Methods
# ============================================================================

function Base.show(io::IO, ::MIME"text/latex", held::HeldCmd)
    print(io, "\$\$")
    if held.cmd === :integrate
        _latex_integrate(io, held.args)
    elseif held.cmd === :diff
        _latex_diff(io, held.args)
    elseif held.cmd === :laplace
        _latex_transform(io, "L", held.args)
    elseif held.cmd === :invlaplace || held.cmd === :ilaplace
        _latex_inv_transform(io, "L", held.args)
    elseif held.cmd === :ztransform || held.cmd === :ztrans
        _latex_transform(io, "Z", held.args)
    elseif held.cmd === :invztransform || held.cmd === :invztrans
        _latex_inv_transform(io, "Z", held.args)
    else
        _latex_generic(io, held)
    end
    print(io, "\$\$")
end

function Base.show(io::IO, held::HeldCmd)
    print(io, string(held.cmd), "(")
    if !isempty(held.args)
        arg_strs = [string(a) for a in held.args]
        print(io, join(arg_strs, ", "))
    end
    print(io, ") [held]")
end

function Base.show(io::IO, ::MIME"text/plain", held::HeldCmd)
    print(io, "HeldCmd: ")
    show(io, held)
end

# ============================================================================
# HeldEquation Type (059-heldcmd-equation-tilde)
# ============================================================================

"""
    HeldEquation

Represents an equation where at least one side is a `HeldCmd` (unevaluated command).

Provides proper LaTeX rendering that preserves the unevaluated command form,
unlike a plain `GiacExpr` equation where GIAC's `latex()` would evaluate both sides.

# Fields
- `lhs`: Left-hand side (HeldCmd, GiacExpr, or Number)
- `rhs`: Right-hand side (HeldCmd, GiacExpr, or Number)

# Examples
```julia
@giac_var x
h = hold_cmd(:factor, x^4 - 1)
eq = h ~ factor(x^4 - 1)  # Displays: factor(x⁴-1) = (x-1)(x+1)(x²+1)
```

# See also
- [`HeldCmd`](@ref): Unevaluated command type
- [`~`](@ref): Equation operator
"""
struct HeldEquation
    lhs::Any
    rhs::Any
end

# LaTeX helper for one side of the equation
function _side_to_latex(io::IO, side::HeldCmd)
    # Delegate to the existing HeldCmd LaTeX rendering (without $$ delimiters)
    if side.cmd === :integrate
        _latex_integrate(io, side.args)
    elseif side.cmd === :diff
        _latex_diff(io, side.args)
    elseif side.cmd === :laplace
        _latex_transform(io, "L", side.args)
    elseif side.cmd === :invlaplace || side.cmd === :ilaplace
        _latex_inv_transform(io, "L", side.args)
    elseif side.cmd === :ztransform || side.cmd === :ztrans
        _latex_transform(io, "Z", side.args)
    elseif side.cmd === :invztransform || side.cmd === :invztrans
        _latex_inv_transform(io, "Z", side.args)
    else
        _latex_generic(io, side)
    end
end

function _side_to_latex(io::IO, side::GiacExpr)
    latex_result = invoke_cmd(:latex, side)
    latex_str = string(latex_result)
    # Strip surrounding quotes from GIAC's latex() output
    if length(latex_str) > 2 && latex_str[1] == '"' && latex_str[end] == '"'
        print(io, latex_str[2:end-1])
    else
        print(io, string(side))
    end
end

function _side_to_latex(io::IO, side::Number)
    print(io, string(side))
end

function Base.show(io::IO, ::MIME"text/latex", eq::HeldEquation)
    print(io, "\$\$")
    _side_to_latex(io, eq.lhs)
    print(io, " = ")
    _side_to_latex(io, eq.rhs)
    print(io, "\$\$")
end

function _side_to_string(side::HeldCmd)::String
    arg_strings = String[_arg_to_giac_string(a) for a in side.args]
    return _build_command_string(string(side.cmd), arg_strings)
end

_side_to_string(side) = string(side)

function Base.show(io::IO, eq::HeldEquation)
    print(io, _side_to_string(eq.lhs), " = ", _side_to_string(eq.rhs))
end

function Base.show(io::IO, ::MIME"text/plain", eq::HeldEquation)
    show(io, eq)
end

# ============================================================================
# Equation Operator (~) for HeldCmd (059-heldcmd-equation-tilde)
# ============================================================================

"""
    ~(a::HeldCmd, b::GiacExpr) -> HeldEquation

Create an equation with an unevaluated command on the left.

# Examples
```julia
@giac_var x
h = hold_cmd(:factor, x^4 - 1)
eq = h ~ factor(x^4 - 1)  # factor(x⁴-1) = (x-1)(x+1)(x²+1)
```
"""
Base.:~(a::HeldCmd, b::GiacExpr) = HeldEquation(a, b)

"""
    ~(a::GiacExpr, b::HeldCmd) -> HeldEquation

Create an equation with an unevaluated command on the right.
"""
Base.:~(a::GiacExpr, b::HeldCmd) = HeldEquation(a, b)

"""
    ~(a::HeldCmd, b::HeldCmd) -> HeldEquation

Create an equation between two unevaluated commands.
"""
Base.:~(a::HeldCmd, b::HeldCmd) = HeldEquation(a, b)

"""
    ~(a::HeldCmd, b::Number) -> HeldEquation

Create an equation with an unevaluated command and a number.
"""
Base.:~(a::HeldCmd, b::Number) = HeldEquation(a, b)

"""
    ~(a::Number, b::HeldCmd) -> HeldEquation

Create an equation with a number and an unevaluated command.
"""
Base.:~(a::Number, b::HeldCmd) = HeldEquation(a, b)
