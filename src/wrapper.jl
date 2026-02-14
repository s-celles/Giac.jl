# Low-level wrapper for libgiac-julia-wrapper
# Provides CxxWrap bindings to the GIAC library

using CxxWrap
using Libdl
using libcxxwrap_julia_jll

# Library path storage
const _wrapper_lib_path = Ref{String}("")

"""
    find_wrapper_library()

Find the libgiac_wrapper shared library.
Checks GIAC_WRAPPER_LIB environment variable first, then common locations.
"""
function find_wrapper_library()
    # Check environment variable first
    env_path = get(ENV, "GIAC_WRAPPER_LIB", "")
    if !isempty(env_path)
        if isfile(env_path)
            return env_path
        end
        # Try as directory
        for name in ["libgiac_wrapper.so", "libgiac_wrapper.dylib", "giac_wrapper.dll"]
            full_path = joinpath(env_path, name)
            if isfile(full_path)
                return full_path
            end
        end
    end

    # Try common locations relative to this package
    pkg_root = dirname(dirname(@__FILE__))
    possible_paths = [
        joinpath(pkg_root, "deps", "libgiac_wrapper.so"),
        joinpath(pkg_root, "deps", "lib", "libgiac_wrapper.so"),
        joinpath(pkg_root, "build", "src", "libgiac_wrapper.so"),
        # System paths
        "/usr/local/lib/libgiac_wrapper.so",
        "/usr/lib/libgiac_wrapper.so",
    ]

    # Also check the parent giac directory (for development)
    giac_root = dirname(dirname(pkg_root))  # Up from Giac.jl
    push!(possible_paths, joinpath(giac_root, "libgiac-julia-wrapper", "build", "src", "libgiac_wrapper.so"))

    for path in possible_paths
        if isfile(path)
            return path
        end
    end

    return ""
end

# Flag to track initialization state
const _initialized = Ref{Bool}(false)
const _stub_mode = Ref{Bool}(true)

# Keep references to library handles to prevent unloading
# IMPORTANT: These must remain open for the entire process lifetime
const _giac_lib_handle = Ref{Ptr{Cvoid}}(C_NULL)
const _cxxwrap_lib_handle = Ref{Ptr{Cvoid}}(C_NULL)
const _wrapper_lib_handle = Ref{Ptr{Cvoid}}(C_NULL)

# Find libgiac given a wrapper path
function _find_giac_library(wrapper_path::String)
    wrapper_dir = dirname(wrapper_path)
    for giac_name in ["libgiac.so", "libgiac.so.0", "libgiac.so.1", "libgiac.dylib"]
        for parent in [wrapper_dir, dirname(wrapper_dir), dirname(dirname(wrapper_dir))]
            # Check GIAC 2.0.0 location first, then fallback locations
            for subdir in ["", "lib", "../giac-2.0.0/src/.libs", "build_julia", "../giac/build_julia"]
                test_path = joinpath(parent, subdir, giac_name)
                if isfile(test_path)
                    return test_path
                end
            end
        end
    end
    return "libgiac.so"  # Fall back to system search
end

