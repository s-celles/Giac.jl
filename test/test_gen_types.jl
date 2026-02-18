# Tests for GenTypes module (041-scoped-type-enum)
using Test
using Giac
using Giac.GenTypes: T, INT, DOUBLE, ZINT, REAL, CPLX, POLY, IDNT, VECT, SYMB
using Giac.GenTypes: SPOL1, FRAC, EXT, STRNG, FUNC, ROOT, MOD, USER, MAP, EQW, GROB, POINTER, FLOAT

@testset "GenTypes Module" begin
    @testset "T enum exists and is importable" begin
        # T007: using Giac.GenTypes: T works
        @test T isa DataType
        @test T <: Enum
    end

    @testset "All 22 enum values have correct integer values" begin
        # T004: Verify all 22 enum values
        @test Int(INT) == 0
        @test Int(DOUBLE) == 1
        @test Int(ZINT) == 2
        @test Int(REAL) == 3
        @test Int(CPLX) == 4
        @test Int(POLY) == 5
        @test Int(IDNT) == 6
        @test Int(VECT) == 7
        @test Int(SYMB) == 8
        @test Int(SPOL1) == 9
        @test Int(FRAC) == 10
        @test Int(EXT) == 11
        @test Int(STRNG) == 12
        @test Int(FUNC) == 13
        @test Int(ROOT) == 14
        @test Int(MOD) == 15
        @test Int(USER) == 16
        @test Int(MAP) == 17
        @test Int(EQW) == 18
        @test Int(GROB) == 19
        @test Int(POINTER) == 20
        @test Int(FLOAT) == 21
    end

    @testset "Int() conversion of enum values" begin
        # T005: Int() conversion works
        @test Int(INT) isa Integer
        @test Int(VECT) isa Integer
        @test Int(SYMB) isa Integer
        @test Int(FLOAT) isa Integer
    end

    @testset "T() construction from integers" begin
        # T006: T() construction from integers
        @test T(0) == INT
        @test T(1) == DOUBLE
        @test T(7) == VECT
        @test T(8) == SYMB
        @test T(21) == FLOAT

        # Invalid values should throw
        @test_throws ArgumentError T(100)
        @test_throws ArgumentError T(-1)
    end

    @testset "US2: Complete C++ enum alignment" begin
        # T011-T019: Verify additional enum values
        @test Int(EXT) == 11      # T011
        @test Int(ROOT) == 14     # T012
        @test Int(MOD) == 15      # T013
        @test Int(USER) == 16     # T014
        @test Int(MAP) == 17      # T015
        @test Int(EQW) == 18      # T016
        @test Int(GROB) == 19     # T017
        @test Int(POINTER) == 20  # T018
        @test Int(FLOAT) == 21    # T019
    end

    @testset "Enum values are of type T" begin
        @test INT isa T
        @test DOUBLE isa T
        @test VECT isa T
        @test SYMB isa T
        @test FLOAT isa T
    end

    @testset "US1: giac_type returns T enum" begin
        # T008: giac_type(giac_eval("42")) == INT
        @test giac_type(giac_eval("42")) == INT
        @test giac_type(giac_eval("3.14")) == DOUBLE
        @test giac_type(giac_eval("[1, 2, 3]")) == VECT
        @test giac_type(giac_eval("x")) == IDNT
        @test giac_type(giac_eval("sin(x)")) == SYMB
        @test giac_type(giac_eval("3/4")) == FRAC

        # Verify giac_type returns T, not Int32
        @test giac_type(giac_eval("42")) isa T
    end

    @testset "US3: Legacy GIAC_* constants removed" begin
        # T020: GIAC_INT is not defined (throws error)
        @test !isdefined(Giac, :GIAC_INT)
        @test !isdefined(Giac, :GIAC_DOUBLE)
        @test !isdefined(Giac, :GIAC_ZINT)
        @test !isdefined(Giac, :GIAC_REAL)
        @test !isdefined(Giac, :GIAC_CPLX)

        # T021: GIAC_VECT is not defined (throws error)
        @test !isdefined(Giac, :GIAC_VECT)
        @test !isdefined(Giac, :GIAC_SYMB)
        @test !isdefined(Giac, :GIAC_IDNT)
        @test !isdefined(Giac, :GIAC_STRNG)
        @test !isdefined(Giac, :GIAC_FRAC)
        @test !isdefined(Giac, :GIAC_FUNC)

        # Legacy subtype constants also removed
        @test !isdefined(Giac, :GIAC_SEQ_VECT)
        @test !isdefined(Giac, :GIAC_SET_VECT)
        @test !isdefined(Giac, :GIAC_LIST_VECT)
    end
end
