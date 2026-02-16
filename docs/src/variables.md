# Symbolic variables

## Simple Variable Creation

Create a symbolic variable with `@giac_var`:

```julia
using Giac

@giac_var a
@giac_var a

a + b

# or simply

@giac_var a b
```

## Batch Variable Creation

Create multiple indexed symbolic variables with `@giac_several_vars`:

```julia
using Giac

# 1D vector of variables
@giac_several_vars a 3
# Creates: a1, a2, a3
# Returns: (a1, a2, a3)
a1 + a2 + a3  # Symbolic sum

# 2D matrix of variables
@giac_several_vars m 2 3
# Creates: m11, m12, m13, m21, m22, m23 (row-major order)
# Returns: (m11, m12, m13, m21, m22, m23)

# N-dimensional tensors
@giac_several_vars t 2 2 2
# Creates: t111, t112, t121, t122, t211, t212, t221, t222

# Large dimensions use underscore separators
@giac_several_vars b 2 10
# Creates: b_1_1, b_1_2, ..., b_2_10

# Unicode base names supported
@giac_several_vars α 2
# Creates: α1, α2

# Capture return tuple for iteration
vars = @giac_several_vars c 4
for v in vars
    println(v)
end
```