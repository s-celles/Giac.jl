# Tests for Symbolics.jl extension (042-preserve-symbolic-sqrt)
# Verifies symbolic expression preservation during to_symbolics conversion

using Test
using Giac
using Symbolics
using Symbolics.SymbolicUtils: Term

@testset "Symbolics Extension - Symbolic Preservation" begin

    # ============================================================================
    # Foundational Helper Tests (Phase 2) - T008
    # ============================================================================
    @testset "Foundational Helpers" begin
        # Access internal functions via the extension module
        ext = Base.get_extension(Giac, :GiacSymbolicsExt)
        if ext !== nothing
            # T008: Tests for _is_function_call
            @testset "_is_function_call" begin
                @test ext._is_function_call("sqrt(2)") == true
                @test ext._is_function_call("sin(x + 1)") == true
                @test ext._is_function_call("f(a, b, c)") == true
                @test ext._is_function_call("x + 1") == false
                @test ext._is_function_call("123") == false
                @test ext._is_function_call("x") == false
            end

            # T008: Tests for _extract_function_parts
            @testset "_extract_function_parts" begin
                @test ext._extract_function_parts("sqrt(2)") == ("sqrt", "2")
                @test ext._extract_function_parts("sin(x + 1)") == ("sin", "x + 1")
                @test ext._extract_function_parts("f(a, b, c)") == ("f", "a, b, c")
            end

            # T008: Tests for _split_args
            @testset "_split_args" begin
                @test ext._split_args("a, b, c") == ["a", "b", "c"]
                @test ext._split_args("f(x), g(y)") == ["f(x)", "g(y)"]
                @test ext._split_args("a + b, c * d") == ["a + b", "c * d"]
                @test ext._split_args("") == String[]
                @test ext._split_args("single") == ["single"]
            end
        else
            @warn "Skipping helper tests - GiacSymbolicsExt not loaded"
            @test_broken false
        end
    end

    # ============================================================================
    # User Story 1: Square Root Preservation (P1 - MVP)
    # ============================================================================
    @testset "US1: Square Root Preservation" begin
        if !Giac.is_stub_mode()
            # T009: Test sqrt(2) preservation
            @testset "T009: sqrt(2) preserves symbolic sqrt" begin
                result = giac_eval("sqrt(2)")
                sym = to_symbolics(result)
                sym_str = string(sym)
                # Should contain sqrt, not 1.414...
                @test occursin("sqrt", sym_str) || occursin("^", sym_str)  # sqrt or power form
                @test !occursin("1.414", sym_str)
            end

            # T010: Test factor(x^8-1) contains sqrt(2)
            @testset "T010: factor(x^8-1) preserves sqrt(2)" begin
                result = giac_eval("factor(x^8-1)")
                sym = to_symbolics(result)
                sym_str = string(sym)
                # Should contain sqrt(2), not float approximation
                @test !occursin("1.414", sym_str)
            end

            # T011: Test nested sqrt preservation
            @testset "T011: nested sqrt(sqrt(2)) preservation" begin
                result = giac_eval("sqrt(sqrt(2))")
                sym = to_symbolics(result)
                sym_str = string(sym)
                @test !occursin("1.189", sym_str)  # sqrt(sqrt(2)) ≈ 1.189
            end

            # T012: Test mixed expression
            @testset "T012: mixed expression x^2 + sqrt(2)*x + 1" begin
                result = giac_eval("x^2 + sqrt(2)*x + 1")
                sym = to_symbolics(result)
                sym_str = string(sym)
                @test !occursin("1.414", sym_str)
            end
        else
            @warn "Skipping US1 tests - GIAC library not available (stub mode)"
            @test_broken false
        end
    end

    # ============================================================================
    # User Story 2: Other Symbolic Functions Preservation (P2)
    # ============================================================================
    @testset "US2: Other Symbolic Functions" begin
        if !Giac.is_stub_mode()
            # T017: Test cbrt(2) preservation
            @testset "T017: cbrt(2) preserves symbolic cbrt" begin
                result = giac_eval("2^(1/3)")  # GIAC uses 2^(1/3) for cbrt
                sym = to_symbolics(result)
                sym_str = string(sym)
                @test !occursin("1.259", sym_str)
            end

            # T018: Test exp(1) preservation
            @testset "T018: exp(1) preserves symbolic exp" begin
                result = giac_eval("exp(1)")
                sym = to_symbolics(result)
                sym_str = string(sym)
                @test !occursin("2.718", sym_str)
            end

            # T019: Test log(2) preservation
            @testset "T019: log(2) preserves symbolic log" begin
                result = giac_eval("log(2)")
                sym = to_symbolics(result)
                sym_str = string(sym)
                @test !occursin("0.693", sym_str)
            end

            # T020: Test pi preservation
            @testset "T020: pi returns Symbolics constant" begin
                result = giac_eval("pi")
                sym = to_symbolics(result)
                sym_str = string(sym)
                @test !occursin("3.141", sym_str)
            end

            # T021: Test trigonometric functions
            @testset "T021: sin, cos, tan preservation" begin
                # sin(1)
                result = giac_eval("sin(1)")
                sym = to_symbolics(result)
                @test !occursin("0.841", string(sym))

                # cos(1)
                result = giac_eval("cos(1)")
                sym = to_symbolics(result)
                @test !occursin("0.540", string(sym))
            end
        else
            @warn "Skipping US2 tests - GIAC library not available (stub mode)"
            @test_broken false
        end
    end

    # ============================================================================
    # User Story 3: Complex Numbers with Symbolic Parts (P3)
    # ============================================================================
    @testset "US3: Complex Numbers Symbolic Preservation" begin
        if !Giac.is_stub_mode()
            # T027: Test 1 + sqrt(2)*i
            @testset "T027: 1 + sqrt(2)*i preserves sqrt(2)" begin
                result = giac_eval("1 + sqrt(2)*i")
                sym = to_symbolics(result)
                sym_str = string(sym)
                @test !occursin("1.414", sym_str)
            end

            # T028: Test sqrt(2) + sqrt(3)*i
            @testset "T028: sqrt(2) + sqrt(3)*i preserves both sqrts" begin
                result = giac_eval("sqrt(2) + sqrt(3)*i")
                sym = to_symbolics(result)
                sym_str = string(sym)
                @test !occursin("1.414", sym_str)
                @test !occursin("1.732", sym_str)
            end

            # T029: Test exp(i*pi)
            @testset "T029: exp(i*pi) preserves symbolic form" begin
                result = giac_eval("exp(i*pi)")
                sym = to_symbolics(result)
                # exp(i*pi) = -1, but we want symbolic form preserved
                sym_str = string(sym)
                # This could simplify to -1 which is fine, or preserve exp
                @test sym_str == "-1" || occursin("exp", sym_str) || occursin("π", sym_str)
            end
        else
            @warn "Skipping US3 tests - GIAC library not available (stub mode)"
            @test_broken false
        end
    end

    # ============================================================================
    # Edge Cases and Backward Compatibility (Phase 6)
    # ============================================================================
    @testset "Edge Cases and Backward Compatibility" begin
        if !Giac.is_stub_mode()
            # T036: Mixed numeric/symbolic expressions
            @testset "T036: Mixed numeric and symbolic" begin
                result = giac_eval("2.5 + sqrt(2)")
                sym = to_symbolics(result)
                sym_str = string(sym)
                # 2.5 should stay as 2.5, sqrt(2) should not become 1.414
                @test occursin("2.5", sym_str) || occursin("5/2", sym_str)
                @test !occursin("1.414", sym_str)
            end

            # T037: Backward compatibility - simple expressions still work
            @testset "T037: Backward compatibility" begin
                # Simple polynomial
                result = giac_eval("x^2 + 2*x + 1")
                sym = to_symbolics(result)
                @test sym isa Num

                # Simple integer
                result = giac_eval("42")
                sym = to_symbolics(result)
                @test sym isa Num
            end
        else
            @warn "Skipping edge case tests - GIAC library not available (stub mode)"
            @test_broken false
        end
    end

end  # @testset "Symbolics Extension"
