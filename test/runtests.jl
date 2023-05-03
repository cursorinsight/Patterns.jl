###-----------------------------------------------------------------------------
### Copyright (C) Patterns.jl
###
### SPDX-License-Identifier: MIT License
###-----------------------------------------------------------------------------

###=============================================================================
### Imports
###=============================================================================

using Test

using Patterns: @pattern

###=============================================================================
### Tests
###=============================================================================

# TODO `@testset` modifies function identifiers, `function f end` couldn't be
# identified by its name `f`.

# Initalize a function to extend with patterns
function f end

@test f isa Function
@test length(methods(f)) == 0

# Short definition
@pattern f(:x) = "x"

@test length(methods(f)) == 1
@test hasmethod(f, Tuple{Val{:x}})
@test @pattern f(:x) isa String
@test @pattern f(:x) == "x"

# Long definition
@pattern function f(:y)::Char
    return 'y'
end

@test length(methods(f)) == 2
@test hasmethod(f, Tuple{Val{:y}})
@test @pattern f(:y) isa Char
@test @pattern f(:y) == 'y'

# Token with argument signature and keyword argument
@pattern function f(:y, num::Integer; f::Function = identity)
    return f(num)
end

@test length(methods(f)) == 3
@test hasmethod(f, Tuple{Val{:y}, Integer})
@test @pattern f(:y, 42) == 42
@test @pattern f(:y, 42; f = sign) == +1

# More token signature
@pattern function f(:a, :b, :c)
    return :abc
end

@test length(methods(f)) == 4
@test hasmethod(f, Tuple{Val{:a}, Val{:b}, Val{:c}})
@test @pattern f(:a, :b, :c) !== :abc
@test (@pattern f(:a, :b, :c)) == :abc

# Token and parametric type
@pattern function f(:d, str::T) where {T <: AbstractString}
    return str
end

@test length(methods(f)) == 5
@test hasmethod(f, Tuple{Val{:d}, AbstractString})
@test @pattern f(:d, "something") == "something"

# Type based signature
@pattern function f(::Type{Int})
    return 123
end

@test length(methods(f)) == 6
@test hasmethod(f, Tuple{Type{Int}})
@test @pattern f(Int) == 123

# Type based signature with token
@pattern function f(::Type{Int}, :zero)
    return 0
end

@test length(methods(f)) == 7
@test hasmethod(f, Tuple{Type{Int}, Val{:zero}})
@test @pattern f(Int, :zero) == 0
@test @pattern f(Int) * f(Int, :zero) == 0

@test_throws MethodError f(:missing, :signature)
@test 2 == @pattern 1+1
