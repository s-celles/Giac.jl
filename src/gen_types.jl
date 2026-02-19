# GenTypes module - Scoped enum for GIAC expression types
# Feature: 041-scoped-type-enum
# Provides type-safe enum matching C++ gen_unary_types

"""
    GenTypes

A submodule containing the `T` enum for GIAC expression type constants.

This module provides type-safe, scoped access to GIAC's internal type system,
matching the C++ `gen_unary_types` enum exactly.

# Usage

```julia
using Giac.GenTypes: T, INT, VECT, SYMB

# Access type constants as module values
INT     # Machine integer (0)
DOUBLE  # Double-precision float (1)
VECT    # Vector/list/sequence (7)
SYMB    # Symbolic expression (8)

# Or use the T type for construction from integers
T(0)    # INT
T(7)    # VECT

# Use with giac_type()
expr = giac_eval("42")
giac_type(expr) == INT  # true

# Convert to integer
Int(VECT)  # 7
```

# Type Values

The enum values match the C++ `gen_unary_types` enum:
- Types 0-1 and 20-21 are "immediate" (no memory allocation)
- Types 2-19 are "pointer" types (require memory allocation)

See also: [`Giac.giac_type`](@ref)
"""
module GenTypes

"""
    T

Enum representing GIAC expression types, matching C++ `gen_unary_types`.

# Values

| Value | Int | C++ Name | Description |
|-------|-----|----------|-------------|
| `T.INT` | 0 | `_INT_` | Machine integer |
| `T.DOUBLE` | 1 | `_DOUBLE_` | Double-precision float |
| `T.ZINT` | 2 | `_ZINT` | Arbitrary precision integer |
| `T.REAL` | 3 | `_REAL` | Extended precision real |
| `T.CPLX` | 4 | `_CPLX` | Complex number |
| `T.POLY` | 5 | `_POLY` | Polynomial |
| `T.IDNT` | 6 | `_IDNT` | Identifier/variable |
| `T.VECT` | 7 | `_VECT` | Vector/list/sequence |
| `T.SYMB` | 8 | `_SYMB` | Symbolic expression |
| `T.SPOL1` | 9 | `_SPOL1` | Sparse polynomial |
| `T.FRAC` | 10 | `_FRAC` | Rational fraction |
| `T.EXT` | 11 | `_EXT` | Algebraic extension |
| `T.STRNG` | 12 | `_STRNG` | String |
| `T.FUNC` | 13 | `_FUNC` | Function reference |
| `T.ROOT` | 14 | `_ROOT` | Root of polynomial |
| `T.MOD` | 15 | `_MOD` | Modular arithmetic |
| `T.USER` | 16 | `_USER` | User-defined type |
| `T.MAP` | 17 | `_MAP` | Map/dictionary |
| `T.EQW` | 18 | `_EQW` | Equation writer data |
| `T.GROB` | 19 | `_GROB` | Graphic object |
| `T.POINTER` | 20 | `_POINTER_` | Raw pointer |
| `T.FLOAT` | 21 | `_FLOAT_` | Float (immediate) |

# Examples

```julia
using Giac.GenTypes: T, INT, VECT, FLOAT

# Check integer value
Int(INT) == 0     # true
Int(VECT) == 7    # true
Int(FLOAT) == 21  # true

# Create from integer
T(0) == INT       # true
T(7) == VECT      # true
```
"""
@enum T::Int32 begin
    INT = 0       # _INT_ - Machine integer (immediate)
    DOUBLE = 1    # _DOUBLE_ - Double-precision float (immediate)
    ZINT = 2      # _ZINT - Arbitrary precision integer
    REAL = 3      # _REAL - Extended precision real
    CPLX = 4      # _CPLX - Complex number
    POLY = 5      # _POLY - Polynomial
    IDNT = 6      # _IDNT - Identifier/variable
    VECT = 7      # _VECT - Vector/list/sequence
    SYMB = 8      # _SYMB - Symbolic expression
    SPOL1 = 9     # _SPOL1 - Sparse polynomial
    FRAC = 10     # _FRAC - Rational fraction
    EXT = 11      # _EXT - Algebraic extension
    STRNG = 12    # _STRNG - String
    FUNC = 13     # _FUNC - Function reference
    ROOT = 14     # _ROOT - Root of polynomial
    MOD = 15      # _MOD - Modular arithmetic
    USER = 16     # _USER - User-defined type
    MAP = 17      # _MAP - Map/dictionary
    EQW = 18      # _EQW - Equation writer data
    GROB = 19     # _GROB - Graphic object
    POINTER = 20  # _POINTER_ - Raw pointer (immediate)
    FLOAT = 21    # _FLOAT_ - Float (immediate)
end

export T
# Export all enum values for direct access after `using Giac.GenTypes`
export INT, DOUBLE, ZINT, REAL, CPLX, POLY, IDNT, VECT, SYMB
export SPOL1, FRAC, EXT, STRNG, FUNC, ROOT, MOD, USER, MAP, EQW, GROB, POINTER, FLOAT

end # module GenTypes
