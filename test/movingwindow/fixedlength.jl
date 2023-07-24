for npoints in 1:N
    for window_length in 1:npoints
        for window_step in 1:npoints
            indices = movingwindow(npoints; window_length = window_length, window_step = window_step)
            indices_coverage = movingwindow(npoints; window_length = window_length, window_step = window_step, force_coverage = true)

            # @show indices, indices_coverage
            # @show indices

            # window_length
            @test length(unique([length(ids) for ids in indices])) == 1
            @test all([length(i) == window_length for i in indices]) == true

            for indices_ in [indices, indices_coverage]
                # window_step
                @test all([first(indices_[i+1]) - first(indices_[i]) == window_step for i in 1:length(indices_)-1]) == true
                # others
                @test first(first(indices_)) == 1
                @test all([first(i) in 1:npoints for i in indices_]) == true
            end

            # above tests
            @test isempty(setdiff(indices, indices_coverage)) == true

            # force_coverage
            if indices != indices_coverage
                @test first(unique([last(ids) for ids in setdiff(indices_coverage, indices)])) == npoints
            end
        end
    end
end