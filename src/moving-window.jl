
# -------------------------------------------------------------
# moving window

"""
TODO: docs
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
        _moving_window(
            npoints,
            window_size,
            window_step;
            kwargs...
        )
    elseif !isnothing(nwindows) && !isnothing(relative_overlap)
        _moving_window(
            npoints,
            nwindows,
            relative_overlap;
            kwargs...
        )
    end
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
function _moving_window(
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
    _moving_window(npoints, window_size, window_step; landmark, allow_landmark_position, allow_landmark_on_edges, allow_overflow)

Return a certain number of windows where each window as length `window_size` and the step
between each window is `window_step`.

When a `landmark` is passed to the function, each of the generated windows will have a point
in common, the one indicated by `landmark`.

`allow_landmark_on_edges` allow to discard or not those windows where the landmark is on the
first or last point.
Note that in some cases (still to define) setting `allow_landmark_on_edges` to false will
generate no window due to the used method of windows generation. In these cases, is possible
to force the generation of the windows by setting `force` to true (still to implement).

Note: the step between two window is the distance between the first point of a window and
the first point of the window next to it.

"""
function _moving_window(
        npoints::Integer,
        window_size::Integer,
        window_step::Integer;
        landmark::Union{Integer,Nothing} = nothing,
        allow_landmark_position::Tuple{<:AbstractFloat,<:AbstractFloat} = (0.0, 1.0),
        # TODO: refactor `allow_landmark_on_edges` to accept a range of accepted relative
        #         positions the landmark can be in
        allow_landmark_on_edges::Bool = true,
        allow_overflow = false,
        # TODO: consider whether this is needed or not: force::Bool = false
    )::AbstractVector{UnitRange{Int}}

    # f = open("aatest.txt", "a+")
    # TODO: following asserts:
    #  - window_step < window_size in each cases? even with allow_overflow setted to true?
    #  - allow_landmark_on_edges true, then landmark != 1 && landmark != npoints && window_size > 3
    #    if allow_overflow then landmark can be equal to npoints. Even landmark == 1?
    #  -

    start = !isnothing(landmark) ? landmark-window_size+1 : 1
    # start = landmark == window_size ? start + 1 : start
    start = start < 1 ? 1 : start
    indices = map((r)->r:r+window_size-1, range(start, npoints-(window_size-1), step = window_step))

    if !allow_overflow
        filter!((w)->w.start in 1:npoints && w.stop in 1:npoints, indices)
    end

    if !isnothing(landmark)
        filter!(x->landmark in x, indices)

        if allow_landmark_position != (0.0, 1.0)
            filter!(x->!(landmark in first(x):round(Int, length(x) * first(allow_landmark_position))), indices)
            filter!(x->!(landmark in round(Int, length(x) * (1 - last(allow_landmark_position))):last(x)), indices)
        end

        if !allow_landmark_on_edges
            if isempty(filter(x->(first(x) != landmark && last(x) != landmark), indices))
                if length(indices) == 1
                    # TODO: DO WE WANT THE FUNCTION TO RETURN AN EMPTY VECTOR IN SOME CASES? if yes the following lines
                    # are not necessary and so the following todos.

                    #println(f, string("npoints: ", npoints, " window_size: ", window_size, " window_step: ", window_step, " landmark: ", landmark))
                    # window_step > window_size
                    if indices[1][1] == landmark
                        @test start + window_step + window_size - 1 in npoints == false
                        # TODO: find for which combinations of npoints, window_size, window_step, landmark, ecc. we
                        # end up here and put an assert at the top of the function. If force is true, that assert will
                        # not be considdered
                        indices = [indices[1][1]-1:indices[1][end]-1]
                    elseif indices[1][end] == landmark
                        # TODO: find for which combinations of npoints, window_size, window_step, landmark, ecc. we
                        # end up here and put an assert at the top of the function. If force is true, that assert will
                        # not be considdered
                        indices = [indices[1][1]+1:indices[1][end]+1]
                    end
                elseif length(indices) == 2
                    # TODO: find for which combinations of npoints, window_size, window_step, landmark, ecc. we
                    # end up here and put an assert at the top of the function. If force is true, that assert will
                    # not be considdered
                    indices = [
                        indices[1][1]+1:indices[1][end]+1,
                        indices[2][1]+1:indices[2][end]+1
                    ]
                    # @show npoints, window_size, window_step, landmark
                end
            else
                filter!(x->(first(x) != landmark && last(x) != landmark), indices)
            end
        end
    end
    # close(f)

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
