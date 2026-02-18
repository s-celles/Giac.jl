using Test
using Giac
using LinearAlgebra

@testset "Giac.jl" begin
    # Module loading test (US2)
    @testset "Module Loading" begin
        @test isdefined(Giac, :GiacExpr)
        @test isdefined(Giac, :GiacContext)
        @test isdefined(Giac, :GiacError)
        @test isdefined(Giac, :giac_eval)
    end

    # Include individual test files
    include("test_types.jl")
    include("test_wrapper.jl")
    include("test_api.jl")
    include("test_operators.jl")
    include("test_calculus.jl")
    include("test_algebra.jl")
    include("test_linalg.jl")
    include("test_memory.jl")

    # Command invocation tests (003-giac-commands)
    include("test_commands.jl")
    include("test_command_registry.jl")

    # Namespace command access tests (007-giac-namespace-commands)
    include("test_namespace_commands.jl")

    # Commands submodule tests (009-commands-submodule)
    include("test_commands_submodule.jl")

    # TempApi submodule tests (010-tempapi-submodule)
    include("test_tempapi.jl")

    # Macro tests (011-giac-symbol-macro)
    include("test_macros.jl")

    # Matrix display tests (011-giacmatrix-display)
    include("test_matrix_display.jl")

    # Introspection tests (003-giac-introspection)
    include("test_introspection.jl")

    # Type conversion tests (022-julia-type-conversion)
    include("test_type_conversion.jl")

    # Multiple dispatch for conflicts tests (023-conflicts-multidispatch)
    include("test_conflicts_multidispatch.jl")

    # Equation syntax tests (024-equation-syntax)
    include("test_equation_syntax.jl")

    # Tables.jl compatibility tests (025-tables-compatibility)
    include("test_tables.jl")

    # Julia help system integration tests (026-julia-help-docstrings)
    include("test_docstrings.jl")

    # Substitute function tests (028-substitute-mechanism)
    include("test_substitute.jl")

    # Output handling tests (029-output-handling)
    include("test_output_handling.jl")

    # ============================================================================
    # Domain Documentation Tests (036-domain-docs-tests)
    # Verifies that all code examples in documentation work correctly
    # ============================================================================

    # Mathematics domain documentation tests
    include("test_docs_math_calculus.jl")
    include("test_docs_math_algebra.jl")
    include("test_docs_math_linalg.jl")
    include("test_docs_math_odes.jl")
    include("test_docs_math_trig.jl")

    # Physics domain documentation tests
    include("test_docs_physics_mechanics.jl")
    include("test_docs_physics_em.jl")

    # ============================================================================
    # UnitRange Indices Support Tests (037-unitrange-indices)
    # Verifies UnitRange support in GiacMatrix and @giac_several_vars
    # ============================================================================
    include("test_unitrange_indices.jl")

    # ============================================================================
    # Inf and -Inf Support Tests (038-inf-support)
    # Verifies Julia Inf/-Inf conversion to GIAC inf/-inf
    # ============================================================================
    include("test_inf_support.jl")

    # ============================================================================
    # Z-Transform Function Tests (039-z-transform)
    # Verifies z-transform and inverse z-transform functions
    # ============================================================================
    include("test_ztransform.jl")

    # ============================================================================
    # Laplace Transform Function Tests (040-laplace-transform)
    # Verifies Laplace transform and inverse Laplace transform functions
    # ============================================================================
    include("test_laplace.jl")

    # ============================================================================
    # GenTypes Module Tests (041-scoped-type-enum)
    # Verifies T enum for GIAC expression types
    # ============================================================================
    include("test_gen_types.jl")

    # ============================================================================
    # Symbolics Extension Tests (042-preserve-symbolic-sqrt)
    # Verifies symbolic expression preservation in to_symbolics
    # ============================================================================
    include("test_symbolics_ext.jl")
end

# Aqua.jl package quality tests
using Aqua
@testset "Aqua.jl" begin
    Aqua.test_all(Giac; ambiguities=false)
end
