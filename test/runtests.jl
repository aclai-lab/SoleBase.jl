using Distributed
addprocs(2)

@everywhere begin
    using SoleBase
    using Test
    using Random
    using StatsBase
    using IterTools
    using FillArrays
    using CategoricalArrays
    # using StableRNGs
end

function run_tests(list)
    println("\n" * ("#"^50))
    for test in list
        println("TEST: $test")
        include(test)
    end
end

println("Julia version: ", VERSION)

test_suites = [
    ("Moving window", ["movingwindow.jl"]),
    ("Machine learning utils", ["machine_learning_utils.jl"]),
]

@testset "SoleBase.jl" begin
    for ts in eachindex(test_suites)
        name = test_suites[ts][1]
        list = test_suites[ts][2]
        let
            @testset "$name" begin
                run_tests(list)
            end
        end
    end
    println()
end
