
# -------------------------------------------------------------
# moving window

"""
    moving_window(npoints, nwindows, relative_overlap, window_size, window_step; kwargs...)

Generates a certain number of windows from a time serie, and returns them as a Vector of
indices.
"""
function moving_window(
        npoints::Integer;
        nwindows::Union{Nothing,Integer} = nothing,
        relative_overlap::Union{Nothing,AbstractFloat} = nothing,
        window_size::Union{Nothing,Number} = nothing,
        window_step::Union{Nothing,Number} = nothing,
        kwargs...
    )::AbstractVector{UnitRange{Int}}
    if !isnothing(window_size) && !isnothing(window_step)
        _moving_window_fixed_size_step(
            npoints,
            window_size,
            window_step;
            kwargs...
        )
    elseif !isnothing(nwindows) && !isnothing(relative_overlap)
        _moving_window_fixed_num(
            npoints,
            nwindows,
            relative_overlap;
            kwargs...
        )
    elseif !isnothing(nwindows) && !isnothing(window_size)
        _moving_window_fixed_num_size(
            npoints,
            nwindows,
            window_size;
            kwargs...
        )
    end
    # TODO: add error message
end

function moving_window(v::AbstractVector{<:Real}, args...; kwargs...)
    return map(r -> v[r], moving_window(args...; kwargs...))
end

function moving_window(f::Function, v::AbstractVector{<:Real}, args...; kwargs...)
    return map(f, moving_window(v, args...; kwargs...))
end


# -------------------------------------------------------------
# moving window - npoints- fixed number of windows

"""
    _moving_window(npoints, nwindows, relative_overlap)

Returns `nwindows` where each windows overlap with each other by `relative_overlap`.

Note: relative_overlap indicates in percentage the overlap between the windows
"""
function _moving_window_fixed_num(
        npoints::Integer,
        nwindows::Integer,
        relative_overlap::AbstractFloat;
        landmark::Union{Nothing,Integer} = nothing,
        do_without::Symbol = :nwindows,
        allow_landmark_position::Tuple{<:AbstractFloat,<:AbstractFloat} = (0.0, 1.0),
        # TODO: allow_overflow::Bool = false
    )::AbstractVector{UnitRange{Int}}

    if nwindows == 1 && isnothing(landmark)
        return [1:npoints]
    end

    if do_without == :relative_overlap
        window_size = npoints / nwindows
        start = landmark - window_size
        start = start < 1 ? 1 : start
        indices = map((r)->ceil(Int, r):round(Int, r+window_size-1), range(start, npoints, step = landmark / nwindows))
    else
        overlap = npoints / nwindows * relative_overlap
        end_bounds = Iterators.take(
            iterated(x -> npoints / nwindows + x, 0),
            nwindows + 1
        ) |> collect
    end

    @show overlap, end_bounds
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


# -------------------------------------------------------------
# moving window - npoints- fixed window size and step

