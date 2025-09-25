
using StatsBase
using FillArrays
using CategoricalArrays

doc_supervised_ml = """
    const XGLabel = Tuple{Union{AbstractString, Integer, CategoricalValue}, Real}
    const CLabel  = Union{AbstractString,Integer,CategoricalValue}
    const RLabel  = AbstractFloat
    const Label   = Union{CLabel,RLabel}

Types for supervised machine learning labels (classification and regression).
"""

"""$(doc_supervised_ml)"""
const XGLabel = Tuple{Union{AbstractString, Integer, CategoricalValue}, Real}
"""$(doc_supervised_ml)"""
const CLabel = Union{AbstractString, Symbol, CategoricalValue, UInt32}
"""$(doc_supervised_ml)"""
const RLabel = Real
"""$(doc_supervised_ml)"""
const Label = Union{CLabel, RLabel}

############################################################################################

# Convert a list of labels to categorical form
Base.@propagate_inbounds @inline function get_categorical_form(Y::AbstractVector)
    class_names = unique(Y)

    dict = Dict{eltype(Y), Int64}()
    @simd for i in 1:length(class_names)
        @inbounds dict[class_names[i]] = i
    end

    _Y = Array{UInt32}(undef, length(Y))
    @simd for i in 1:length(Y)
        @inbounds _Y[i] = dict[Y[i]]
    end

    return class_names, _Y
end

############################################################################################

"""
    bestguess(
        labels::AbstractVector{<:Label},
        weights::Union{Nothing,AbstractVector} = nothing;
        suppress_parity_warning = false,
        parity_func = sort(collect(counts), by = x -> x[1])[1][1]
    )

Return the best guess for a set of labels; that is, the label that best approximates the
labels provided. For classification labels, this function returns the majority class; for
regression labels, the average value.
If no labels are provided, `nothing` is returned.
The computation can be weighted.

See also
[`CLabel`](@ref),
[`RLabel`](@ref),
[`Label`](@ref).
"""
function bestguess(
    labels::AbstractVector{<:Label},
    weights::Union{Nothing, AbstractVector}=nothing;
    suppress_parity_warning=false,
    parity_func=x->argmax(x)
) end

# Classification: (weighted) majority vote
function bestguess(
    labels::AbstractVector{<:CLabel},
    weights::Union{Nothing, AbstractVector}=nothing;
    suppress_parity_warning=false,
    parity_func=x->argmax(x)
)
    if length(labels) == 0
        return nothing
    end

    counts = begin
        if isnothing(weights)
            # return StatsBase.mode(labels) ..?
            countmap(labels)
        else
            @assert length(labels)===length(weights) "Cannot compute "*
                                                     "best guess with mismatching number of votes "*
                                                     "$(length(labels)) and weights $(length(weights))."
            countmap(labels, weights)
        end
    end

    if sum(counts[argmax(counts)] .== values(counts)) > 1
        suppress_parity_warning || (
            @warn "Parity encountered in bestguess! " *
                  "counts ($(length(labels)) elements): $(counts), " *
                  "argmax: $(argmax(counts)), " *
                  "max: $(counts[argmax(counts)]) (sum = $(sum(values(counts))))"
        )
        parity_func(counts)
    else
        argmax(counts)
    end
end

# Regression: (weighted) mean (or other central tendency measure?)
function bestguess(
    labels::AbstractVector{<:RLabel},
    weights::Union{Nothing, AbstractVector}=nothing;
    suppress_parity_warning=false,
    parity_func=x->(x)
)
    if length(labels) == 0
        return nothing
    end

    (isnothing(weights) ? StatsBase.mean(labels) : sum(labels .* weights) / sum(weights))
end

function bestguess(
    labels::AbstractVector{<:XGLabel},
    classlabels::AbstractVector{<:CLabel};
    return_sum::Bool=false
)
    length(labels) == 0 && return nothing
    nclass = length(classlabels)

    class_sums = [0.0 for i in 1:nclass]

    for (i, (_, value)) in enumerate(labels)
        class_idx = ((i - 1) % nclass) + 1
        class_sums[class_idx] += value
    end

    class_sums = exp.(class_sums)

    best_class = classlabels[argmax(class_sums)]
    # return either just the class or both class and sum
    return return_sum ? (best_class, class_sums[argmax(class_sums)]) : best_class
end

############################################################################################

# Default weights are optimized using FillArrays
"""
    default_weights(n::Integer)::AbstractVector{<:Number}

Return a default weight vector of `n` values.
"""
function default_weights(n::Integer)
    Ones{Int64}(n)
end
default_weights(Y::AbstractVector) = default_weights(length(Y))

# Class rebalancing weights (classification case)
"""
    default_weights(Y::AbstractVector{L}) where {L<:CLabel}::AbstractVector{<:Number}

Return a class-rebalancing weight vector, given a label vector `Y`.
"""
function balanced_weights(Y::AbstractVector{L}) where {L <: CLabel}
    class_counts_dict = countmap(Y)
    if length(unique(values(class_counts_dict))) == 1 # balanced case
        default_weights(length(Y))
    else
        # Assign weights in such a way that the dataset becomes balanced
        tot = sum(values(class_counts_dict))
        balanced_tot_per_class = tot / length(class_counts_dict)
        weights_map = Dict{L, Float64}([class => (balanced_tot_per_class / n_instances)
                                        for (class, n_instances) in class_counts_dict])
        W = [weights_map[y] for y in Y]
        W ./ sum(W)
    end
end

slice_weights(W::Ones{Int64}, inds::AbstractVector) = default_weights(length(inds))
slice_weights(W::Any, inds::AbstractVector) = @view W[inds]
slice_weights(W::Ones{Int64}, i::Integer) = 1
slice_weights(W::Any, i::Integer) = W[i]
