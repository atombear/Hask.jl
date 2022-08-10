i found this an instructive exercise to understand monads, as well as their use and limitations in other more imperative
high level languages.

compounding monads requires the use of nested functions, which is unwieldy without the availability of special syntax, the
so called do-notation of Haskell. it is straightforward to implement this syntax in julia using native ast metaprogramming.
ultimately, julia's type system does not support function-types, and thus makes the entire endeavor very difficult, as a
central conceit of functional languages is using types to reason about and compound functions. it would seem that without
true first-class support for functions, functional programming loses much of its appeal and usability. a few notes, some
instructive, follow regarding this implementation.


# monads

Without providing another exposition on monads, category theory κλπ, it suffices to say that monads capture context in
the form of data or closures, and have associated with them functions that afford composability, *in a way that appears
imperative*. Waxing poetical, a computation is built up by feeding monads sequentially into Kleisli arrows. The final
result of this composition is in fact a single function, which can be applied ultimately to data provided by the 
runtime. The utility of course is to have functional code that can be written and read as imperative code, that has the
appearance of conveying state through a computation. Of course an entire monadic composition must itself live within a
function, but then those functions can be composed. From the perspective of composability, monads should be thought of
as function-like, and in the broader understanding of category theory, form a category, like functions. In programming
monads are a type class captures and contextualizes some object. The monad type `m a` is written in terms of its type
constructor `m` which contextualizes some type `a`. The construction of a monad instance thus requires an instance of
type `a`. Central to monadic programming is the ability to 'extract' an object from its context. In julia, a parametric 
`struct` is a good candidate for specifying monadic types.


# do-notation

Consider a simple 


# types

the type system in julia has some features that would make it well suited for hosting monads. A monad would naturally
be expressed as a struct with free type parameters that are reflect the type that the monad is wrapping, which is to
say, upon construction of the type. This works perfectly well, for example, for the Writer monad:

```
struct Writer{T}
    runWriter::Tuple{Log, T}
    Writer(runWriter) = new{typeof(runWriter[2])}(runWriter)
end
```

Julia can infer the type at runtime and construct the appropriate parametric type. A new abstract type `Log` represents
all possible logging types, and it is a simple matter to wrap eg a String in that construction. Incidentally, this is 
counter to the way julia 'should' be programmed, which is to say, dynamically. Establishing argument types is seen as
unnecessarily restrictive, whose effect is to do nothing at best, or confuse the compiler at worst. Typing should be 
used as part of a generic programming approach, where multiple dispatch is used in lieu of classes and bespoke methods.
That quality of julia is indeed useful in this context, as the monadic functions `fmap`, `pure`, `liftA2`, `unit`, 
`bind`, etc must be implemented uniquely for every monad. Unfortunately, julia does not allow for a typeclass 
specification, that is, it doesn't allow for indication that the implementation of a set of functions for a derived
type is *necessary*. Nonetheless, it is straightforward to implement and use any of these functions on its associated
monadic varieties.

Although nominally counter to the preferred julia style, the type system is almost suited for a functional programming
approach. Functions in julia, incidentally, are not strictly first-class citizens. Without a strict typing for functions
it is less appealing to build a functional programming style around them. The State monad for instance contextualizes a
function `StateT -> a`, where `StateT` is any struct representative of the state the program wants to capture. One
mildly-satisfying implementation is

```
struct State{T}
    runState::Function
    State(runState) = new{get_tuple_type(Base.return_types(runState)[1])}(runState)
end
```

While it seems promising that runtime introspection can capture the return type, there are instances where a function
like this will need to be written generically. In `bind` for instance it is sensible to return `State(runState)` for a
function `runState` that is defined in the context of the function `bind`. The return type of this function is related 
to the return type of the Kleisli arrow that is the second argument to bind, with type `a -> State b`. In principle this
type can be known from the type of the function contextualized by `State b`, but the typing system does not allow that
to be specified. It is possible to make the type an argument to the `State` constructor and discover the state at 
runtime, leading to a possible implementation of bind, but this is not satisfying.

```
function bind(state::State{T}, k) :: State{<:Any} where {T <: Any}
    function runState(s::StateT) :: Tuple{StateT, <:Any}
        (sp, vala) = state.runState(s)
        return k(vala).runState(sp)
    end
    return State(get_state_type(Base.return_types(k)[1]), runState)
end
```

