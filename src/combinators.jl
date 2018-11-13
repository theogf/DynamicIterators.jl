


"""

    mix(f, P, Q)

Mix two dynamic iterators by applying the mixing function `f`
to their states:

    x, y = f(x, y)

## Example
```
collectfrom(Mix((x,y) -> (x+y, y), 1:0, 1:100), (1,1)))
# last value 100*101/2 + 100
```
"""
struct Mix{F,T,S} <: DynamicIterator
    f::F
    P::T
    Q::S
end

#dyniterate(M::Mix{<:Any, <:GEvolution, <:GEvolution}, u) = dyniterate_(M, (value=u,))
#dyniterate(M::Mix{<:Any, <:GEvolution, <:GEvolution}, v::Value2) = dyniterate_(M, v)
#dyniterate(M::Mix, v::Value2) = dyniterate_(M, v)
dyniterate(M::Mix{<:Any, <:GEvolution, <:GEvolution}, u) = dub(evolve(M, u))
#dyniterate(M::Mix{<:Any, <:GEvolution, <:GEvolution}, ::Nothing, (u,)::Value2) = dub(evolve(M, u))
dyniterate(M::Mix{<:Any, <:GEvolution, <:GEvolution}, u::Start) = dub(evolve(M, u.value))
evolve(M::Mix{<:Any, <:GEvolution, <:GEvolution}, (i, pq)::Pair) = i+1 => evolve(M, pq)

function evolve(M::Mix{<:Any, <:GEvolution, <:GEvolution}, (p, q)::Tuple)
    p = evolve(M.P, p)
    p === nothing && return nothing
    q = evolve(M.Q, q)
    q === nothing && return nothing
    M.f(p, q)
end

function dyniterate(M::Mix, ::Nothing, (value,)::Value2)
    x, y = value
    ϕ = dyniterate(M.P, (value=x,))
    ϕ === nothing && return nothing
    x, p = ϕ
    ψ = dyniterate(M.Q, (value=y,))
    ψ === nothing && return nothing
    y, q = ψ
    x, y = M.f(x, y)
    (x, y), (p, q)
end
function dyniterate(M::Mix, u, (value,)::Value2=(value=u))
    p, q = u
    x, y = value
    ϕ = dyniterate(M.P, p, (value=x,))
    ϕ === nothing && return nothing
    x, p = ϕ
    ψ = dyniterate(M.Q, q, (value=y,))
    ψ === nothing && return nothing
    y, q = ψ
    x, y = M.f(x, y)
    (x, y), (p, q)
end


mix(f, P, Q) = Mix(f, P, Q)


"""

    mixture(I, Ps)

    evolve(M::Mixture, (i, x))
Choose evolution in `Ps[i]` for `x` using iterate `i` of `I`.
"""
struct Mixture{S,T} <: Evolution
    I::S
    Ps::T
end


evolve(M::Mixture, (i, ix)::Pair) = i+1 => evolve(M, ix)

function evolve(M::Mixture, (i, x)::Tuple)
    i = evolve(M.I, i)
    x = evolve(M.Ps[i], x)
    (i, x)
end

mixture(I, args) = Mixture(I, args)





struct Synchronize{T} <: Evolution
    Ps::T
end

"""
    synchronize
"""
synchronize(args...) = Synchronize(args)



state((t, xs), M::Synchronize) = (t => xs, Tuple(evolve.(M.Ps, Pair.(t, xs))))


function evolve(M::Synchronize, ((t, x), next)::T) where {T}
    all(u === nothing for u in next) && return nothing
    tᵒ = minimum(first.(Iterators.filter(x -> !(t===nothing), next))) #use isnothing
    xᵒ = Any[]
    nextᵒ = Any[]
    for  (P, xᵢ, u) in zip(M.Ps, x, next)
        if !(u === nothing) && u[1] == tᵒ
            xᵢ = u[2]
            u = evolve(P, u)
        end
        push!(xᵒ, xᵢ)
        push!(nextᵒ, u)
    end
    (tᵒ => Tuple(xᵒ), Tuple(nextᵒ))::T
end
