module Hask

include("Monad.jl")
using .Monad

include("WriterMonad.jl")
using .WriterMonad

include("StateMonad.jl")
using .StateMonad

end # module
