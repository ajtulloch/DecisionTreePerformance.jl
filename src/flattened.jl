const LEAF_FEATURE = -1::Int64

immutable FlatNode
    feature::Int64
    value::Float64
    leftChild::Int64
end

immutable FlatTree
    nodes::Vector{FlatNode}

    function FlatTree(t::Union(Inner, Leaf))
        nodes = [FlatNode(0, 0, 0)]
        function recur(l::Leaf, current_index::Int64)
            nodes[current_index] = FlatNode(LEAF_FEATURE, l.value, 0)
        end

        function recur(i::Inner, current_index::Int64)
            left_child = length(nodes) + 1
            push!(nodes, FlatNode(0, 0, 0), FlatNode(0, 0, 0))
            nodes[current_index] = FlatNode(i.feature, i.splitValue, left_child)
            recur(i.left, left_child)
            recur(i.right, left_child + 1)
        end
        recur(t, 1)
        return new(nodes)
    end
end

function evaluate(t::FlatTree, features::Vector{Float64})
    current = 1
    while true
        n = t.nodes[current]
        if n.feature == LEAF_FEATURE
            return n.value
        end
        current = features[n.feature] < n.value ? n.leftChild : n.leftChild + 1
    end
end

immutable FlatForest
    trees::Vector{FlatTree}

    function FlatForest(f::Forest)
        return new([FlatTree(t) for t in f.trees])
    end
end

function evaluate(f::FlatForest, features::Vector{Float64})
    sum = 0.0
    for t in f.trees
        sum += evaluate(t, features)
    end
    return sum
end
