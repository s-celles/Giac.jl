# Integration tests for 003-giac-introspection feature
# Tests for type introspection, to_julia conversions, Tier 1 functions, and typed accessors

@testset "Introspection (003-giac-introspection)" begin

    # ========================================================================
    # T-015: Scalar constructors and giac_eval
    # ========================================================================
    @testset "Scalar Constructors and giac_eval" begin
        if !Giac.is_stub_mode()
            # Integer evaluation
            result = giac_eval("42")
            @test string(result) == "42"
            @test to_julia(result) == 42

            # Float evaluation
            result = giac_eval("3.14159")
            @test occursin("3.14", string(result))

            # Expression evaluation
            result = giac_eval("2 + 3")
            @test string(result) == "5"
            @test to_julia(result) == 5

            # Symbolic evaluation
            result = giac_eval("x")
            @test string(result) == "x"

            # Complex expression
            result = giac_eval("x^2 + 2*x + 1")
            @test occursin("x", string(result))
        else
            @warn "Skipping scalar constructor tests - GIAC library not available (stub mode)"
            @test_broken false
        end
    end

    # ========================================================================
    # T-079-084: to_julia conversions
    # ========================================================================
    @testset "to_julia Conversions" begin
        if !Giac.is_stub_mode()
            # T-079: Integer conversion
            @testset "Integer → Int64" begin
                result = giac_eval("42")
                julia_val = to_julia(result)
                @test julia_val == 42
                @test julia_val isa Integer
            end

            # T-080: Rational conversion
            @testset "Fraction → Rational" begin
                result = giac_eval("3/7")
                julia_val = to_julia(result)
                @test julia_val == 3//7
                @test julia_val isa Rational
            end

            # T-081: Complex conversion
            @testset "Complex → ComplexF64" begin
                result = giac_eval("2+3*i")
                julia_val = to_julia(result)
                @test real(julia_val) ≈ 2.0
                @test imag(julia_val) ≈ 3.0
                @test julia_val isa Complex
            end

            # T-082: Matrix - currently returns GiacExpr (not yet implemented)
            @testset "Matrix" begin
                result = giac_eval("[[1,2],[3,4]]")
                julia_val = to_julia(result)
                # Currently returns GiacExpr for matrices
                @test julia_val isa GiacExpr
                @test occursin("1", string(julia_val))
                @test occursin("4", string(julia_val))
            end

            # T-083: Identifier - currently returns GiacExpr (not yet implemented)
            @testset "Identifier" begin
                result = giac_eval("x")
                julia_val = to_julia(result)
                # Currently returns GiacExpr for identifiers
                @test julia_val isa GiacExpr
                @test string(julia_val) == "x"
            end

            # T-084: Symbolic expression returns GiacExpr
            @testset "Symbolic Expression" begin
                result = giac_eval("sin(x) + cos(y)")
                julia_val = to_julia(result)
                # Symbolic expressions return as GiacExpr
                @test julia_val isa GiacExpr
                @test occursin("sin", string(julia_val))
                @test occursin("cos", string(julia_val))
            end

            # Vector - currently returns GiacExpr
            @testset "Vector" begin
                result = giac_eval("[1, 2, 3, 4, 5]")
                julia_val = to_julia(result)
                # Currently returns GiacExpr for vectors
                @test julia_val isa GiacExpr
                @test occursin("1", string(julia_val))
                @test occursin("5", string(julia_val))
            end

            # Boolean (GIAC represents true as 1)
            @testset "Boolean" begin
                result = giac_eval("true")
                julia_val = to_julia(result)
                @test julia_val == 1
            end

            # String
            @testset "String" begin
                result = giac_eval("\"hello\"")
                julia_val = to_julia(result)
                # Strings are returned as GiacExpr
                @test occursin("hello", string(julia_val))
            end

            # Infinity
            @testset "Infinity" begin
                result = giac_eval("infinity")
                julia_val = to_julia(result)
                # Check if it's infinity or symbolic (GiacExpr)
                @test julia_val isa GiacExpr || (julia_val isa Number && isinf(julia_val))
            end

            # Large integers
            @testset "Large Integer" begin
                result = giac_eval("factorial(20)")
                julia_val = to_julia(result)
                @test julia_val == factorial(big(20))
            end
        else
            @warn "Skipping to_julia conversion tests - GIAC library not available (stub mode)"
            @test_broken false
        end
    end

    # ========================================================================
    # T-143-145: Tier 1 functions
    # ========================================================================
    @testset "Tier 1 Functions" begin
        if !Giac.is_stub_mode()
            # T-143: sin(x) returns sin(x)
            @testset "Trigonometric Functions" begin
                x = giac_eval("x")

                result = sin(x)
                @test occursin("sin", string(result))

                result = cos(x)
                @test occursin("cos", string(result))

                result = tan(x)
                @test occursin("tan", string(result))

                # Numeric evaluation
                result = sin(giac_eval("0"))
                @test to_julia(result) == 0

                result = cos(giac_eval("0"))
                @test to_julia(result) == 1
            end

            @testset "Exponential and Logarithm" begin
                x = giac_eval("x")

                result = exp(x)
                @test occursin("exp", string(result))

                result = log(x)
                @test occursin("ln", string(result)) || occursin("log", string(result))

                result = sqrt(x)
                @test occursin("sqrt", string(result))

                # Numeric
                result = exp(giac_eval("0"))
                @test to_julia(result) == 1

                result = sqrt(giac_eval("4"))
                @test to_julia(result) == 2
            end

            @testset "Arithmetic Functions" begin
                result = abs(giac_eval("-5"))
                @test to_julia(result) == 5

                result = sign(giac_eval("-5"))
                @test to_julia(result) == -1

                result = floor(giac_eval("3.7"))
                @test to_julia(result) == 3

                result = ceil(giac_eval("3.2"))
                @test to_julia(result) == 4
            end

            @testset "Complex Functions" begin
                z = giac_eval("2+3*i")

                result = real(z)
                @test to_julia(result) == 2

                result = imag(z)
                @test to_julia(result) == 3

                result = conj(z)
                @test occursin("2", string(result))
                @test occursin("-3", string(result)) || occursin("- 3", string(result))
            end

            # T-144: diff(sin(x^2), x) = 2*x*cos(x^2)
            @testset "Calculus - Differentiation" begin
                x = giac_eval("x")
                expr = sin(x^2)
                result = Giac.giac_cmd(:diff, expr, x)
                result_str = string(result)
                # Should contain 2, x, and cos
                @test occursin("2", result_str)
                @test occursin("cos", result_str)
            end

            @testset "Calculus - Integration" begin
                x = giac_eval("x")
                # integrate(x^2, x) = x^3/3
                result = Giac.giac_cmd(:integrate, x^2, x)
                result_str = string(result)
                @test occursin("3", result_str)  # x^3/3 contains 3
            end

            # T-145: Mixed-type operators
            @testset "Mixed-Type Operators" begin
                x = giac_eval("x")

                # GiacExpr + Integer
                result = x + 1
                @test occursin("x", string(result))
                @test occursin("1", string(result))

                # Integer * GiacExpr
                result = 2 * x
                @test occursin("2", string(result))
                @test occursin("x", string(result))

                # GiacExpr ^ Integer
                result = x^3
                @test occursin("x", string(result))
                @test occursin("3", string(result))

                # Numeric mixed operations
                result = giac_eval("5") + 3
                @test to_julia(result) == 8

                result = 2 * giac_eval("7")
                @test to_julia(result) == 14
            end
        else
            @warn "Skipping Tier 1 function tests - GIAC library not available (stub mode)"
            @test_broken false
        end
    end

    # ========================================================================
    # T-102-105: Typed accessors and predicates
    # ========================================================================
    @testset "Typed Accessors" begin
        if !Giac.is_stub_mode()
            # T-102: frac_num/frac_den (tested via to_julia)
            @testset "Fraction Accessors" begin
                result = giac_eval("5/7")
                julia_val = to_julia(result)
                @test numerator(julia_val) == 5
                @test denominator(julia_val) == 7
            end

            # T-103: vect_size/vect_at (tested via string representation)
            @testset "Vector Accessors" begin
                result = giac_eval("[10, 20, 30]")
                result_str = string(result)
                @test occursin("10", result_str)
                @test occursin("20", result_str)
                @test occursin("30", result_str)
            end

            # T-104: symb_sommet_name (via string representation)
            @testset "Symbolic Accessors" begin
                result = giac_eval("sin(x)")
                result_str = string(result)
                @test occursin("sin", result_str)
                @test occursin("x", result_str)
            end
        else
            @warn "Skipping typed accessor tests - GIAC library not available (stub mode)"
            @test_broken false
        end
    end

    # ========================================================================
    # CxxWrap Gen type tests (when library available)
    # ========================================================================
    @testset "CxxWrap Gen Type" begin
        if !Giac.is_stub_mode() && Giac.GiacCxxBindings._have_library
            using Giac.GiacCxxBindings: giac_eval as cxx_eval, to_string, type, subtype
            using Giac.GiacCxxBindings: giac_sin, giac_cos, giac_diff
            using Giac.GiacCxxBindings: is_zero, is_one, is_integer

            @testset "Gen Type Information" begin
                # Integer type
                g = cxx_eval("42")
                @test type(g) == Giac.GiacCxxBindings.GENTYPE_INT

                # Symbolic type
                g = cxx_eval("x")
                @test type(g) == Giac.GiacCxxBindings.GENTYPE_IDNT

                # Expression type
                g = cxx_eval("x + 1")
                @test type(g) == Giac.GiacCxxBindings.GENTYPE_SYMB
            end

            @testset "Gen Predicates" begin
                @test is_zero(cxx_eval("0")) == true
                @test is_zero(cxx_eval("1")) == false
                @test is_one(cxx_eval("1")) == true
                @test is_one(cxx_eval("0")) == false
                @test is_integer(cxx_eval("42")) == true
                @test is_integer(cxx_eval("3.14")) == false
            end

            @testset "Gen Tier 1 Direct Wrappers" begin
                x = cxx_eval("x")

                result = giac_sin(x)
                @test occursin("sin", to_string(result))

                result = giac_cos(x)
                @test occursin("cos", to_string(result))

                # Differentiation
                result = giac_diff(cxx_eval("x^2"), x)
                @test occursin("2", to_string(result))
                @test occursin("x", to_string(result))
            end
        else
            @warn "Skipping CxxWrap Gen type tests - library not available"
            @test_broken false
        end
    end

    # ========================================================================
    # Function listing and help
    # ========================================================================
    @testset "Function Listing" begin
        if !Giac.is_stub_mode()
            @testset "help_count" begin
                hc = Giac.help_count()
                @test hc >= 2200
                @test hc isa Integer
            end

            @testset "VALID_COMMANDS" begin
                vc = length(Giac.VALID_COMMANDS)
                @test vc >= 2000
                @test "sin" in Giac.VALID_COMMANDS
                @test "cos" in Giac.VALID_COMMANDS
                @test "diff" in Giac.VALID_COMMANDS
                @test "integrate" in Giac.VALID_COMMANDS
                @test "factor" in Giac.VALID_COMMANDS
            end
        else
            @warn "Skipping function listing tests - GIAC library not available (stub mode)"
            @test_broken false
        end
    end

end
