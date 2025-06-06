# # ---------------------------------------------------------------------------- #
# #                                    utils                                     #
# # ---------------------------------------------------------------------------- #
# """
#     check_dimensions(X::AbstractMatrix) -> Int

# Check that all elements in a matrix have consistent dimensions.

# # Arguments
# - `X::AbstractMatrix`: Matrix containing array-like elements to check for dimension consistency

# # Returns
# - `Int`: The number of dimensions of the elements (0 if matrix is empty)

# # Throws
# - `ArgumentError`: If elements have more than 1 dimension
# - `DimensionMismatch`: If elements have inconsistent dimensions
# """
# function check_dimensions(X::AbstractMatrix)
#     isempty(X) && return 0
    
#     # Get reference dimensions from first element
#     first_col = first(eachcol(X))
#     ref_dims = ndims(first(first_col))
    
#     # Early dimension check
#     ref_dims > 1 && throw(ArgumentError("Elements more than 1D are not supported."))
    
#     # Check all columns maintain same dimensionality
#     all(col -> all(x -> ndims(x) == ref_dims, col), eachcol(X)) ||
#         throw(DimensionMismatch("Inconsistent dimensions across elements"))
    
#     return ref_dims
# end

# check_dimensions(df::DataFrame) = check_dimensions(Matrix(df))

# """
#     find_max_length(X::AbstractMatrix) -> Tuple{Vararg{Int}}

# Find the maximum dimensions of elements in a matrix containing either scalar values or array-like elements.

# # Arguments
# - `X::AbstractMatrix`: A matrix where each element can be either a scalar or an array-like structure

# # Returns
# - `Tuple{Vararg{Int}}`: A tuple containing the maximum sizes:
#   - For empty matrices: Returns `0`
#   - For matrices with scalar values: Returns `(1,)`
#   - For matrices with vector elements: Returns `(max_length,)` where `max_length` is the length of the longest vector
#   - For matrices with multi-dimensional arrays: Returns a tuple with maximum size in each dimension
# """
# function find_max_length(X::AbstractMatrix)
#     isempty(X) && return 0
    
#     # check the type of the first element to determine DataFrame structure
#     first_element = first(skipmissing(first(eachcol(X))))
    
#     if first_element isa Number
#         return (1,)
#     else
#         ndims_val = ndims(first_element)
#         # for each dimension, find the maximum size
#         ntuple(ndims_val) do dim
#             mapreduce(col -> maximum(x -> size(x, dim), col), max, eachcol(X); init=0)
#         end
#     end
# end

# find_max_length(df::DataFrame) = find_max_length(Matrix(df))
# # ---------------------------------------------------------------------------- #
# #                              min/max normalize                               #
# # ---------------------------------------------------------------------------- #
# minmax_normalize(c, args...; kwars...) = minmax_normalize!(deepcopy(c), args...; kwars...)

# """
#     minmax_normalize!(X; kwargs...)
#     minmax_normalize!(X, min::Real, max::Real)

# Apply min-max normalization to scale values to the range [0,1], modifying the input in-place.

# # Common Methods
# - `minmax_normalize!(X::AbstractMatrix; kwargs...)`: Normalize a matrix
# - `minmax_normalize!(df::AbstractDataFrame; kwargs...)`: Normalize a DataFrame
# - `minmax_normalize!(md::MultiData.MultiDataset, frame_index::Integer; kwargs...)`: Normalize a specific frame in a multimodal dataset
# - `minmax_normalize!(v::AbstractArray{<:Real}, min::Real, max::Real)`: Normalize an array using specific min/max values
# - `minmax_normalize!(v::AbstractArray{<:AbstractArray{<:Real}}, min::Real, max::Real)`: Normalize an array of arrays

# # Arguments
# - `X`: The data to normalize (matrix, DataFrame, or MultiDataset)
# - `frame_index`: For MultiDataset, the index of the frame to normalize
# - `min::Real`: Minimum value for normalization (when provided directly)
# - `max::Real`: Maximum value for normalization (when provided directly)

