# MathJSON Conversion Extension Tests (054-mathjson-conversion)
# Tests bidirectional conversion between GiacExpr/GiacMatrix and MathJSON types

using MathJSON

@testset "MathJSON Conversion" begin

    # ============================================================================
    # US1: GiacExpr -> MathJSON (to_mathjson)
    # ============================================================================

    @testset "to_mathjson - basic numeric types" begin
        # INT -> NumberExpr(Int64)
        expr = giac_eval("42")
        result = to_mathjson(expr)
        @test result isa NumberExpr
        @test result.value == 42
        @test result.value isa Int64

        # Negative integer
        expr = giac_eval("-7")
        result = to_mathjson(expr)
        @test result isa NumberExpr
        @test result.value == -7

        # Zero
        expr = giac_eval("0")
        result = to_mathjson(expr)
        @test result isa NumberExpr
        @test result.value == 0

        # DOUBLE -> NumberExpr(Float64)
        expr = giac_eval("3.14")
        result = to_mathjson(expr)
        @test result isa NumberExpr
        @test result.value isa Float64
        @test result.value ≈ 3.14
    end

    @testset "to_mathjson - identifiers and constants" begin
        # Variable x -> SymbolExpr("x")
        expr = giac_eval("x")
        result = to_mathjson(expr)
        @test result isa SymbolExpr
        @test result.name == "x"

        # Variable y -> SymbolExpr("y")
        expr = giac_eval("y")
        result = to_mathjson(expr)
        @test result isa SymbolExpr
        @test result.name == "y"

        # Constant pi -> SymbolExpr("Pi")
        expr = giac_eval("pi")
        result = to_mathjson(expr)
        @test result isa SymbolExpr
        @test result.name == "Pi"

        # Constant e: GIAC evaluates "e" to exp(1) (SYMB type)
        expr = giac_eval("e")
        result = to_mathjson(expr)
        @test result isa FunctionExpr
        @test result.operator == :Exp
        @test result.arguments[1] isa NumberExpr
        @test result.arguments[1].value == 1

        # Constant i: GIAC evaluates "i" to complex 0+1*i (CPLX type)
        expr = giac_eval("i")
        result = to_mathjson(expr)
        @test result isa FunctionExpr
        @test result.operator == :Complex
        @test result.arguments[1] isa NumberExpr
        @test result.arguments[1].value == 0
        @test result.arguments[2] isa NumberExpr
        @test result.arguments[2].value == 1
    end

    @testset "to_mathjson - symbolic expressions" begin
        # sin(x) -> FunctionExpr(:Sin, [SymbolExpr("x")])
        expr = giac_eval("sin(x)")
        result = to_mathjson(expr)
        @test result isa FunctionExpr
        @test result.operator == :Sin
        @test length(result.arguments) == 1
        @test result.arguments[1] isa SymbolExpr
        @test result.arguments[1].name == "x"

        # cos(x) -> FunctionExpr(:Cos, ...)
        expr = giac_eval("cos(x)")
        result = to_mathjson(expr)
        @test result isa FunctionExpr
        @test result.operator == :Cos

        # exp(x) -> FunctionExpr(:Exp, ...)
        expr = giac_eval("exp(x)")
        result = to_mathjson(expr)
        @test result isa FunctionExpr
        @test result.operator == :Exp

        # sqrt(x) -> FunctionExpr(:Sqrt, ...)
        expr = giac_eval("sqrt(x)")
        result = to_mathjson(expr)
        @test result isa FunctionExpr
        @test result.operator == :Sqrt

        # x + 1 -> FunctionExpr(:Add, ...)
        @giac_var x
        expr = x + 1
        result = to_mathjson(expr)
        @test result isa FunctionExpr
        @test result.operator == :Add

        # x * y -> FunctionExpr(:Multiply, ...)
        @giac_var y
        expr = x * y
        result = to_mathjson(expr)
        @test result isa FunctionExpr
        @test result.operator == :Multiply

        # x^2 -> FunctionExpr(:Power, ...)
        expr = x^2
        result = to_mathjson(expr)
        @test result isa FunctionExpr
        @test result.operator == :Power
    end

    @testset "to_mathjson - unsupported types" begin
        # String type should throw error
        expr = giac_eval("\"hello\"")
        @test_throws ErrorException to_mathjson(expr)
    end

    # ============================================================================
    # US2: MathJSON -> GiacExpr (to_giac)
    # ============================================================================

    @testset "to_giac - NumberExpr" begin
        # Integer
        result = to_giac(NumberExpr(42))
        @test result isa GiacExpr
        @test string(result) == "42"

        # Float
        result = to_giac(NumberExpr(3.14))
        @test result isa GiacExpr
        @test string(result) == "3.14"

        # Zero
        result = to_giac(NumberExpr(0))
        @test result isa GiacExpr
        @test string(result) == "0"

        # Negative
        result = to_giac(NumberExpr(-5))
        @test result isa GiacExpr
        @test string(result) == "-5"
    end

    @testset "to_giac - SymbolExpr" begin
        # Variable
        result = to_giac(SymbolExpr("x"))
        @test result isa GiacExpr
        @test string(result) == "x"

        # Pi constant
        result = to_giac(SymbolExpr("Pi"))
        @test result isa GiacExpr
        @test string(result) == "pi"

        # ExponentialE constant (GIAC represents e as exp(1))
        result = to_giac(SymbolExpr("ExponentialE"))
        @test result isa GiacExpr
        @test string(result) == "exp(1)"

        # ImaginaryUnit constant
        result = to_giac(SymbolExpr("ImaginaryUnit"))
        @test result isa GiacExpr
        @test string(result) == "i"
    end

    @testset "to_giac - FunctionExpr" begin
        # Add: x + 1
        expr = FunctionExpr(:Add, AbstractMathJSONExpr[
            SymbolExpr("x"),
            NumberExpr(1),
        ])
        result = to_giac(expr)
        @test result isa GiacExpr
        @test string(result) == "x+1"

        # Sin(x)
        expr = FunctionExpr(:Sin, AbstractMathJSONExpr[SymbolExpr("x")])
        result = to_giac(expr)
        @test result isa GiacExpr
        @test string(result) == "sin(x)"

        # Power: x^2
        expr = FunctionExpr(:Power, AbstractMathJSONExpr[
            SymbolExpr("x"),
            NumberExpr(2),
        ])
        result = to_giac(expr)
        @test result isa GiacExpr
        @test string(result) == "x^2"

        # Nested: sin(x^2)
        inner = FunctionExpr(:Power, AbstractMathJSONExpr[
            SymbolExpr("x"),
            NumberExpr(2),
        ])
        expr = FunctionExpr(:Sin, AbstractMathJSONExpr[inner])
        result = to_giac(expr)
        @test result isa GiacExpr
        @test string(result) == "sin(x^2)"
    end

    @testset "to_giac - error handling" begin
        # StringExpr should throw
        @test_throws ErrorException to_giac(StringExpr("hello"))

        # Unsupported operator should warn (not error)
        expr = FunctionExpr(:ColorFromColorspace, AbstractMathJSONExpr[NumberExpr(1)])
        result = @test_logs (:warn, r"Unsupported MathJSON operator") to_giac(expr)
        @test result isa GiacExpr
    end

    # ============================================================================
    # US4: Extended types - FRAC, CPLX, VECT, Matrix, Equation
    # ============================================================================

    @testset "FRAC (rational) conversion" begin
        # to_mathjson: 3/4 -> FunctionExpr(:Rational, [3, 4])
        expr = giac_eval("3/4")
        result = to_mathjson(expr)
        @test result isa FunctionExpr
        @test result.operator == :Rational
        @test length(result.arguments) == 2
        @test result.arguments[1] isa NumberExpr
        @test result.arguments[1].value == 3
        @test result.arguments[2] isa NumberExpr
        @test result.arguments[2].value == 4

        # to_giac: FunctionExpr(:Rational, [3, 4]) -> 3/4
        mathjson = FunctionExpr(:Rational, AbstractMathJSONExpr[
            NumberExpr(3), NumberExpr(4),
        ])
        giac_result = to_giac(mathjson)
        @test string(giac_result) == "3/4"
    end

    @testset "CPLX (complex) conversion" begin
        # to_mathjson: 3+4*i -> FunctionExpr(:Complex, [3, 4])
        expr = giac_eval("3+4*i")
        result = to_mathjson(expr)
        @test result isa FunctionExpr
        @test result.operator == :Complex
        @test length(result.arguments) == 2

        # to_giac: FunctionExpr(:Complex, [3, 4]) -> 3+4*i
        mathjson = FunctionExpr(:Complex, AbstractMathJSONExpr[
            NumberExpr(3), NumberExpr(4),
        ])
        giac_result = to_giac(mathjson)
        @test string(giac_result) == "3+4*i"
    end

    @testset "VECT (vector/list) conversion" begin
        # to_mathjson: [1,2,3] -> FunctionExpr(:List, [...])
        expr = giac_eval("[1,2,3]")
        result = to_mathjson(expr)
        @test result isa FunctionExpr
        @test result.operator == :List
        @test length(result.arguments) == 3
        @test all(a -> a isa NumberExpr, result.arguments)
        @test result.arguments[1].value == 1
        @test result.arguments[2].value == 2
        @test result.arguments[3].value == 3

        # to_giac: FunctionExpr(:List, [1,2,3]) -> [1,2,3]
        mathjson = FunctionExpr(:List, AbstractMathJSONExpr[
            NumberExpr(1), NumberExpr(2), NumberExpr(3),
        ])
        giac_result = to_giac(mathjson)
        @test string(giac_result) == "[1,2,3]"
    end

    @testset "GiacMatrix conversion" begin
        # to_mathjson: [[1,2],[3,4]] -> FunctionExpr(:Matrix, [rows...])
        m = GiacMatrix([[1, 2], [3, 4]])
        result = to_mathjson(m)
        @test result isa FunctionExpr
        @test result.operator == :Matrix
        @test length(result.arguments) == 2
        # Each row is a :List
        @test result.arguments[1] isa FunctionExpr
        @test result.arguments[1].operator == :List
        @test result.arguments[2] isa FunctionExpr
        @test result.arguments[2].operator == :List
    end

    @testset "Equation conversion" begin
        # to_mathjson: x=1 -> FunctionExpr(:Equal, [x, 1])
        @giac_var x
        expr = x ~ 1
        result = to_mathjson(expr)
        @test result isa FunctionExpr
        @test result.operator == :Equal
        @test length(result.arguments) == 2

        # to_giac: FunctionExpr(:Equal, [x, 1]) -> equation
        mathjson = FunctionExpr(:Equal, AbstractMathJSONExpr[
            SymbolExpr("x"), NumberExpr(1),
        ])
        giac_result = to_giac(mathjson)
        @test string(giac_result) == "x=1"
    end

    # ============================================================================
    # US3: Round-Trip Fidelity
    # ============================================================================

    @testset "Round-trip: GiacExpr -> MathJSON -> GiacExpr" begin
        @giac_var x y

        # Simple polynomial
        original = x^2 + 2 * x + 1
        roundtrip = to_giac(to_mathjson(original))
        @test string(giac_eval("simplify(($(string(original)))-($(string(roundtrip))))")) == "0"

        # Trig expression
        original = giac_eval("sin(x)+cos(x)")
        mathjson = to_mathjson(original)
        roundtrip = to_giac(mathjson)
        @test string(giac_eval("simplify(($(string(original)))-($(string(roundtrip))))")) == "0"

        # Constant pi
        original = giac_eval("pi")
        roundtrip = to_giac(to_mathjson(original))
        @test string(roundtrip) == "pi"

        # Rational
        original = giac_eval("3/4")
        roundtrip = to_giac(to_mathjson(original))
        @test string(roundtrip) == "3/4"

        # Vector
        original = giac_eval("[1,2,3]")
        roundtrip = to_giac(to_mathjson(original))
        @test string(roundtrip) == "[1,2,3]"
    end

    @testset "Round-trip: MathJSON -> GiacExpr -> MathJSON" begin
        # Simple add
        original = FunctionExpr(:Add, AbstractMathJSONExpr[SymbolExpr("x"), NumberExpr(1)])
        roundtrip = to_mathjson(to_giac(original))
        @test roundtrip isa FunctionExpr
        @test roundtrip.operator == :Add

        # Sin(x)
        original = FunctionExpr(:Sin, AbstractMathJSONExpr[SymbolExpr("x")])
        roundtrip = to_mathjson(to_giac(original))
        @test roundtrip isa FunctionExpr
        @test roundtrip.operator == :Sin
        @test roundtrip.arguments[1] isa SymbolExpr
        @test roundtrip.arguments[1].name == "x"

        # Number
        original = NumberExpr(42)
        roundtrip = to_mathjson(to_giac(original))
        @test roundtrip isa NumberExpr
        @test roundtrip.value == 42
    end

    @testset "Round-trip: deeply nested expressions" begin
        # sin(cos(tan(x)))
        expr = giac_eval("sin(cos(tan(x)))")
        mathjson = to_mathjson(expr)
        roundtrip = to_giac(mathjson)
        @test string(giac_eval("simplify(($(string(expr)))-($(string(roundtrip))))")) == "0"

        # exp(ln(sqrt(x)))
        expr = giac_eval("exp(ln(sqrt(x)))")
        mathjson = to_mathjson(expr)
        roundtrip = to_giac(mathjson)
        # May simplify to sqrt(x) — just check it converts without error
        @test roundtrip isa GiacExpr
    end

end
