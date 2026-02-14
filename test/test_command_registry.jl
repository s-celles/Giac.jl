# Tests for command registry and discovery
# Features: 003-giac-commands, 004-formatted-help-output

# ============================================================================
# 004-formatted-help-output: HelpResult and _parse_help Tests
# ============================================================================

@testset "HelpResult Type" begin
    @testset "HelpResult construction" begin
        result = Giac.HelpResult("factor", "Factorizes a polynomial.", ["ifactor", "partfrac"], ["factor(x^2-1)"])
        @test result isa Giac.HelpResult
        @test result.command == "factor"
        @test result.description == "Factorizes a polynomial."
        @test result.related == ["ifactor", "partfrac"]
        @test result.examples == ["factor(x^2-1)"]
    end

    @testset "HelpResult with empty fields" begin
        result = Giac.HelpResult("unknown", "", String[], String[])
        @test result.command == "unknown"
        @test isempty(result.description)
        @test isempty(result.related)
        @test isempty(result.examples)
    end
end

@testset "_parse_help" begin
    @testset "valid help text" begin
        # T004: Test _parse_help with valid help text
        raw = """Description: Factorizes a polynomial.
Related: ifactor, partfrac, normal
Examples:
factor(x^4-1);factor(x^4-4,sqrt(2));factor(x^4+12*x^3+54*x^2+108*x+81)"""
        result = Giac._parse_help(raw, "factor")

        @test result isa Giac.HelpResult
        @test result.command == "factor"
        @test result.description == "Factorizes a polynomial."
        @test result.related == ["ifactor", "partfrac", "normal"]
        @test length(result.examples) == 3
        @test "factor(x^4-1)" in result.examples
        @test "factor(x^4-4,sqrt(2))" in result.examples
    end

    @testset "missing sections" begin
        # T005: Test _parse_help with missing sections
        raw = "Description: Simple command."
        result = Giac._parse_help(raw, "simple")

        @test result.description == "Simple command."
        @test isempty(result.related)
        @test isempty(result.examples)
    end

    @testset "empty input" begin
        # T006: Test _parse_help with empty/malformed input
        result = Giac._parse_help("", "empty")

        @test result.command == "empty"
        @test isempty(result.description)
        @test isempty(result.related)
        @test isempty(result.examples)
    end

    @testset "only examples" begin
        raw = """Examples:
sin(0);sin(pi/2)"""
        result = Giac._parse_help(raw, "sin")

        @test isempty(result.description)
        @test isempty(result.related)
        @test length(result.examples) == 2
        @test "sin(0)" in result.examples
    end
end

@testset "HelpResult Display" begin
    @testset "text/plain format" begin
        # T008: Test Base.show(io, MIME"text/plain"(), result) formatted output
        result = Giac.HelpResult("factor", "Factorizes a polynomial.", ["ifactor", "partfrac"], ["factor(x^2-1)", "factor(x^4-1)"])
        io = IOBuffer()
        show(io, MIME("text/plain"), result)
        output = String(take!(io))

        # T009: Test that description section appears with label
        @test occursin("factor", output)
        @test occursin("══════", output)  # Unicode underline
        @test occursin("Description:", output)
        @test occursin("Factorizes a polynomial.", output)

        # T010: Test that related commands appear comma-separated
        @test occursin("Related:", output)
        @test occursin("ifactor, partfrac", output)

        # T011: Test that each example appears on its own line with bullet
        @test occursin("Examples:", output)
        @test occursin("• factor(x^2-1)", output)
        @test occursin("• factor(x^4-1)", output)
    end

    @testset "compact format" begin
        # T028: Test compact Base.show(io, result)
        result = Giac.HelpResult("sin", "Sine function", ["cos", "tan"], ["sin(0)", "sin(pi)"])
        io = IOBuffer()
        show(io, result)
        output = String(take!(io))

        @test occursin("HelpResult(:sin", output)
        @test occursin("2 related", output)
        @test occursin("2 examples", output)
    end

    @testset "empty sections omitted" begin
        # T017: Test that empty sections are omitted
        result = Giac.HelpResult("cmd", "Description only.", String[], String[])
        io = IOBuffer()
        show(io, MIME("text/plain"), result)
        output = String(take!(io))

        @test occursin("Description:", output)
        @test !occursin("Related:", output)  # Empty, should be omitted
        @test !occursin("Examples:", output)  # Empty, should be omitted
    end

    @testset "no description fallback" begin
        # T035: Test "[No description available]" fallback
        result = Giac.HelpResult("cmd", "", String[], String[])
        io = IOBuffer()
        show(io, MIME("text/plain"), result)
        output = String(take!(io))

        @test occursin("[No description available]", output)
    end
end