# CxxWrap module for GIAC bindings
# The @wrapmodule macro must be called at compile time, so we need the library
# path available then via environment variable.
module GiacCxxBindings
    using CxxWrap
    using Libdl
    using libcxxwrap_julia_jll

    # Get library path from environment at compile time
    const _compile_time_lib_path = get(ENV, "GIAC_WRAPPER_LIB", "")
    const _have_library = !isempty(_compile_time_lib_path) && isfile(_compile_time_lib_path)

    # Storage for library handles (to prevent GC/unload)
    const _giac_handle = Ref{Ptr{Cvoid}}(C_NULL)
    const _cxxwrap_handle = Ref{Ptr{Cvoid}}(C_NULL)

    # Helper function to find libgiac
    function _find_giac_lib(wrapper_path::String)
        wrapper_dir = dirname(wrapper_path)
        for giac_name in ["libgiac.so", "libgiac.so.0", "libgiac.so.1", "libgiac.dylib"]
            for parent in [wrapper_dir, dirname(wrapper_dir), dirname(dirname(wrapper_dir))]
                # Check GIAC 2.0.0 location first, then fallback locations
                for subdir in ["", "lib", "../giac-2.0.0/src/.libs", "build_julia", "../giac/build_julia"]
                    test_path = joinpath(parent, subdir, giac_name)
                    if isfile(test_path)
                        return test_path
                    end
                end
            end
        end
        return "libgiac.so"  # Fall back to system search
    end

    if _have_library
        # Pre-load dependencies with RTLD_GLOBAL AT COMPILE TIME
        # This is CRITICAL: CxxWrap's @wrapmodule internally calls dlopen to
        # introspect the library structure. Without RTLD_GLOBAL on libgiac.so,
        # the wrapper library can't resolve its GIAC symbols.

        # Find and load libgiac first
        _giac_lib_path = _find_giac_lib(_compile_time_lib_path)
        _giac_handle[] = Libdl.dlopen(_giac_lib_path, Libdl.RTLD_NOW | Libdl.RTLD_GLOBAL)

        # Load libcxxwrap_julia with RTLD_GLOBAL
        _cxxwrap_handle[] = Libdl.dlopen(libcxxwrap_julia_jll.libcxxwrap_julia, Libdl.RTLD_NOW | Libdl.RTLD_GLOBAL)

        # Now CxxWrap can load the wrapper module and introspect it
        @wrapmodule(() -> _compile_time_lib_path, :define_julia_module)

        function __init__()
            # At runtime, re-load dependencies with RTLD_GLOBAL BEFORE @initcxx
            # The compile-time handles don't persist across precompilation

            giac_lib_path = _find_giac_lib(_compile_time_lib_path)

            # Load libgiac with RTLD_GLOBAL first
            _giac_handle[] = Libdl.dlopen(giac_lib_path, Libdl.RTLD_NOW | Libdl.RTLD_GLOBAL)

            # Load libcxxwrap_julia with RTLD_GLOBAL
            _cxxwrap_handle[] = Libdl.dlopen(libcxxwrap_julia_jll.libcxxwrap_julia, Libdl.RTLD_NOW | Libdl.RTLD_GLOBAL)

            # Now initialize CxxWrap - this will load the wrapper and resolve symbols
            @initcxx
        end
    else
        # Stubs when library not available at compile time
        giac_version() = "stub"
        wrapper_version() = "stub"
        is_giac_available() = false
    end
end

"""
    _init_xcasroot(wrapper_lib_path)

Initialize the xcasroot path for GIAC help file support.
Searches for share/giac directory relative to the wrapper library location.
"""
function _init_xcasroot(wrapper_lib_path::String)
    # Try to find share/giac directory
    wrapper_dir = dirname(wrapper_lib_path)

    # Search patterns for share/giac (relative to wrapper lib)
    search_paths = [
        # Development layout: wrapper is in libgiac-julia-wrapper/build/src/
        # aide_cas is in giac-2.0.0/doc/
        joinpath(dirname(dirname(dirname(wrapper_dir))), "giac-2.0.0", "doc"),
        joinpath(dirname(dirname(dirname(wrapper_dir))), "giac-2.0.0", "install", "share", "giac"),
        # Installed layout: share/giac is sibling to lib
        joinpath(dirname(wrapper_dir), "share", "giac"),
        joinpath(dirname(dirname(wrapper_dir)), "share", "giac"),
        # JLL layout: artifact_dir/share/giac
        joinpath(dirname(dirname(dirname(wrapper_dir))), "share", "giac"),
    ]

    # Also check GIAC_jll if available
    try
        @eval using GIAC_jll
        jll_share = joinpath(GIAC_jll.artifact_dir, "share", "giac")
        pushfirst!(search_paths, jll_share)
    catch
        # GIAC_jll not available, continue with other paths
    end

    for path in search_paths
        aide_cas_path = joinpath(path, "aide_cas")
        if isfile(aide_cas_path)
            # Path must end with / for GIAC's xcasroot
            xcasroot_path = path * "/"
            GiacCxxBindings.set_xcasroot(xcasroot_path)
            # Pre-initialize help database to avoid fallback error messages
            if GiacCxxBindings.init_help(aide_cas_path)
                @debug "GIAC help initialized from $aide_cas_path"
            end
            return
        end
    end

    @warn "Could not find GIAC aide_cas help file. Help commands may not work."
