###-----------------------------------------------------------------------------
### Copyright (C) Patterns.jl
###
### SPDX-License-Identifier: MIT License
###-----------------------------------------------------------------------------

module Utilities

###=============================================================================
### Functions
###=============================================================================

show_pattern_type(::Type{Val{x}}) where {x} = ":$x"
show_pattern_type(::Type{T}) where {T} = "::$T"

symbol_to_val(s::Symbol) = Val(s)
symbol_to_val(x) = x

default(f) = Tuple{typeof(f), Vararg{Any}}

function patterns(f)::Vector
    return [method.sig
            for method in methods(f).ms
            if !(default(f) <: method.sig)]
end

end # module
