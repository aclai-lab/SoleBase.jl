
# ------------------------------------------------------------------------------
# movingwindow

"""
    movingwindow(vec::AbstractVector; kwargs...)::AbstractVector{UnitRange{Int}}
    movingwindow(npoints::Integer; kwargs...)::AbstractVector{UnitRange{Int}}

Return a certain number of equally-spaced windows (i.e., vector of integer
indices), used for slicing a vector `vec` (or a vector of `npoints` values).

    movingwindow(f::Base.Callable, vec::AbstractVector; kwargs...)::AbstractVector

Return the `map` of `f` over the window slicing of `vec`.

As for the keyword arguments, different flavors of this function are available,
according to different use cases.

# Fixed-size windows

    function movingwindow(
        npoints::Integer;
        window_length::Union{Nothing,Real} = nothing,
        window_step::Union{Nothing,Real} = nothing,
        # Optional arguments
        landmark::Union{Integer,Nothing} = nothing,
        allow_landmark_position::Tuple{<:AbstractFloat,<:AbstractFloat} = (0.0, 1.0),
        kwargs...
    )::AbstractVector{UnitRange{Int}}

Return windows of length `window_length`, with a step between consecutive windows of
`window_step`.
When the `window_step` is a floating point number, the step within the returned
windows is not constant, but fluctuates around `window_step`.

When a `landmark::Integer` point is specified to the function, only windows containing
the landmark will be returned. For example, with `npoints=100` and `landmark=50`,
all the windows will contain `50`.
It is also possible to specify the range for the relative position of the landmark within
the windows using `allow_landmark_position`.

# Fixed number of windows

    function movingwindow(
        npoints::Integer;
        nwindows::Union{Nothing,Integer} = nothing,
        relative_overlap::Union{Nothing,AbstractFloat} = nothing,
        kwargs...
    )::AbstractVector{UnitRange{Int}}

Compute `nwindows` windows, with consecutive windows overlapping by a portion equal to
`relative_overlap`.

# Fixed number of fixed-sized windows

    function movingwindow(
        npoints::Integer;
        nwindows::Union{Nothing,Integer} = nothing,
        window_length::Union{Nothing,Real} = nothing,
        kwargs...
    )::AbstractVector{UnitRange{Int}}

Compute `nwindows` windows of length `window_length`.

# Examples
TODO

Compute windows of length `window_length`, with consecutive windows being shifted by
`window_step` units.
"""

# TODO: Docs
"""
    movingwindow(npoints, nwindows, relative_overlap, window_length, window_step; kwargs...)

Generates a certain number of windows from a serie of points (`npoints`), and
returns them as a Vector of indices (that can be used for slicing a vector of
`npoints` values).

NOTE: The call to the moving window must expect three, and only three,
positional parameters, i.e. `npoints` and a combination of the rest.

# Arguments
* `npoints` is the Vector of Integer on which the windows will be generated;
* `nwindows` indicates the number of will to generate;
* `relative_overlap`
* `window_length` indicates the length of the single window;
* `window_step` indicates the distance (step) between the starting point of one window (not included) and the starting point of the next one (included).
"""
function movingwindow(
    npoints::Integer;
    nwindows::Union{Nothing,Integer} = nothing,
    relative_overlap::Union{Nothing,AbstractFloat} = nothing,
    window_length::Union{Nothing,Real} = nothing,
    window_step::Union{Nothing,Real} = nothing,
    kwargs...
)::AbstractVector{UnitRange{Int}}

    if !isnothing(window_length) && !isnothing(window_step)
        _movingwindow_fixed_lenght(
            npoints,
            window_length,
            window_step;
            kwargs...
        )
    elseif !isnothing(nwindows) && !isnothing(relative_overlap)
        _movingwindow_fixed_num(
            npoints,
            nwindows,
            relative_overlap;
            kwargs...
        )
    elseif !isnothing(nwindows) && !isnothing(window_length)
        _movingwindow_fixed_num_size(
            npoints,
            nwindows,
            window_length;
            kwargs...
        )
    else
        _args = (;
            nwindows = nwindows,
            relative_overlap = relative_overlap,
            window_length = window_length,
            window_step = window_step,
        )
        specified_args = collect(keys(filter(((k,v),)->!isnothing(v), pairs(_args))))
        if length(specified_args) == 0
            error("Cannot compute moving window without any keyword argument. " *
                "Please refer to the help for movingwindow.")
        else
            error("Cannot compute moving window with keyword arguments: " *
                join(specified_args, "`, `", "` and `") *
                ". Please refer to the help for movingwindow.")
        end
    end
end

"""
    movingwindow(v, args...; kwargs...)

Slices a Vector into a certain number of windows, which are returned.

# Arguments

* `v` is a Vector to split into windows.
"""
function movingwindow(v::AbstractVector, args...; kwargs...)
    npoints = length(v)
    return map(r -> v[r], movingwindow(npoints, args...; kwargs...))
end