"""
    _moving_window(npoints, window_size, window_step; landmark, allow_landmark_position, allow_landmark_on_edges, allow_overflow)

Return a certain number of windows where each window as length `window_size` and the step
between each window is `window_step`.

When a `landmark` is passed to the function, each of the generated windows will have a point
in common, the one indicated by `landmark`. For example, if the time serie has 100 points and
the landmark is 50, all the generated windows will have the 50th point.
Additionally, is possible to specify the position of the landmark in the generated window
using `allow_landmark_position`.

By setting `allow_overflow` the function is allowed to generate windows where not all the
points are in the original time serie. For example, if the time serie has 100 points and
`allow_overflow` is true then even the window with indices 97:116 will be generated.

Note: the step between two window is the distance between the first point of a window and
the first point of the window next to it.
"""
function _moving_window_fixed_size_step(
        npoints::Integer,
        window_size::Integer,
        window_step::Union{Integer,AbstractFloat};
        landmark::Union{Integer,Nothing} = nothing,
        allow_landmark_position::Tuple{<:AbstractFloat,<:AbstractFloat} = (0.0, 1.0),
        allow_overflow = false, # TODO: remove overflow (never used)
        start::Integer = 1,
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

    start = !isnothing(landmark) ? landmark-window_size+1 : start
    start = start < 1 ? 1 : start
    # indices = map((r)->r:r+window_size-1, range(start, npoints, step = window_step))
    indices = map((r)->round(Int,r):round(Int, r+window_size-1), range(start, npoints, step = window_step))

    # @show indices
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


# -------------------------------------------------------------
# moving window - npoints- fixed window size and step with floating step

function __moving_window_without_overflow_fixed_size(
        npoints::Integer,
        window_size::AbstractFloat,
        window_step::Real,
    )::AbstractVector{UnitRange{Int}}

    # NOTE: assumed it is important to the user to keep all windows the same size (not
    #         caring about keeping strictly the same step)
    nws = round(Int, window_size)

    if floor(Int, window_size) != 0
        @warn "`window_size` is not an integer: it will be approximated to " * string(nws)
    end

    return __moving_window_without_overflow_fixed_size(npoints, nws, window_step)
end

function __moving_window_without_overflow_fixed_size(
        npoints::Integer,
        window_size::Integer,
        window_step::AbstractFloat,
    )::AbstractVector{UnitRange{Int}}
    # TODO: implement

    # window_size = round(Int, window_size) # NOTE non-sense
    # @show window_size
    # # [clamp(round(Int, i), 1, npoints):clamp(round(Int, i)+window_size-1, 1, npoints) for i in 1:window_step:(npoints-(window_size-1))]
    # #[round(Int, i):round(Int, i)+window_size-1 for i in 1:window_step:(npoints-(window_size-1))]
    # [r:r+window_size for r in range(1, npoints, step = window_size)]
end

#step_size = (npoints-(nwind*window_size)) / (nwind-1)
# questo è lo step a partire dalla fine della finestra precedente (quindi può anche essere negativo se c'è un overlap tra le finestre)

function _moving_window_fixed_num_size(
        npoints::Integer,
        nwindows::Integer,
        window_size::Integer;
        landmark::Union{Integer,Nothing} = nothing,
        kwargs...
    )
    # window_size <= npoints
    if window_size == npoints
        map(_->1:npoints, 1:nwindows)
        # @show map(_->1:npoints, 1:nwindows)
    else
        if !isnothing(landmark)
            start = landmark - window_size + 1
            finish = landmark + window_size - 1
            npoints = length(start:finish)
        else
            start = 1
            finish = npoints
        end

        steps = (npoints - (nwindows * window_size))

        if steps == 0
            window_step = window_size
        elseif steps > 0
            if nwindows != 1
                window_step = (steps / (nwindows - 1)) + window_size
            else
                window_step = (steps / nwindows) + window_size
            end
        else
            window_step = window_size - (abs(steps) / (nwindows - 1))
        end

        @show steps, window_step, start, finish
        #@show range(start, npoints, step = window_step)
        #indices = moving_window(finish; window_size = window_size, window_step = window_step, start = start)
        #@show indices
        #indices[1:nwindows]
        indices = map((r)->round(Int,r):(round(Int, r)+window_size-1), range(start, finish, step = window_step))

        # indices = map((r)->round(Int,r):round(Int, r+window_size-1), range(start, npoints, step = window_step))[1:npoints]

        # indices = map((r)->round(Int,r):round(Int, r+window_size-1), range(landmark-window_size+1, landmark+window_size, step = window_step))
    end
end

# old version
# function _moving_window_fixed_num_size(
#         npoints::Integer,
#         nwindows::Integer,
#         window_size::Integer;
#         landmark::Union{Integer,Nothing} = nothing,
#         kwargs...
#     )::AbstractVector{UnitRange{Int}}
#     start = !isnothing(landmark) ? landmark-window_size+1 : 1
#     start = start < 1 ? 1 : start

#     finish = !isnothing(landmark) ? landmark-1 : npoints

#     if start != landmark
#         step =  !isnothing(landmark) ? floor(Int, (length(start:landmark)-1) / (nwindows)) : floor(Int, window_size/nwindows)
#     else
#         step = 1
#     end

#     if (start + step * (nwindows -1)  + window_size) > npoints && !isnothing(landmark)
#         step = floor(Int, length(landmark:npoints) / nwindows)
#     end

#     #@show start, step, start + step * (nwindows -1)
#     # Case 2: landmark too close to end of time serie
#     #

#     indices = moving_window(npoints; window_size = window_size, window_step = step, landmark = landmark, kwargs...)
#     @show indices

#     #indices = [r:r+window_size-1 for r in range(start, npoints, step = step)]

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