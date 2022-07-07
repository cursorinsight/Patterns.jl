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

using MacroTools: @capture, postwalk
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
    @assert f.head == :function
    @assert(length(f.args) == 1,
        "The macro must be called on an empty function declaration!")
    @assert f.args[1] isa Symbol "The function must be named!"

    f_name = esc(f.args[1])

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

julia> @pattern function f(:num, x::Number)::Number
           return x
       end
f (generic function with 4 methods)
```
"""
macro pattern(f)
    is_function = false

    expr = postwalk(f) do x
        is_captured = @capture(x, f_name_(args__))
        if is_captured
            is_function = true
            new_args::Vector = map(args) do arg
                return arg isa QuoteNode ? :(::Val{$(esc(arg))}) : arg
            end
            return :($(esc(f_name))($(new_args...)))
        end
        return x
    end

    @assert is_function "Expected a function!"

    return expr
end

end # module
