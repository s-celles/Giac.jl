# Contributors & Acknowledgements

Giac.jl is developed and maintained by Sébastien Celles
([@s-celles](https://github.com/s-celles)) — PRAG, IUT de Poitiers,
Département GEII.

This package would not exist without the work of many people. Thanks to
everyone who has built, reviewed, tested, suggested features, or filed
issues.

## Giac side

- **Bernard Parisse** & **Renée De Graeve** (Université Grenoble Alpes) —
  authors of the [Giac/Xcas](https://www-fourier.univ-grenoble-alpes.fr/~parisse/giac.html)
  computer algebra system that this package wraps.
- **Harald Hofstaetter**
  ([@HaraldHofstaetter](https://github.com/HaraldHofstaetter)) — author
  of the original
  [Giac.jl](https://github.com/HaraldHofstaetter/Giac.jl), which
  inspired this rewrite.

## Julia ecosystem

- **Viral B. Shah** ([@ViralBShah](https://github.com/ViralBShah)) —
  Julia co-creator; advice on Yggdrasil packaging.
- **Mosè Giordano** ([@giordano](https://github.com/giordano)) and
  **Max Horn** ([@fingolfin](https://github.com/fingolfin)) — reviewers
  on Yggdrasil / BinaryBuilder for the `GIAC_jll` and
  `libgiac_julia_jll` recipes.
- **John Verzani** ([@jverzani](https://github.com/jverzani)) — early
  tester and contributor of multiple pull requests in v0.12:
  [#6](https://github.com/s-celles/Giac.jl/pull/6) (function-arg
  interaction with `substitute`),
  [#8](https://github.com/s-celles/Giac.jl/pull/8) (introspection),
  [#9](https://github.com/s-celles/Giac.jl/pull/9) and
  [#16](https://github.com/s-celles/Giac.jl/pull/16) (math operators),
  [#10](https://github.com/s-celles/Giac.jl/pull/10) (`GiacMatrix`
  iteration and linear indexing).

## Ideas, feedback, and bug reports

- **Thibault Duretz** ([@tduretz](https://github.com/tduretz)) —
  - Suggested the `build_function` feature on the Julia Discourse
    announcement thread:
    [discourse.julialang.org/t/136681/6](https://discourse.julialang.org/t/ann-giac-jl-julia-interface-to-the-giac-computer-algebra-system/136681/6).
    Implemented in v0.13 (Tier 1) and v0.14 (Tier 3, `:symbolics`
    backend).
  - Reported the `D(ϕ)` failure on Unicode identifiers, fixed in
    v0.14.1.

## Methodology

- **Sam Abbott** ([@seabbs](https://github.com/seabbs)) — inspiring
  Julia development skill
  ([seabbs/claude#6](https://github.com/seabbs/claude/issues/6)).

## How to contribute

Contributions are welcome — issues, ideas, and pull requests. See the
[README](README.md) for development setup and the
[CHANGELOG](CHANGELOG.md) for the project history.
