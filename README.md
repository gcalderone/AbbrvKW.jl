# AbbrvKW

### Allow using abbreviated keyword names in function calls.

[![Build Status](https://travis-ci.org/gcalderone/AbbrvKW.jl.svg?branch=master)](https://travis-ci.org/gcalderone/AbbrvKW.jl)


Julia supports keyword arguments in function calls, albeit the keyword names must be entirely specified even when there is no possibility of ambiguity.

In order to improve code readability it may be useful to use abbreviated names. This packages provide such functionality through the `@AbbrvKW` macro.

The idea for this macro came out from a [post](https://discourse.julialang.org/t/keyword-name-disambiguation/5459) in the Usage forum.  Hopefully, this functionality will be included as a native feature in future versions of Julia.

You may install this package typing

``` julia
Pkg.clone("https://github.com/gcalderone/AbbrvKW.jl.git")
```
in the Julia REPL.


## Example
Consider the following function:

``` julia
function Foo(; Keyword1::Int=1, AnotherKeyword::Float64=2.0, StillAnotherOne=3, KeyString::String="bar")
    @show Keyword1
    @show AnotherKeyword
    @show StillAnotherOne
    @show KeyString
end
```

The only way to use the keywords is to type their entire names, resulting in very long code lines, i.e.:

``` julia
Foo(Keyword1=10, AnotherKeyword=20.0, StillAnotherOne=30, KeyString="baz")
```

By using the `@AbbrvKW` macro within the `Foo` function you may use abbreviated keywords, as long as the provided names allow complete disambiguation:
``` julia
using AbbrvKW

function Foo(; kw...)
    @AbbrvKW(kw, Keyword1::Int=1, AnotherKeyword::Float64=2.0, StillAnotherOne=3, KeyString::String="bar")
    @assert(length(kw) == 0, "Unrecognized keyword(s): " * string(kw))

    @show Keyword1
    @show AnotherKeyword
    @show StillAnotherOne
    @show KeyString
end

Foo(Keyw=10, A=20.0, S=30, KeyS="baz")
```
Much shorter, isn't it?
We also added a line to raise an error if an unrecognized keyword is given.


## Usage
To use the `@AbbrvKW` macro you should use a symbol to catch all the provided keywords in the function definition, and pass it as first argument to the macro.  In the example above this symbol is `kw` (you may freely choose any other valid Julia symbol).

The `@AbbrvKW` should be placed at the very beginning of the function block, and the keyword should be listed in exactly the same way you would do in the function definition, optionally specifying a type for each keyword.  Remember that the default value is mandatory!

Within the function you may use the keyword variables as usual, specifying their whole names (obviously...).

Note that the keywords listed in the `@AbbrvKW` call are removed from the splat variable, as if they were listed in the function definition.  Hence if the `kw` array length is not zero an unrecognized keyword has been given.  You may either pass this/these further keyword(s) to another function, or raise an error.

The macro call shown in the example above will expand in the following code (check by yourself using `@macroexpand` in the Julia REPL):

``` julia
julia> @macroexpand @AbbrvKW(kw, Keyword1::Int=1, AnotherKeyword::Float64=2.0, StillAnotherOne=3, KeyString::String="bar")

Keyword1::Int = 1
AnotherKeyword::Float64 = 2.0
StillAnotherOne = 3
KeyString::String = "bar"
____ = 1
while ____ <= length(kw)
    if (kw[____])[1] in (:Keyword1, :Keyw, :Keywo, :Keywor, :Keyword)
        Keyword1 = (kw[____])[2]
        deleteat!(kw, ____)
        continue
    end
    if (kw[____])[1] in (:AnotherKeyword, :A, :An, :Ano, :Anot, :Anoth, :Anothe, :Another, :AnotherK, :AnotherKe, :AnotherKey, :AnotherKeyw, :AnotherKeywo, :AnotherKeywor)
        AnotherKeyword = (kw[____])[2]
        deleteat!(kw, ____)
        continue
    end
    if (kw[____])[1] in (:StillAnotherOne, :S, :St, :Sti, :Stil, :Still, :StillA, :StillAn, :StillAno, :StillAnot, :StillAnoth, :StillAnothe, :StillAnother, :StillAnotherO, :StillAnotherOn)
        StillAnotherOne = (kw[____])[2]
        deleteat!(kw, ____)
        continue
    end
    if (kw[____])[1] in (:KeyString, :KeyS, :KeySt, :KeyStr, :KeyStri, :KeyStrin)
        KeyString = (kw[____])[2]
        deleteat!(kw, ____)
        continue
    end
    ____ += 1
end
____ = nothing
```
