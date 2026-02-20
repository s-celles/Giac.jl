# Upstream Issues

This document tracks known issues in upstream dependencies that affect Giac.jl functionality.

## SymbolicUtils.jl - Display Error with Negative Symbolic Coefficients

**Status**: Open  
**Affects**: `to_symbolics` display in REPL  
**Upstream Package**: [SymbolicUtils.jl](https://github.com/JuliaSymbolics/SymbolicUtils.jl)  
**First Observed**: 2026-02-20  
**Issue** https://github.com/JuliaSymbolics/SymbolicUtils.jl/issues/864
**PR** https://github.com/JuliaSymbolics/SymbolicUtils.jl/pull/865
**Workaround**: Using `@test_broken sym isa Num` in test_symbolics_ext.jl @testset "T010: factor(x^8-1) preserves sqrt(2)"