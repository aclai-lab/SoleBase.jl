# # Moving window using nwindows and relative_overlap
# for npoints in 1:100
#     for nwindows in 1:npoints
#         for relative_overlap in 0.0:0.1:1
#             indices = moving_window(npoints; nwindows = nwindows, relative_overlap = relative_overlap)

#             # nwindows
#             @test length(indices) == nwindows
#             # relative_overlap
#             if relative_overlap == 0.0
#                 @test all([last(indices[i]) == first(indices[i+1]) - 1 for i in 1:length(indices)-1]) == true
#             end
#             # others
#             @test first(first(indices)) == 1
#             @test last(last(indices)) == npoints

#             for landmark in 1:npoints
#                 #@show indices, npoints, relative_overlap, nwindows, landmark
#                 indices = moving_window(npoints; nwindows = nwindows, relative_overlap = relative_overlap, landmark = landmark)
#                 # nwindows
#                 @test length(indices) == nwindows
#                 # relative_overlap
#                 if relative_overlap == 0.0
#                     @test all([last(indices[i]) == first(indices[i+1]) - 1 for i in 1:length(indices)-1]) == true
#                 end
#                 # landmark
#                 @test all([landmark in i for i in indices]) == true
#             end
#         end
#     end
# end

# @show indices, npoints, window_size, window_step

# Moving window using window_size and window_step
for npoints in 1:N
    println(npoints)
    for window_size in 1:npoints
        for window_step in 1:npoints
            # Moving Window - window_size, window_step
            indices = moving_window(npoints; window_size = window_size, window_step = window_step)
            indices_overflow = moving_window(npoints; window_size = window_size, window_step = window_step)
            for ids in [indices, indices_overflow]
                # window_size
                @test length(unique([length(ids) for ids in indices])) == 1
                @test all([length(i) == window_size for i in indices]) == true
                # window_step
                @test all([first(indices[i+1]) - first(indices[i]) == window_step for i in 1:length(indices)-1]) == true
                # others
                @test first(first(indices)) == 1
            end
            #overflow
            @test all([first(i) in 1:npoints for i in indices]) == true


            @test all(length.(indices) .== length(first(indices))) == true

            # for landmark in 1:npoints
            #     indices = moving_window(npoints; window_size = window_size, nwindows = nwindows, landmark = landmark)
            #     # window_size
            #     @test all(length.(indices) .== length(first(indices))) == true
            #     # nwindows
            #     @test length(indices) == nwindows
            #     # landmark
            #     @test all(map((i)->landmark in i,indices)) == true
        end
    end
end


# seed = 1

# # Moving window using window_size and window_step
# for npoints in 1:50
#     for window_size in 1:npoints
#         for window_step in 1:npoints
#             # Moving Window - window_size, window_step
#             indices = moving_window(npoints; window_size = window_size, window_step = window_step)
#             indices_overflow = moving_window(npoints; window_size = window_size, window_step = window_step)
#             for ids in [indices, indices_overflow]
#                 # window_size
#                 @test length(unique([length(ids) for ids in indices])) == 1
#                 @test all([length(i) == window_size for i in indices]) == true
#                 # window_step
#                 @test all([first(indices[i+1]) - first(indices[i]) == window_step for i in 1:length(indices)-1]) == true
#                 # others
#                 @test first(first(indices)) == 1
#             end
#             #overflow
#             @test all([first(i) in 1:npoints for i in indices]) == true

#             for landmark in 1:npoints
#                 # Moving Window - window_size, window_step, landmark
#                 indices = moving_window(npoints; window_size = window_size, window_step = window_step, landmark = landmark)
#                 indices_overflow = moving_window(npoints; window_size = window_size, window_step = window_step, landmark = landmark)
#                 for ids in [indices, indices_overflow]
#                     # window_size
#                     @test length(unique([length(ids) for ids in indices])) == 1
#                     @test all([length(i) == window_size for i in indices]) == true
#                     # window_step
#                     @test all([first(indices[i+1]) - first(indices[i]) == window_step for i in 1:length(indices)-1]) == true
#                     # landmanrk
#                     @test all([landmark in i for i in indices]) == true
#                 end
#                 # overflow
#                 @test all([first(i) in 1:npoints for i in indices]) == true

#                 # Moving Window - window_size, window_step, landmark, allow_landmark_position
#                 rng = MersenneTwister(seed)
#                 a = collect(0.0:0.1:1.0)
#                 positions = filter(x->x[1] < x[2], product(a,a) |> collect |> vec)
#                 positions = positions[[rand(rng, 1:length(positions)) for c in 1:20]]
#                 for pos in positions
#                     indices = moving_window(npoints; window_size = window_size, window_step = window_step, landmark = landmark, allow_landmark_position = pos)
#                     indices_overflow = indices = moving_window(npoints; window_size = window_size, window_step = window_step, landmark = landmark, allow_landmark_position = pos)
#                     for ids in [indices, indices_overflow]
#                         # window_size
#                         if length(indices) > 1
#                             @test length(unique([length(ids) for ids in indices])) == 1
#                         end
#                         @test all([length(i) == window_size for i in indices]) == true
#                         # window_step
#                         @test all([first(indices[i+1]) - first(indices[i]) == window_step for i in 1:length(indices)-1]) == true
#                         # allow_landmark_position
#                         # loc = [(findfirst(x->x==landmark, i))/length(i) for i in indices]
#                         # @test all(l->round(l, digits = 1) in pos[1]:0.1:pos[2], loc) == true
#                     end
#                     # overflow
#                     @test all([first(i) in 1:npoints for i in indices]) == true
#                 end
#             end
#         end
#     end
# end

# for npoints in 1:100
#     for nwindows in 1:npoints
#         for window_size in nwindows:floor(Int, npoints/nwindows)
#             indices = moving_window_fixed_size(npoints, nwindows, window_size)
#             # @show npoints, nwindows, window_size, indices
#             # window_size
#             @test all(length.(indices) .== length(first(indices))) == true
#             # nwindows
#             @test length(indices) == nwindows
#             for landmark in 1:npoints
#                 @show npoints, nwindows, window_size, landmark
#                 indices = moving_window_fixed_size(npoints, nwindows, window_size; landmark)
#                 @show indices
#                 # window_size
#                 @test all(length.(indices) .== length(first(indices))) == true
#                 # nwindows
#                 @test length(indices) == nwindows
#                 #landmark
#                 @test all([landmark in i for i in indices]) == true
#             end
#         end
#     end
# end
