
seed = 1
N = 10

@testset "Fixed-size moving window" begin
    include("movingwindow/fixedsize.jl")
end

@testset "Fixed-size moving window with landmark" begin
    include("movingwindow/fixedsize-landmark.jl")
end
