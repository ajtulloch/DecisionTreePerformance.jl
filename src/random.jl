function random_tree(num_features, depth)
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
random_feature_vectors(num_examples, num_features) = map(_ -> random_feature_vector(num_features), 1:num_examples)

function random_forest(num_trees, num_features, depth)
    return Forest([random_tree(num_features, depth) for _ in 1:num_trees])
end

