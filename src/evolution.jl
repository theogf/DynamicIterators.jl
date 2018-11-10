

"""
    Evolution

Evolutions define
```
    evolve(iter, value::T)::T
```
and possibly
```
    evolve(iter, key=>value)
```

They guarantee `HasEltype()` and `eltype(iter) == T`.
"""
abstract type Evolution <: DynamicIterator
end
const GEvolution = Union{Evolution, UnitRange, StepRange}

"""
    statefrom(E, x)

Create state for E following `x`.
"""
statefrom(E, x) = dyniterate(i.itr, (value=i.x,))
evolve(r::UnitRange, i) = i < last(r) ?  i + 1 : nothing
function evolve(r::StepRange, i) # Fixme
    i = i + step(r)
    i <= last(r) ?  i : nothing
end


@inline dyniterate(r::Union{UnitRange, StepRange}) = iterate(r)
@inline dyniterate(r::Union{UnitRange, StepRange}, (value,)::Value) = iterate(r, value)
@inline dyniterate(r::Union{UnitRange, StepRange}, i, (value,)::Value=(value=i,)) = iterate(r, value)

dyniterate(E::Evolution, state, (value,)::Value=(value=state,)) = dub(evolve(E, value))
dyniterate(E::Evolution, (value,)::Value) = dub(evolve(E, value))

dyniterate(E::Evolution, (value, nextkey)::NamedTuple{(:value,:nextkey)}) = dub(evolve(E, value, nextkey))
dyniterate(E::Evolution, value::Pair, (nextkey,)::Nextkey) = dub(evolve(E, value, nextkey))

iterate(E::Evolution, x=first(E)) = dub(evolve(E, x))
IteratorSize(::Evolution) = SizeUnknown()

dyniterate(E::Evolution, state, (value,)::NamedTuple{(:value,)}=(value=state,)) = dub(evolve(E, value))
dyniterate(E::Evolution, (value,)::NamedTuple{(:value,)}) = dub(evolve(E, value))

"""
    evolve(f)

Create the DynamicIterator corresponding to the evolution
```
    x = f(x)
```

Integer keys default to increments.
Integer control defaults to repetition.

```
julia> collect(take(from(Evolve(x->x + 1), 10), 5))
5-element Array{Any,1}:
 10
 11
 12
 13
 14
```
"""
struct Evolve{T} <: Evolution
    f::T
end

evolve(F::Evolve, x) = F.f(x)
evolve(F::Evolve, (i,x)::Pair) = i+1 => F.f(x)

function evolve(F::Evolve, (i,x)::Pair{T}, j::T) where {T}
    @assert j ≥ i
    for k in 1:j-i
        x = evolve(F, x)
        x === nothing && return nothing
    end
    j => x
end
