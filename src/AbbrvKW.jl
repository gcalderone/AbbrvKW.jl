module AbbrvKW

import StatsBase.countmap
export @AbbrvKW

function findAbbrv(symLong::Vector{Symbol})
    if length(symLong) == 0 
        return symLong
    end

    out = Dict()
    for sym in symLong
        out[sym] = Vector{Symbol}()
    end

    symAbbr = deepcopy(symLong)
    symStr = convert.(String, symLong)
    kwCount = length(symLong)

    # Max length of string representation of keywords
    maxLen = maximum(length.(symStr))

    # Identify all abbreviations
    for len in 1:maxLen
        for i in 1:kwCount
            s = symStr[i]
            if length(s) >= len
                s = s[1:len]
                push!(symLong, symLong[i])
                push!(symAbbr, convert(Symbol, s))
                push!(symStr , s)
            end
        end
    end
    symStr = nothing # no longer needed

    # Identify unique abbreviations
    abbrCount = 0
    for (sym, count) in countmap(symAbbr)
        if count == 1
            i = find(symAbbr .== sym)
            @assert length(i) == 1
            i = i[1]
            if symLong[i] != symAbbr[i]
                push!(out[symLong[i]], symAbbr[i])
                abbrCount += 1
            end
        end
    end

    for (key, val) in out
        sort!(out[key])
    end

    return (out, abbrCount)
end


"""
Allow to use abbreviated keyword names in function calls.

This macro allows to shorten function calls by means of abbreviated
keyword names, while using full descriptive keyword names in the
function definition.

Example:
```
@AbbrvKW function Foo(;Keyword::Int=1, verboseLevel::Union{Void,Int}=nothing)
    println("Keyword: ", Keyword)
    if verboseLevel != nothing
        println("New verbosity level: ", verboseLevel)
    end
end

Foo(verb=1, K=3)
```
"""
macro AbbrvKW(func)
    @assert func.head == :function "Not a function"

    if length(func.args[1].args) <= 1
        # Empty parameter list"
        return esc(func)
    end

    if (typeof(func.args[1].args[2]) != Expr)  ||
        (func.args[1].args[2].head != :parameters)
        # No keywords given
        return esc(func)
    end
    
    sym = Vector{Symbol}() # Symbol, long version
    typ = Dict()           # Data type
    splat = Symbol()
    splatFound = false    
    for k in func.args[1].args[2].args
        @assert typeof(k) == Expr "Expr expected"
        @assert k.head in (:kw, :(...)) "Expected :kw or :..., got $(k.head)"

        #dump(k)
        if k.head == :kw
            @assert typeof(k.args[1]) in (Expr, Symbol) "Expected Expr or Symbol"

            if typeof(k.args[1]) == Symbol
                push!(sym, k.args[1])
                typ[sym[end]] = :Any
            elseif typeof(k.args[1]) == Expr
                @assert k.args[1].head == :(::) "Expected :(::), got $(k.args[1].head)"
                push!(sym, k.args[1].args[1])
                typ[sym[end]] = k.args[1].args[2]
            end
        elseif k.head == :(...)
            splat = k.args[1]
            splatFound = true
        end
    end

    # Find abbreviations
    (abbr, count) = findAbbrv(sym)
    if count == 0
        # No abbreviations found
        return esc(func)
    end

    # Add a splat variable if not present
    if !splatFound
        splat = :_abbrvkw_
        a = :($splat...)
        a = a.args[1]
        push!(func.args[1].args[2].args, a)
        a = nothing
    end

    # Build output Expr
    expr = Expr(:block)
    push!(expr.args, :(_ii_ = 1))
    push!(expr.args, Expr(:while, :(_ii_ <= length($splat)), Expr(:block)))

    for (sym, tup) in abbr
        length(tup) > 0 || continue
        tup = tuple(tup...)
        push!(expr.args[end].args[end].args,
              :(
                if $(splat)[_ii_][1] in $tup
                typeassert($(splat)[_ii_][2], $(typ[sym]))
                $(sym) = $(splat)[_ii_][2]
                deleteat!($splat, _ii_)
                continue
                end
                ))
    end
    push!(expr.args[end].args[end].args, :(_ii_ += 1))
    push!(expr.args, :(_ii_ = nothing))

    if !splatFound
        push!(expr.args, :(if length($splat) !=0 ;
                           error("Unrecognized keyword abbreviation(s): " * string($splat))
                           end))
        push!(expr.args, :($splat = nothing))
    end

    @assert length(func.args) == 2 "Function Expr has " * string(length(func.args)) * " args"
    @assert func.args[2].head == :block "Function block is not a block, but " * string(func.args[2].head)

    prepend!(func.args[2].args, [expr])
    #@show func
    return esc(func)
end

end # module
