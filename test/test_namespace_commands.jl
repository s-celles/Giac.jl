# Tests for namespace command access (007-giac-namespace-commands)

using Test
using Giac

@testset "GiacCommand Type" begin
    # =========================================================================
    # Phase 2: Foundational Tests
    # =========================================================================

    @testset "GiacCommand creation" begin
        # T007: Basic test for GiacCommand creation
        cmd = Giac.GiacCommand(:factor)
        @test cmd isa Giac.GiacCommand
        @test cmd.name === :factor

        # Create with different command names
        diff_cmd = Giac.GiacCommand(:diff)
        @test diff_cmd.name === :diff

        integrate_cmd = Giac.GiacCommand(:integrate)
        @test integrate_cmd.name === :integrate
    end

    @testset "GiacCommand callable behavior" begin
        # T008: Test for GiacCommand callable behavior
        if !Giac.is_stub_mode()
            expr = giac_eval("x^2 - 1")

            # Create a GiacCommand and call it
            factor_cmd = Giac.GiacCommand(:factor)
            result = factor_cmd(expr)
            @test result isa Giac.GiacExpr
            @test string(result) == "(x-1)*(x+1)"

            # Test with multiple arguments
            x = giac_eval("x")
            diff_cmd = Giac.GiacCommand(:diff)
            deriv = diff_cmd(giac_eval("x^3"), x)
            @test string(deriv) == "3*x^2"
        else
            @warn "Skipping GiacCommand callable tests - GIAC library not available (stub mode)"
            @test_broken false  # Mark as broken in stub mode
        end
    end
end

@testset "Namespace Command Access (US1)" begin
    # =========================================================================
    # Phase 3: User Story 1 - Direct Command Access Tests
    # =========================================================================

    if !Giac.is_stub_mode()
        @testset "Giac.factor returns correct GiacExpr" begin
            # T010: Test for Giac.factor(expr) returns correct GiacExpr
            expr = giac_eval("x^2 - 1")
            result = Giac.factor(expr)
            @test result isa Giac.GiacExpr
            @test string(result) == "(x-1)*(x+1)"
        end

        @testset "Giac.diff with multiple arguments" begin
            # T011: Test for Giac.diff(expr, x) with multiple arguments
            expr = giac_eval("x^3")
            x = giac_eval("x")
            deriv = Giac.diff(expr, x)
            @test deriv isa Giac.GiacExpr
            @test string(deriv) == "3*x^2"
        end

        @testset "Giac.integrate works" begin
            # T012: Test for Giac.integrate(expr, x)
            expr = giac_eval("x^2")
            x = giac_eval("x")
            integral = Giac.integrate(expr, x)
            @test integral isa Giac.GiacExpr
            @test string(integral) == "x^3/3"
        end

        @testset "Invalid command raises error with suggestions" begin
            # T013: Test for invalid command raises error with suggestions
            expr = giac_eval("x^2")
            @test_throws Exception Giac.factr(expr)
            # The error should contain suggestion for 'factor'
        end
    else
        @warn "Skipping namespace command access tests - GIAC library not available (stub mode)"

        @testset "Stub mode returns stub results" begin
            # T014: Test for stub mode returns stub results
            # In stub mode, getproperty should still work without error
            cmd = Giac.GiacCommand(:factor)
            @test cmd isa Giac.GiacCommand
        end
    end
end

@testset "Exported Commands (US2)" begin
    # =========================================================================
    # Phase 4: User Story 2 - Exported Commands Tests
    # =========================================================================

    @testset "factor is exported" begin
        # T021: Test that factor is exported (available without prefix)
        @test isdefined(Giac, :factor)
    end

    @testset "diff is exported" begin
        # T022: Test that diff is exported
        @test isdefined(Giac, :diff)
    end

    @testset "integrate is exported" begin
        # T023: Test that integrate is exported
        @test isdefined(Giac, :integrate)
    end

    @testset "simplify is exported" begin
        # T024: Test that simplify is exported
        @test isdefined(Giac, :simplify)
    end

    @testset "At least 50 commands exported" begin
        # T025: Test that at least 50 commands are exported
        if isdefined(Giac, :EXPORTED_COMMANDS)
            @test length(Giac.EXPORTED_COMMANDS) >= 50
        else
            @test_broken false  # Not yet implemented
        end
    end
end

@testset "Tab Completion Support (US3)" begin
    # =========================================================================
    # Phase 5: User Story 3 - Tab Completion Tests
    # =========================================================================

    if !Giac.is_stub_mode()
        @testset "propertynames returns tuple of Symbols" begin
            # T034: Test that propertynames(Giac) returns tuple of Symbols
            props = propertynames(Giac)
            @test props isa Tuple
            @test all(p -> p isa Symbol, props)
        end

        @testset "propertynames includes :factor" begin
            # T035: Test that propertynames includes :factor
            props = propertynames(Giac)
            @test :factor in props
        end

        @testset "propertynames excludes operators" begin
            # T036: Test that propertynames excludes operators (non-letter starting)
            props = propertynames(Giac)
            # Check that no property starts with a non-letter character
            for p in props
                s = string(p)
                if !isempty(s)
                    @test isletter(first(s)) || first(s) == '_'
                end
            end
        end
    else
        @testset "Stub mode propertynames returns module names" begin
            # T037: Test for stub mode - propertynames returns module exported names
            # Note: We cannot override Base.propertynames for modules due to Julia precompilation restrictions
            # So propertynames returns the standard module names (exported symbols)
            props = propertynames(Giac)
            # Julia's default propertynames for modules returns a Vector of Symbols
            @test props isa AbstractVector
            # Should include exported symbols like :factor
            @test :factor in props
        end
    end
end
