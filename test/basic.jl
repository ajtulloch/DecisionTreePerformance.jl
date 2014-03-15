using DecisionTreePerformance
using Base.Test

function assert_all_eq(elements)
    head = elements[1]
    for el in elements
        @test head == el
    end
end

function check_all_equal(features::Vector{Float64}, evaluators::Any)
    map(p -> evaluate(p[2], features), evaluators) |> assert_all_eq
end

function test_equal_evaluations(num_trees, num_features, depth, iterations)

    evaluators = random_forest(num_trees, num_features, depth) |> construct_evaluators

    # QuickCheck style test
    for i in 1:iterations
        fv = random_feature_vector(num_features)
        check_all_equal(fv, evaluators)
    end
end

function bench_evaluation(feature_vector, evaluator, iterations)
    @profile begin
        for i in 1:iterations
            evaluate(evaluator, feature_vector)
        end
    end
end    

test_equal_evaluations(5, 5, 2, 10)
