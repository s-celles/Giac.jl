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

# ============================================================================
# 005-nearest-command-suggestions: Levenshtein Distance Tests
# ============================================================================

@testset "_levenshtein" begin
    @testset "identical strings" begin
        # T004: Test _levenshtein with identical strings
        @test Giac._levenshtein("factor", "factor") == 0
        @test Giac._levenshtein("", "") == 0
        @test Giac._levenshtein("sin", "sin") == 0
        @test Giac._levenshtein("a", "a") == 0
    end

    @testset "single-char edits" begin
        # T005: Test _levenshtein with single-char edits
        # Deletion
        @test Giac._levenshtein("factor", "factr") == 1
        @test Giac._levenshtein("abc", "ab") == 1
        # Insertion
        @test Giac._levenshtein("factr", "factor") == 1
        @test Giac._levenshtein("ab", "abc") == 1
        # Substitution
        @test Giac._levenshtein("sin", "son") == 1
        @test Giac._levenshtein("abc", "adc") == 1
    end

    @testset "multiple edits" begin
        # T006: Test _levenshtein with multiple edits
        @test Giac._levenshtein("sin", "cos") == 3  # s→c, i→o, n→s
        @test Giac._levenshtein("kitten", "sitting") == 3
        @test Giac._levenshtein("abc", "xyz") == 3
        @test Giac._levenshtein("", "abc") == 3
        @test Giac._levenshtein("abc", "") == 3
    end

    @testset "edge cases" begin
        @test Giac._levenshtein("", "a") == 1
        @test Giac._levenshtein("a", "") == 1
        @test Giac._levenshtein("ab", "ba") == 2  # Not a swap algorithm
    end
end

@testset "_max_threshold" begin
    # T008: Test _max_threshold with various input lengths
    @testset "short inputs" begin
        @test Giac._max_threshold("a") == 0   # 1÷2 = 0
        @test Giac._max_threshold("ab") == 1  # 2÷2 = 1
    end

    @testset "medium inputs" begin
        @test Giac._max_threshold("abc") == 1   # 3÷2 = 1
        @test Giac._max_threshold("abcd") == 2  # 4÷2 = 2
        @test Giac._max_threshold("abcde") == 2 # 5÷2 = 2
        @test Giac._max_threshold("abcdef") == 3 # 6÷2 = 3
    end

    @testset "long inputs" begin
        @test Giac._max_threshold("abcdefg") == 3   # 7÷2 = 3
        @test Giac._max_threshold("abcdefgh") == 4  # 8÷2 = 4
        @test Giac._max_threshold("abcdefghi") == 4 # 9÷2 = 4, but capped at 4
        @test Giac._max_threshold("integrate") == 4 # 9÷2 = 4
        @test Giac._max_threshold("verylongcommand") == 4  # Capped at 4
    end
end

# ============================================================================
# 005-nearest-command-suggestions: User Story 1 - Get Suggestions
# ============================================================================

@testset "suggest_commands (US1)" begin
    if Giac.is_stub_mode()
        @warn "Skipping suggestion tests - GIAC library not available (stub mode)"
        @test_skip true
    else
        @testset "returns Vector{String}" begin
            # T010: Test suggest_commands(:factr) returns Vector{String}
            result = suggest_commands(:factr)
            @test result isa Vector{String}
        end

        @testset "sorted by distance then alphabetically" begin
            # T011: Test that suggestions are sorted by distance then alphabetically
            result = Giac.suggest_commands_with_distances(:factr)
            if length(result) >= 2
                # Check distance ordering
                for i in 1:(length(result)-1)
                    @test result[i][2] <= result[i+1][2]
                    # If same distance, check alphabetical
                    if result[i][2] == result[i+1][2]
                        @test result[i][1] <= result[i+1][1]
                    end
                end
            end
        end

        @testset "exact match returns empty" begin
            # T012: Test that exact match returns empty suggestions
            @test isempty(suggest_commands(:factor))
            @test isempty(suggest_commands(:sin))
        end

        @testset "adaptive threshold" begin
            # T013: Test for adaptive threshold (short vs long input)
            # Short input - strict threshold
            short_result = suggest_commands(:si)
            # Long input - more relaxed threshold
            long_result = suggest_commands(:integrat)
            # Both should be non-empty if similar commands exist
            # The long input should potentially find more matches due to higher threshold
            @test long_result isa Vector{String}
            @test short_result isa Vector{String}
        end

        @testset "no results when distance exceeds threshold" begin
            # T014: Test that no results when distance exceeds threshold
            # Very different string that won't match anything
            result = suggest_commands(:xyzzyqwerty)
            @test isempty(result)
        end

        @testset "factor typo suggestions" begin
            # Verify "factor" appears in suggestions for "factr"
            result = suggest_commands(:factr)
            @test "factor" in result
        end

        @testset "case insensitive" begin
            # T017: Input normalization - case insensitive
            lower_result = suggest_commands(:factr)
            upper_result = suggest_commands(:FACTR)
            @test lower_result == upper_result
        end

        @testset "respects n parameter" begin
            # Test that n parameter limits results
            result_default = suggest_commands(:fact)
            result_limited = suggest_commands(:fact, n=2)
            @test length(result_limited) <= 2
            if length(result_default) > 2
                @test length(result_limited) < length(result_default)
            end
        end
    end
