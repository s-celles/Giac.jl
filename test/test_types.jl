@testset "Types" begin
    @testset "GiacError" begin
        # T007: Test GiacError exception type
        err = GiacError("test error", :parse)
        @test err isa Exception
        @test err.msg == "test error"
        @test err.category == :parse

        # Test error categories
        @test GiacError("", :eval).category == :eval
        @test GiacError("", :type).category == :type
        @test GiacError("", :memory).category == :memory
    end

    @testset "GiacExpr" begin
        # T007: Test GiacExpr type exists
        @test isdefined(Giac, :GiacExpr)

        # Test GiacExpr has required fields
        # Note: Actual construction requires wrapper to be working
    end

    @testset "GiacContext" begin
        # T007: Test GiacContext type exists
        @test isdefined(Giac, :GiacContext)

        # T034 [US2]: Test DEFAULT_CONTEXT is initialized
        @test isdefined(Giac, :DEFAULT_CONTEXT)
    end

    @testset "to_julia conversion" begin
        # T022 [US1]: Test to_julia numeric conversion
        # These tests will be expanded when giac_eval is working
    end
end
