using Logging
using Random

"""
Log overview info
"""
const LogOverview = LogLevel(-500)
"""
Log debug info
"""
const LogDebug = LogLevel(-1000)
"""
Log detailed debug info
"""
const LogDetail = LogLevel(-1500)

"""
Return the human-readable size in Bytes/KBs/MBs/GBs/TBs of a Julia object.
"""
function humansize(X; digits = 2, minshowndigits = digits)
    s = Base.summarysize(X)
    d = repeat('0', digits-minshowndigits)
    if !startswith(string(round(s/1024/1024/1024/1024, digits=digits)), "0.$(d)")
        "$(s/1024/1024/1024/1024 |> x->round(x, digits=digits)) TBs"
    elseif !startswith(string(round(s/1024/1024/1024, digits=digits)), "0.$(d)")
        "$(s/1024/1024/1024 |> x->round(x, digits=digits)) GBs"
    elseif !startswith(string(round(s/1024/1024, digits=digits)), "0.$(d)")
        "$(s/1024/1024 |> x->round(x, digits=digits)) MBs"
    elseif !startswith(string(round(s/1024, digits=digits)), "0.$(d)")
        "$(s/1024 |> x->round(x, digits=digits)) KBs"
    else
        "$(s |> x->round(x, digits=digits)) Bytes"
    end
end

"""
    throw_n_log(str::AbstractString, err_type = ErrorException)

Logs string `str` with `@error` and `throw` error of type `err_type`.
"""
function throw_n_log(str::AbstractString, err_type = ErrorException)
    @error str
    throw(err_type(str))
end

"""
    nat_sort(x, y)

"Little than" function implementing natural sort.
It is meant to be used with Base.Sort functions as in `sort(..., lt=nat_sort)`.

"""
function nat_sort(x, y)
    # https://titanwolf.org/Network/Articles/Article?AID=969b78b2-141a-43ef-9391-7c55b3c513c7
    splitbynum(x) = split(x, r"(?<=\D)(?=\d)|(?<=\d)(?=\D)")
    numstringtonum(arr) = [(n = tryparse(Float32, e)) != nothing ? n : e for e in arr]

    xarr = numstringtonum(splitbynum(string(x)))
    yarr = numstringtonum(splitbynum(string(y)))
    for i in 1:min(length(xarr), length(yarr))
        if typeof(xarr[i]) != typeof(yarr[i])
            a = string(xarr[i]); b = string(yarr[i])
        else
             a = xarr[i]; b = yarr[i]
        end
        if a == b
            continue
        else
            return a < b
        end
    end
    return length(xarr) < length(yarr)
end

# https://discourse.julialang.org/t/groupby-function/9896

"""
    group items of list l according to the corresponding values in list v

    julia> _groupby([31,28,31,30,31,30,31,31,30,31,30,31],
           [:Jan,:Feb,:Mar,:Apr,:May,:Jun,:Jul,:Aug,:Sep,:Oct,:Nov,:Dec])
    Dict{Int64,Array{Symbol,1}} with 3 entries:
        31 => Symbol[:Jan, :Mar, :May, :Jul, :Aug, :Oct, :Dec]
        28 => Symbol[:Feb]
        30 => Symbol[:Apr, :Jun, :Sep, :Nov]

"""
function _groupby(v::AbstractVector, l::AbstractVector)
  @assert length(v) == length(l) "$(@show v, l)"
  res = Dict{eltype(v),Vector{eltype(l)}}()
  for (k, val) in zip(v, l)
    push!(get!(res, k, similar(l, 0)), val)
  end
  res
end

"""
    group items of list l according to the values taken by function f on them

    julia> _groupby(iseven,1:10)
    Dict{Bool,Array{Int64,1}} with 2 entries:
        false => [1, 3, 5, 7, 9]
        true  => [2, 4, 6, 8, 10]

Note:in this version l is required to be non-empty since I do not know how to
access the return type of a function
"""
function _groupby(f,l::AbstractVector)
  res = Dict(f(l[1]) => [l[1]]) # l should be nonempty
  for val in l[2:end]
    push!(get!(res, f(val), similar(l, 0)), val)
  end
  res
end

############################################################################################

_typejoin(S::_S) where {_S} = S
_typejoin(S::_S, T::_T) where {_S,_T} = typejoin(S, T)
_typejoin(S::_S, T::_T, args...) where {_S,_T} = typejoin(S, typejoin(T, args...))

vectorize(x::Real) = [x]
vectorize(x::AbstractVector) = x

############################################################################################

"""
Spawns a `MersenneTwister` seeded using a number peeled from another `rng`.
Useful for reproducibility.
"""
function spawn(rng::Random.AbstractRNG)
    Random.MersenneTwister(abs(rand(rng, Int)))
end
