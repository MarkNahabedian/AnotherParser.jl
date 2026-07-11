# An example grammar for arithmetic expressions.

using AnotherParser

Pkg.develop(path=joinpath(@__DIR__, "../BNFExample"))
using BNFExample

delete!(AllGrammars, :LeftRecursiveArithmeticGrammar)

BNFGrammar(:ExampleArithmeticGrammar)

#This grammar has two left-recursive derivations: <expr> and <term> so
#can not driive a top-down parser.

bnf"""
<sum-op> ::= "+" | "-"
<mult-op> ::= "*" | "/"
<expr> ::= <term> | <expr> <sum-op> <term>
<term> ::= <factor> | <term> <mult-op> <factor>
<factor> ::= <paren-expr> | <integer>
<paren-expr> ::= "(" <expr> ")"
<integer> ::= <digit> | <digit> <integer>
<digit> ::= "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
"""LeftRecursiveArithmeticGrammar

check_references(:LeftRecursiveArithmeticGrammar)


delete!(AllGrammars, :ExampleArithmeticGrammar)

# Refactor the above grammar to use iteration rather than left recursion:
bnf"""
<sum-op> ::= "+" | "-"
<mult-op> ::= "*" | "/"
<expr> ::= <term> | <term> <more-exprs>
<more-exprs> ::= <term> | <sum-op> <more-exprs>
<term> ::= <factor> | <factor> <more-terms>
<more-terms> ::=  <factor> | <mult-op> <more-terms>
<factor> ::= <paren-expr> | <integer>
<paren-expr> ::= "(" <expr> ")"
<integer> ::= <digit> | <digit> <integer>
<digit> ::= "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
"""ExampleArithmeticGrammar


AllGrammars[:ExampleArithmeticGrammar]["<sum-op>"].constructor =
    function (context, input::AbstractString, from::Int, to::Int, op)
        Symbol(op)
    end

AllGrammars[:ExampleArithmeticGrammar]["<mult-op>"].constructor =
    # Same as for <sum-op>:
    AllGrammars[:ExampleArithmeticGrammar]["<sum-op>"].constructor

AllGrammars[:ExampleArithmeticGrammar]["<expr>"].constructor =
    # <expr> ::= <term> | <term> <more-exprs>
    # identity_constructor_function
    function (context, input::AbstractString, from::Int, to::Int, elts)
        if elts isa Vector
            return Expr(:call, :+, elts[1], elts[2])
        else
            return elts
        end
    end

AllGrammars[:ExampleArithmeticGrammar]["<more-exprs>"].constructor =
    # <more-exprs> ::= <term> | <sum-op> <more-exprs>
    function (context, input::AbstractString, from::Int, to::Int, elts)
        if elts isa Vector
            op, subexpression = elts
            if op == :-
                if subexpression isa Expr
                    subexpression = Expr(:call, :-, subexpression)
                elseif subexpression isa Number
                    subexpression = - subexpression
                else
                    error("unhandled subexpression $subexpression")
                end
            end
            return subexpression
        else
            return elts
        end
    end
        
AllGrammars[:ExampleArithmeticGrammar]["<term>"].constructor =
    # <term> ::= <factor> | <factor> <more-terms>
    # identity_constructor_function
    function (context, input::AbstractString, from::Int, to::Int, elts)
        if elts isa Vector
            factor, more = elts
            return Expr(:call, :*, factor, more)
        else
            return elts
        end
    end

AllGrammars[:ExampleArithmeticGrammar]["<more-terms>"].constructor = 
    # <more-terms> ::=  <factor> | <mult-op> <more-terms>
    # identity_constructor_function
    function (context, input::AbstractString, from::Int, to::Int, elts)
        if elts isa Vector
            multop, subexpression = elts
            if multop == :/
                subexpression = Expr(:call, :/, 1, subexpression)
            end
            return subexpression
        else
            return elts
        end
    end

# <factor> uses the identity constructor.

AllGrammars[:ExampleArithmeticGrammar]["<paren-expr>"].constructor =
    function (context, input::AbstractString, from::Int, to::Int, elts)
        elts[2]
    end

AllGrammars[:ExampleArithmeticGrammar]["<integer>"].constructor =
    function (context, input::AbstractString, from::Int, to::Int, digit)
        parse(Int, SubString(input, from, to))
    end

# <digit uses the identity constructor.


check_references(:ExampleArithmeticGrammar)

