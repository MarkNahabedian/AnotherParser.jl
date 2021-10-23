
using DataStructures

mutable struct NonTerminalInstance
    node::BNFNode
    start_index::Int
    end_index::Union{Nothing, Int}
    contents::Vector

    function NonTerminalInstance(node, start=0)
        new(node, start, nothing, [])
    end
end

# Reduce: When we reach the end of a NonTerminalInstance we set it's
# end index, pop it from the Parser's stack, and add it to the
# contents of the new top of stack.

struct Parser
    input::String
    input_index::Int
    stack::Stack{NonTerminalInstance}

    function Parser(input::String; start=0)
        new(input, start, Stack())
    end
end

function start(parser::Parser, target::BNFNode)
    push(stack, NonTerminalInstance(target, parser.input_index))
    parser
end

function finish(parser::Parser, at::Int)
    nt = pop(parser.stack)
    nt.end_index = at
    push!(first(parser.stack)contents, nt)
    # *** How do we validate whether nt.node is a v alid consitituent
    # *** of first(parser.stack).node?
    parser
end

function parse(parser::Parser)
end

