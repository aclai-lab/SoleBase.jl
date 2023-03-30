# # # Moving window using nwindows and relative_overlap
# # for npoints in 10:100
# #     for nwindows in 1:npoints
# #         for relative_overlap in 0.0:0.1:1
# #             indices = _moving_window(npoints; nwindows = nwindows, relative_overlap = relative_overlap)

# #             @test length(indices) == nwindows
# #             if relative_overlap == 0.0
# #                 @test all([last(indices[i]) == first(indices[i+1]) - 1 for i in 1:length(indices)-1]) == true
# #             end
# #             @test first(first(indices)) == 1
# #             @test last(last(indices)) == npoints
# #         end
# #     end
# # end

# # # Moving window using window_size and window_step
# # for npoints in 10:100
# #     for window_size in 1:npoints
# #         for window_step in 1:npoints
# #             indices = _moving_window(npoints; window_size = window_size, window_step = window_step)

# #             @test length(unique([length(ids) for ids in indices])) == 1
# #             @test unique([length(ids) for ids in indices])[1] == window_size
# #             @test all([first(indices[i]) + window_step == first(indices[i+1]) for i in 1:length(indices)-1]) == true
# #             @test first(first(indices)) == 1
# #         end
# #     end
# # end

# # Moving window using window_size and window_step with landmark
# for npoints in 10:50
#     for window_size in 1:npoints
#         for window_step in 1:npoints
#             for landmark in 1:npoints

#                 # indices = _moving_window(npoints; window_size = window_size, window_step = window_step, landmark = landmark)
#                 # @test any([landmark in i for i in indices]) == true
#                 # @test all([length(i) == window_size for i in indices]) == true
#                 # @test all([first(indices[i+1]) - first(indices[i]) == window_step for i in 1:length(indices)-1]) == true

#                 if window_size > 2 && landmark != 1 && landmark != npoints
#                     if window_size != window_step && window_size != window_step + 1 && window_step < window_size && window_size != window_step + 2
#                         @show npoints, window_size, window_step, landmark

#                         indices = _moving_window(npoints; window_size = window_size, window_step = window_step, landmark = landmark, allow_landmark_on_edges = false)
#                         @show indices
#                         # allow_landmark_on_edges
#                         # @test all([landmark != first(i) && landmark != last(i) for i in indices]) == true
#                         @test any([landmark in i for i in indices]) == true
#                         # @test all([length(i) == window_size for i in indices]) == true
#                         # @test all([first(indices[i+1]) - first(indices[i]) == window_step for i in 1:length(indices)-1]) == true
#                    end
#                 end
#             end
#         end
#     end
# end

# # Moving window using window_size and window_step with landmark

for npoints in 10:50
    for window_size in 1:npoints
        for window_step in 1:npoints
                indices = moving_window(npoints; window_size = window_size, window_step = window_step)
                # window_size
                @test length(unique([length(ids) for ids in indices])) == 1
                @test all([length(i) == window_size for i in indices]) == true
                # window_step
                @test all([first(indices[i+1]) - first(indices[i]) == window_step for i in 1:length(indices)-1]) == true
                # other
                @test first(first(indices)) == 1

            for landmark in 1:npoints
                if window_step < window_size
                    indices = moving_window(npoints; window_size = window_size, window_step = window_step, landmark = landmark)
                    # window_size
                    @test length(unique([length(ids) for ids in indices])) == 1
                    @test all([length(i) == window_size for i in indices]) == true
                    # window_step
                    @test all([first(indices[i+1]) - first(indices[i]) == window_step for i in 1:length(indices)-1]) == true
                    # landmanrk
                    @test any([landmark in i for i in indices]) == true
                end

                if landmark != 1 && landmark != npoints && window_size > 3
                    indices = moving_window(npoints; window_size = window_size, window_step = window_step, landmark = landmark, allow_landmark_on_edges = false)
                    # @show indices, npoints, window_size, window_step, landmark
                    # window_size
                    @test length(unique([length(ids) for ids in indices])) == 1
                    @test all([length(i) == window_size for i in indices]) == true
                    # window_step
                    @test all([first(indices[i+1]) - first(indices[i]) == window_step for i in 1:length(indices)-1]) == true
                    # landmanrk
                    @test any([landmark in i for i in indices]) == true
                    # landmanrk on edges
                    @test all([landmark != first(i) && landmark != last(i) for i in indices]) == true
                end

                # TODO: Test with:
                #  - landmanrk position
                #  - allow_overflow
                #  - force (if implemented)
            end
        end
    end
end