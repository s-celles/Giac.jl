# Tests for namespace command access (007-giac-namespace-commands)
# Updated for 009-commands-submodule

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

@testset "Namespace Command Access (US1) - Updated for 009" begin
    # =========================================================================
    # Phase 3: User Story 1 - Command Access via Commands Submodule
    # =========================================================================

    if !Giac.is_stub_mode()
        @testset "Giac.Commands.factor returns correct GiacExpr" begin
            # T010: Test for Giac.Commands.factor(expr) returns correct GiacExpr
            expr = giac_eval("x^2 - 1")
            result = Giac.Commands.factor(expr)
            @test result isa Giac.GiacExpr
            @test string(result) == "(x-1)*(x+1)"
        end

        @testset "Giac.Commands.diff with multiple arguments" begin
            # T011: Test for Giac.Commands.diff(expr, x) with multiple arguments
            expr = giac_eval("x^3")
            x = giac_eval("x")
            deriv = Giac.Commands.diff(expr, x)
            @test deriv isa Giac.GiacExpr
            @test string(deriv) == "3*x^2"
        end

        @testset "Giac.Commands.integrate works" begin
            # T012: Test for Giac.Commands.integrate(expr, x)
            expr = giac_eval("x^2")
            x = giac_eval("x")
            integral = Giac.Commands.integrate(expr, x)
            @test integral isa Giac.GiacExpr
            @test string(integral) == "x^3/3"
        end

        @testset "Invalid command raises error with suggestions" begin
            # T013: Test for invalid command raises error with suggestions
            expr = giac_eval("x^2")
            @test_throws Exception invoke_cmd(:factr, expr)
            # The error should contain suggestion for 'factor'
        end
    else
        @warn "Skipping namespace command access tests - GIAC library not available (stub mode)"

        @testset "Stub mode returns stub results" begin
            # T014: Test for stub mode returns stub results
            # In stub mode, GiacCommand should still work without error
            cmd = Giac.GiacCommand(:factor)
            @test cmd isa Giac.GiacCommand
        end
    end
end

@testset "Commands Submodule Exports (US2) - Updated for 009" begin
    # =========================================================================
    # Phase 4: User Story 2 - Commands are in Giac.Commands, not main Giac
    # =========================================================================

    @testset "factor is in Giac.Commands" begin
        # T021: Test that factor is defined in Giac.Commands
        if !Giac.is_stub_mode()
            @test isdefined(Giac.Commands, :factor)
        else
            @test_skip true  # Commands not generated in stub mode
        end
    end

    @testset "diff is in Giac.Commands" begin
        # T022: Test that diff is in Giac.Commands
        # Note: diff is always defined because it's not in JULIA_CONFLICTS
        if !Giac.is_stub_mode()
            @test isdefined(Giac.Commands, :diff)
        else
            @test_skip true  # Commands not generated in stub mode
        end
    end

    @testset "integrate is in Giac.Commands" begin
        # T023: Test that integrate is in Giac.Commands
        if !Giac.is_stub_mode()
            @test isdefined(Giac.Commands, :integrate)
        else
            @test_skip true  # Commands not generated in stub mode
        end
    end

    @testset "invoke_cmd is exported from main Giac" begin
        # T024: Test that invoke_cmd is exported from main Giac module
        @test isdefined(Giac, :invoke_cmd)
        giac_exports = names(Giac)
        @test :invoke_cmd ∈ giac_exports
    end

    @testset "Commands are NOT exported from main Giac" begin
        # T025: Test that commands like factor are NOT directly exported from Giac
        giac_exports = names(Giac)
        @test :factor ∉ giac_exports
        @test :expand ∉ giac_exports
        @test :diff ∉ giac_exports
        @test :integrate ∉ giac_exports
    end
end

@testset "Tab Completion Support (US3) - Updated for 009" begin
    # =========================================================================
    # Phase 5: User Story 3 - Tab Completion via Commands Submodule
    # =========================================================================

    @testset "Giac.Commands has many exported symbols" begin
        if !Giac.is_stub_mode()
            # Commands submodule should have many exported commands
            commands_exports = names(Giac.Commands)
            @test length(commands_exports) > 100  # Many commands
        else
            # In stub mode, only invoke_cmd is exported
            commands_exports = names(Giac.Commands)
            @test :invoke_cmd ∈ commands_exports
            @warn "Skipping exported symbols count test - GIAC library not available (stub mode)"
        end
    end

    @testset "Core API in main Giac module" begin
        # Core types and functions should be in main Giac
        giac_exports = names(Giac)
        @test :GiacExpr ∈ giac_exports
        @test :giac_eval ∈ giac_exports
        @test :invoke_cmd ∈ giac_exports
        # Note: help is no longer exported (027-remove-help-function)
        # Use ?cmd or Giac.giac_help(:cmd) instead
        @test :giac_help ∈ giac_exports
    end
