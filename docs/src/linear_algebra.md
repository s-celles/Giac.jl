# Linear Algebra

```julia
using Giac, LinearAlgebra

A = GiacMatrix([1 2; 3 4])
det(A)        # -2
tr(A)         # 5
inv(A)        # inverse matrix
transpose(A)  # transposed matrix

# Symbolic matrix
@giac_var a b c d
B = GiacMatrix([[a, b],
                [c, d]])
det(B)  # a*d-b*c

@giac_several_vars m 2 2
M = GiacMatrix([[m11, m12],
                [m21, m22]])
det(M)  # m11*m22-m12*m21

julia> GiacMatrix(:m, 100, 100)
100×100 GiacMatrix:
  m_1_1    m_1_2    m_1_3    m_1_4    m_1_5  ⋯    m_1_99    m_1_100
  m_2_1    m_2_2    m_2_3    m_2_4    m_2_5  ⋯    m_2_99    m_2_100
  m_3_1    m_3_2    m_3_3    m_3_4    m_3_5  ⋯    m_3_99    m_3_100
  m_4_1    m_4_2    m_4_3    m_4_4    m_4_5  ⋯    m_4_99    m_4_100
  m_5_1    m_5_2    m_5_3    m_5_4    m_5_5  ⋯    m_5_99    m_5_100
      ⋮        ⋮        ⋮        ⋮        ⋮  ⋱         ⋮          ⋮
 m_99_1   m_99_2   m_99_3   m_99_4   m_99_5  ⋯   m_99_99   m_99_100
m_100_1  m_100_2  m_100_3  m_100_4  m_100_5  ⋯  m_100_99  m_100_100
```

## Table of functions

| Function | Description |
|----------|-------------|
| `GiacMatrix(array)` | Create symbolic matrix |
| `det(M)` | Determinant |
| `inv(M)` | Inverse |
| `tr(M)` | Trace |
| `transpose(M)` | Transpose |