end

"""
    init_giac_library()

Initialize the GIAC library. Called automatically during module __init__.

Loads the libgiac-julia-wrapper shared library using CxxWrap.

# Throws
- `GiacError`: If library loading or initialization fails
"""
function init_giac_library()
    if _initialized[]
        return
    end

    lib_path = find_wrapper_library()

    if isempty(lib_path)
        # Stub mode for development without the library
        @warn "GIAC wrapper library not found. Using stub implementation for development." *
              "\nSet GIAC_WRAPPER_LIB environment variable to the library path."
        _stub_mode[] = true
        _initialized[] = true
        return
    end

    # Store the path
    _wrapper_lib_path[] = lib_path

    # Check if CxxWrap bindings were loaded at compile time
    if GiacCxxBindings._have_library
        _stub_mode[] = false
        _initialized[] = true
        @info "GIAC wrapper library loaded from $lib_path"

        # Initialize xcasroot for help file support
        _init_xcasroot(lib_path)
    else
        # Library found at runtime but not at compile time
        # CxxWrap requires the library at compile time for @wrapmodule
        @warn "GIAC library found at runtime but was not available at compile time." *
              "\nSet GIAC_WRAPPER_LIB=$lib_path and restart Julia to enable CxxWrap bindings."
        _stub_mode[] = true
        _initialized[] = true
    end
end

"""
    is_stub_mode()

Check if the wrapper is running in stub mode (without the actual library).
"""
is_stub_mode() = _stub_mode[]

# ============================================================================
# Stub implementations for development without the actual library
# These will be replaced with CxxWrap calls when the library is available
# ============================================================================

# Expression type enum for stubs
const _EXPR_TYPE_SYMBOLIC = 0
const _EXPR_TYPE_INTEGER = 1
const _EXPR_TYPE_FLOAT = 2
const _EXPR_TYPE_COMPLEX = 3
const _EXPR_TYPE_RATIONAL = 4
const _EXPR_TYPE_VECTOR = 5
const _EXPR_TYPE_MATRIX = 6

# Stub pointer tracking (for development/testing)
const _stub_expressions = Dict{UInt, String}()
const _stub_counter = Ref{UInt}(0)

# Shared CxxWrap context for evaluation (lazily initialized)
const _cxxwrap_context = Ref{Any}(nothing)

function _get_cxxwrap_context()
    if _cxxwrap_context[] === nothing && GiacCxxBindings._have_library
        _cxxwrap_context[] = GiacCxxBindings.GiacContext()
    end
    return _cxxwrap_context[]
end

function _make_stub_ptr(expr::String)::Ptr{Cvoid}
    _stub_counter[] += 1
    ptr = Ptr{Cvoid}(_stub_counter[])
    _stub_expressions[_stub_counter[]] = expr
    return ptr
end

function _get_stub_expr(ptr::Ptr{Cvoid})::String
    return get(_stub_expressions, UInt(ptr), "<unknown>")
end