# # Keyword Arguments
# - `min_quantile::Real=0.0`: Lower quantile threshold for normalization
#   - `0.0`: Use the absolute minimum (no outlier exclusion)
#   - `> 0.0`: Use the specified quantile as minimum (e.g., 0.05 excludes bottom 5% as outliers)
# - `max_quantile::Real=1.0`: Upper quantile threshold for normalization
#   - `1.0`: Use the absolute maximum (no outlier exclusion)
#   - `< 1.0`: Use the specified quantile as maximum (e.g., 0.95 excludes top 5% as outliers)
# - `col_quantile::Bool=true`: How to calculate quantiles
#   - `true`: Calculate separate quantiles for each column (column-wise normalization)
#   - `false`: Calculate global quantiles across the entire dataset

# # Returns
# The input data, normalized in-place.

# # Throws
# - `DomainError`: If min_quantile < 0, max_quantile > 1, or max_quantile ≤ min_quantile

# # Details
# ## Matrix/DataFrame normalization:
# When normalizing matrices or DataFrames, this function:
# 1. Validates the quantile parameters
# 2. Determines min/max values based on the specified quantiles
# 3. If `col_quantile=true`, calculates separate min/max for each column
# 4. If `col_quantile=false`, uses the same min/max across the entire dataset
# 5. Applies the normalization to transform values to the [0,1] range

# ## Array normalization:
# For direct array normalization with provided min/max values:
# 1. If min equals max, returns an array filled with 0.5 values
# 2. Otherwise, scales values to [0,1] range using the formula: (x - min) / (max - min)
# """
# function minmax_normalize!(
#     md::MultiData.MultiDataset,
#     frame_index::Integer;
#     min_quantile::Real = 0.0,
#     max_quantile::Real = 1.0,
#     col_quantile::Bool = true,
# )
#     return minmax_normalize!(
#         MultiData.modality(md, frame_index);
#         min_quantile = min_quantile,
#         max_quantile = max_quantile,
#         col_quantile = col_quantile
#     )
# end

# function minmax_normalize!(
#     X::AbstractMatrix;
#     min_quantile::Real = 0.0,
#     max_quantile::Real = 1.0,
#     col_quantile::Bool = true,
# )
#     min_quantile < 0.0 &&
#         throw(DomainError(min_quantile, "min_quantile must be greater than or equal to 0"))
#     max_quantile > 1.0 &&
#         throw(DomainError(max_quantile, "max_quantile must be less than or equal to 1"))
#     max_quantile ≤ min_quantile &&
#         throw(DomainError("max_quantile must be greater then min_quantile"))

#     icols = eachcol(X)

#     if (!col_quantile)
#         # look for quantile in entire dataset
#         itdf = Iterators.flatten(Iterators.flatten(icols))
#         min = StatsBase.quantile(itdf, min_quantile)
#         max = StatsBase.quantile(itdf, max_quantile)
#     else
#         # quantile for each column
#         itcol = Iterators.flatten.(icols)
#         min = StatsBase.quantile.(itcol, min_quantile)
#         max = StatsBase.quantile.(itcol, max_quantile)
#     end
#     minmax_normalize!.(icols, min, max)
#     return X
# end

# function minmax_normalize!(
#     df::AbstractDataFrame;
#     kwargs...
# )
#     minmax_normalize!(Matrix(df); kwargs...)
# end

# function minmax_normalize!(
#     v::AbstractArray{<:AbstractArray{<:Real}},
#     min::Real,
#     max::Real
# )
#     return minmax_normalize!.(v, min, max)
# end

# function minmax_normalize!(
#     v::AbstractArray{<:Real},
#     min::Real,
#     max::Real
# )
#     if (min == max)
#         return repeat([0.5], length(v))
#     end
#     min = float(min)
#     max = float(max)
#     max = 1 / (max - min)
#     rt = StatsBase.UnitRangeTransform(1, 1, true, [min], [max])
#     # This function doesn't accept Integer
#     return StatsBase.transform!(rt, v)
# end

# # ---------------------------------------------------------------------------- #
# #                               normalize dataset                              #
# # ---------------------------------------------------------------------------- #
# """
#     _normalize_dataset!(
#         X::AbstractMatrix{T},
#         Xinfo::Vector{<:SoleFeatures.InfoFeat};
#         min_quantile::AbstractFloat=0.00,
#         max_quantile::AbstractFloat=1.00,
#         group::Tuple{Vararg{Symbol}}=(:nwin, :feat),
#     ) where {T<:Number}

# Normalize the dataset matrix `X` by applying min-max normalization to groups of features.

