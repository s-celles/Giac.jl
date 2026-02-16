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
end

# Aqua.jl package quality tests
using Aqua
@testset "Aqua.jl" begin
    Aqua.test_all(Giac; ambiguities=false)
end
