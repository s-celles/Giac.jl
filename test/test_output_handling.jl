# Tests for output handling (029-output-handling)
# Type introspection, conversion, and iteration

using Test
using Giac
# Import specific functions to avoid ambiguity with Symbolics.jl
using Giac: numer, denom, is_integer, is_numeric, is_vector, is_symbolic
using Giac: is_identifier, is_fraction, is_complex, real_part, imag_part

@testset "Output Handling" begin

    # ========================================================================
    # Type Constants
    # ========================================================================
    @testset "Type Constants Defined" begin
        # Verify all type constants are exported and have expected values
        @test GIAC_INT isa Integer
        @test GIAC_DOUBLE isa Integer
        @test GIAC_ZINT isa Integer
        @test GIAC_REAL isa Integer
        @test GIAC_CPLX isa Integer
        @test GIAC_VECT isa Integer
        @test GIAC_SYMB isa Integer
        @test GIAC_IDNT isa Integer
        @test GIAC_STRNG isa Integer
        @test GIAC_FRAC isa Integer
        @test GIAC_FUNC isa Integer

        # Subtype constants
        @test GIAC_SEQ_VECT isa Integer
        @test GIAC_SET_VECT isa Integer
        @test GIAC_LIST_VECT isa Integer
    end

    # ========================================================================
    # Type Introspection (US2)
    # ========================================================================
    @testset "Type Introspection" begin
        if !Giac.is_stub_mode()
            @testset "giac_type returns correct constants" begin
                # Integer
                g_int = giac_eval("42")
                @test giac_type(g_int) == GIAC_INT

                # Float
                g_float = giac_eval("3.14")
                @test giac_type(g_float) == GIAC_DOUBLE

                # Vector
                g_vec = giac_eval("[1, 2, 3]")
                @test giac_type(g_vec) == GIAC_VECT

                # Symbolic
                g_symb = giac_eval("sin(x)")
                @test giac_type(g_symb) in [GIAC_SYMB, GIAC_IDNT]

                # Identifier
                g_idnt = giac_eval("x")
                @test giac_type(g_idnt) == GIAC_IDNT
            end

            @testset "is_integer predicate" begin
                @test is_integer(giac_eval("42")) == true
                @test is_integer(giac_eval("3.14")) == false
                @test is_integer(giac_eval("x")) == false
            end

            @testset "is_numeric predicate" begin
                @test is_numeric(giac_eval("42")) == true
                @test is_numeric(giac_eval("3.14")) == true
                @test is_numeric(giac_eval("x")) == false
            end

            @testset "is_vector predicate" begin
                @test is_vector(giac_eval("[1, 2, 3]")) == true
                @test is_vector(giac_eval("42")) == false
            end

            @testset "is_symbolic predicate" begin
                @test is_symbolic(giac_eval("sin(x)")) == true
                @test is_symbolic(giac_eval("42")) == false
            end

            @testset "is_identifier predicate" begin
                @test is_identifier(giac_eval("x")) == true
                @test is_identifier(giac_eval("sin(x)")) == false
            end

            @testset "is_fraction predicate" begin
                @test is_fraction(giac_eval("3/4")) == true
                @test is_fraction(giac_eval("42")) == false
            end

            @testset "is_complex predicate" begin
                @test is_complex(giac_eval("3+4*i")) == true
                @test is_complex(giac_eval("42")) == false
            end
        else
            @warn "Skipping type introspection tests - GIAC library not available (stub mode)"
            @test_broken false
        end
    end

    # ========================================================================
    # Type Conversion (US1)
    # ========================================================================
    @testset "Type Conversion - to_julia" begin
        if !Giac.is_stub_mode()
            @testset "to_julia for GIAC_INT returns Int64" begin
                g = giac_eval("42")
                result = to_julia(g)
                @test result isa Int64
                @test result == 42
            end

            @testset "to_julia for GIAC_DOUBLE returns Float64" begin
                g = giac_eval("3.14")
                result = to_julia(g)
                @test result isa Float64
                @test result ≈ 3.14
            end

            @testset "to_julia for GIAC_VECT returns Vector" begin
                g = giac_eval("[1, 2, 3]")
                result = to_julia(g)
                @test result isa Vector
                @test length(result) == 3
            end

            @testset "to_julia for symbolic returns GiacExpr" begin
                g = giac_eval("x + 1")
                result = to_julia(g)
                @test result isa GiacExpr
            end

            @testset "MVP criterion: zeros conversion" begin
                # to_julia(zeros(x^2-1)) should return [-1, 1]::Vector{Int64}
                g = giac_eval("zeros(x^2-1)")
                result = to_julia(g)
                @test result isa Vector{Int64}
                @test sort(result) == [-1, 1]
            end
        else
            @warn "Skipping type conversion tests - GIAC library not available (stub mode)"
            @test_broken false
        end
    end

    # ========================================================================
    # Vector Indexing and Iteration (US3)
    # ========================================================================
    @testset "Vector Indexing" begin
        if !Giac.is_stub_mode()
            @testset "Base.length for vectors" begin
                g = giac_eval("[1, 2, 3, 4, 5]")
                @test length(g) == 5

                g_scalar = giac_eval("42")
                @test length(g_scalar) == 1
            end

            @testset "Base.getindex with 1-based indexing" begin
                g = giac_eval("[10, 20, 30]")
                @test to_julia(g[1]) == 10
                @test to_julia(g[2]) == 20
                @test to_julia(g[3]) == 30
            end

            @testset "BoundsError for invalid indices" begin
                g = giac_eval("[1, 2, 3]")
                @test_throws BoundsError g[0]
                @test_throws BoundsError g[4]
            end

            @testset "Error for indexing non-vectors" begin
                g = giac_eval("42")
                @test_throws ErrorException g[1]
            end

            @testset "Base.iterate protocol" begin
                g = giac_eval("[1, 2, 3]")
                collected = collect(g)
                @test length(collected) == 3
                @test all(e -> e isa GiacExpr, collected)
            end
        else
            @warn "Skipping vector indexing tests - GIAC library not available (stub mode)"
            @test_broken false
        end
    end

    # ========================================================================
    # Fraction and Complex Components (US4)
    # ========================================================================
    @testset "Fraction and Complex Components" begin
        if !Giac.is_stub_mode()
            @testset "numer for fraction" begin
                g = giac_eval("3/4")
                if is_fraction(g)
                    n = numer(g)
                    @test to_julia(n) == 3
                end
            end

            @testset "denom for fraction" begin
                g = giac_eval("3/4")
                if is_fraction(g)
                    d = denom(g)
                    @test to_julia(d) == 4
                end
            end

            @testset "numer for integer returns itself" begin
                g = giac_eval("5")
                n = numer(g)
                @test to_julia(n) == 5
            end

            @testset "denom for integer returns 1" begin
                g = giac_eval("5")
                d = denom(g)
                @test to_julia(d) == 1
            end

            @testset "real_part for complex" begin
                g = giac_eval("3+4*i")
                if is_complex(g)
                    re = real_part(g)
                    @test to_julia(re) ≈ 3.0
                end
            end

            @testset "imag_part for complex" begin
                g = giac_eval("3+4*i")
                if is_complex(g)
                    im = imag_part(g)
                    @test to_julia(im) ≈ 4.0
                end
            end
        else
            @warn "Skipping fraction/complex tests - GIAC library not available (stub mode)"
            @test_broken false
        end
    end

    # ========================================================================
    # Vector Type Narrowing (US5)
    # ========================================================================
    @testset "Vector Type Narrowing" begin
        if !Giac.is_stub_mode()
            @testset "All integers returns Vector{Int64}" begin
                g = giac_eval("[1, 2, 3]")
                result = to_julia(g)
                @test result isa Vector{Int64}
            end

            @testset "Mixed numeric returns promoted type" begin
                g = giac_eval("[1, 2.5, 3]")
                result = to_julia(g)
                @test result isa Vector{Float64}
            end

            @testset "Vector with symbolic returns Vector{Any}" begin
                g = giac_eval("[1, x, 3]")
                result = to_julia(g)
                @test result isa Vector{Any}
            end

            @testset "Empty vector handling" begin
                g = giac_eval("[]")
                result = to_julia(g)
                @test result isa Vector
                @test length(result) == 0
            end
        else
            @warn "Skipping type narrowing tests - GIAC library not available (stub mode)"
            @test_broken false
        end
    end

    # ========================================================================
    # Explicit Type Conversion (US6)
    # ========================================================================
    @testset "Explicit Type Conversion" begin
        if !Giac.is_stub_mode()
            @testset "convert(Int64, g)" begin
                g = giac_eval("42")
                result = convert(Int64, g)
                @test result isa Int64
                @test result == 42
            end

            @testset "convert(Float64, g)" begin
                g = giac_eval("3.14")
                result = convert(Float64, g)
                @test result isa Float64
                @test result ≈ 3.14
            end

            @testset "convert(Vector, g)" begin
                g = giac_eval("[1, 2, 3]")
                result = convert(Vector, g)
                @test result isa Vector
            end

            @testset "convert with incompatible type throws" begin
                g = giac_eval("x")  # symbolic
                @test_throws MethodError convert(Int64, g)
            end
        else
            @warn "Skipping explicit conversion tests - GIAC library not available (stub mode)"
            @test_broken false
        end
    end

    # ========================================================================
    # Edge Cases
    # ========================================================================
    @testset "Edge Cases" begin
        if !Giac.is_stub_mode()
            @testset "Deeply nested vectors" begin
                g = giac_eval("[[1, 2], [3, 4]]")
                result = to_julia(g)
                @test result isa Vector
                @test length(result) == 2
            end

            @testset "firstindex and lastindex" begin
                g = giac_eval("[1, 2, 3]")
                @test firstindex(g) == 1
                @test lastindex(g) == 3
            end

            @testset "eachindex" begin
                g = giac_eval("[1, 2, 3]")
                indices = collect(eachindex(g))
                @test indices == [1, 2, 3]
            end

            @testset "Very large BigInt values" begin
                # Test that very large integers are handled correctly
                large_int_str = "10^100"
                g = giac_eval(large_int_str)
                if giac_type(g) == GIAC_ZINT
                    result = to_julia(g)
                    @test result isa BigInt
                    @test result == big(10)^100
                end
            end
        else
            @warn "Skipping edge case tests - GIAC library not available (stub mode)"
            @test_broken false
        end
    end

end  # @testset "Output Handling"
