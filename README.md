# Patterns.jl

[![CI](https://github.com/cursorinsight/Patterns.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/cursorinsight/Patterns.jl/actions/workflows/CI.yml)

Patterns.jl is a Julia package that provides support for pattern matching.

## Installation

Patterns.jl can be installed after adding Cursor Insight's [own registry][CIJR]
to the Julia environment:

```julia
julia> ]
pkg> registry add https://github.com/cursorinsight/julia-registry
     Cloning registry from "https://github.com/cursorinsight/julia-registry"
       Added registry `CursorInsightJuliaRegistry` to
       `~/.julia/registries/CursorInsightJuliaRegistry`

pkg> add Patterns
```

## Usage

Load the package via

```julia
using Patterns
```

This imports `@pattern` macro.

You can create functions with a pattern in their signature using `@pattern`:

```julia
function f end # need to declare a function before defining a pattern call

@pattern f(:one) = 1
```

You can also use multiple symbols and other parameters in the signature:

```julia
@pattern function f(::Type{String}, :one)
    return "1"
end
```

You can call a function with a pattern:

```julia
@assert f(String, :one) == string(f(:one))
```

## Advanced example

Create fixtures that provide data for your tests:

```julia
function fixture end

@pattern function fixture(:numbers, :odd)
    return [1, 7, 11]
end

@pattern function fixture(:numbers, :even)
    return [2, 8, 12]
end
```

To execute the following test:

```julia
using Test

@test !any(iseven, fixture(:numbers, :odd))
@test  all(iseven, fixture(:numbers, :even))
```

[CIJR]: https://github.com/cursorinsight/julia-registry
