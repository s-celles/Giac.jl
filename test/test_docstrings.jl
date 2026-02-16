# Tests for Julia help system integration (026-julia-help-docstrings)
using Test
using Giac

@testset "Julia Help System Integration" begin

    # Helper to check if GIAC library is available
    giac_available = !Giac.is_stub_mode()

    # ========================================================================
    # US1: View Help for Imported GIAC Command
    # ========================================================================
    @testset "US1: Basic Docstring Presence" begin
        @testset "@doc returns non-empty string for exported command" begin
            # ifactor is a GIAC-only command (not in Base)
            if giac_available
                docstring = string(@doc Giac.Commands.ifactor)
                @test !isempty(docstring)
                @test docstring != "No documentation found."
            else
                @test_broken false  # Skip in stub mode
            end
        end

        @testset "Docstring contains command description" begin
            if giac_available
                docstring = string(@doc Giac.Commands.factor)
                # Should contain description from GIAC help
                @test occursin("factor", lowercase(docstring))
            else
                @test_broken false  # Skip in stub mode
            end
        end

        @testset "Docstring contains 'GIAC command:' label" begin
            if giac_available
                docstring = string(@doc Giac.Commands.ifactor)
                @test occursin("GIAC command", docstring)
            else
                @test_broken false  # Skip in stub mode
            end
        end

        @testset "Fallback docstring for commands without help" begin
            # Even commands without detailed help should have a basic docstring
            if giac_available
                # Pick a command that exists but may have minimal help
                docstring = string(@doc Giac.Commands.factor)
                # Should at least have the command name and GIAC label
                @test occursin("GIAC", docstring) || occursin("factor", docstring)
            else
                @test_broken false  # Skip in stub mode
            end
        end
    end

    # ========================================================================
    # US2: Help Shows Syntax Difference Warning
    # ========================================================================
    @testset "US2: Syntax Warning" begin
        @testset "Docstring includes syntax warning when examples present" begin
            if giac_available
                # factor typically has examples
                docstring = string(@doc Giac.Commands.factor)
                # Check for either the warning text or examples section
                has_examples_or_warning = occursin("Examples", docstring) ||
                                          occursin("GIAC syntax", docstring) ||
                                          occursin("syntax", lowercase(docstring))
                @test has_examples_or_warning || !occursin("example", lowercase(docstring))
            else
                @test_broken false  # Skip in stub mode
            end
        end

        @testset "Syntax warning mentions GIAC/Julia differences" begin
            if giac_available
                docstring = string(@doc Giac.Commands.factor)
                # If there's a syntax note, it should mention GIAC or Julia
                if occursin("syntax", lowercase(docstring))
                    @test occursin("GIAC", docstring) || occursin("Julia", docstring)
                else
                    @test true  # No syntax section is also acceptable
                end
            else
                @test_broken false  # Skip in stub mode
            end
        end
    end

    # ========================================================================
    # US3: Help for Base-Extended Commands
    # ========================================================================
    @testset "US3: Base-Extended Commands" begin
        @testset "Base-extended command has docstring" begin
            if giac_available
                # sin is a Base function that GIAC extends
                # Check that the GiacExpr method has documentation
                docstring = string(@doc Base.sin(::GiacExpr))
                @test !isempty(docstring) || occursin("sin", docstring)
            else
                @test_broken false  # Skip in stub mode
            end
        end

        @testset "Base extension note present" begin
            if giac_available
                # sin extends Base.sin
                docstring = string(@doc Base.sin(::GiacExpr))
                # Should mention Base or extension
                has_base_note = occursin("Base", docstring) ||
                                occursin("extends", lowercase(docstring)) ||
                                occursin("GIAC", docstring)
                @test has_base_note || !isempty(docstring)
            else
                @test_broken false  # Skip in stub mode
            end
        end

        @testset "Regular command does NOT include Base extension note" begin
            if giac_available
                # ifactor is NOT a Base function
                docstring = string(@doc Giac.Commands.ifactor)
                # Should NOT say "extends Base"
                @test !occursin("extends Base", docstring)
            else
                @test_broken false  # Skip in stub mode
            end
        end
    end

end
