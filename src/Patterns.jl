###-----------------------------------------------------------------------------
### Copyright (C) Patterns.jl
###
### SPDX-License-Identifier: MIT License
###-----------------------------------------------------------------------------

module Patterns

###=============================================================================
### Exports
###=============================================================================

export @pattern, @p

###=============================================================================
### Imports
###=============================================================================

using MacroTools: postwalk, isshortdef, combinedef, splitdef
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
        def[:args] = map(replace_token(T -> :(::$T)), def[:args])

        expr = combinedef(def)

        return esc(expr)
    else
        expr = postwalk(replace_token(T -> :($T())), expr)
        return esc(expr)
    end
end

"""
Abbreviation for `@pattern`.
"""
macro p(expr...)
    return :(@pattern $(expr...)) |> esc
end

###-----------------------------------------------------------------------------
### Internals
###-----------------------------------------------------------------------------

is_definition(expr::Expr)::Bool = isshortdef(expr) || expr.head == :function
is_definition(_)::Bool = false

is_token(expr::QuoteNode)::Bool = expr.value isa Symbol
is_token(_)::Bool = false

function replace_token(by::Function, expr)
    if is_token(expr)
        return by(Val{expr.value})
    else
        return expr
    end
end

function replace_token(by::Function)::Fix1
    return Fix1(replace_token, by)
end

end # module
