I found this an instructive exercise to understand monads, as well as their use and limitations in other, more 
imperative, high level languages.

Compounding monads requires the use of nested functions, which is unwieldy without the availability of special syntax, 
the so called do-notation of Haskell. It is straightforward to implement this syntax in julia using native ast 
metaprogramming. Ultimately, julia's type system does not support function-types, and thus makes the entire endeavor 
very difficult, as a central conceit of functional languages is using types to reason about and compound functions. It 
would seem that without true first-class support for functions, functional programming loses much of its appeal and 
usability. A few notes, some instructive, follow regarding this implementation.


## monads

Without providing another exposition on monads, category theory, κλπ, it suffices to say that monads capture context in
the form of data or closures, and have associated with them functions that afford composability, *in a way that appears
imperative*. Waxing poetical, a computation is built up by feeding monads sequentially into Kleisli arrows. The final
result of this composition is unsurprisingly single function, which can be applied ultimately to data provided by the 
runtime. The utility of this style is to have functional code that can be written and read as imperative code - 
functional code that has the appearance of conveying state through composition. Of course an entire monadic composition 
must itself live within a  function, but then those functions can be composed. From the perspective of composability, 
monads should be thought of  as function-like, and in the broader understanding of category theory, like functions, form 
a category. In programming, monads are a type class that captures and contextualizes some object. The monad type `m a` 
is written in terms of its type constructor `m` which contextualizes some type `a`. The construction of a monad instance 
thus requires an instance of type `a`. Central to monadic programming is the ability to 'extract' an object from its 
context. In julia, a parametric `struct` is a good candidate for specifying monadic types.


## do-notation

There is a fascinating correspondence between imperative programs and functional programs when every line in the former
is an expression, except for the final line in the program, which must be a statement and is interpreted as the return
value of the imperative program. The following arithmetic program for example:

```
x = 3
y = 2 * x
z = 8 + y
z
```

may be written in functional form as

```
3     ↦ (\x ->
2 * x ↦ (\y -> 
8 + y ↦ (\z ->
z)))
```

Where the symbol `↦` means left-application of the function which is following, ie `x ↦ f ≡ f(x)`. This can be attained 
in a relatively straightforward fashion in an imperative language by use of a continuation

```
cont = \v -> \f -> f(v)
```

With this in hand, the above can be expressed in any imperative language that supports higher order functions, and
ideally syntax for anonymous (lambda) functions.

```
cont(3)     (\x ->
cont(2 * x) (\y -> 
cont(8 + y) (\z ->
z)))
```

Even with the nested lambdas this reads thoroughly imperative. The translation from the first writing and the last is
entirely programmatic and is accomplished in julia in straightforward fashion by leveraging its native ast 
metaprogramming. A macro `@do_notation` exists to decorate a function, which will process the lines of the body of the
function recursively, establishing the source of each line's evaluation (if any), calling `cont` on it, and 'pushing' it 
into the subsequent functional context, by passing it as an argument. Monads, by virtue of being like functions, have 
very similar semantics, with the following replacement: assignment `=` is replaced with `←`, and `cont(v)(f)` is 
replaced with `bind(v, f)` - the monad's bind operation. Thus, a program that includes both monadic and functional 
'steps' is parsed as above, allowing for both types of 'assignment', and replacing accordingly.

It should be obvious by now that the use of monads and the syntactic sugar of do-notation was entirely borrowed from
Haskell, as part of a study on the use of functional and monadic aspects in imperative languages - especially those that
feature metaprogramming capable of supporting new syntax.

## types

the type system in julia has some features that would make it well suited for hosting monads. A monad would naturally
be expressed as a struct with free type parameters that reflect the type that the monad is wrapping, which is to say, 
upon construction of the type. This works perfectly well, for example, for the Writer monad:

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
used as part of a generic programming approach, where the use of multiple dispatch replaces classes and bespoke methods.
That quality of julia is indeed useful in this context, as the monadic functions `fmap`, `pure`, `liftA2`, `unit`, 
`bind`, etc must be implemented uniquely for every monad. Unfortunately, julia does not allow for a typeclass 
specification, that is, it doesn't allow for indication that the implementation of a set of functions for a derived
type is *necessary*. Nonetheless, it is straightforward to implement and use any of these functions on their associated
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

