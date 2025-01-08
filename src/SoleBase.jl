
module SoleBase

export AbstractDataset
export humansize
export ninstances

export moving_window, movingwindow, wholewindow, splitwindow, adaptivewindow

export slicedataset, displaystructure
# -------------------------------------------------------------
# AbstractDataset

"""
    abstract type AbstractDataset end

Abstract supertype for all datasets.

# Interface
- [`concatdatasets`](@ref)
- [`instances`](@ref)
- [`ninstances`](@ref)
- [`eachinstance`](@ref)

# Utility functions
- [`slicedataset`](@ref)

See also [`ninstances`](@ref).
"""
abstract type AbstractDataset end

"""
    slicedataset(
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

See [`concatdatasets`](@ref).
"""
function slicedataset(
    dataset::D,
    dataset_slice::Union{Colon, Integer, AbstractVector, Tuple};
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
             (!(dataset_slice isa Union{AbstractVector{<:Integer}, Tuple{<:Integer}}) ||
              length(dataset_slice) > 0))
            return error("Cannot apply empty slice to dataset.")
        end
        return instances(dataset, dataset_slice, Val(return_view); kwargs...)
    end
end

"""
    concatdatasets(datasets...)

Return the concatenation of machine learning datasets.

See [`slicedataset`](@ref).
"""
function concatdatasets(datasets::D...) where {D}
    return error("`concatdatasets` method not implemented for type "
                 * string(typejoin(typeof.(datasets)...))) * "."
end

"""See [`slicedataset`](@ref)."""
function instances(
    dataset::D,
    inds::AbstractVector,
    return_view::Union{Val{true}, Val{false}};
    kwargs...,
) where {D}
    return error("`instances` method not implemented for type "
                 * string(typeof(dataset))) * "."
end

"""
Return a string representing a dataset's structure.
"""
function displaystructure end
# function displaystructure(dataset; kwargs...)
#     return error("`displaystructure` method not implemented for type "
#                  * string(typeof(dataset))) * "."
# end

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
# AbstractDataset - eachinstance

"""
    eachinstance(X::AbstractDataset)

Return an iterator to the instances (also referred to as observations, or samples) in a dataset.

See also [`AbstractDataset`](@ref).
"""
function eachinstance(X::AbstractDataset)
    return error("Please, provide method eachinstance(::$(typeof(X))).")
end

# -------------------------------------------------------------

"""
Return the dimensionality of a dimensional dataset.

See also [`AbstractDataset`](@ref).
"""
function dimensionality end

"""
Return the channel size for a uniform dimensional dataset.

See also [`AbstractDataset`](@ref).
"""
function channelsize end

# -------------------------------------------------------------
# includes

include("utils.jl")
include("machine-learning-utils.jl")

include("movingwindow.jl")

@deprecate moving_window(args...; kwargs...) movingwindow(args...; kwargs...)

end
