# Tests for output handling (029-output-handling, 030-to-julia-bool-conversion)
# Type introspection, conversion, and iteration
# Updated for 041-scoped-type-enum: Uses GenTypes.T enum instead of GIAC_* constants

using Test
using Giac
using Giac.GenTypes: T, INT, DOUBLE, ZINT, REAL, CPLX, VECT, SYMB, IDNT, FRAC, STRNG, FUNC
# Import specific functions to avoid ambiguity with Symbolics.jl
using Giac: numer, denom, is_integer, is_numeric, is_vector, is_symbolic
using Giac: is_identifier, is_fraction, is_complex, is_boolean, real_part, imag_part

@testset "Output Handling" begin

    # ========================================================================
    # Type Constants (041-scoped-type-enum)
    # ========================================================================
    @testset "T Enum Values Defined" begin
        # Verify all type enum values exist and have correct integer values
        @test Int(INT) == 0
        @test Int(DOUBLE) == 1
        @test Int(ZINT) == 2
        @test Int(REAL) == 3
        @test Int(CPLX) == 4
        @test Int(VECT) == 7
        @test Int(SYMB) == 8
        @test Int(IDNT) == 6
        @test Int(STRNG) == 12
        @test Int(FRAC) == 10
        @test Int(FUNC) == 13
    end

    # ========================================================================
    # Type Introspection (US2)
    # ========================================================================
    @testset "Type Introspection" begin
        if !Giac.is_stub_mode()
            @testset "giac_type returns correct T enum values" begin
                # Integer
                g_int = giac_eval("42")
                @test giac_type(g_int) == INT

                # Float
                g_float = giac_eval("3.14")
                @test giac_type(g_float) == DOUBLE

                # Vector
                g_vec = giac_eval("[1, 2, 3]")
                @test giac_type(g_vec) == VECT

                # Symbolic
                g_symb = giac_eval("sin(x)")
                @test giac_type(g_symb) in [SYMB, IDNT]

                # Identifier
                g_idnt = giac_eval("x")
                @test giac_type(g_idnt) == IDNT
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
            @testset "to_julia for INT returns Int64" begin
                g = giac_eval("42")
                result = to_julia(g)
                @test result isa Int64
                @test result == 42
            end

            @testset "to_julia for DOUBLE returns Float64" begin
                g = giac_eval("3.14")
                result = to_julia(g)
                @test result isa Float64
                @test result ≈ 3.14
            end

            @testset "to_julia for VECT returns Vector" begin
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
    # Boolean Conversion (030-to-julia-bool-conversion)
    # ========================================================================
    @testset "Boolean Conversion - to_julia" begin
        if !Giac.is_stub_mode()
            @testset "T005: to_julia(giac_eval(\"true\")) returns true::Bool" begin
                g = giac_eval("true")
                result = to_julia(g)
                @test result isa Bool
                @test result === true
            end

            @testset "T006: to_julia(giac_eval(\"false\")) returns false::Bool" begin
                g = giac_eval("false")
                result = to_julia(g)
                @test result isa Bool
                @test result === false
            end

            @testset "T007: to_julia(giac_eval(\"1==1\")) returns true::Bool" begin
                g = giac_eval("1==1")
                result = to_julia(g)
                @test result isa Bool
                @test result === true
            end

            @testset "T008: to_julia(giac_eval(\"1==0\")) returns false::Bool" begin
                g = giac_eval("1==0")
                result = to_julia(g)
                @test result isa Bool
                @test result === false
            end

            @testset "T013-T016: Boolean in control flow" begin
                # T013: Boolean in if statement
                result = to_julia(giac_eval("1==1"))
                @test if result; true else; false end

                # T014: Boolean with && operator
                @test to_julia(giac_eval("true")) && true
                @test !(to_julia(giac_eval("false")) && true)

                # T015: Boolean with || operator
                @test to_julia(giac_eval("true")) || false
                @test to_julia(giac_eval("false")) || true

                # T016: Boolean with ! (not) operator
                @test !to_julia(giac_eval("false"))
                @test !(!to_julia(giac_eval("true")))
            end

            @testset "T018-T021: Integer vs Boolean distinction" begin
                # T018: Integer 1 returns Int64
                g = giac_eval("1")
                result = to_julia(g)
                @test result isa Int64
                @test result == 1

                # T019: Integer 0 returns Int64
                g = giac_eval("0")
                result = to_julia(g)
                @test result isa Int64
                @test result == 0

                # T020: Integer 42 returns Int64
                g = giac_eval("42")
                result = to_julia(g)
                @test result isa Int64
                @test result == 42

                # T021: Integer 1 vs boolean true type comparison
                int_one = to_julia(giac_eval("1"))
                bool_true = to_julia(giac_eval("1==1"))
                @test int_one isa Int64
                @test bool_true isa Bool
                @test typeof(int_one) != typeof(bool_true)  # Different types
            end
        else
            @warn "Skipping boolean conversion tests - GIAC library not available (stub mode)"
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

            @testset "Vector with symbolic returns Vector{GiacExpr}" begin
                # If ANY element is symbolic, keep ALL as GiacExpr for consistency
                g = giac_eval("[1, x, 3]")
                result = to_julia(g)
                @test result isa Vector{GiacExpr}
                @test length(result) == 3
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

            # T023-T025: Base.convert(Bool, ...) tests (030-to-julia-bool-conversion)
            @testset "T023: convert(Bool, giac_eval(\"true\"))" begin
                g = giac_eval("true")
                result = convert(Bool, g)
                @test result isa Bool
                @test result === true
            end

            @testset "T024: convert(Bool, giac_eval(\"1\")) returns true" begin
                g = giac_eval("1")
                result = convert(Bool, g)
                @test result isa Bool
                @test result === true
            end

            @testset "T025: convert(Bool, giac_eval(\"2\")) throws InexactError" begin
                g = giac_eval("2")
                @test_throws InexactError convert(Bool, g)
            end

            @testset "convert(Bool, giac_eval(\"0\")) returns false" begin
                g = giac_eval("0")
                result = convert(Bool, g)
                @test result isa Bool
                @test result === false
            end
        else
            @warn "Skipping explicit conversion tests - GIAC library not available (stub mode)"
            @test_broken false
        end
    end

    # ========================================================================
    # Vector Boolean Narrowing (030-to-julia-bool-conversion)
    # ========================================================================
    @testset "T026: Vector with booleans" begin
        if !Giac.is_stub_mode()
            @testset "to_julia([true, false]) returns Vector{Bool}" begin
                g = giac_eval("[true, false]")
                result = to_julia(g)
                @test result isa Vector{Bool}
                @test result == [true, false]
            end

            @testset "Mixed boolean/integer vector" begin
                g = giac_eval("[true, 1, 2]")
                result = to_julia(g)
                # Mixed types - should be Any or promoted
                @test result isa Vector
            end
        else
            @warn "Skipping vector boolean narrowing tests - GIAC library not available (stub mode)"
            @test_broken false
        end
    end

    # ========================================================================
    # GiacMatrix Conversion (030-to-julia-bool-conversion)
    # ========================================================================
    @testset "T027: to_julia(::GiacMatrix)" begin
        if !Giac.is_stub_mode()
            @testset "to_julia(GiacMatrix) returns Julia Matrix" begin
                g = giac_eval("[[1, 2], [3, 4]]")
                m = GiacMatrix(g)
                result = to_julia(m)
                @test result isa Matrix
                @test size(result) == (2, 2)
                @test result[1, 1] == 1
                @test result[2, 2] == 4
            end

            @testset "to_julia(GiacMatrix) with booleans" begin
                g = giac_eval("[[true, false], [false, true]]")
                m = GiacMatrix(g)
                result = to_julia(m)
                @test result isa Matrix{Bool}
                @test result[1, 1] === true
                @test result[1, 2] === false
                @test result[2, 1] === false
                @test result[2, 2] === true
            end

            @testset "to_julia(GiacMatrix) with integers" begin
                g = giac_eval("[[1, 2, 3], [4, 5, 6]]")
                m = GiacMatrix(g)
                result = to_julia(m)
                @test result isa Matrix{Int64}
                @test result == [1 2 3; 4 5 6]
            end
        else
            @warn "Skipping GiacMatrix conversion tests - GIAC library not available (stub mode)"
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
                if giac_type(g) == ZINT
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

    # ========================================================================
    # solve Result Conversion (031-fix-solve-to-julia)
    # ========================================================================
    @testset "solve Result Conversion (031)" begin
        if !Giac.is_stub_mode()
            @testset "T002: _ptr_to_gen returns valid Gen" begin
                # Verify _ptr_to_gen works correctly
                g = giac_eval("[1, 2, 3]")
                gen = Giac._ptr_to_gen(g)
                @test gen !== nothing
            end

            @testset "T006: solve(x^2-1~0) |> to_julia returns Vector with -1 and 1" begin
                # Use giac_eval for direct GIAC commands
                result = giac_eval("solve(x^2-1,x)")
                julia_result = to_julia(result)
                @test julia_result isa Vector
                @test length(julia_result) == 2
                @test sort(julia_result) == [-1, 1]
            end

            @testset "T007: cSolve(x^2+1=0) |> to_julia returns Vector with complex solutions" begin
                # Use cSolve to get complex solutions (solve returns empty for x^2+1=0 in real mode)
                result = giac_eval("cSolve(x^2+1=0,x)")
                julia_result = to_julia(result)
                @test julia_result isa Vector
                @test length(julia_result) == 2
                # Complex solutions: i and -i converted to Julia Complex
                @test julia_result isa Vector{Complex{Int64}}
            end

            @testset "T008: Empty solution set returns empty Vector" begin
                # Use an unsolvable equation (0=1 has no solutions)
                result = giac_eval("solve(0=1,x)")
                julia_result = to_julia(result)
                @test julia_result isa Vector
                @test isempty(julia_result)
            end

            @testset "T015: giac_eval(\"[1,2,3]\") vector conversion" begin
                g = giac_eval("[1, 2, 3]")
                result = to_julia(g)
                @test result isa Vector{Int64}
                @test result == [1, 2, 3]
            end

            @testset "T021: Nested collections from systems of equations" begin
                # Use giac_eval for direct GIAC command
                result = giac_eval("solve([x+y=1,x-y=0],[x,y])")
                julia_result = to_julia(result)
                @test julia_result isa Vector
                # Should contain nested structure with solution values
            end
        else
            @warn "Skipping solve conversion tests - GIAC library not available (stub mode)"
            @test_broken false
        end
    end

end  # @testset "Output Handling"
