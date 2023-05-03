###-----------------------------------------------------------------------------
### Copyright (C) Patterns.jl
###
### SPDX-License-Identifier: MIT License
###-----------------------------------------------------------------------------

module Patterns

###=============================================================================
### Exports
###=============================================================================

export @pattern

###=============================================================================
### Imports
###=============================================================================

using MacroTools: @capture, prewalk, isshortdef, combinedef, splitdef
using Base: Fix1

###=============================================================================
### Implementation
###=============================================================================

"""
    @pattern <function definition>

Create a function that can be called by `@pattern`.

# Examples
```jldoctest
julia> @pattern function f(:one)
           return 1
       end
f (generic function with 2 methods)

julia> @pattern function f(:double, x::Number; plus::Number = 0)::Number
           return 2x + plus
       end
f (generic function with 4 methods)
```

---
    @pattern <code>

Resolve pattern.

# Examples
```jldoctest
julia> @pattern f(:one)
1

julia> @pattern f(:double, 123; plus = 1)
247

julia> @pattern @assert isone(f(:one))

julia> @pattern f(:one) + f(:one) == f(:double, 1)
```
"""
macro pattern(expr)
    if is_definition(expr) # Pattern in function definition
        def::Dict{Symbol, Any} = splitdef(expr)

        # Replace tokens in signature
        def[:args] = replace_tokens_in_definition(def[:args])

        expr = combinedef(def)

        return esc(expr)
    else
        expr = prewalk(expr) do expr
            if @capture(expr, f_(args__))
                args = replace_tokens_in_call(args)

                return :($f($(args...)))
            else
                return expr
            end
        end

        return esc(expr)
    end
end

###-----------------------------------------------------------------------------
### Internals
###-----------------------------------------------------------------------------

is_definition(expr::Expr)::Bool = isshortdef(expr) || expr.head == :function
is_definition(_)::Bool = false

is_token(expr::QuoteNode)::Bool = expr.value isa Symbol
is_token(_)::Bool = false

function replace_tokens_in_definition(args::Vector)::Vector
    return replace_tokens(T -> :(::$T), args)
end

function replace_tokens_in_call(args::Vector)::Vector
    return replace_tokens(T -> :($T()), args)
end

function replace_tokens(by, args::Vector)::Vector
    return map(replace_token(by), args)
end

function replace_token(f::Function)::Fix1
    return Fix1(replace_token, f)
end

function replace_token(f::Function, expr)
    if is_token(expr)
        T = Val{expr.value}
        return f(T)
    else
        return expr
    end
end

end # module