# ## Parameters
# - `X`: The input matrix to be normalized in-place
# - `Xinfo`: A vector of feature information objects that contain metadata about each feature
# - `min_quantile`: The quantile to use as the minimum value (default: 0.00)
#   - When set to 0.00, uses the absolute minimum value
#   - Higher values (e.g., 0.05) ignore lower outliers by using the specified quantile instead
# - `max_quantile`: The quantile to use as the maximum value (default: 1.00)
#   - When set to 1.00, uses the absolute maximum value
#   - Lower values (e.g., 0.95) ignore upper outliers by using the specified quantile instead
# - `group`: A tuple of symbols representing fields in the `InfoFeat` objects to group by (default: (:nwin, :feat))
#   - Features with the same values for these fields will be normalized together
#   - For example, with the default (:nwin, :feat), features from the same window and of the same type
#     will be normalized as a group, preserving their relative scale

# ## Details
# The function performs group-wise normalization, which is essential when working with features that 
# should maintain their relative scales. For example, when working with time series data, different 
# measures (min, max, mean) applied to the same window should be normalized together to preserve 
# their relationships.
# """
# function _normalize_dataset(
#     X::AbstractMatrix{T},
#     Xinfo::Vector{<:InfoFeat};
#     min_quantile::AbstractFloat=0.00,
#     max_quantile::AbstractFloat=1.00,
#     group::Tuple{Vararg{Symbol}}=(:nwin, :feat),
# ) where {T<:Number}
#     for g in _features_groupby(Xinfo, group)
#         minmax_normalize!(
#             view(X, :, g);
#             min_quantile = min_quantile,
#             max_quantile = max_quantile,
#             col_quantile = false
#         )
#     end
# end

# function _normalize_dataset(Xdf::AbstractDataFrame, Xinfo::Vector{<:InfoFeat}; kwargs...)
#     original_names = names(Xdf)
#     DataFrame(_normalize_dataset!(Matrix(Xdf), Xinfo; kwargs...), original_names)
# end

# function _features_groupby(
#     Xinfo::Vector{<:InfoFeat},
#     aggrby::Tuple{Vararg{Symbol}}
# )::Vector{Vector{Int}}
#     res = Dict{Any, Vector{Int}}()
#     for (i, g) in enumerate(Xinfo)
#         key = Tuple(getproperty(g, field) for field in aggrby)
#         push!(get!(res, key, Int[]), i)
#     end
#     return collect(values(res))  # Return the grouped indices
# end

# # ---------------------------------------------------------------------------- #
# #                                 treatment                                    #
# # ---------------------------------------------------------------------------- #
# """
#     _treatment(X::AbstractMatrix{T}, vnames::VarNames, treatment::Symbol,
#               features::FeatNames, winparams::WinParams; 
#               reducefunc::Base.Callable=mean) -> Tuple{Matrix, Vector{String}}

# Process a matrix data by applying feature extraction or dimension reduction.

# # Arguments
# - `X::AbstractMatrix{T}`: Matrix where each element is a time series (array) or scalar value
# - `vnames::VarNames`: Names of variables/columns in the original data
# - `treatment::Symbol`: Treatment method to apply:
#   - `:aggregate`: Extract features from time series (propositional approach)
#   - `:reducesize`: Reduce time series dimensions while preserving temporal structure
# - `features::FeatNames`: Functions to extract features from time series segments
# - `winparams::WinParams`: Parameters for windowing time series:
#   - `type`: Window function to use (e.g., `adaptivewindow`, `wholewindow`)
#   - `params`: Additional parameters for the window function
# - `reducefunc::Base.Callable=mean`: Function to reduce windows in `:reducesize` mode (default: `mean`)

# # Returns
# - `Tuple{Matrix, Vector{String}}`: Processed matrix and column names:
#   - For `:aggregate`: Matrix of extracted features with column names like `"func(var)w1"`
#   - For `:reducesize`: Matrix where each cell contains a reduced vector with original column names

# # Details
# ## Aggregate Treatment
# When `treatment = :aggregate`:
# 1. Divides each time series into windows using the specified windowing function
# 2. Applies each feature function to each window of each variable
# 3. Creates a feature matrix where each row contains features extracted from original data
# 4. Handles variable-length time series by padding with NaN values as needed
# 5. Column names include function name, variable name and window index (e.g. "mean(temp)w1")

