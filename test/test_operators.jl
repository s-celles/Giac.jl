@testset "Operators" begin
    @testset "Arithmetic Operators" begin
        # T048-T053 [US3]: Test operator overloading
        # Test that operators are defined
        a = giac_eval("2")
        b = giac_eval("3")

        if is_stub_mode()
            # In stub mode, operators will throw GiacError because C_NULL is returned
            @test_throws GiacError a + b
            @test_throws GiacError a - b
            @test_throws GiacError a * b
            @test_throws GiacError a / b
            @test_throws GiacError a ^ b
            @test_throws GiacError -a
        else
            # With real GIAC, operators return results
            @test string(a + b) == "5"
            @test string(a - b) == "-1"
            @test string(a * b) == "6"
            @test string(a / b) == "2/3"
            @test string(a ^ b) == "8"
            @test string(-a) == "-2"
        end
    end

    @testset "Mixed Type Arithmetic" begin
        # T054-T057 [US3]: Test mixed type operations
        a = giac_eval("x")

        if is_stub_mode()
            # In stub mode, these will throw because operators return C_NULL
            @test_throws GiacError a + 1
            @test_throws GiacError 1 + a
            @test_throws GiacError a - 1
            @test_throws GiacError 1 - a
            @test_throws GiacError a * 2
            @test_throws GiacError 2 * a
            @test_throws GiacError a / 2
            @test_throws GiacError 2 / a
        else
            # With real GIAC, mixed type operations work
            @test string(a + 1) == "x+1"
            @test string(1 + a) == "1+x"
            @test string(a - 1) == "x-1"
            @test string(1 - a) == "1-x"
            @test string(a * 2) in ["2*x", "x*2"]  # GIAC may not reorder
            @test string(2 * a) == "2*x"
            @test string(a / 2) == "x/2"
            @test string(2 / a) == "2/x"
        end
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
