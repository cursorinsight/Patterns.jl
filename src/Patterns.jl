###-----------------------------------------------------------------------------
### Copyright (C) 2022- Cursor Insight
###
### All rights reserved.
###-----------------------------------------------------------------------------

module Patterns

###=============================================================================
### Exports
###=============================================================================

export @pattern, @with_pattern

###=============================================================================
### Imports
###=============================================================================

include("Utilities.jl")

using MacroTools: @capture, combinedef, splitdef
using .Utilities: patterns, show_pattern_type, symbol_to_val

###=============================================================================
### Implementation
###=============================================================================

"""
    @with_pattern empty function declaration

Create a function which allows the usage of symbols as a pattern in function
signatures. Must be called on an empty function declaration.

# Examples
```jldoctest
julia> @with_pattern function f end
f (generic function with 1 method)
```
"""
macro with_pattern(f)
    is_captured = @capture(f, function f_name_ end)

    @assert is_captured
        "The macro must be called on an empty function declaration!"

    f_name = esc(f_name)

    return quote
        $(esc(f))
        function $f_name(args...)
            _args = symbol_to_val.(args)
            called_signature =
                Base.signature_type($f_name, Base.to_tuple_type(typeof(_args)))
            try
                if !any(signature -> called_signature <: signature,
                        patterns($f_name))
                    throw(MethodError($f_name, _args))
                end

                return $f_name(_args...)
            catch e
                if e isa MethodError && e.f == $f_name
                    f_name = $f_name
                    params = typeof(_args).parameters
                    str = join(params .|> show_pattern_type, ", ")
                    @error "Missing pattern $f_name($str)"
                end
                rethrow(e)
            end
        end
    end
end

"""
    @pattern function definition

Create a function with symbols as pattern in the signature.

# Examples
```jldoctest
julia> @pattern function f(:one)
           return 1
       end
f (generic function with 2 methods)

julia> @pattern f(:two) = 2
f (generic function with 3 methods)

julia> @pattern function f(:double, x::Number)::Number
           return 2x
       end
f (generic function with 4 methods)

julia> f(:two)
2

julia> f(:double, 123)
246
```
"""
macro pattern(f)
    def::Dict = splitdef(f)
    def[:args] = map(do_replace, def[:args])
    return esc(combinedef(def))
end

do_replace(arg::QuoteNode) = :(::Val{$arg})
do_replace(arg) = arg

end # module
