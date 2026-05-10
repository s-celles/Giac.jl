#!/usr/bin/env julia
# unpin_pluto.jl — Remove [compat] constraints and the frozen manifest
# from one or more Pluto notebooks, so Pluto re-resolves to the latest
# registered versions on next open.
#
# Usage:
#   julia unpin_pluto.jl notebook.jl
#   julia unpin_pluto.jl *.jl
#   julia unpin_pluto.jl notebooks/

function unpin_notebook(path::AbstractString)
    content = read(path, String)
    original = content

    # 1. Strip the [compat] section inside PLUTO_PROJECT_TOML_CONTENTS
    #    (from "[compat]" up to the closing """)
    content = replace(content,
        r"\n\[compat\][^\"]*?(?=\"\"\")" => "")

    # 2. Empty PLUTO_MANIFEST_TOML_CONTENTS to force re-resolution
    content = replace(content,
        r"PLUTO_MANIFEST_TOML_CONTENTS = \"\"\".*?\"\"\""s =>
        "PLUTO_MANIFEST_TOML_CONTENTS = \"\"\"\"\"\"")

    if content == original
        println("  (no constraints found in $path)")
        return false
    end

    # Backup before writing
    cp(path, path * ".bak"; force=true)
    write(path, content)
    println("✓ $path  (backup: $path.bak)")
    return true
end

function process(arg::AbstractString)
    if isdir(arg)
        for f in readdir(arg; join=true)
            endswith(f, ".jl") && unpin_notebook(f)
        end
    elseif isfile(arg)
        unpin_notebook(arg)
    else
        @warn "Not found: $arg"
    end
end

if isempty(ARGS)
    println("Usage: julia unpin_pluto.jl <notebook.jl | directory> [...]")
    exit(1)
end

foreach(process, ARGS)