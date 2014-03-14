using DecisionTreePerformance
using Base.Test

function assert_all_eq(elements)
    head = elements[1]
    for el in elements
        @test head == el
    end
end

function check_all_equal(features::Vector{Float64}, evaluators::Array{(ASCIIString,Any),1})
    evaluations = map(p -> evaluate(p[2], features), evaluators)
    assert_all_eq(evaluations)    
end

function test_equal_evaluations()
    num_trees = 5
    num_features = 5
    depth = 2
    num_feature_vectors = 1

    evaluators = random_forest(num_trees, num_features, depth) |> construct_evaluators

    # QuickCheck style test
    for i in 1:num_feature_vectors
        fv = random_feature_vector(num_features)
        check_all_equal(fv, evaluators)
    end
end

test_equal_evaluations()

