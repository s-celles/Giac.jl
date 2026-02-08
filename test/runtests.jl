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
end

# Aqua.jl package quality tests
using Aqua
@testset "Aqua.jl" begin
    Aqua.test_all(Giac; ambiguities=false)
end
