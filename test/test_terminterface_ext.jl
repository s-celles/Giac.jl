# TermInterface Extension Tests (Issue #3 task 3)
# Verifies that TermInterface.iscall / operation / arguments / maketerm /
# isexpr dispatch correctly to Giac's introspection methods on GiacExpr.

using TermInterface

@testset "TermInterface extension" begin

    @giac_var x y

    # ========================================================================
    # iscall / isexpr
    # ========================================================================

    @testset "iscall and isexpr" begin
        # Compound expressions
        @test TermInterface.iscall(sin(x)) == true
        @test TermInterface.iscall(x + y) == true
        @test TermInterface.iscall(x * y) == true
        @test TermInterface.isexpr(sin(x)) == true

        # Atomic
        @test TermInterface.iscall(x)              == false  # identifier
        @test TermInterface.iscall(giac_eval("1")) == false  # literal
        @test TermInterface.iscall(giac_eval("pi")) == false # constant
        @test TermInterface.isexpr(x) == false
    end

    # ========================================================================
    # operation
    # ========================================================================

    @testset "operation" begin
        @test TermInterface.operation(sin(x)) === sin
        @test TermInterface.operation(x + y) === +
        @test TermInterface.operation(x * y) === *
    end

    # ========================================================================
    # arguments
    # ========================================================================

    @testset "arguments" begin
        @test TermInterface.arguments(sin(x))           == [x]
        @test length(TermInterface.arguments(x + y))    == 2
        @test TermInterface.arguments(giac_eval("a*b*c")) |> length == 3
    end

    # ========================================================================
    # maketerm
    # ========================================================================

    @testset "maketerm" begin
        # Reconstruct sin(x) from op + args.
        rebuilt = TermInterface.maketerm(GiacExpr, sin, (x,))
        @test rebuilt isa GiacExpr
        @test string(rebuilt) == "sin(x)"

        # 2 + 3 == 5
        @test TermInterface.maketerm(
                GiacExpr, +, (giac_eval("2"), giac_eval("3"))
              ) == giac_eval("5")
    end

    # ========================================================================
    # End-to-end consistency: arguments(maketerm(op, args)) == args
    # ========================================================================

    @testset "round-trip" begin
        original = sin(x + 1)
        @test TermInterface.iscall(original)
        op = TermInterface.operation(original)
        args = TermInterface.arguments(original)
        rebuilt = TermInterface.maketerm(GiacExpr, op, Tuple(args))
        @test string(rebuilt) == string(original)
    end

    # ========================================================================
    # head / children (Issue #41)
    #
    # TermInterface's `iscall` docstring makes these mandatory: "If `iscall(x)`
    # is true, then also `isexpr(x)` *must* be true. […] This means that,
    # `head(x)` and `children(x)` must be defined. Together with `operation(x)`
    # and `arguments(x)`." A consumer written against the protocol's documented
    # spelling previously hit a MethodError where operation/arguments worked.
    #
    # Giac is a language in which every expression node is a function call, so
    # the two spellings coincide — as TermInterface's own docstring
    # anticipates for SymbolicUtils-like languages.
    # ========================================================================

    @testset "head and children" begin
        @testset "defined wherever isexpr is true" begin
            for e in (sin(x), x + y, x * y, giac_eval("a*b*c"), sin(x + 1))
                @test TermInterface.isexpr(e)
                @test TermInterface.head(e) === TermInterface.operation(e)
                @test TermInterface.children(e) == TermInterface.arguments(e)
            end
        end

        @testset "the iscall => isexpr implication holds" begin
            for e in (
                sin(x),
                x + y,
                x,
                giac_eval("1"),
                giac_eval("pi"),
                giac_eval("42"),
                giac_eval("[1,2,3]"),
            )
                TermInterface.iscall(e) && @test TermInterface.isexpr(e)
            end
        end

        @testset "concrete heads and children" begin
            @test TermInterface.head(sin(x)) === sin
            @test TermInterface.head(x + y) === +
            @test TermInterface.head(x * y) === *
            @test TermInterface.children(sin(x)) == [x]
            @test length(TermInterface.children(x + y)) == 2
            @test length(TermInterface.children(giac_eval("a*b*c"))) == 3
            @test TermInterface.children(sin(x)) isa Vector{GiacExpr}
        end

        @testset "sorted_children follows children" begin
            # TermInterface defaults `sorted_children` to `children`; Giac
            # stores its arguments in order, so the default is correct and a
            # consumer that asks for the deterministic spelling gets it.
            e = giac_eval("a*b*c")
            @test TermInterface.sorted_children(e) == TermInterface.children(e)
        end

        @testset "leaves have no head or children" begin
            # `isexpr` is false for these, so the protocol does not require
            # head/children to answer — and they must not answer silently
            # wrong. They raise, exactly as operation/arguments do.
            for leaf in (x, giac_eval("42"), giac_eval("pi"))
                @test !TermInterface.isexpr(leaf)
                @test_throws ArgumentError TermInterface.head(leaf)
                @test_throws ArgumentError TermInterface.children(leaf)
            end
        end

        @testset "a head/children traversal reaches literals" begin
            # The trap the issue calls out: a Giac numeric literal is a
            # `GiacExpr`, not a `Number`, so a walk written over
            # Number/symbol/call looks exhaustive but silently drops literals.
            # `to_julia` is what unwraps them.
            lit = giac_eval("42")
            @test !(lit isa Number)
            @test to_julia(lit) === 42

            leaves = Any[]
            walk(e) =
                TermInterface.isexpr(e) ? foreach(walk, TermInterface.children(e)) :
                push!(leaves, e)
            walk(giac_eval("2*x+3"))
            @test any(l -> to_julia(l) === 2, leaves)
            @test any(l -> to_julia(l) === 3, leaves)
            @test any(l -> string(l) == "x", leaves)
        end
    end
end
