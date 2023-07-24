for npoints in 1:N
    for window_length in 1:npoints
        for window_step in 1:npoints
            for landmark in 1:npoints
                indices = moving_window(npoints; window_length = window_length, window_step = window_step, landmark = landmark)
                indices_coverage = moving_window(npoints; window_length = window_length, window_step = window_step, landmark = landmark, force_coverage = true)

                # TODO: Keep only the landmark test? landmark is just a filter
                # and window_length, window_step, force_coverage and other
                # things are already tested in fixedlength.jl.

                # window_length
                if length(indices) >= 1
                    @test length(unique([length(ids) for ids in indices])) == 1
                    @test all([length(i) == window_length for i in indices]) == true
                end

                for indices_ in [indices, indices_coverage]
                    # window_step
                    @test all([first(indices_[i+1]) - first(indices_[i]) == window_step for i in 1:length(indices_)-1]) == true
                    # landmanrk
                    @test all([landmark in i for i in indices]) == true
                    # others
                    @test all([first(i) in 1:npoints for i in indices_]) == true
                end

                # above tests
                @test isempty(setdiff(indices, indices_coverage)) == true

                # force_coverage
                if indices != indices_coverage
                    @test first(unique([last(ids) for ids in setdiff(indices_coverage, indices)])) == npoints
                end

                rng = MersenneTwister(seed)
                a = collect(0.0:0.1:1.0)
                positions = filter(x->x[1] < x[2], Iterators.product(a,a) |> collect |> vec)
                positions = positions[[rand(rng, 1:length(positions)) for c in 1:20]]
                for pos in positions
                    indices = moving_window(npoints; window_length = window_length, window_step = window_step, landmark = landmark, allow_landmark_position = pos)
                    indices_coverage = moving_window(npoints; window_length = window_length, window_step = window_step, landmark = landmark, allow_landmark_position = pos, force_coverage = true)

                    # TODO: Keep only the allow_landmark_position test?
                    # allow_landmark_position is just a filter and landmark,
                    # window_length, window_step, force_coverage and other
                    # things are already tested in fixedlength.jl and above.

                    # window_length
                    if length(indices) >= 1
                        @test length(unique([length(ids) for ids in indices])) == 1
                        @test all([length(i) == window_length for i in indices]) == true
                    end

                    for indices_ in [indices, indices_coverage]
                        # window_step
                        @test all([first(indices_[i+1]) - first(indices_[i]) == window_step for i in 1:length(indices_)-1]) == true
                        # landmanrk
                        @test all([landmark in i for i in indices]) == true
                        # allow_landmark_position
                        loc = [(findfirst(x->x==landmark, i))/length(i) for i in indices_]
                        @test all(l->round(l, digits = 1) in pos[1]:0.1:pos[2], loc) == true
                        # others
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
    end
end