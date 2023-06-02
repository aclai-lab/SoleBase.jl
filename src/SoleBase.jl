
module SoleBase


export AbstractDataset
export ninstances

export moving_window

# -------------------------------------------------------------
# AbstractDataset

"""
    abstract type AbstractDataset end

Abstract supertype for all datasets.

See also [`ninstances`](@ref).
"""
abstract type AbstractDataset end

# -------------------------------------------------------------
# AbstractDataset - ninstances

"""
ninstances(X::AbstractDataset)

Returns the number of instances (or samples) in the dataset.

See also [`AbstractDataset`](@ref).
"""
function ninstances(X::AbstractDataset)
    error("Please, provide method ninstances(::$(typeof(X))).")
end


# -------------------------------------------------------------
# includes

include("utils.jl")


end
