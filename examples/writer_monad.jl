using Hask.Monad: process, lapply, @do_notation

using Hask.WriterMonad: log, Writer, bind, unit


@do_notation function addTwo(val::Int) :: Writer
    log("adding 2")
    unit(val + 2)
end


@do_notation function do_some_procedure(x::Int, y::Int) :: Writer{Int}
    log("running_procedure...")
    xp ← addTwo(x)
    yp ← addTwo(y)
    log("impromptu triplication")
    xpp = 3 * xp
    log("finalizing procedure...")
    unit(xpp + yp)
end


w = do_some_procedure(3, 4)
println(w.runWriter[1].s)
println(w.runWriter[2])
