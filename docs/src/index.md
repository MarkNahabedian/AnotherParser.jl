```@meta
CurrentModule = AnotherParser
```

# AnotherParser

Documentation for [AnotherParser](https://github.com/MarkNahabedian/AnotherParser.jl).

AnotherParser allows one to implement a recursive descent parser given
a hierarchical grammar expressed as
[BNF](https://en.wikipedia.org/wiki/Backus%E2%80%93Naur_form).

ISO EBNF is not yet supported.


## Grammars

A grammar is represented by a [`BNFGrammar`](@ref) struct.
[`AllGrammars`](@ref) is a catalog of all of the defined grammars.

```@docs
BNFGrammar
AllGrammars
```

Each `BNFGrammar` includes a collection of [`DerivationRule`]@ref)s.
Each `DerivationRule` has a "left hand side' that is a tree of
[`BNFNode`](@ref)s.

A `DerivationRule` can be referred to by name via [`BNFRef`](@ref),
and thus shared among different parts of the grammar and between
grammars.


```@autodocs
Modules = [ AnotherParser ]
Order = [ :type ]
Filter = t -> t <: AnotherParser.BNFNode
```

Each BNFNode implements the `recognize` generic function, which
performs the actual parsing:

```@docs
recognize
```


## Utility Functions

```@docs
@bnf_str
show_grammar
check_references
pretty
is_left_recursive
walk_nodes
```

## Construction Utilities

A grammar has little use recognizing its input if it does not also
build a useful data structure from the abstract syntax tree.

All BNFNode types should describe what their `recognize` methods
return as a value.  For `CharacterLiteral` and `StringLiteral` it is
just the matched character or string.  For `RegexNode` it is the
regular expression's match object.  For `Alternatives` it is the value
of whatever subexpression matched.  For `Sequence` it is a `Vector` of
the matched values of the subexpressions.

The `Constructor` BNFNode type can be used to wrap another BNFNode
expression to massage the value that it returns.

Also, `DerivationRule` can be assigned a `constructor` property.

Various functions are provided to serve as constructors:


### Constructor Functions

The application usually wants to construct some form of data structure
during the parsing operation, not just a simple tree representing the
result of the parse.  Both [`Constructor`](@ref) and
[`DerivationRule`](@ref) allow for a constructor function to be called
on the currently recognized input and return instead an object that is
meaningful to the application.  Each constructor function takes as
arguments:

* a context object that is meaningless to everything but the
  constructor function;

* the entire input string;

* the start index into that input string string of the portion
  currently recognized;

* the index of the first character in the input after the recognized
  item;

* the subordinate fragments that were just parsed.

```@docs
AnotherParser.identity_constructor_function
AnotherParser.substring_constructor_function
```


## Example

```@example
using AnotherParser

# A grammar is named by a symbol
BNFGrammar(:example)

# "text" can be one word, or a sequence of words separated by spaces:
# Note the two uses of Constructor so that the result will be a
# single, flat Tuple of words:
DerivationRule(
    :example,
    "text",
    Alternatives(
        Constructor(BNFRef(:example, "word"),
                    (context, input::AbstractString, from::Int, to::Int, x) -> (x,)),
        Constructor(
            Sequence(BNFRef(:example, "word"),
                     BNFRef(:example, "space"),
                     BNFRef(:example, "text")),
            (context, input::AbstractString, from::Int, to::Int, x) -> (x[1], x[3]...))))

# Collapse the successive characters of a word into a string:
DerivationRule(
    :example,
    "word",
    BNFRef(:example, "word1")).constructor = substring_constructor_function

# "word1" is a sequence of letters:
DerivationRule(
    :example,
    "word1",
    Alternatives(BNFRef(:example, "letter"),
                 Sequence(BNFRef(:example, "letter"),
                          BNFRef(:example, "word1"))))

# Lowercase letters
DerivationRule(
    :example,
    "letter",
    Alternatives([CharacterLiteral(c) for c in 'a':'z']...))

# Whitespace:
DerivationRule(
    :example,
    "space",
    Alternatives(
        CharacterLiteral(' '),
        Sequence(
            CharacterLiteral(' '),
            BNFRef(:example, "space"))))

# recognize will return a tuple of "word"s and
# the next index of the input string
recognize(AllGrammars[:example]["text"],
          "this  is    a test")
```

There is much room for simplification and syntactic sugar.

Until I write more documentation, see the example grammars in the
`examples` directory.


Additional examples are available in the `./examples` directory.  This
includes an a grammar for parsing SemVer semantic version number
format and a grammar for BNF as specified on the 
[`Wikipedia BNF page`](https://en.wikipedia.org/wiki/Backus%E2%80%93Naur_form).


## Debugging

```@docs
debug_parsing
DEBUG_BNFNODES
```

## The Grammar for BNF

The grammar for BNF itself is specified as BNF.  The file
`./examples/BNF/bnf.jl` implements two BNF grammars.
`:BootstrapBNFGrammar` is a grammar that is hand coded using
[`BNFNode`](@ref) types.  `:BNF` is automatically built by the
`:BootstrapBNFGrammar` grammar.

There is some machinery to orchestrate that.  I won't decribe it here.
I hope the implementation is clear enough.


## Index

```@index
```

