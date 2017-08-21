module AbbrvKW

import StatsBase.countmap
export @AbbrvKW

macro AbbrvKW(outSym, kw...)
    length(kw) != 0 || return :()

    syml = Vector{Symbol}() # Symbol, long version
    typ  = Vector{Any}()    # Data type
    defv = Vector{Any}()    # Default value
    syma = Vector{Symbol}() # Symbol, abbreviated version
    syms = Vector{String}() # Symbol converted to String

    for i in 1:length(kw)
        #dump(kw[i])
        #println()
        @assert typeof(kw[i]) == Expr

        # Symbol name
        if typeof(kw[i].args[1]) == Expr
            @assert kw[i].args[1].head == :(::)
            push!(syml, kw[i].args[1].args[1])
        else
            push!(syml, kw[i].args[1])
        end
        
        # Symbol type
        t = :Any
        if typeof(kw[i].args[1]) == Expr
            t = kw[i].args[1].args[2]
        end
        push!(typ , t)

        # Default value            
        push!(defv, kw[i].args[2])

        push!(syma, syml[end])
        push!(syms, string(syml[end]))
    end
    
    # Max length of string representation of keywords
    maxlen = maximum(length.(syms))
    
    # Identify all abbreviations and add them to syma
    orig_syml = deepcopy(syml)
    for len in 1:maxlen
        abbrv_syml = Vector{Symbol}()
        abbrv_syma = Vector{Symbol}()
        abbrv_syms = Vector{String}()
        for i in 1:length(orig_syml)
            s = syms[i]
            if length(s) > len
                s = s[1:len]
                push!(abbrv_syml, syml[i])
                push!(abbrv_syma, convert(Symbol, s))
                push!(abbrv_syms, s)
            end
        end

        cm = countmap(abbrv_syms)
        for (sym, count) in cm
            if count == 1
                i = find(abbrv_syms .== sym)
                @assert length(i) == 1
                push!(syml, abbrv_syml[i[1]])
                push!(syma, abbrv_syma[i[1]])
            end
        end
    end
    
    # Build output Expr
    expr = Expr(:block)
    for i in 1:length(kw)
        push!(expr.args, Expr(:(=)))
        
        if typ[i] != :Any
            push!(expr.args[end].args, Expr(:(::)))
            push!(expr.args[end].args[end].args, syml[i])
            push!(expr.args[end].args[end].args, typ[i])
        else
            push!(expr.args[end].args, syml[i])
        end
        push!(expr.args[end].args, defv[i])
    end

    push!(expr.args, :(____ = 1))
    push!(expr.args, Expr(:while, :(____ <= length($outSym)), Expr(:block)))

    for i in 1:length(kw)
        j = find(syml .== syml[i])
        t = Expr(:tuple)
        for s in syma[j]
            push!(t.args, QuoteNode(s))
        end

        push!(expr.args[end].args[end].args, 
              :(
                if $(outSym)[____][1] in $t
                  $(syml[i]) = $(outSym)[____][2]
                  deleteat!($outSym, ____)
                  continue
                end
                ))
    end
    push!(expr.args[end].args[end].args, :(____ += 1))
    push!(expr.args, :(____ = nothing))

    return esc(expr)
end

end # module
