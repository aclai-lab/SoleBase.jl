module SoleBase

"""
    abstract type AbstractDataset end

Abstract supertype for all datasets.

See also [`nsamples`](@ref).
"""
abstract type AbstractDataset end

"""
    nsamples(X::AbstractDataset)

Number of samples in the dataset.

See also [`AbstractDataset`](@ref).
"""
function nsamples(X::AbstractDataset)
    error("Please, provide method nsamples(::$(typeof(X))).")
end

include("utils.jl")

end
