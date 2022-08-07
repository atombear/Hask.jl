module Monad

export lapply, process, @do_notation

function lapply(val)
    return f -> f(val)
end


function process(e_args)
    top = popfirst!(e_args)

    if top.args[1] === :←
        m = top.args[3]
        var = top.args[2]
    elseif top.head === :(=)
        m = nothing
        var = top.args[1]
    else
        m = top
        var = :_
    end

    if length(e_args) > 0
        if m === nothing
            return Expr(:call, Expr(:call, :lapply, top.args[2]), Expr(:->, var, process(e_args)))
        else
            return Expr(:call, :bind, m, Expr(:->, var, process(e_args)))
        end
    else
        return m
    end
end


macro do_notation(f)
    body = f.args[2].args
    f.args[2] = filter(x -> typeof(x) !== LineNumberNode, body) |> process
    return esc(f)
end

end