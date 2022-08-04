# Patterns.jl

[![CI](https://github.com/cursorinsight/Patterns.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/cursorinsight/Patterns.jl/actions/workflows/CI.yml)

Patterns.jl is a Julia package that provides support for pattern matching.

## Installation

```julia
julia>]
pkg> add https://github.com/cursorinsight/Patterns.jl
```

## Usage

Load the package via

```julia
using Patterns
```

This exports two macros, `@with_pattern` and `@pattern`.

To use symbols as a pattern in function signatures first create an empty
function with the usage of `@with_pattern`:

```julia
@with_pattern function f end
```

Then you can create functions with pattern in the signature using `@pattern`:

```julia
@pattern function f(:one)
    return 1
end
```

You can also use multiple symbols and other parameters in the signature:

```julia
@pattern function f(:one, :string)
    return "1"
end

@pattern function f(x::Number, :number)
    return x
end
```


## Advanced example

Create fixtures that provide data for your tests.

```julia
@with_pattern function fixture end

@pattern function fixture(:numbers)
    return [1, 7, 12]
end

@pattern function fixture(:numbers, x)
    return [1, 7, 12, x]
end

@pattern function fixture(:numbers, :even)
    return [2, 8, 12]
end
```

## Notes

### Limitations

Be aware that keyword arguments are currently not working when you are using
symbols as a pattern in the function signature. This will be added in a future
update.
