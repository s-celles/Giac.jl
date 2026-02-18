# Linear Algebra

Giac.jl provides comprehensive symbolic linear algebra capabilities including matrix operations, determinants, eigenvalues, and linear system solving.

## Setup

```julia
using Giac, LinearAlgebra
using Giac.Commands: eigenvalues, linsolve

@giac_var a b c d x y
```

## Matrix Creation

### Numeric Matrices

Create matrices from Julia arrays:

```julia
A = GiacMatrix([1 2; 3 4])
# 2×2 GiacMatrix:
#  1  2
#  3  4
```

### Symbolic Matrices

Create matrices with symbolic entries:

```julia
@giac_var a b c d
B = GiacMatrix([[a, b],
                [c, d]])
# 2×2 GiacMatrix:
#  a  b
#  c  d
```

### Symbol Constructor

Create large symbolic matrices using the symbol constructor:

```julia
@giac_several_vars m 2 2
M = GiacMatrix([[m11, m12],
                [m21, m22]])
det(M)  # m11*m22-m12*m21

# Or use the compact constructor:
M = GiacMatrix(:m, 3, 3)
# 3×3 GiacMatrix with entries m_1_1, m_1_2, ...
```

For very large matrices:

```julia
M = GiacMatrix(:m, 100, 100)
# 100×100 GiacMatrix:
#   m_1_1    m_1_2    m_1_3    ...    m_1_100
#   m_2_1    m_2_2    m_2_3    ...    m_2_100
#      ⋮        ⋮        ⋮     ⋱          ⋮
# m_100_1  m_100_2  m_100_3   ...  m_100_100
```

## Determinant

Compute the determinant using `det`:

```julia
A = GiacMatrix([1 2; 3 4])
det(A)
# Output: -2

# Symbolic determinant
@giac_var a b c d
B = GiacMatrix([[a, b], [c, d]])
det(B)
# Output: a*d-b*c
```

## Inverse

Compute the matrix inverse using `inv`:

```julia
A = GiacMatrix([1 2; 3 4])
inv(A)
# Returns the inverse matrix
```

For singular matrices, GIAC will return an error.

## Trace

Compute the trace (sum of diagonal elements) using `tr`:

```julia
A = GiacMatrix([1 2; 3 4])
tr(A)
# Output: 5
```

## Transpose

Compute the transpose using `transpose`:

```julia
A = GiacMatrix([1 2; 3 4])
transpose(A)
# 2×2 GiacMatrix:
#  1  3
#  2  4
```

## Eigenvalues and Eigenvectors

### Eigenvalues

Compute eigenvalues using the `eigenvalues` command from `Giac.Commands`:

```julia
using Giac.Commands: eigenvalues

A = GiacMatrix([2 1; 1 2])
# Convert GiacMatrix to GiacExpr via ptr for eigenvalues command
eigenvalues(GiacExpr(A.ptr))
# Output: 3,1
```

### Characteristic Polynomial

The characteristic polynomial can be computed for eigenvalue analysis.

## Linear System Solving

### Using linsolve

Solve systems of linear equations using `linsolve`:

```julia
using Giac.Commands: linsolve

@giac_var x y

# System: x + y = 3, x - y = 1
linsolve([x + y ~ 3, x - y ~ 1], [x, y])
# Output: [2, 1]
```

### Using solve

The general `solve` command also works for linear systems:

```julia
using Giac.Commands: solve

solve([x + y ~ 3, x - y ~ 1], [x, y])
# Returns the solution
```

## Matrix Rank

Compute the rank of a matrix using `invoke_cmd(:rank, ...)`:

```julia
A = GiacMatrix([1 2 3; 4 5 6; 7 8 9])
# Use invoke_cmd because rank conflicts with LinearAlgebra.rank
# Convert GiacMatrix to GiacExpr via ptr
invoke_cmd(:rank, GiacExpr(A.ptr))
# Output: 2 (linearly dependent rows)
```

## Matrix Operations

### Addition and Subtraction

```julia
A = GiacMatrix([1 2; 3 4])
B = GiacMatrix([5 6; 7 8])

A + B
# 2×2 GiacMatrix:
#  6   8
# 10  12

A - B
# 2×2 GiacMatrix:
# -4  -4
# -4  -4
```

### Matrix Multiplication

```julia
A = GiacMatrix([1 2; 3 4])
B = GiacMatrix([5 6; 7 8])

A * B
# 2×2 GiacMatrix:
# 19  22
# 43  50
```

### Scalar Multiplication

```julia
A = GiacMatrix([1 2; 3 4])

2 * A
# 2×2 GiacMatrix:
# 2  4
# 6  8
```

### Matrix Powers

```julia
A = GiacMatrix([1 2; 3 4])

A^2
# Computes A * A
```

## Table of Functions

| Function | Description |
|----------|-------------|
| `GiacMatrix(array)` | Create symbolic matrix from array |
| `GiacMatrix(:sym, m, n)` | Create m×n symbolic matrix |
| `det(M)` | Determinant |
| `inv(M)` | Inverse |
| `tr(M)` | Trace |
| `transpose(M)` | Transpose |
| `eigenvalues(GiacExpr(M.ptr))` | Eigenvalues |
| `linsolve(eqs, vars)` | Solve linear system |
| `invoke_cmd(:rank, GiacExpr(M.ptr))` | Matrix rank |

## Notes

- All matrix operations work symbolically
- For numerical evaluation, use `to_julia` to convert results
- Large symbolic matrices can be created efficiently using the symbol constructor
- The `~` operator creates equations for use with `linsolve` and `solve`