end

# ============================================================================
# 009-commands-submodule: invoke_cmd Tests
# ============================================================================

@testset "invoke_cmd Function (009)" begin
    if !Giac.is_stub_mode()
        @testset "invoke_cmd works for exportable commands" begin
            expr = giac_eval("x^2 - 1")
            result = invoke_cmd(:factor, expr)
            @test result isa GiacExpr
            @test string(result) == "(x-1)*(x+1)"
        end

        @testset "invoke_cmd works for conflicting commands" begin
            # eval, sin, etc. must use invoke_cmd
            # Reset warnings for clean test
            Giac.reset_conflict_warnings!()

            # eval is a conflicting command
            result = invoke_cmd(:eval, giac_eval("2+3"))
            @test result isa GiacExpr

            # sin is a conflicting command
            result2 = invoke_cmd(:sin, giac_eval("0"))
            @test string(result2) == "0"

            # Reset for other tests
            Giac.reset_conflict_warnings!()
        end

        @testset "invoke_cmd with multiple arguments" begin
            x = giac_eval("x")
            expr = giac_eval("x^3")
            deriv = invoke_cmd(:diff, expr, x)
            @test string(deriv) == "3*x^2"
        end
    end
end

@testset "Runtime Generated Functions (009)" begin
    if !Giac.is_stub_mode()
        @testset "Commands submodule has generated functions" begin
            # Commands should be defined in Giac.Commands
            @test isdefined(Giac.Commands, :factor)
            @test isdefined(Giac.Commands, :expand)
            @test isdefined(Giac.Commands, :simplify)
            @test isdefined(Giac.Commands, :diff)
            @test isdefined(Giac.Commands, :integrate)
        end

        @testset "Runtime-generated commands work correctly" begin
            # Test a runtime-generated function via Commands submodule
            if isdefined(Giac.Commands, :ifactor)
                result = Giac.Commands.ifactor(giac_eval("120"))
                @test result isa GiacExpr
                # 120 = 2^3 * 3 * 5
                str_result = string(result)
                @test occursin("2", str_result)
                @test occursin("3", str_result)
                @test occursin("5", str_result)
            end
        end

        @testset "Conflicting commands are NOT exported from Commands" begin
            # Commands in JULIA_CONFLICTS should NOT be exported from Commands
            commands_exports = names(Giac.Commands)
            @test :eval ∉ commands_exports
            @test :sin ∉ commands_exports
            @test :cos ∉ commands_exports
            @test :det ∉ commands_exports
        end

        @testset "Commands.invoke_cmd and Giac.invoke_cmd are the same" begin
            # invoke_cmd should be accessible from both
            expr = giac_eval("x^2 - 1")
            result1 = Giac.invoke_cmd(:factor, expr)
            result2 = Giac.Commands.invoke_cmd(:factor, expr)
            @test string(result1) == string(result2)
        end
    else
        @testset "Stub mode - invoke_cmd defined" begin
            # Even in stub mode, invoke_cmd should be defined
            @test isdefined(Giac, :invoke_cmd)
            @test isdefined(Giac.Commands, :invoke_cmd)
        end
    end
end

@testset "Module-Qualified Access (009)" begin
    if !Giac.is_stub_mode()
        @testset "Access via Giac.Commands.commandname works" begin
            expr = giac_eval("x^2 - 1")

            # Access via Commands submodule
            result = Giac.Commands.factor(expr)
            @test string(result) == "(x-1)*(x+1)"

            # Check expand works
            expr2 = giac_eval("(x-1)*(x+1)")
            result2 = Giac.Commands.expand(expr2)
            @test string(result2) == "x^2-1"
        end
    else
        @warn "Skipping Module-Qualified Access tests - GIAC library not available (stub mode)"
        @test_skip true
    end
end
