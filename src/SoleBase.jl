module SoleBase

"""
Abstract supertype for all datasets.
"""
abstract type AbstractDataset end

function nsamples(X::AbstractDataset)
    error("Please, provide method nsamples(::$(typeof(X))).")
end

include("utils.jl")

end
