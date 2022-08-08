module StateMonad

import Base: *, +

export State, unit, bind


abstract type StateT end


get_tuple_type(::Type{Tuple{T, N}}) where {T, N} = N


struct State{T}
    runState::Function
    State(runState) = new{get_tuple_type(Base.return_types(runState)[1])}(runState)
    State(runState, t_) = new{t_}(runState)
end


function unit(val::T) :: State{typeof(val)} where T <: Any
    return State(s -> (s, val))
end


function bind(state::State{T}, k) :: State{<:Any} where {T <: Any}
    function runState(s::StateT) :: Tuple{StateT, <:Any}
        (sp, vala) = state.runState(s)
        return k(vala).runState(sp)
    end
    return State(runState, Any)
end

end