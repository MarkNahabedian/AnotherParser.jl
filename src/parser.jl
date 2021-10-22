
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
# end index, pip it from the Parser's stack, and add it to the
# contents of the new top of stack.

struct Parser
    input::String
    input_index::Int
    stack::Stack{NonTerminalInstance}

    function Parser(target::BNFNode, input::String; start=0)
        stack = Stack()
        push(stack, NonTerminalInstance(Target, 0))
        new(input, start, stack)
    end
end
