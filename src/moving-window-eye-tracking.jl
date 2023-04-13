#moving window - adding coalculations on pytrack eye features
#const world_size = (640, 480)

using NEVArt

function __moving_window_eyetracking(
    window_size::Integer,
    window_step::Integer,
    points::AbstractVector{<:Tuple{<:TimeType,<:NTuple{2,Real},<:Real}};
    maxDist = 25,
    minDur = 100,
    confidenceThreshold = 0.6,
    )

    if window_size > length(points)
        return NEVArt.SignalProcessing.fixation(points; res=(640,480), maxdist=maxDist, mindur=minDur, confidence_threshold=confidenceThreshold)
    end

    ret = []
    for i in range(1,length(points)-window_size*2)
        append!(ret,[NEVArt.SignalProcessing.fixation(points[i:i+window_size]; res=(640,480), maxdist=maxDist, mindur=minDur, confidence_threshold=confidenceThreshold)])
        i = i+window_step
    end

    return ret

end
