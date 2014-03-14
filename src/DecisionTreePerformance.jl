module DecisionTreePerformance

export Leaf, Inner, Forest, evaluate, CompiledForest, FlatForest,
       random_forest, random_feature_vector, construct_evaluators

include("common.jl")
include("flattened.jl")
include("compiled.jl")
include("random.jl")

end
