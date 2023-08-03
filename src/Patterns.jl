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

using MacroTools: combinedef, isexpr, isshortdef, splitarg, splitdef

import Base: show

###=============================================================================
### Implementation
###=============================================================================

"""
    @pattern <function_definition>

Create a function that can be called with a pattern of symbols (and arbitrary
other arguments).

# Examples

```jldoctest
julia> @pattern f(:one) = 1
f (generic function with 1 method)

julia> @pattern function f(:double, x::Number; plus::Number = 0)::Number
           return 2x + plus
       end
f (generic function with 1 methods)

julia> f(:one)
1

julia> f(:double, 123; plus = 1)
247

julia> f(:one) + f(:one) == f(:double, 1)
true
```
"""
macro pattern(expr)
    return pattern(__module__, __source__, expr)
end

"""
Abbreviation for [`@pattern`](@ref).
"""
macro p(expr)
    return pattern(__module__, __source__, expr)
end

###-----------------------------------------------------------------------------
### Internals
###-----------------------------------------------------------------------------

const Pattern = @NamedTuple begin
    nargs::Int
    issplat::Bool
    points::Vector{Int}
    tokens::Vector{Symbol}
end

const Case = @NamedTuple begin
    src::LineNumberNode
    λ::Function
end

const DispatchTable = Dict{Pattern, Case}
const dispatch_tables = Dict{Function, DispatchTable}()

function pattern(mod::Module, src::LineNumberNode, expr)
    # support legacy syntax: return expr as is when applied on a function call
    isdef(expr) || return expr

    def = splitdef(expr)
    name = def[:name]
    @assert(isdefined(mod, name) && getfield(mod, name) isa Function,
            "$name must be declared as a function!")
    dt = get!(dispatch_tables, getfield(mod, name), DispatchTable())

    nargs = length(def[:args])
    (_, _, issplat, _) = splitarg(def[:args][end])
    points = findall(a -> a isa QuoteNode, def[:args])
    tokens = map(qn::QuoteNode -> qn.value, splice!(def[:args], points))
    ptrn = (; nargs, issplat, points, tokens)

    λargs = [fill("_", nargs - 1); issplat ? "..." : "_"]
    λargs[points] .= repr.(tokens)
    def[:name] = Symbol(name, '(', join(λargs, ", "), ')')
    λ = esc(combinedef(def))

    code = quote
        $dt[$ptrn] = (src = $(QuoteNode(src)), λ = $λ)
        $(esc(def[:name]))
    end
    if isempty(dt)
        code = quote
            function $(esc(name))(args...; kwargs...)
                return dispatch($dt, $(esc(name)), args...; kwargs...)
            end
            $(code.args...)
        end
    end
    return code
end

function dispatch(dispatch_table::DispatchTable, f, args...; kwargs...)
    nargs = length(args)
    match = filter(dispatch_table) do (p, _)
        return (p.issplat ? nargs >= p.nargs - 1 : nargs == p.nargs) &&
            all(args[p.points] .=== p.tokens)
    end
    length(match) == 1 || throw(PatternMatchError(f, args, !isempty(match)))
    ((; points), (; λ)) = only(match)
    return λ(args[setdiff(1:end, points)]...; kwargs...)
end

isdef(expr)::Bool = isshortdef(expr) || isexpr(expr, :function)

struct PatternMatchError{F <: Function, A <: Tuple} <: Exception
    f::F
    args::A
    ambiguous::Bool
end

function show(io::IO, e::PatternMatchError)
    args = map(e.args) do arg
        return arg isa Symbol ? repr(arg) : "::$(typeof(arg))"
    end
    write(io, "PatternMatchError: ")
    e.ambiguous || write(io, "no pattern matching ")
    write(io, "$(e.f)(", join(args, ", "), ") ")
    e.ambiguous && write(io, "is ambiguous. ")
    write(io, "Candidates:")
    for (_, (; src, λ)) in dispatch_tables[e.f]
        write(io, "\n  $(λ) in $(parentmodule(λ)) at $(src.file):$(src.line)")
    end
end

end # module
