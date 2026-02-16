# Developer Guide

Welcome to the Giac.jl Developer Guide. This documentation is intended for developers who want to contribute to Giac.jl or understand its internal architecture.

## Audience

This guide is for:
- **Contributors** wanting to add new mathematical functions
- **Maintainers** needing to understand the codebase
- **Advanced users** curious about performance optimization

## Prerequisites

Before diving in, you should be familiar with:
- Julia programming fundamentals
- Basic understanding of C/C++ interop concepts
- Git version control

## Guide Contents

### [Package Architecture](architecture.md)
Understand how Giac.jl is structured, including the purpose of each source file and how they interact.

### [Performance Tiers](tier-system.md)
Learn about the three-tier performance system that powers Giac.jl's function calls, from high-performance C++ wrappers to flexible string evaluation.

### [Adding Functions](contributing.md)
Step-by-step guides for adding new mathematical functions at each tier level.

### [Memory Management](memory.md)
Understand how Giac.jl manages memory for C++ objects, including finalizers and thread safety.

### [Troubleshooting](troubleshooting.md)
Common issues and debugging strategies for development work.

## Quick Reference

| Task | Where to Start |
|------|----------------|
| Add a new high-performance function | [Performance Tiers](tier-system.md) then [Adding Functions](contributing.md) |
| Understand the codebase | [Package Architecture](architecture.md) |
| Debug a crash or memory issue | [Memory Management](memory.md) then [Troubleshooting](troubleshooting.md) |
| Fix a failing test | [Troubleshooting](troubleshooting.md) |

## Getting Started

1. Clone the repository and set up your development environment
2. Read the [Package Architecture](architecture.md) to understand the codebase structure
3. Familiarize yourself with the [Performance Tiers](tier-system.md) system
4. Follow the [Adding Functions](contributing.md) guide for your contribution

## Version Compatibility

This documentation applies to Giac.jl v0.x (current development version). API and internal structure may change before v1.0.
