@testset "API" begin
    @testset "giac_eval" begin
        # T009 [US1]: Test basic expression evaluation
        @test isdefined(Giac, :giac_eval)

        # Test evaluation with string
        result = giac_eval("2+3")
        @test result isa GiacExpr

        # Test empty string throws error
        @test_throws GiacError giac_eval("")
    end

    @testset "to_julia" begin
        # T022 [US1]: Test numeric conversion
        @test isdefined(Giac, :to_julia)

        # Placeholder tests - will work once library is connected
        # These test the stub behavior for now
    end

    @testset "Calculus Functions" begin
        # T025-T028: Calculus API functions exist
        @test isdefined(Giac, :giac_diff)
        @test isdefined(Giac, :giac_integrate)
        @test isdefined(Giac, :giac_limit)
        @test isdefined(Giac, :giac_series)
    end

    @testset "Algebra Functions" begin
        # T029-T033: Algebra API functions exist
        @test isdefined(Giac, :giac_factor)
        @test isdefined(Giac, :giac_expand)
        @test isdefined(Giac, :giac_simplify)
        @test isdefined(Giac, :giac_solve)
        @test isdefined(Giac, :giac_gcd)
    end
end
