using Test
using Random

seed = 1
N = 10

@testset "Fixed-size moving window" begin
    include("movingwindow/fixedlength.jl")
end

@testset "Fixed-size moving window with landmark" begin
    include("movingwindow/fixedlength-landmark.jl")
end
