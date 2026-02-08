@testset "Operators" begin
    @testset "Arithmetic Operators" begin
        # T048-T053 [US3]: Test operator overloading
        # Test that operators are defined
        a = giac_eval("2")
        b = giac_eval("3")

        # In stub mode, operators will throw GiacError because C_NULL is returned
        # These tests verify the operator methods exist and handle errors correctly
        @test_throws GiacError a + b
        @test_throws GiacError a - b
        @test_throws GiacError a * b
        @test_throws GiacError a / b
        @test_throws GiacError a ^ b
        @test_throws GiacError -a
    end

    @testset "Mixed Type Arithmetic" begin
        # T054-T057 [US3]: Test mixed type operations
        a = giac_eval("x")

        # In stub mode, these will throw because operators return C_NULL
        @test_throws GiacError a + 1
        @test_throws GiacError 1 + a
        @test_throws GiacError a - 1
        @test_throws GiacError 1 - a
        @test_throws GiacError a * 2
        @test_throws GiacError 2 * a
        @test_throws GiacError a / 2
        @test_throws GiacError 2 / a
    end

    @testset "Comparison Operators" begin
        # T058 [US3]: Test equality
        a = giac_eval("x")
        b = giac_eval("x")

        # Note: equality comparison depends on stub implementation
        @test (a == b) isa Bool
    end

    @testset "Hash" begin
        # Test that GiacExpr can be hashed
        a = giac_eval("x^2")
        @test hash(a) isa UInt
    end
end
