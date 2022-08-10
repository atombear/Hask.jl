module StateMonad

export State, unit, bind


abstract type StateT end


struct State{T}
    runState::Function
    State(runStateT, runState) = new{runStateT}(runState)
end


get_state_type(::Type{State{T}}) where T <: Any = T


function unit(val::T) :: State{typeof(val)} where T <: Any
    return State(typeof(val), s -> (s, val))
end


function bind(state::State{T}, k) :: State{<:Any} where {T <: Any}
    function runState(s::StateT) :: Tuple{StateT, <:Any}
        (sp, vala) = state.runState(s)
        return k(vala).runState(sp)
    end
    return State(get_state_type(Base.return_types(k)[1]), runState)
end

end