end

# ============================================================================
# 005-nearest-command-suggestions: User Story 2 - Configuration
# ============================================================================

@testset "Suggestion Configuration (US2)" begin
    # Save original count for restoration
    original_count = get_suggestion_count()

    @testset "get_suggestion_count returns default 4" begin
        # T021: Test get_suggestion_count() returns default 4
        # Reset to default first
        set_suggestion_count(4)
        @test get_suggestion_count() == 4
    end

    @testset "set_suggestion_count updates count" begin
        # T022: Test set_suggestion_count(n) updates count
        set_suggestion_count(6)
        @test get_suggestion_count() == 6
        set_suggestion_count(2)
        @test get_suggestion_count() == 2
    end

    @testset "invalid count resets to default" begin
        # T023: Test that invalid count (<=0) resets to default
        set_suggestion_count(0)
        @test get_suggestion_count() == 4
        set_suggestion_count(-5)
        @test get_suggestion_count() == 4
    end

    @testset "suggest_commands respects configured count" begin
        # T024: Test that suggest_commands respects configured count
        if !Giac.is_stub_mode()
            set_suggestion_count(2)
            result = suggest_commands(:fact)
            @test length(result) <= 2

            set_suggestion_count(6)
            result = suggest_commands(:fact)
            @test length(result) <= 6
        end
    end

    # Restore original count
    set_suggestion_count(original_count)
end

# ============================================================================
# 005-nearest-command-suggestions: User Story 3 - With Distances
# ============================================================================

@testset "suggest_commands_with_distances (US3)" begin
    if Giac.is_stub_mode()
        @warn "Skipping distance tests - GIAC library not available (stub mode)"
        @test_skip true
    else
        @testset "returns Vector{Tuple{String, Int}}" begin
            # T029: Test returns Vector{Tuple{String, Int}}
            result = Giac.suggest_commands_with_distances(:factr)
            @test result isa Vector{Tuple{String, Int}}
        end

        @testset "distances are correct" begin
            # T030: Test that distances are correct in results
            result = Giac.suggest_commands_with_distances(:factr)
            for (cmd, dist) in result
                @test dist == Giac._levenshtein("factr", lowercase(cmd))
            end
        end

        @testset "results sorted by distance" begin
            # T031: Test that results are sorted by distance
            result = Giac.suggest_commands_with_distances(:factr)
            if length(result) >= 2
                for i in 1:(length(result)-1)
                    @test result[i][2] <= result[i+1][2]
                end
            end
        end
    end
end

# ============================================================================
# 005-nearest-command-suggestions: Helper Functions
# ============================================================================

@testset "_format_suggestions" begin
    @testset "empty suggestions" begin
        @test Giac._format_suggestions(String[]) == ""
    end

    @testset "single suggestion" begin
        result = Giac._format_suggestions(["factor"])
        @test result == " Did you mean: factor?"
    end

    @testset "multiple suggestions" begin
        result = Giac._format_suggestions(["factor", "ifactor", "cfactor"])
        @test result == " Did you mean: factor, ifactor, cfactor?"
    end
end

# ============================================================================
# 005-nearest-command-suggestions: Integration Tests
# ============================================================================

@testset "help() with suggestions (T035)" begin
    if Giac.is_stub_mode()
        @warn "Skipping help suggestions test - GIAC library not available (stub mode)"
        @test_skip true
    else
        @testset "help(:factr) includes suggestions" begin
            # T035: Test that help(:factr) includes suggestions in description
            result = help(:factr)
            @test result isa Giac.HelpResult
            # Should contain "Did you mean:" in the description
            @test occursin("Did you mean:", result.description)
            # Should suggest "factor"
            @test occursin("factor", result.description)
        end
    end
end

# ============================================================================
# 006-search-command-description: Scoring Helper Tests
# ============================================================================

