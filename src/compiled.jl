const EVAL_FUNCTION_NAME = "evaluate"::String

function evaluate(f::FlatForest, features::Vector{Float64})
    result = 0.0
    for tree in f.trees
        result += evaluate(tree, features)
    end
    return result
end

type CompiledForest
    handle::Ptr{Void}
    func::Ptr{Void}


    function CompiledForest(f::Forest)
        function from_path(path::String)
            h = dlopen(path, RTLD_LAZY | RTLD_LOCAL)
            @assert h != C_NULL
            p = dlsym(h, EVAL_FUNCTION_NAME)
            @assert p != C_NULL
            result = new(h, p)
            finalizer(result, r -> dlclose(r.handle))
            return result
        end

        function code_str(f)
            buf = IOBuffer()
            write(buf, "extern \"C\" {\n")
            code_gen(f, buf)
            write(buf, "}\n")
            return takebuf_string(buf)
        end

        generated_code = code_str(f)
        tempdir = mktempdir()
        cpp_file = joinpath(tempdir, "tree.cpp")
        cpp_stream = open(cpp_file, "w")
        write(cpp_stream, generated_code)
        flush(cpp_stream)

        object_file = joinpath(tempdir, "tree.o")
        shared_object_file = joinpath(tempdir, "tree.so")
        run(`clang $cpp_file -c -O3 -o $object_file`)
        run(`clang -shared $object_file -dynamiclib -O3 -o $shared_object_file`)
        return from_path(shared_object_file)
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

