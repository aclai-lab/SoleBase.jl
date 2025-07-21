@testset "Machine Learning Utils Tests" begin
    
    @testset "Type Definitions" begin
        @test SoleBase.XGLabel == Tuple{Union{AbstractString, Integer, CategoricalValue}, Real}
        @test SoleBase.CLabel == Union{AbstractString, Symbol, CategoricalValue}
        @test SoleBase.RLabel == Real
        @test SoleBase.Label == Union{SoleBase.CLabel, SoleBase.RLabel}
    end
    
    @testset "get_categorical_form" begin
        # Test with string labels
        Y_str = ["cat", "dog", "cat", "bird", "dog"]
        class_names, _Y = SoleBase.get_categorical_form(Y_str)
        @test length(class_names) == 3
        @test all(x -> x in class_names, unique(Y_str))
        @test length(_Y) == length(Y_str)
        @test all(x -> x isa Integer, _Y)
        
        # Test with integer labels
        Y_int = [1, 2, 1, 3, 2]
        class_names_int, _Y_int = SoleBase.get_categorical_form(Y_int)
        @test length(class_names_int) == 3
        @test length(_Y_int) == length(Y_int)
    end
    
    @testset "bestguess - Classification" begin
        # Test majority vote
        labels = ["a", "b", "a", "a", "c"]
        @test SoleBase.bestguess(labels) == "a"
        
        # Test with weights
        labels = ["a", "b", "b"]
        weights = [1.0, 0.5, 0.4]
        @test SoleBase.bestguess(labels, weights) == "a"
        
        # Test empty vector
        @test SoleBase.bestguess(String[]) === nothing
        
        # Test with categorical values
        cat_labels = categorical(["x", "y", "x", "x"])
        @test SoleBase.bestguess(cat_labels) isa CategoricalValue{String, UInt32}
        @test SoleBase.bestguess(cat_labels) == "x"

        # Test that parity warning is shown when not suppressed
        parity_labels = ["a", "b"]
        @test_logs (:warn, r"Parity encountered in bestguess!") SoleBase.bestguess(parity_labels, suppress_parity_warning=false)

        # Test parity warning suppression
        @test_nowarn SoleBase.bestguess(parity_labels, suppress_parity_warning=true)
    end
    
    @testset "bestguess - Regression" begin
        # Test mean calculation
        reg_labels = [1.0, 2.0, 3.0, 4.0]
        @test SoleBase.bestguess(reg_labels) == 2.5
        
        # Test weighted mean
        reg_labels = [1.0, 2.0, 3.0]
        weights = [1.0, 2.0, 1.0]
        expected = (1.0*1.0 + 2.0*2.0 + 3.0*1.0) / (1.0 + 2.0 + 1.0)
        @test SoleBase.bestguess(reg_labels, weights) == expected
        
        # Test empty vector
        @test SoleBase.bestguess(Float64[]) === nothing
    end
    
    @testset "bestguess - XGLabel" begin
        # Test XGLabel bestguess
        xg_labels = [("class1", 0.8), ("class2", 0.3), ("class1", 0.9)]
        classlabels = ["class1", "class2"]
        result = SoleBase.bestguess(xg_labels, classlabels)
        @test result in classlabels
        
        # Test with return_sum
        result_with_sum = SoleBase.bestguess(xg_labels, classlabels, return_sum=true)
        @test isa(result_with_sum, Tuple)
        @test length(result_with_sum) == 2
        
        # Test empty XGLabel vector
        @test SoleBase.bestguess(Tuple{String, Float64}[], ["class1"]) === nothing
    end
    
    @testset "default_weights" begin
        # Test with integer input
        n = 5
        weights = SoleBase.default_weights(n)
        @test length(weights) == n
        @test all(x -> x == 1, weights)
        @test isa(weights, Ones{Int64})
        
        # Test with vector input
        Y = [1, 2, 3, 4]
        weights = SoleBase.default_weights(Y)
        @test length(weights) == length(Y)
    end
    
    @testset "balanced_weights" begin
        # Test balanced case
        balanced_Y = ["a", "b", "a", "b"]
        weights = SoleBase.balanced_weights(balanced_Y)
        @test isa(weights, Ones{Int64})
        
        # Test imbalanced case
        imbalanced_Y = ["a", "a", "a", "b"]
        weights = SoleBase.balanced_weights(imbalanced_Y)
        @test length(weights) == length(imbalanced_Y)
        @test sum(weights) ≈ 1.0
        @test weights[4] > weights[1]  # minority class should have higher weight
        
        # Test with categorical
        cat_Y = categorical(["x", "x", "y"])
        weights = SoleBase.balanced_weights(cat_Y)
        @test length(weights) == length(cat_Y)
    end
    
    @testset "slice_weights" begin
        # Test with Ones
        ones_weights = Ones{Int64}(10)
        inds = [1, 3, 5]
        sliced = SoleBase.slice_weights(ones_weights, inds)
        @test isa(sliced, Ones{Int64})
        @test length(sliced) == length(inds)
        
        # Test with regular array
        reg_weights = [0.1, 0.2, 0.3, 0.4, 0.5]
        inds = [2, 4]
        sliced = SoleBase.slice_weights(reg_weights, inds)
        @test sliced == [0.2, 0.4]
        
        # Test single index with Ones
        @test SoleBase.slice_weights(ones_weights, 3) == 1
        
        # Test single index with regular array
        @test SoleBase.slice_weights(reg_weights, 3) == 0.3
    end
end