"""
    movingwindow(f, v, args...; kwargs...)

Slices a Vector into a certain number of windows, which are returned after
applying an `f` function to them.

# Arguments

* `v` is the Vector to split into windows;
* `f` is the function to apply to the windows.
"""
function movingwindow(f::Base.Callable, v::AbstractVector, args...; kwargs...)
    return map(f, movingwindow(v, args...; kwargs...))
end


# ------------------------------------------------------------------------------
# movingwindow - fixed length

# TODO: Check docs
"""
    movingwindow_fixed_length(npoints, window_length, window_step; landmark, allow_landmark_position, force_coverage)

Return a certain number of windows where each window as length `window_length`
and the step between the starting point of one window (not included) and the
starting point of the next one (included) is `window_step`.

When a `landmark` is passed to the function, each of the generated windows will
have a point in common, the one indicated by `landmark`. For example, if the
`npoints` of length 100 and `landmark` equal to 50 are given, all the generated
windows will have the 50th point of `npoints` in them. Additionally, is possible
to specify the position of the landmark in the generated window using
`allow_landmark_position`

By setting `force_coverage` to true the final window (if it ends after npoints)
will be clamped at npoints.

# Arguments

* `npoints` is the Vector of Integer on which the windows will be generated;
* `window_length` is a Integer that indicates the length of the single window;
* `window_step` is a Integer that indicates the distance (step) between the starting point of one window (not included) and the starting point of the next one (included);
* `landmark` is a Integer that indicates a point (between 1 and npoints) which must be present in all generated windows;
* `allow_landmark_position` is a tuple of Number in [0:1] that indicates in which portion of the windows the landmark must be present;
* `force_coverage` indicates whether to clamp (at npoints) or exclude the last window, if it ends after npoints.
* `start`
"""
function _movingwindow_fixed_lenght(
    npoints::Integer,
    window_length::Union{Integer,AbstractFloat},
    window_step::Union{Integer,AbstractFloat};
    landmark::Union{Integer,Nothing} = nothing,
    allow_landmark_position::Tuple{<:Number,<:Number} = (0.0, 1.0), # Use Number?
    force_coverage::Bool = false,
    start::Integer = 1, # TODO don't mention in the docstrings?
)::AbstractVector{UnitRange{Int}}

    window_length = max(round(Int, window_length), 1)

    if isnothing(landmark) && allow_landmark_position != (0.0,1.0)
        @warn "allow_landmark_position position is specified but landmark is not."
    end
    if first(allow_landmark_position) > last(allow_landmark_position)
        throw(ArgumentError(
            string("allow_landmark_position must have the second element greater than the
            first one. Got $(first(allow_landmark_position)) >
            $(last(allow_landmark_position))")
        ))
    end
    if !(0 <= first(allow_landmark_position) <= 1) || !(0 <= last(allow_landmark_position) <= 1)
        throw(ArgumentError(
            string("element of allow_landmark_position must be in range 0:1. Got range
            [$(first(allow_landmark_position)):$(last(allow_landmark_position))]")
        ))
    end

    start = !isnothing(landmark) ? landmark-window_length+1 : start
    start = start < 1 ? 1 : start
    # indices = map((r)->r:r+window_length-1, range(start, npoints, step = window_step)) # TODO: Delete
    indices = map((r)->round(Int,r):round(Int, r+window_length-1), range(start, npoints, step = window_step))

    @show indices
    if !force_coverage
        filter!((w)->w.start in 1:npoints && w.stop in 1:npoints, indices)
    else
        map!((w)->clamp(w.start, 1, npoints):clamp(w.stop, 1, npoints), indices, indices)
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


# ------------------------------------------------------------------------------
# moving window - fixed number of windows
function _movingwindow_fixed_num(
    npoints::Integer,
    nwindows::Integer,
    relative_overlap::AbstractFloat;
    landmark::Union{Nothing,Integer} = nothing,
    do_without::Symbol = :nwindows,
    allow_landmark_position::Tuple{<:AbstractFloat,<:AbstractFloat} = (0.0, 1.0),
)::AbstractVector{UnitRange{Int}}

    if nwindows == 1 && isnothing(landmark)
        return [1:npoints]
    end

    if do_without == :relative_overlap
        window_length = npoints / nwindows
        start = landmark - window_length
        start = start < 1 ? 1 : start
        indices = map((r)->ceil(Int, r):round(Int, r+window_length-1), range(start, npoints, step = landmark / nwindows))
    else
        overlap = npoints / nwindows * relative_overlap
        end_bounds = Iterators.take(
            iterated(x -> npoints / nwindows + x, 0),
            nwindows + 1
        ) |> collect
    end

    @show overlap, end_bounds
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

    if !isnothing(landmark)
        if do_without == :nwindows
            filter!(x->landmark in x, indices)

            if allow_landmark_position != (0.0, 1.0)
                landmark_positions = map((i)->(findfirst(x->x==landmark, i))/length(i), indices)
                indices = indices[findall(l->round(l, digits = 1) in allow_landmark_position[1]:0.001:allow_landmark_position[2], landmark_positions)]
            end
        else

        end
    end

    indices
    # NOTE for overflow: [(1+round(Int, end_bounds[i])-overlap):(round(Int, end_bounds[i+1])+overlap) for i in 1:length(end_bounds)-1]
end

# ------------------------------------------------------------------------------------------
# moving window - fixed number of fixed-size windows

function _movingwindow_fixed_num_size(
    npoints::Integer,
    nwindows::Integer,
    window_length::Integer;
    landmark::Union{Integer,Nothing} = nothing,
)
    # window_length <= npoints
    if window_length == npoints
        map(_->1:npoints, 1:nwindows)
        # @show map(_->1:npoints, 1:nwindows)
    else
        if !isnothing(landmark)
            start = landmark - window_length + 1
            finish = landmark + window_length - 1
            npoints = length(start:finish)
        else
            start = 1
            finish = npoints
        end

        steps = (npoints - (nwindows * window_length))

        if steps == 0
            window_step = window_length
        elseif steps > 0
            if nwindows != 1
                window_step = (steps / (nwindows - 1)) + window_length
            else
                window_step = (steps / nwindows) + window_length
            end
        else
            window_step = window_length - (abs(steps) / (nwindows - 1))
        end

        @show steps, window_step, start, finish
        #@show range(start, npoints, step = window_step)
        #indices = movingwindow(finish; window_length = window_length, window_step = window_step, start = start)
        #@show indices
        #indices[1:nwindows]
        indices = map((r)->round(Int,r):(round(Int, r)+window_length-1), range(start, finish, step = window_step))

        # indices = map((r)->round(Int,r):round(Int, r+window_length-1), range(start, npoints, step = window_step))[1:npoints]

        # indices = map((r)->round(Int,r):round(Int, r+window_length-1), range(landmark-window_length+1, landmark+window_length, step = window_step))
    end
end


############################################################################################
############################################################################################
############################################################################################

# old version
# function _movingwindow_fixed_num_size(
#         npoints::Integer,
#         nwindows::Integer,
#         window_length::Integer;
#         landmark::Union{Integer,Nothing} = nothing,
#         kwargs...
#     )::AbstractVector{UnitRange{Int}}
#     start = !isnothing(landmark) ? landmark-window_length+1 : 1
#     start = start < 1 ? 1 : start

#     finish = !isnothing(landmark) ? landmark-1 : npoints

#     if start != landmark
#         step =  !isnothing(landmark) ? floor(Int, (length(start:landmark)-1) / (nwindows)) : floor(Int, window_length/nwindows)
#     else
#         step = 1
#     end

#     if (start + step * (nwindows -1)  + window_length) > npoints && !isnothing(landmark)
#         step = floor(Int, length(landmark:npoints) / nwindows)
#     end

#     #@show start, step, start + step * (nwindows -1)
#     # Case 2: landmark too close to end of time serie
#     #

#     indices = movingwindow(npoints; window_length = window_length, window_step = step, landmark = landmark, kwargs...)
#     @show indices

#     #indices = [r:r+window_length-1 for r in range(start, npoints, step = step)]

#     if !isempty(indices)
#         if !isnothing(landmark)
#             x = findall(i->landmark in i, indices)
#             @show x, indices
#             return indices[x]
#         else
#             indices[1:nwindows]
#         end
#     else
#         @warn "No windows found"
#         return indices
#     end

# end


# # ------------------------------------------------------------------------------------------
# # moving window - fixed window size and step with floating step

# function __movingwindow_without_overflow_fixed_size(
#     npoints::Integer,
#     window_length::AbstractFloat,
#     window_step::Real,
# )::AbstractVector{UnitRange{Int}}

#     # NOTE: assumed it is important to the user to keep all windows the same size (not
#     #         caring about keeping strictly the same step)
#     nws = round(Int, window_length)

#     if floor(Int, window_length) != 0
#         @warn "`window_length` is not an integer: it will be approximated to " * string(nws)
#     end

#     return __movingwindow_without_overflow_fixed_size(npoints, nws, window_step)
# end

# function __movingwindow_without_overflow_fixed_size(
#     npoints::Integer,
#     window_length::Integer,
#     window_step::AbstractFloat,
# )::AbstractVector{UnitRange{Int}}
#     # TODO: implement

    # window_length = round(Int, window_length) # NOTE non-sense
    # @show window_length
    # # [clamp(round(Int, i), 1, npoints):clamp(round(Int, i)+window_length-1, 1, npoints) for i in 1:window_step:(npoints-(window_length-1))]
    # #[round(Int, i):round(Int, i)+window_length-1 for i in 1:window_step:(npoints-(window_length-1))]
    # [r:r+window_length for r in range(1, npoints, step = window_length)]
# end

#step_size = (npoints-(nwind*window_length)) / (nwind-1)
# questo è lo step a partire dalla fine della finestra precedente (quindi può anche essere negativo se c'è un overlap tra le finestre)

# When `allow_overflow=true`, a simpler algorithm for computing the ... the function is allowed to return windows with
# values outside of `1:npoints`. For example, if `npoints=100`, `window_length=10`,
# `window_step=10` and
# `allow_overflow=true`, then .
