###-----------------------------------------------------------------------------
### Copyright (C) 2022- Cursor Insight
###
### All rights reserved.
###-----------------------------------------------------------------------------

###=============================================================================
### Imports
###=============================================================================

using Test

using Patterns: @pattern,  @with_pattern

###=============================================================================
### Tests
###=============================================================================

@testset "Pattern" begin
    @with_pattern function f end

    @test f isa Function
    @test length(methods(f)) == 1 # there is a default wrapper
    @test hasmethod(f, Tuple{Vararg{Symbol}})

    @pattern function f(:x)
        return "x"
    end

    @test length(methods(f)) == 2
    @test hasmethod(f, Tuple{Val{:x}})
    @test f(:x) isa String
    @test f(:x) == "x"

    @pattern function f(:y)::Char
        return 'y'
    end

    @test length(methods(f)) == 3
    @test hasmethod(f, Tuple{Val{:y}})
    @test f(:y) isa Char
    @test f(:y) == 'y'

    @pattern function f(:z, num::Integer)
        return num
    end

    @test length(methods(f)) == 4
    @test hasmethod(f, Tuple{Val{:y}, Integer})
    @test f(:z, 42) == 42

    @pattern function f(:a, :b, :c)
        return "abc"
    end

    @test length(methods(f)) == 5
    @test hasmethod(f, Tuple{Val{:a}, Val{:b}, Val{:c}})
    @test f(:a, :b, :c) == "abc"

    @pattern function f(:d, str::T) where {T <: AbstractString}
        return str
    end

    @test length(methods(f)) == 6
    @test hasmethod(f, Tuple{Val{:d}, AbstractString})
    @test f(:d, "something") == "something"

    @test_throws AssertionError @macroexpand @pattern a = 1
end
