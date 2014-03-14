immutable Leaf
    value::Float64
end

immutable Inner
    feature::Int64
    splitValue::Float64
    left::Union(Inner, Leaf)
    right::Union(Inner, Leaf)
end

immutable Forest
    trees::Vector{Inner}
end

evaluate(l::Leaf, features::Vector{Float64}) = l.value

function evaluate(n::Inner, features::Vector{Float64})
    return features[n.feature] < n.splitValue ? evaluate(n.left, features) : evaluate(n.right, features)
end

function evaluate(f::Forest, features::Vector{Float64})
    result = 0.0
    for tree in f.trees
        result += evaluate(tree, features)
    end
    return result
end
