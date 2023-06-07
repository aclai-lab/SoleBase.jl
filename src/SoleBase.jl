
module SoleBase


export AbstractDataset
export humansize
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


_doc_slicedataset = """
    function slicedataset(
        dataset::D,
        dataset_slice::AbstractVector{<:Integer};
        allow_no_instances = false,
        return_view = false,
        kwargs...,
    )::D where {D<:AbstractDataset}

Return a machine learning dataset with a subset of the instances.

# Implementation

In order to use slicedataset on a custom dataset representation,
provide the following method:
    instances(
        dataset::D,
        dataset_slice::AbstractVector{<:Integer},
        return_view::Union{Val{true},Val{false}};
        kwargs...
    )::D where {D<:AbstractDataset}
"""

"""$(_doc_slicedataset)"""
function slicedataset(
    dataset::D,
    dataset_slice::Union{Colon,Integer,AbstractVector{<:Integer},Tuple{<:Integer}};
    allow_no_instances = false,
    return_view = false,
    kwargs...,
)::D where {D}
    if dataset_slice isa Integer
        dataset_slice = [dataset_slice]
    elseif dataset_slice isa Tuple{<:Integer}
        dataset_slice = collect(dataset_slice)
    end
    if dataset_slice isa Colon
        return deepcopy(dataset)
    else
        @assert (allow_no_instances ||
            (!(dataset_slice isa Union{AbstractVector{<:Integer},Tuple{<:Integer}}) ||
                length(dataset_slice) > 0)) "Can't apply empty slice to dataset."
        return instances(dataset, dataset_slice, Val(return_view); kwargs...)
    end
end

"""$(_doc_slicedataset)"""
function instances(
    dataset::D,
    dataset_slice::AbstractVector{<:Integer},
    return_view::Union{Val{true},Val{false}};
    kwargs...
)::D where {D}
    return error("`instances` method not implemented for type "
        * string(typeof(dataset))) * "."
end


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

include("movingwindow.jl")

# Alias (TODO remove?)
moving_window = movingwindow


end
