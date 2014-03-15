const EVAL_FUNCTION_NAME = "evaluate"

function evaluate(f::FlatForest, features::Vector{Float64})
    result = 0.0
    for tree in f.trees
        result += evaluate(tree, features)
    end
    return result
end

type CompiledForest <: Evaluator
    handle::Ptr{Void}
    func::Ptr{Void}

    function CompiledForest(f::Forest)
        function load_shared_object(path::String)
            h = dlopen(path, RTLD_LAZY | RTLD_LOCAL)
            @assert h != C_NULL
            p = dlsym(h, EVAL_FUNCTION_NAME)
            @assert p != C_NULL
            result = new(h, p)
            finalizer(result, r -> dlclose(r.handle))
            return result
        end

        function write_code_to_file(f::Forest)
            tempdir = mktempdir()
            cpp_file = joinpath(tempdir, "tree.cpp")
            stream = open(cpp_file, "w")
            buf = IOBuffer()
            write(stream, "extern \"C\" {\n")
            code_gen(f, stream)
            write(stream, "}\n")
            flush(stream)
            return cpp_file
        end

        function compile_to_shared_object(cpp_file::String)
            tempdir = mktempdir()
            object_file = joinpath(tempdir, "tree.o")
            shared_object_file = joinpath(tempdir, "tree.so")
            run(`clang $cpp_file -c -O3 -o $object_file`)
            run(`clang -shared $object_file -dynamiclib -O3 -o $shared_object_file`)
            return shared_object_file
        end
        
        return f |>
        write_code_to_file |>
        compile_to_shared_object |>
        load_shared_object
    end
end

function evaluate(c::CompiledForest, features::Vector{Float64})
    return ccall(c.func, Float64, (Ptr{Float64},), features)
end

function code_gen(f::Forest, io::IO)
    for i = 1:length(f.trees)
        write(io, "double evaluate_$i(const double* f) {\n")
        code_gen(f.trees[i], io)
        write(io, "}\n")
    end

    write(io, "double $EVAL_FUNCTION_NAME(const double* f) {\n")
    write(io, "double result = 0.0;\n")
    for i = 1:length(f.trees)
        write(io, "result += evaluate_$i(f);\n")
    end
    write(io, "return result;\n")
    write(io, "}\n")
end

function code_gen(t::Leaf, io::IO)
    value = t.value
    write(io, "return $value;\n")
end

function code_gen(i::Inner, io::IO)
    split_value = i.splitValue
    # Switch to C-style array indexing
    feature = i.feature - 1
    write(io, "if (f[$feature] < $split_value) {\n")
    code_gen(i.left, io)
    write(io, "} else {\n")
    code_gen(i.right, io)
    write(io, "}\n")
end
