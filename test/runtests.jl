###-----------------------------------------------------------------------------
### Copyright (C) Patterns.jl
###
### SPDX-License-Identifier: MIT License
###-----------------------------------------------------------------------------

###=============================================================================
### Imports
###=============================================================================

using Test

using Patterns: PatternMatchError, @pattern

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
@test length(methods(var"f(:x)")) == 1
@test f(:x) isa String
@test f(:x) == "x"

# Long definition
@pattern function f(:y)::Char
    return 'y'
end

@test length(methods(f)) == 1
@test length(methods(var"f(:y)")) == 1
@test f(:y) isa Char
@test f(:y) == 'y'

# Token with argument signature and keyword argument
@pattern function f(:y, num::Integer; f::Function = identity)
    return f(num)
end

@test length(methods(f)) == 1
@test length(methods(var"f(:y, _)")) == 1
@test f(:y) isa Char
@test f(:y) == 'y'
@test f(:y, 42) == 42
@test f(:y, 42; f = sign) == +1

# Multiple tokens signature
@pattern function f(:a, :b, :c)
    return :abc
end

@test length(methods(f)) == 1
@test length(methods(var"f(:a, :b, :c)")) == 1
@test f(:a, :b, :c) == :abc

# Token and parametric type
@pattern function f(:d, str::T) where {T <: AbstractString}
    return str
end

@test length(methods(f)) == 1
@test length(methods(var"f(:d, _)")) == 1
@test f(:d, "something") == "something"

# Type based signature (no pattern)
function f(::Type{Int})
    return 123
end

@test length(methods(f)) == 2
@test hasmethod(f, Tuple{Type{Int}})
@test f(Int) == 123

# Type based signature with token
@pattern function f(::Type{Int}, :zero)
    return 0
end

@test length(methods(f)) == 2
@test length(methods(var"f(_, :zero)")) == 1
@test f(Int, :zero) == 0
@test f(Int) * f(Int, :zero) == 0

# Broadcast
@pattern function f(::Type{Int}, :one)
    return 1
end

@test length(methods(f)) == 2
@test length(methods(var"f(_, :one)")) == 1
@test sum(f.(Int, [:zero, :one, :zero, :one])) == 2

# Splat

@pattern f(:splat, x...) = sum(x; init = 0)

@test f(:splat) == 0
@test f(:splat, 1, 2, 3) == 6

# Ambiguity, missing patterns

@pattern f(:splat) = 0

@test_throws PatternMatchError f(:splat)
@test_throws PatternMatchError f(:missing, :signature)