# ## Reducesize Treatment
# When `treatment = :reducesize`:
# 1. Divides each time series into windows using the specified windowing function
# 2. Applies the reduction function to each window (by default `mean`)
# 3. Returns a matrix where each element is a reduced-length vector
# 4. Maintains original column names
# """
# function _treatment(
#     X::AbstractMatrix{T},
#     vnames::VarNames,
#     treatment::Symbol,
#     features::FeatNames,
#     winparams::WinParams;
#     reducefunc::Union{Base.Callable, Nothing}=nothing
# ) where T
#     # working with audio files, we need to consider audio of different lengths.
#     max_interval = first(find_max_length(X))
#     n_intervals = winparams.type(max_interval; winparams.params...)

#     # define column names and prepare data structure based on treatment type
#     if treatment == :aggregate        # propositional
#         if n_intervals == 1
#             col_names = [string(f, "(", v, ")") for f in features for v in vnames]
            
#             n_rows = size(X, 1)
#             n_cols = length(col_names)
#             result_matrix = Matrix{eltype(T)}(undef, n_rows, n_cols)
#         else
#             # define column names with features names and window indices
#             col_names = [string(f, "(", v, ")w", i) 
#                          for f in features 
#                          for v in vnames 
#                          for i in 1:length(n_intervals)]
            
#             n_rows = size(X, 1)
#             n_cols = length(col_names)
#             result_matrix = Matrix{eltype(T)}(undef, n_rows, n_cols)
#         end
            
#         # fill matrix
#         for (row_idx, row) in enumerate(eachrow(X))
#             row_intervals = winparams.type(maximum(length.(collect(row))); winparams.params...)
#             interval_diff = length(n_intervals) - length(row_intervals)

#             # calculate feature values for this row
#             feature_values = vcat([
#                 vcat([f(col[r]) for r in row_intervals],
#                     fill(NaN, interval_diff)) for col in row, f in features
#             ]...)
#             result_matrix[row_idx, :] = feature_values
#         end

#     elseif treatment == :reducesize   # modal
#         col_names = vnames
        
#         n_rows = size(X, 1)
#         n_cols = length(col_names)
#         result_matrix = Matrix{T}(undef, n_rows, n_cols)

#         isnothing(reducefunc) && (reducefunc = mean)
        
#         for (row_idx, row) in enumerate(eachrow(X))
#             row_intervals = winparams.type(maximum(length.(collect(row))); winparams.params...)
#             interval_diff = length(n_intervals) - length(row_intervals)
            
#             # calculate reduced values for this row
#             reduced_data = [
#                 vcat([reducefunc(col[r]) for r in row_intervals],
#                      fill(NaN, interval_diff)) for col in row
#             ]
#             result_matrix[row_idx, :] = reduced_data
#         end
#     end

#     return result_matrix, col_names
# end

# _treatment(df::DataFrame, args...) = _treatment(Matrix(df), args...)

# # ---------------------------------------------------------------------------- #
# #                        feature selection preprocess                          #
# # ---------------------------------------------------------------------------- #
# function feature_selection_preprocess(
#     X::DataFrame;
#     vnames::VarNames=nothing,
#     features::FeatNames=nothing,
#     type::Base.Callable=adaptivewindow,
#     nwindows::Int=6,
#     relative_overlap::Real=0.05
# )
#     # validate parameters
#     isnothing(vnames) && (vnames = names(X))
#     isnothing(features) && (features = DEFAULT_FE.features)
#     treatment = :aggregate
#     _ = check_dimensions(X) # TODO multidimensions
#     type ∈ FE_AVAIL_WINS || throw(ArgumentError("Invalid window type."))
#     nwindows > 0 || throw(ArgumentError("Number of windows must be positive."))
#     relative_overlap ≥ 0 || throw(ArgumentError("Overlap must be non-negative."))
    
#     # build winparams
#     # winparams = Dict($type => (nwindows, relative_overlap))
#     winparams = (type = type, nwindows = nwindows, relative_overlap = relative_overlap)

#     # create Xinfo
#     nf, nv, nw = length(features), length(vnames), nwindows
#     Xinfo = [
#         InfoFeat(
#             (f_idx-1) * nv * nw + (v_idx-1) * nw + w_idx, 
#             vnames[v_idx],
#             Symbol(features[f_idx]), 
#             w_idx
#         )
#         for f_idx in 1:nf 
#         for v_idx in 1:nv 
#         for w_idx in 1:nw
#     ]

#     _treatment(X, vnames, treatment, features, winparams), Xinfo
# end
