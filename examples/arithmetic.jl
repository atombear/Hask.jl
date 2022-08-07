using Hask.Monad: process, lapply, @do_notation

@do_notation function f(x::Int) :: Int
    y = 7 * x
    z = 8 + y
    z
end

q = quote
    y = 7 * x
    z = 8 + y
    z
end

println("A macro that turns this:")
args = filter(x -> typeof(x) !== LineNumberNode, q.args)
for a in args
    println(a)
end

println()
println("into this:")

println(process(args))

println()

@assert f(3) == 29
