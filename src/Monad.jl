module Monad

export lapply, process, @do_notation

function lapply(val)
    return f -> f(val)
end


function process(e_args)
    top = popfirst!(e_args)

    statement = false
    if typeof(top) === Symbol
        m = top
        var = :_
        statement = true
    elseif top.args[1] === :←
        m = top.args[3]
        var = top.args[2]
        statement = false
    elseif top.head === :(=)
        m = nothing
        var = top.args[1]
        statement = false
    else
        m = top
        var = :_
        statement = true
    end

    if length(e_args) > 0
        if m === nothing
            return Expr(:call, Expr(:call, :lapply, top.args[2]), Expr(:->, var, process(e_args)))
        else
            return Expr(:call, :bind, m, Expr(:->, var, process(e_args)))
        end
    else
        @assert statement
        return m
    end
end


macro do_notation(f)
    body = f.args[2].args
    f.args[2] = filter(x -> typeof(x) !== LineNumberNode, body) |> process
    return esc(f)
end

end