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
