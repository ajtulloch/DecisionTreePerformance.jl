using DecisionTreePerformance
using Base.Test

num_trees = 5
num_features = 5
depth = 5

f = random_forest(num_trees, num_features, depth)

evaluators = (forest) -> [forest,
                          FlatForest(forest),
                          CompiledForest(forest)]


function assert_all_eq(elements)
    head = elements[1]
    for el in elements
        @test head == el
    end
end

for i in 1:10
    fv = random_feature_vector(num_features)
    println(fv)
    evaluations = map(x -> evaluate(x, fv), evaluators(f))
    println(evaluations)
    assert_all_eq(evaluations)
end


