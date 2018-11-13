
endtime(T) = (t, _)::Pair -> t >= T


"""
    from(P, x)

Attach a starting value to a `DynamicIterator`.


## Example
```
collect(from(1:14, 10)) == [11, 12, 13, 14]
```
"""
struct From{I,T} <: DynamicIterator
    itr::I
    x::T
end
from(i, x) = From(i, x)

collectfrom(it, x) = collect(from(it, x))
collectfrom(it, x, n) = collect(take(from(it, x), n))

#@propagate_inbounds iterate(i::From) = dyniterate(i.itr, nothing, (value=i.x,))
@propagate_inbounds iterate(i::From) = dyniterate(i.itr, Start(i.x))
@propagate_inbounds iterate(i::From, u) = dyniterate(i.itr, u)
@propagate_inbounds dyniterate(i::From, args...) = dyniterate(i.itr, args...)


eltype(::Type{From{I,T}}) where {I<:DynamicIterator,T} = T
eltype(::Type{<:From{I}}) where {I} = eltype(I)

IteratorEltype(::Type{<:From{<:DynamicIterator}}) = HasEltype()
IteratorEltype(::Type{<:From{I}}) where {I} = IteratorEltype(I)

IteratorSize(::Type{<:From{I}}) where {I} = Iterators.rest_iteratorsize(IteratorSize(I))


"""
    trace(P, u::Pair, stop; register = x->true)

Trace the trajectoy of a keyed Dynamic iterator
as `Trajectory`.
"""
function trace(E::Evolution, u::Pair, stop = x->false; register = x->true)
    if !register(u)
        while !stop(u)
            u = evolve(E, u)
            u === nothing && error("registered nothing")
            register(u) && break
        end
    end
    X = trajectory((u,))
    while !stop(u)
        u = evolve(E, u)
        u === nothing && break
        register(u) && push!(X, u)
    end
    X
end

function trace(P, u::Pair, stop = x->false; register = x->true)
    while true
        if register(u)
            X = trajectory((u,))
            ϕ = dyniterate(P, nothing, (value=u,))
            ϕ === nothing && return X
            u, state = ϕ
            register(u) && push!(X, u)
            return trace_(P, X, u, state, stop, register)
        else
            ϕ = dyniterate(P, nothing, (value=u,))
            ϕ === nothing && break
            u, state = ϕ
            if register(u)
                X = trajectory((u,))
                return trace_(P, X, u, state, stop, register)
            else
                while !stop(u)
                    ϕ = dyniterate(P, state)
                    ϕ === nothing && break
                    u, state = ϕ
                    if register(u)
                        X = trajectory((u,))
                        return trace_(P, X, u, state, stop, register)
                    end
                end
            end
        end
    end
    error("registered nothing")
end
function trace_(P, X::Trajectory, u, state, stop, register)
    while !stop(u)
        ϕ = dyniterate(P, state)
        ϕ === nothing && break
        u, state = ϕ
        register(u) && push!(X, u)
    end
    X
end

function lastiterate(P::DynamicIterator, u, stop=u->false)
    while !stop(u)
        u = evolve(P, u)
        u === nothing && return u
    end
    u
end
lastiterate(P, u, stop=u->false) = _lastiterate(P, u, stop)

function _lastiterate(P, u, stop=u->false)
    if !stop(u)
        ϕ = dyniterate(P, Start(u))
        ϕ === nothing && return u
        u, state = ϕ
        while !stop(u)
            ϕ = dyniterate(P, state, (value=u,))
            ϕ === nothing && return u
            u, state = ϕ
        end
    end
    u
end