function _giac_eval_string(expr::String, ctx_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    if !_stub_mode[] && GiacCxxBindings._have_library
        # Use CxxWrap bindings for real evaluation
        ctx = _get_cxxwrap_context()
        result_std = GiacCxxBindings.giac_eval(ctx, expr)
        # Convert C++ std::string to Julia String
        result = String(result_std)
        # Store the result string and return a handle
        return _make_stub_ptr(result)
    end
    # Stub mode: just store the expression as-is
    return _make_stub_ptr(expr)
end

function _giac_expr_to_string(ptr::Ptr{Cvoid})::String
    return _get_stub_expr(ptr)
end

function _giac_free_expr(ptr::Ptr{Cvoid})
    if ptr == C_NULL
        return
    end
    if _stub_mode[]
        delete!(_stub_expressions, UInt(ptr))
    end
    nothing
end

function _giac_create_context()::Ptr{Cvoid}
    # Always return a stub pointer for now
    # The real context is managed by CxxWrap's GiacContext type
    # TODO: integrate properly with CxxWrap context
    return Ptr{Cvoid}(1)
end

function _giac_free_context(ptr::Ptr{Cvoid})
    if ptr == C_NULL
        return
    end
    nothing
end

function _giac_expr_type(ptr::Ptr{Cvoid})::Symbol
    if !_stub_mode[] && GiacCxxBindings._have_library
        expr_str = _get_stub_expr(ptr)
        # Try to detect type from string representation
        # Integer: only digits, possibly with leading minus
        if occursin(r"^-?\d+$", expr_str)
            return :integer
        # Rational: digits/digits
        elseif occursin(r"^-?\d+/-?\d+$", expr_str)
            return :rational
        # Float: digits with decimal point
        elseif occursin(r"^-?\d+\.\d+$", expr_str)
            return :float
        # Complex: contains i or I
        elseif occursin(r"\bi\b", expr_str) || occursin(r"\bI\b", expr_str)
            return :complex
        else
            return :symbolic
        end
    end
    return :symbolic
end

function _type_code_to_symbol(code::Cint)::Symbol
    if code == 0
        return :integer
    elseif code == 1
        return :float
    elseif code == 2
        return :complex
    elseif code == 3
        return :rational
    elseif code == 4
        return :infinity
    elseif code == 5
        return :undefined
    elseif code == 6
        return :vector
    elseif code == 7
        return :matrix
    else
        return :symbolic
    end
end

function _giac_to_int64(ptr::Ptr{Cvoid})::Int64
    if !_stub_mode[] && GiacCxxBindings._have_library
        expr_str = _get_stub_expr(ptr)
        return parse(Int64, expr_str)
    end
    return 0
end

function _giac_to_float64(ptr::Ptr{Cvoid})::Float64
    if !_stub_mode[] && GiacCxxBindings._have_library
        expr_str = _get_stub_expr(ptr)
        return parse(Float64, expr_str)
    end
    return 0.0
end

function _giac_complex_real(ptr::Ptr{Cvoid})::Float64
    # Complex parsing would require more sophisticated handling
    # For now, return 0.0 as placeholder
    return 0.0
end

function _giac_complex_imag(ptr::Ptr{Cvoid})::Float64
    # Complex parsing would require more sophisticated handling
    # For now, return 0.0 as placeholder
    return 0.0
end

function _giac_rational_num(ptr::Ptr{Cvoid})::Int64
    if !_stub_mode[] && GiacCxxBindings._have_library
        expr_str = _get_stub_expr(ptr)
        # Parse rational: num/den
        parts = split(expr_str, "/")
        if length(parts) == 2
            return parse(Int64, parts[1])
        end
    end
    return 0
end

function _giac_rational_den(ptr::Ptr{Cvoid})::Int64
    if !_stub_mode[] && GiacCxxBindings._have_library
        expr_str = _get_stub_expr(ptr)
        # Parse rational: num/den
        parts = split(expr_str, "/")
        if length(parts) == 2
            return parse(Int64, parts[2])
        end
    end
    return 1
end

# Matrix operations
function _giac_free_matrix(ptr::Ptr{Cvoid})
    if ptr == C_NULL
        return
    end
    if _stub_mode[]
        delete!(_stub_expressions, UInt(ptr))
    end
    nothing
end

# ============================================================================
# Calculus operations - use string-based GIAC evaluation
# ============================================================================

function _giac_diff(expr_ptr::Ptr{Cvoid}, var_ptr::Ptr{Cvoid}, n::Int, ctx_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    if !_stub_mode[] && GiacCxxBindings._have_library
        expr_str = _get_stub_expr(expr_ptr)
        var_str = _get_stub_expr(var_ptr)
        giac_cmd = n == 1 ? "diff($expr_str, $var_str)" : "diff($expr_str, $var_str, $n)"
        return _giac_eval_string(giac_cmd, ctx_ptr)
    end
    return C_NULL
end

function _giac_integrate(expr_ptr::Ptr{Cvoid}, var_ptr::Ptr{Cvoid}, ctx_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    if !_stub_mode[] && GiacCxxBindings._have_library
        expr_str = _get_stub_expr(expr_ptr)
        var_str = _get_stub_expr(var_ptr)
        return _giac_eval_string("integrate($expr_str, $var_str)", ctx_ptr)
    end
    return C_NULL
end

function _giac_integrate_definite(expr_ptr::Ptr{Cvoid}, var_ptr::Ptr{Cvoid},
                                   a_ptr::Ptr{Cvoid}, b_ptr::Ptr{Cvoid},
                                   ctx_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    if !_stub_mode[] && GiacCxxBindings._have_library
        expr_str = _get_stub_expr(expr_ptr)
        var_str = _get_stub_expr(var_ptr)
        a_str = _get_stub_expr(a_ptr)
        b_str = _get_stub_expr(b_ptr)
        return _giac_eval_string("integrate($expr_str, $var_str, $a_str, $b_str)", ctx_ptr)
    end
    return C_NULL
end

function _giac_limit(expr_ptr::Ptr{Cvoid}, var_ptr::Ptr{Cvoid}, point_ptr::Ptr{Cvoid},
                     dir::Int, ctx_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    if !_stub_mode[] && GiacCxxBindings._have_library
        expr_str = _get_stub_expr(expr_ptr)
        var_str = _get_stub_expr(var_ptr)
        point_str = _get_stub_expr(point_ptr)
        # dir: -1 = left, 0 = both, 1 = right
        giac_cmd = if dir == -1
            "limit($expr_str, $var_str, $point_str, -1)"
        elseif dir == 1
            "limit($expr_str, $var_str, $point_str, 1)"
        else
            "limit($expr_str, $var_str, $point_str)"
        end
        return _giac_eval_string(giac_cmd, ctx_ptr)
    end
    return C_NULL
end

function _giac_series(expr_ptr::Ptr{Cvoid}, var_ptr::Ptr{Cvoid}, point_ptr::Ptr{Cvoid},
                      order::Int, ctx_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    if !_stub_mode[] && GiacCxxBindings._have_library
        expr_str = _get_stub_expr(expr_ptr)
        var_str = _get_stub_expr(var_ptr)
        point_str = _get_stub_expr(point_ptr)
        return _giac_eval_string("series($expr_str, $var_str=$point_str, $order)", ctx_ptr)
    end
    return C_NULL
end

# ============================================================================
# Algebra operations - use string-based GIAC evaluation
# ============================================================================

function _giac_factor(expr_ptr::Ptr{Cvoid}, ctx_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    if !_stub_mode[] && GiacCxxBindings._have_library
        expr_str = _get_stub_expr(expr_ptr)
        return _giac_eval_string("factor($expr_str)", ctx_ptr)
    end
    return C_NULL
end

function _giac_expand(expr_ptr::Ptr{Cvoid}, ctx_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    if !_stub_mode[] && GiacCxxBindings._have_library
        expr_str = _get_stub_expr(expr_ptr)
        return _giac_eval_string("expand($expr_str)", ctx_ptr)
    end
    return C_NULL
end

function _giac_simplify(expr_ptr::Ptr{Cvoid}, ctx_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    if !_stub_mode[] && GiacCxxBindings._have_library
        expr_str = _get_stub_expr(expr_ptr)
        return _giac_eval_string("simplify($expr_str)", ctx_ptr)
    end
    return C_NULL
end

function _giac_solve(expr_ptr::Ptr{Cvoid}, var_ptr::Ptr{Cvoid}, ctx_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    if !_stub_mode[] && GiacCxxBindings._have_library
        expr_str = _get_stub_expr(expr_ptr)
        var_str = _get_stub_expr(var_ptr)
        return _giac_eval_string("solve($expr_str, $var_str)", ctx_ptr)
    end
    return C_NULL
end

function _giac_gcd(a_ptr::Ptr{Cvoid}, b_ptr::Ptr{Cvoid}, ctx_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    if !_stub_mode[] && GiacCxxBindings._have_library
        a_str = _get_stub_expr(a_ptr)
        b_str = _get_stub_expr(b_ptr)
        return _giac_eval_string("gcd($a_str, $b_str)", ctx_ptr)
    end
    return C_NULL
end

# ============================================================================
# Arithmetic operations - use string-based GIAC evaluation
# ============================================================================

function _giac_add(a_ptr::Ptr{Cvoid}, b_ptr::Ptr{Cvoid}, ctx_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    if !_stub_mode[] && GiacCxxBindings._have_library
        a_str = _get_stub_expr(a_ptr)
        b_str = _get_stub_expr(b_ptr)
        return _giac_eval_string("($a_str)+($b_str)", ctx_ptr)
    end
    return C_NULL
end

function _giac_sub(a_ptr::Ptr{Cvoid}, b_ptr::Ptr{Cvoid}, ctx_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    if !_stub_mode[] && GiacCxxBindings._have_library
        a_str = _get_stub_expr(a_ptr)
        b_str = _get_stub_expr(b_ptr)
        return _giac_eval_string("($a_str)-($b_str)", ctx_ptr)
    end
    return C_NULL
end

function _giac_mul(a_ptr::Ptr{Cvoid}, b_ptr::Ptr{Cvoid}, ctx_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    if !_stub_mode[] && GiacCxxBindings._have_library
        a_str = _get_stub_expr(a_ptr)
        b_str = _get_stub_expr(b_ptr)
        return _giac_eval_string("($a_str)*($b_str)", ctx_ptr)
    end
    return C_NULL
end

function _giac_div(a_ptr::Ptr{Cvoid}, b_ptr::Ptr{Cvoid}, ctx_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    if !_stub_mode[] && GiacCxxBindings._have_library
        a_str = _get_stub_expr(a_ptr)
        b_str = _get_stub_expr(b_ptr)
        return _giac_eval_string("($a_str)/($b_str)", ctx_ptr)
    end
    return C_NULL
end

function _giac_pow(a_ptr::Ptr{Cvoid}, b_ptr::Ptr{Cvoid}, ctx_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    if !_stub_mode[] && GiacCxxBindings._have_library
        a_str = _get_stub_expr(a_ptr)
        b_str = _get_stub_expr(b_ptr)
        return _giac_eval_string("($a_str)^($b_str)", ctx_ptr)
    end
    return C_NULL
end

function _giac_neg(a_ptr::Ptr{Cvoid}, ctx_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    if !_stub_mode[] && GiacCxxBindings._have_library
        a_str = _get_stub_expr(a_ptr)
        return _giac_eval_string("-($a_str)", ctx_ptr)
    end
    return C_NULL
end

function _giac_equal(a_ptr::Ptr{Cvoid}, b_ptr::Ptr{Cvoid}, ctx_ptr::Ptr{Cvoid})::Bool
    if !_stub_mode[] && GiacCxxBindings._have_library
        a_str = _get_stub_expr(a_ptr)
        b_str = _get_stub_expr(b_ptr)
        # Use GIAC's simplify to check equality: simplify(a - b) == 0
        result = _giac_eval_string("simplify(($a_str)-($b_str))", ctx_ptr)
        result_str = _get_stub_expr(result)
        return result_str == "0"
    end
    return false
end

# ============================================================================
# Matrix operations - use string-based GIAC evaluation
# ============================================================================

function _giac_det(m_ptr::Ptr{Cvoid}, ctx_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    if !_stub_mode[] && GiacCxxBindings._have_library
        m_str = _get_stub_expr(m_ptr)
        return _giac_eval_string("det($m_str)", ctx_ptr)
    end
    return C_NULL
end

function _giac_inv_matrix(m_ptr::Ptr{Cvoid}, ctx_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    if !_stub_mode[] && GiacCxxBindings._have_library
        m_str = _get_stub_expr(m_ptr)
        return _giac_eval_string("inv($m_str)", ctx_ptr)
    end
    return C_NULL
end

function _giac_trace(m_ptr::Ptr{Cvoid}, ctx_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    if !_stub_mode[] && GiacCxxBindings._have_library
        m_str = _get_stub_expr(m_ptr)
        return _giac_eval_string("trace($m_str)", ctx_ptr)
    end
    return C_NULL
end

function _giac_matrix_mul(a_ptr::Ptr{Cvoid}, b_ptr::Ptr{Cvoid}, ctx_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    if !_stub_mode[] && GiacCxxBindings._have_library
        a_str = _get_stub_expr(a_ptr)
        b_str = _get_stub_expr(b_ptr)
        return _giac_eval_string("($a_str)*($b_str)", ctx_ptr)
    end
    return C_NULL
end

function _giac_matrix_add(a_ptr::Ptr{Cvoid}, b_ptr::Ptr{Cvoid}, ctx_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    if !_stub_mode[] && GiacCxxBindings._have_library
        a_str = _get_stub_expr(a_ptr)
        b_str = _get_stub_expr(b_ptr)
        return _giac_eval_string("($a_str)+($b_str)", ctx_ptr)
    end
    return C_NULL
end

function _giac_matrix_sub(a_ptr::Ptr{Cvoid}, b_ptr::Ptr{Cvoid}, ctx_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    if !_stub_mode[] && GiacCxxBindings._have_library
        a_str = _get_stub_expr(a_ptr)
        b_str = _get_stub_expr(b_ptr)
        return _giac_eval_string("($a_str)-($b_str)", ctx_ptr)
    end
    return C_NULL
end

function _giac_matrix_scalar_mul(m_ptr::Ptr{Cvoid}, scalar_ptr::Ptr{Cvoid}, ctx_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    if !_stub_mode[] && GiacCxxBindings._have_library
        m_str = _get_stub_expr(m_ptr)
        s_str = _get_stub_expr(scalar_ptr)
        return _giac_eval_string("($s_str)*($m_str)", ctx_ptr)
    end
    return C_NULL
end

function _giac_matrix_transpose(m_ptr::Ptr{Cvoid}, ctx_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    if !_stub_mode[] && GiacCxxBindings._have_library
        m_str = _get_stub_expr(m_ptr)
        return _giac_eval_string("tran($m_str)", ctx_ptr)
    end
    return C_NULL
end

function _giac_matrix_det(m_ptr::Ptr{Cvoid}, ctx_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    if !_stub_mode[] && GiacCxxBindings._have_library
        m_str = _get_stub_expr(m_ptr)
        return _giac_eval_string("det($m_str)", ctx_ptr)
    end
    return C_NULL
end

function _giac_matrix_inv(m_ptr::Ptr{Cvoid}, ctx_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    if !_stub_mode[] && GiacCxxBindings._have_library
        m_str = _get_stub_expr(m_ptr)
        return _giac_eval_string("inv($m_str)", ctx_ptr)
    end
    return C_NULL
end

function _giac_matrix_trace(m_ptr::Ptr{Cvoid}, ctx_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    if !_stub_mode[] && GiacCxxBindings._have_library
        m_str = _get_stub_expr(m_ptr)
        return _giac_eval_string("trace($m_str)", ctx_ptr)
    end
    return C_NULL
end

function _giac_create_matrix(expr::String, rows::Int, cols::Int, ctx_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    if !_stub_mode[] && GiacCxxBindings._have_library
        # Evaluate the matrix expression to normalize it
        return _giac_eval_string(expr, ctx_ptr)
    end
    # Stub mode: just store the expression
    return _make_stub_ptr(expr)
end

function _giac_matrix_getindex(ptr::Ptr{Cvoid}, i::Int, j::Int)::Ptr{Cvoid}
    if !_stub_mode[] && GiacCxxBindings._have_library
        m_str = _get_stub_expr(ptr)
        # GIAC uses 0-based indexing, but we receive 0-based indices from Julia (already adjusted)
        return _giac_eval_string("($m_str)[$i][$j]", C_NULL)
    end
    return C_NULL
end

# ============================================================================
# Simplified wrappers that use DEFAULT_CONTEXT
# These are convenience functions used by api.jl and operators.jl
# ============================================================================

function _giac_diff(expr_ptr::Ptr{Cvoid}, var_ptr::Ptr{Cvoid}, n::Int)::Ptr{Cvoid}
    return _giac_diff(expr_ptr, var_ptr, n, DEFAULT_CONTEXT[].ptr)
end

function _giac_integrate(expr_ptr::Ptr{Cvoid}, var_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    return _giac_integrate(expr_ptr, var_ptr, DEFAULT_CONTEXT[].ptr)
end

function _giac_integrate_definite(expr_ptr::Ptr{Cvoid}, var_ptr::Ptr{Cvoid},
                                   a_ptr::Ptr{Cvoid}, b_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    return _giac_integrate_definite(expr_ptr, var_ptr, a_ptr, b_ptr, DEFAULT_CONTEXT[].ptr)
end

function _giac_limit(expr_ptr::Ptr{Cvoid}, var_ptr::Ptr{Cvoid}, point_ptr::Ptr{Cvoid}, dir::Int)::Ptr{Cvoid}
    return _giac_limit(expr_ptr, var_ptr, point_ptr, dir, DEFAULT_CONTEXT[].ptr)
end

function _giac_series(expr_ptr::Ptr{Cvoid}, var_ptr::Ptr{Cvoid}, point_ptr::Ptr{Cvoid}, order::Int)::Ptr{Cvoid}
    return _giac_series(expr_ptr, var_ptr, point_ptr, order, DEFAULT_CONTEXT[].ptr)
end

function _giac_factor(expr_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    return _giac_factor(expr_ptr, DEFAULT_CONTEXT[].ptr)
end

function _giac_expand(expr_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    return _giac_expand(expr_ptr, DEFAULT_CONTEXT[].ptr)
end

function _giac_simplify(expr_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    return _giac_simplify(expr_ptr, DEFAULT_CONTEXT[].ptr)
end

function _giac_solve(expr_ptr::Ptr{Cvoid}, var_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    return _giac_solve(expr_ptr, var_ptr, DEFAULT_CONTEXT[].ptr)
end

function _giac_gcd(a_ptr::Ptr{Cvoid}, b_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    return _giac_gcd(a_ptr, b_ptr, DEFAULT_CONTEXT[].ptr)
end

function _giac_add(a_ptr::Ptr{Cvoid}, b_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    return _giac_add(a_ptr, b_ptr, DEFAULT_CONTEXT[].ptr)
end

function _giac_sub(a_ptr::Ptr{Cvoid}, b_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    return _giac_sub(a_ptr, b_ptr, DEFAULT_CONTEXT[].ptr)
end

function _giac_mul(a_ptr::Ptr{Cvoid}, b_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    return _giac_mul(a_ptr, b_ptr, DEFAULT_CONTEXT[].ptr)
end

function _giac_div(a_ptr::Ptr{Cvoid}, b_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    return _giac_div(a_ptr, b_ptr, DEFAULT_CONTEXT[].ptr)
end

function _giac_pow(a_ptr::Ptr{Cvoid}, b_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    return _giac_pow(a_ptr, b_ptr, DEFAULT_CONTEXT[].ptr)
end

function _giac_neg(a_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    return _giac_neg(a_ptr, DEFAULT_CONTEXT[].ptr)
end

function _giac_equal(a_ptr::Ptr{Cvoid}, b_ptr::Ptr{Cvoid})::Bool
    return _giac_equal(a_ptr, b_ptr, DEFAULT_CONTEXT[].ptr)
end

function _giac_matrix_det(m_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    return _giac_matrix_det(m_ptr, DEFAULT_CONTEXT[].ptr)
end

function _giac_matrix_inv(m_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    return _giac_matrix_inv(m_ptr, DEFAULT_CONTEXT[].ptr)
end

function _giac_matrix_trace(m_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    return _giac_matrix_trace(m_ptr, DEFAULT_CONTEXT[].ptr)
end

function _giac_matrix_transpose(m_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    return _giac_matrix_transpose(m_ptr, DEFAULT_CONTEXT[].ptr)
end

function _giac_matrix_mul(a_ptr::Ptr{Cvoid}, b_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    return _giac_matrix_mul(a_ptr, b_ptr, DEFAULT_CONTEXT[].ptr)
end

function _giac_matrix_add(a_ptr::Ptr{Cvoid}, b_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    return _giac_matrix_add(a_ptr, b_ptr, DEFAULT_CONTEXT[].ptr)
end

function _giac_matrix_sub(a_ptr::Ptr{Cvoid}, b_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    return _giac_matrix_sub(a_ptr, b_ptr, DEFAULT_CONTEXT[].ptr)
end

function _giac_matrix_scalar_mul(m_ptr::Ptr{Cvoid}, scalar_ptr::Ptr{Cvoid})::Ptr{Cvoid}
    return _giac_matrix_scalar_mul(m_ptr, scalar_ptr, DEFAULT_CONTEXT[].ptr)
end

function _giac_create_matrix(expr::String, rows::Int, cols::Int)::Ptr{Cvoid}
    return _giac_create_matrix(expr, rows, cols, DEFAULT_CONTEXT[].ptr)
end
