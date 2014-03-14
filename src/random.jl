function random_tree(num_features::Int64, depth::Int64)
    if depth == 0
        return Leaf(rand())
    else
        return Inner(rand(1:num_features),
                     rand(),
                     random_tree(num_features, depth - 1),
                     random_tree(num_features, depth -1))
    end
end

random_feature_vector(num_features::Int64) = rand(num_features)
random_feature_vectors(num_examples::Int64, num_features::Int64) =
    map(_ -> random_feature_vector(num_features), 1:num_examples)

random_forest(num_trees::Int64, num_features::Int64, depth::Int64) =
    Forest([random_tree(num_features, depth) for _ in 1:num_trees])

construct_evaluators(f::Forest) =
    [("Naive", f),
     ("Flattened", FlatForest(f)),
     ("Compiled", CompiledForest(f))]
