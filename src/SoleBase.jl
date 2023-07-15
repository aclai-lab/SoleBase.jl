
module SoleBase


export AbstractDataset
export humansize
export ninstances

export moving_window, movingwindow

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
    ) where {D<:AbstractDataset}

Return a machine learning dataset with a subset of the instances.

# Implementation

In order to use slicedataset on a custom dataset representation,
provide the following method:
    instances(
        dataset::D,
        dataset_slice::AbstractVector{<:Integer},
        return_view::Union{Val{true},Val{false}};
        kwargs...
    ) where {D<:AbstractDataset}
"""

"""$(_doc_slicedataset)"""
function slicedataset(
    dataset::D,
    dataset_slice::Union{Colon,Integer,AbstractVector,Tuple};
    allow_no_instances = false,
    return_view = false,
    kwargs...,
) where {D}
    if dataset_slice isa Colon
        return deepcopy(dataset)
    else
        dataset_slice = vec(collect(dataset_slice))
        if !(eltype(dataset_slice) <: Integer)
            return error("Cannot slice dataset with slice of type $(eltype(dataset_slice))")
        end
        if !(allow_no_instances ||
            (!(dataset_slice isa Union{AbstractVector{<:Integer},Tuple{<:Integer}}) ||
                length(dataset_slice) > 0))
            return error("Cannot apply empty slice to dataset.")
        end
        return instances(dataset, dataset_slice, Val(return_view); kwargs...)
    end
end

function concatdatasets(datasets::D...) where {D}
    return error("`concatdatasets` method not implemented for type "
        * string(typejoin(typeof.(datasets)...))) * "."
end

"""$(_doc_slicedataset)"""
function instances(
    dataset::D,
    inds::AbstractVector{<:Integer},
    return_view::Union{Val{true},Val{false}};
    kwargs...
) where {D}
    return error("`instances` method not implemented for type "
        * string(typeof(dataset))) * "."
end


# -------------------------------------------------------------
# AbstractDataset - ninstances

"""
    ninstances(X::AbstractDataset)

Return the number of instances (also referred to as observations, or samples) in a dataset.

See also [`AbstractDataset`](@ref).
"""
function ninstances(X::AbstractDataset)
    return error("Please, provide method ninstances(::$(typeof(X))).")
end

# -------------------------------------------------------------

function dimensionality end
function channelsize end

# -------------------------------------------------------------
# includes

include("utils.jl")

include("movingwindow.jl")

@deprecate moving_window movingwindow


end
