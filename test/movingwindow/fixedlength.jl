for npoints in 1:N
    for window_length in 1:npoints
        for window_step in 1:npoints
            indices = movingwindow(npoints; window_length = window_length, window_step = window_step)
            indices_coverage = movingwindow(npoints; window_length = window_length, window_step = window_step, force_coverage = true)
            for ids in [indices, indices_coverage[1:end-1]]
                # window_length
                @test length(unique([length(ids) for ids in indices])) == 1
                @test all([length(i) == window_length for i in indices]) == true
                # window_step
                @test all([first(indices[i+1]) - first(indices[i]) == window_step for i in 1:length(indices)-1]) == true
                # others
                @test first(first(indices)) == 1
            end

            # Check if a window as been filtered out due overbound
            if (first(last(indices)) + window_step) <= npoints
                # force_coverage
                @test last(last(indices_coverage)) == npoints
            end

            # for landmark in 1:npoints
            #     indices = movingwindow(npoints; window_length = window_length, nwindows = nwindows, landmark = landmark)
            #     # window_length
            #     @test all(length.(indices) .== length(first(indices))) == true
            #     # nwindows
            #     @test length(indices) == nwindows
            #     # landmark
            #     @test all(map((i)->landmark in i,indices)) == true
        end
    end
end