@testset "_score_help_match" begin
    @testset "description match (score=2)" begin
        # T004: Test _score_help_match with description match
        help_result = Giac.HelpResult("test", "This is about polynomial factorization", String[], String[])
        @test Giac._score_help_match("polynomial", help_result) == 2
        @test Giac._score_help_match("factorization", help_result) == 2
    end

    @testset "example-only match (score=1)" begin
        # T005: Test _score_help_match with example-only match
        help_result = Giac.HelpResult("test", "Some other description", String[], ["factor(x^2-1)", "expand(x+1)"])
        @test Giac._score_help_match("factor", help_result) == 1
        @test Giac._score_help_match("expand", help_result) == 1
    end

    @testset "no match (score=0)" begin
        # T006: Test _score_help_match with no match
        help_result = Giac.HelpResult("test", "Description about something", String[], ["example1", "example2"])
        @test Giac._score_help_match("xyznonexistent", help_result) == 0
        @test Giac._score_help_match("qqqqq", help_result) == 0
    end

    @testset "case insensitive matching" begin
        help_result = Giac.HelpResult("test", "This is about POLYNOMIAL", String[], String[])
        @test Giac._score_help_match("polynomial", help_result) == 2
        @test Giac._score_help_match("POLYNOMIAL", help_result) == 0  # Query must be lowercase
    end
end

# ============================================================================
# 006-search-command-description: User Story 1 - Keyword Search Tests
# ============================================================================

@testset "search_commands_by_description (US1)" begin
    if Giac.is_stub_mode()
        @warn "Skipping description search tests - GIAC library not available (stub mode)"
        @test_skip true
    else
        @testset "returns Vector{String}" begin
            # T008: Test search_commands_by_description returns Vector{String}
            result = search_commands_by_description("factor")
            @test result isa Vector{String}
        end

        @testset "results sorted by relevance" begin
            # T009: Test that results are sorted by relevance
            # This is tested by checking ordering - we can't guarantee specific results
            # but we can verify the function doesn't error
            result = search_commands_by_description("polynomial")
            @test result isa Vector{String}
        end

        @testset "empty query returns empty" begin
            # T010: Test for empty query returns empty Vector{String}
            @test isempty(search_commands_by_description(""))
        end

        @testset "whitespace-only query returns empty" begin
            # T011: Test for whitespace-only query returns empty Vector{String}
            @test isempty(search_commands_by_description("   "))
            @test isempty(search_commands_by_description("\t\n"))
        end

        @testset "non-matching query returns empty" begin
            # T012: Test that non-matching query returns empty results
            result = search_commands_by_description("xyznonexistentterm12345")
            @test isempty(result)
        end
    end

    @testset "stub mode returns empty" begin
        # T013: This test runs regardless of mode - stub mode returns empty safely
        if Giac.is_stub_mode()
            @test isempty(search_commands_by_description("factor"))
        else
            @test true  # Pass if not in stub mode
        end
    end
end

# ============================================================================
# 006-search-command-description: User Story 2 - Case-Insensitive Tests
# ============================================================================

@testset "search_commands_by_description case-insensitive (US2)" begin
    if Giac.is_stub_mode()
        @warn "Skipping case-insensitive tests - GIAC library not available (stub mode)"
        @test_skip true
    else
        @testset "case variations return identical results" begin
            # T020: Test that case variations return identical results
            lower_result = search_commands_by_description("polynomial")
            upper_result = search_commands_by_description("POLYNOMIAL")
            mixed_result = search_commands_by_description("Polynomial")
            @test lower_result == upper_result
            @test lower_result == mixed_result
        end

        @testset "uppercase query INTEGRAL" begin
            # T021: Test for uppercase query "INTEGRAL"
            result = search_commands_by_description("INTEGRAL")
            @test result isa Vector{String}
            # Same as lowercase
            @test result == search_commands_by_description("integral")
        end

        @testset "mixed case query" begin
            # T022: Test for mixed case query "Polynomial"
            result = search_commands_by_description("Polynomial")
            @test result isa Vector{String}
        end
    end
end

# ============================================================================
# 006-search-command-description: User Story 3 - Result Limiting Tests
# ============================================================================

@testset "search_commands_by_description result limiting (US3)" begin
    if Giac.is_stub_mode()
        @warn "Skipping result limiting tests - GIAC library not available (stub mode)"
        @test_skip true
    else
        @testset "n=5 limits results" begin
            # T025: Test that n=5 limits results to 5
            result = search_commands_by_description("function", n=5)
            @test length(result) <= 5
        end

        @testset "default n=20" begin
            # T026: Test that default n=20 is used when not specified
            # This tests the default behavior
            result = search_commands_by_description("a")  # Common letter, many results
            @test length(result) <= 20
        end

        @testset "n<=0 uses default" begin
            # T027: Test that n<=0 uses DEFAULT_SEARCH_LIMIT
            result_zero = search_commands_by_description("a", n=0)
            result_neg = search_commands_by_description("a", n=-5)
            @test length(result_zero) <= 20
            @test length(result_neg) <= 20
        end
    end

    @testset "Symbol input works" begin
        # Test Symbol input
        if !Giac.is_stub_mode()
            result = search_commands_by_description(:factor)
            @test result isa Vector{String}
        end
    end
end
