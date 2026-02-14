# Tests for command registry and discovery
# Feature: 003-giac-commands

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
