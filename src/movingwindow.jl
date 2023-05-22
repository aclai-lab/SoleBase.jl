
# -------------------------------------------------------------
# moving window

"""
    function movingwindow(
        npoints::Integer;
        kwargs...
    )::AbstractVector{UnitRange{Int}}

Compute and return
a certain number of equally-spaced windows (i.e., vector of integer
indices), used for slicing a vector of `npoints` values.
The following two flavors of this function are available.

    function movingwindow(
        npoints::Integer;
        nwindows::Union{Nothing,Integer} = nothing,
        relative_overlap::Union{Nothing,AbstractFloat} = nothing,
        kwargs...
    )::AbstractVector{UnitRange{Int}}

Compute `nwindows` windows, with consecutive windows overlapping by a portion equal to
`relative_overlap`.

    function movingwindow(
        npoints::Integer;
        window_size::Union{Nothing,Number} = nothing,
        window_step::Union{Nothing,Number} = nothing,
        kwargs...
    )::AbstractVector{UnitRange{Int}}

The following keyword arguments are allowed:
TODO landmark

Compute windows of length `window_size`, with consecutive windows being shifted by
`window_step` units.
"""
function movingwindow(
    npoints::Integer;
    nwindows::Union{Nothing,Integer} = nothing,
    relative_overlap::Union{Nothing,AbstractFloat} = nothing,
    window_size::Union{Nothing,Number} = nothing,
    window_step::Union{Nothing,Number} = nothing,
    kwargs...
)::AbstractVector{UnitRange{Int}}

    if !isnothing(window_size) && !isnothing(window_step)
        _movingwindow(
            npoints,
            window_size,
            window_step;
            kwargs...
        )
    elseif !isnothing(nwindows) && !isnothing(relative_overlap)
        _movingwindow(
            npoints,
            nwindows,
            relative_overlap;
            kwargs...
        )
    end
end

function movingwindow(v::AbstractVector{<:Real}, args...; kwargs...)
    return map(r -> v[r], movingwindow(args...; kwargs...))
end

function movingwindow(f::Function, v::AbstractVector{<:Real}, args...; kwargs...)
    return map(f, movingwindow(v, args...; kwargs...))
end


# -------------------------------------------------------------
# moving window - npoints- fixed number of windows

"""
    _movingwindow(npoints, nwindows, relative_overlap)

Return `nwindows` where each window overlaps with the previous/following
by a portion equal to `relative_overlap`.
"""
function _movingwindow(
    npoints::Integer,
    nwindows::Integer,
    relative_overlap::AbstractFloat;
    # TODO: allow_overflow::Bool = false
    # TODO: landmark
)::AbstractVector{UnitRange{Int}}

    if nwindows == 1
        return [1:npoints]
    end

    overlap = npoints / nwindows * relative_overlap
    end_bounds = Iterators.take(
        iterated(x -> npoints / nwindows + x, 0),
        nwindows + 1
    ) |> collect

    # TODO: implement allow_overflow (should be some if in the following code)
    indices = Vector{UnitRange}(([
            if i == 1
                (1+round(Int, end_bounds[i])):(round(Int, end_bounds[i+1]+overlap))
            elseif i == length(end_bounds)-1
                (1+round(Int, end_bounds[i]-overlap)):(round(Int, end_bounds[i+1]))
            else
                (1+round(Int, end_bounds[i]-overlap)):(round(Int, end_bounds[i+1]+overlap))
            end
        for i in 1:length(end_bounds)-1
    ]))

    # NOTE for overflow: [(1+round(Int, end_bounds[i])-overlap):(round(Int, end_bounds[i+1])+overlap) for i in 1:length(end_bounds)-1]
end


# -------------------------------------------------------------
# moving window - npoints- fixed window size and step

"""
    _movingwindow(npoints, window_size, window_step; landmark, allow_landmark_position, allow_landmark_on_edges, allow_overflow)

Return a certain number of windows where each window as length `window_size` and the step
between each window is `window_step`.

When a `landmark` is passed to the function, each of the generated windows will have a point
in common, the one indicated by `landmark`. For example, if the time serie has 100 points and
the landmark is 50, all the generated windows will have the 50th point.
Additionally, is possible to specify the position of the landmark in the generated window
using `allow_landmark_position`.


Note: the step between two window is the distance between the first point of a window and
the first point of the window next to it.

"""
function _movingwindow(
    npoints::Integer,
    window_size::Integer,
    window_step::Integer;
    landmark::Union{Integer,Nothing} = nothing,
    allow_landmark_position::Tuple{<:AbstractFloat,<:AbstractFloat} = (0.0, 1.0),
    allow_overflow = false,
)::AbstractVector{UnitRange{Int}}
    if isnothing(landmark) && allow_landmark_position != (0.0,1.0)
        warn("allow_landmark_position position is specified but landmark is not.")
    end
    if first(allow_landmark_position) > last(allow_landmark_position)
        throw(ArgumentError(
            string("allow_landmark_position must have the second element greater than the
            first one. Got $(first(allow_landmark_position)) >
            $(last(allow_landmark_position))")
        ))
    end
    if !(first(allow_landmark_position) in 0.000:0.001:1.000) || !(last(allow_landmark_position) in 0.000:0.001:1.000)
        throw(ArgumentError(
            string("element of allow_landmark_position must be in range 0.000:0.001:1.000. Got
            $(first(allow_landmark_position)) > * $(last(allow_landmark_position))")
        ))
    end

    start = !isnothing(landmark) ? landmark-window_size+1 : 1
    start = start < 1 ? 1 : start
    indices = map((r)->r:r+window_size-1, range(start, npoints, step = window_step))

    if !allow_overflow
        filter!((w)->w.start in 1:npoints && w.stop in 1:npoints, indices)
    end

    if !isnothing(landmark)
        filter!(x->landmark in x, indices)

        if allow_landmark_position != (0.0, 1.0)
            landmark_positions = map((i)->(findfirst(x->x==landmark, i))/length(i), indices)
            indices = indices[findall(l->round(l, digits = 1) in allow_landmark_position[1]:0.001:allow_landmark_position[2], landmark_positions)]
        end
    end

    indices
end


# # -------------------------------------------------------------
# # moving window - npoints- fixed window size and step with floating step

# function __movingwindow_without_overflow_fixed_size(
#     npoints::Integer,
#     window_size::AbstractFloat,
#     window_step::Real,
# )::AbstractVector{UnitRange{Int}}

#     # NOTE: assumed it is important to the user to keep all windows the same size (not
#     #         caring about keeping strictly the same step)
#     nws = round(Int, window_size)

#     if floor(Int, window_size) != 0
#         @warn "`window_size` is not an integer: it will be approximated to " * string(nws)
#     end

#     return __movingwindow_without_overflow_fixed_size(npoints, nws, window_step)
# end

# function __movingwindow_without_overflow_fixed_size(
#     npoints::Integer,
#     window_size::Integer,
#     window_step::AbstractFloat,
# )::AbstractVector{UnitRange{Int}}
#     # TODO: implement

#     # window_size = round(Int, window_size) # NOTE non-sense
#     # @show window_size
#     # # [clamp(round(Int, i), 1, npoints):clamp(round(Int, i)+window_size-1, 1, npoints) for i in 1:window_step:(npoints-(window_size-1))]
#     # #[round(Int, i):round(Int, i)+window_size-1 for i in 1:window_step:(npoints-(window_size-1))]
#     # [r:r+window_size for r in range(1, npoints, step = window_size)]
# end