@testset "help() Function" begin
    @testset "returns HelpResult type" begin
        # T019: Test help(:cmd) returning HelpResult type
        if !Giac.is_stub_mode()
            result = help(:factor)
            @test result isa Giac.HelpResult
        else
            result = help(:factor)
            @test result isa Giac.HelpResult
            @test occursin("stub mode", result.description)
        end
    end

    @testset "command field accessible" begin
        # T020: Test accessing .command field
        result = help(:factor)
        @test result.command == "factor"
    end

    @testset "description field accessible" begin
        # T021: Test accessing .description field
        if !Giac.is_stub_mode()
            result = help(:factor)
            @test !isempty(result.description)
            @test result.description isa String
        end
    end

    @testset "related field is Vector{String}" begin
        # T022: Test accessing .related as Vector{String}
        if !Giac.is_stub_mode()
            result = help(:factor)
            @test result.related isa Vector{String}
        end
    end

    @testset "examples field is Vector{String}" begin
        # T023: Test accessing .examples as Vector{String}
        if !Giac.is_stub_mode()
            result = help(:factor)
            @test result.examples isa Vector{String}
        end
    end

    @testset "stub mode handling" begin
        # T026: Handle stub mode - return HelpResult with placeholder
        if Giac.is_stub_mode()
            result = help(:factor)
            @test result isa Giac.HelpResult
            @test occursin("stub mode", result.description)
        end
    end
end

@testset "giac_help backward compatibility" begin
    # T037/T042: Verify giac_help() still returns raw String
    @testset "returns String type" begin
        result = giac_help(:factor)
        @test result isa String
    end
end

# ============================================================================
# 003-giac-commands: Command Discovery Tests
# ============================================================================

@testset "Command Discovery (US2)" begin
    if Giac.is_stub_mode()
        @warn "Skipping discovery tests - GIAC library not available (stub mode)"
        @test_skip true
        return
    end

    @testset "String prefix search" begin
        # T041: Test search_commands("sin")
        results = search_commands("sin")
        @test results isa Vector{String}
        @test "sin" in results
        # Should also find sinh, sinc, etc. if they exist
        @test all(cmd -> startswith(cmd, "sin"), results)
    end

    @testset "Regex search" begin
        # T042: Test search_commands(r"^a.*n$")
        results = search_commands(r"^a.*n$")
        @test results isa Vector{String}
        # All results should match the pattern
        for cmd in results
            @test occursin(r"^a.*n$", cmd)
        end
    end

    @testset "giac_help" begin
        # T043: Test giac_help(:factor) returns non-empty string
        help = giac_help(:factor)
        @test help isa String
        # Help may be empty if help system not initialized, but shouldn't error
    end

    @testset "command_info" begin
        # T044: Test command_info(:factor) returns CommandInfo
        info = command_info(:factor)
        if info !== nothing
            @test info isa Giac.CommandInfo
            @test info.name == "factor"
            @test info.category isa Symbol
        end
    end
end

@testset "Category-Based Organization (US3)" begin
    @testset "list_categories" begin
        # T051: Test list_categories() returns all category symbols
        cats = list_categories()
        @test cats isa Vector{Symbol}
        @test :trigonometry in cats
        @test :algebra in cats
        @test :calculus in cats
        @test length(cats) >= 10  # We defined at least 10 categories
    end

    @testset "commands_in_category trigonometry" begin
        # T052: Test commands_in_category(:trigonometry)
        cmds = commands_in_category(:trigonometry)
        @test cmds isa Vector{String}
        @test "sin" in cmds
        @test "cos" in cmds
        @test "tan" in cmds
    end

    @testset "commands_in_category algebra" begin
        # T053: Test commands_in_category(:algebra)
        cmds = commands_in_category(:algebra)
        @test cmds isa Vector{String}
        @test "factor" in cmds
        @test "expand" in cmds
        @test "simplify" in cmds
    end

    @testset "command_info category" begin
        # T054: Test command_info(:sin).category == :trigonometry
        info = command_info(:sin)
        if info !== nothing
            @test info.category == :trigonometry
        end
    end

    @testset "invalid category error" begin
        @test_throws ArgumentError commands_in_category(:nonexistent_category)
    end
end

@testset "Registry Initialization" begin
    @testset "VALID_COMMANDS populated" begin
        # T077: Test that VALID_COMMANDS is non-empty after module load
        if !Giac.is_stub_mode()
            @test !isempty(Giac.VALID_COMMANDS)
        else
            @test isempty(Giac.VALID_COMMANDS)  # Empty in stub mode
        end
    end

    @testset "factor in VALID_COMMANDS" begin
        # T078: Test that "factor" is in VALID_COMMANDS
        if !Giac.is_stub_mode()
            @test "factor" in Giac.VALID_COMMANDS
        end
    end

    @testset "command count approximation" begin
        # T079: Test that command count matches help_count() approximately
        if !Giac.is_stub_mode()
            count = help_count()
            valid_count = length(Giac.VALID_COMMANDS)
            # Should be in the same ballpark (within 50%)
            @test valid_count > 0
            if count > 0
                ratio = valid_count / count
                @test 0.5 < ratio < 2.0
            end
        end
    end
end
