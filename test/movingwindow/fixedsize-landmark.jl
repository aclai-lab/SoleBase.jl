
for npoints in 1:N
    println(npoints)
    for window_size in 1:npoints
        for window_step in 1:npoints
            # Moving Window - window_size, window_step
            indices = moving_window(npoints; window_size = window_size, window_step = window_step)
            indices_overflow = moving_window(npoints; window_size = window_size, window_step = window_step)

            for landmark in 1:npoints
                # Moving Window - window_size, window_step, landmark
                indices = moving_window(npoints; window_size = window_size, window_step = window_step, landmark = landmark)
                indices_overflow = moving_window(npoints; window_size = window_size, window_step = window_step, landmark = landmark)
                for ids in [indices, indices_overflow]
                    # window_size
                    @test length(unique([length(ids) for ids in indices])) == 1
                    @test all([length(i) == window_size for i in indices]) == true
                    # window_step
                    @test all([first(indices[i+1]) - first(indices[i]) == window_step for i in 1:length(indices)-1]) == true
                    # landmanrk
                    @test all([landmark in i for i in indices]) == true
                end
                # overflow
                @test all([first(i) in 1:npoints for i in indices]) == true

                # Moving Window - window_size, window_step, landmark, allow_landmark_position
                rng = MersenneTwister(seed)
                a = collect(0.0:0.1:1.0)
                positions = filter(x->x[1] < x[2], Iterators.product(a,a) |> collect |> vec)
                positions = positions[[rand(rng, 1:length(positions)) for c in 1:20]]
                for pos in positions
                    indices = moving_window(npoints; window_size = window_size, window_step = window_step, landmark = landmark, allow_landmark_position = pos)
                    indices_overflow = indices = moving_window(npoints; window_size = window_size, window_step = window_step, landmark = landmark, allow_landmark_position = pos)
                    for ids in [indices, indices_overflow]
                        # window_size
                        if length(indices) > 1
                            @test length(unique([length(ids) for ids in indices])) == 1
                        end
                        @test all([length(i) == window_size for i in indices]) == true
                        # window_step
                        @test all([first(indices[i+1]) - first(indices[i]) == window_step for i in 1:length(indices)-1]) == true
                        # allow_landmark_position
                        # loc = [(findfirst(x->x==landmark, i))/length(i) for i in indices]
                        # @test all(l->round(l, digits = 1) in pos[1]:0.1:pos[2], loc) == true
                    end
                    # overflow
                    @test all([first(i) in 1:npoints for i in indices]) == true
                end
            end
        end
    end
end
