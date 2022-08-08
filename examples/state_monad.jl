import Base.+

using Hask.Monad: process, lapply, @do_notation

using Hask.StateMonad: StateT, bind, State, unit


struct ListState{T} <: StateT
    list::Vector{T}
end


(+(ls::ListState{T}, vec::Vector{T}) :: ListState{T}) where T = ListState(vcat(ls.list, vec))
(+(vec::Vector{T}, ls::ListState{T}) :: ListState{T}) where T = ListState(vcat(vec, ls.list))


function advance_list(v::Int) :: State{Int}
    function runState(s::ListState{Int}) :: Tuple{ListState{Int}, Int}
        return (s + [v], v+1)
    end
    return State(runState)
end
advance_list(10)


list = reduce(bind, (unit(0), (advance_list for _ in 1:10)...)).runState(ListState(Int[]))

println(list)