```@meta
CurrentModule = AnotherParser
```

# AnotherParser

Documentation for [AnotherParser](https://github.com/MarkNahabedian/AnotherParser.jl).

AnotherParser allows one to implement a recursive descent parser given
a hierarchical grammar expressed as
[BNF](https://en.wikipedia.org/wiki/Backus%E2%80%93Naur_form).

Neither ISO EBNF nor W3C EBNF are currently supported.


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
parse
recognize1
recognize
```


## Utility Functions

```@docs
show_grammar
check_references
pretty
is_left_recursive
walk_nodes
deep_flatten
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

Various functions are provided to serve as constructors.


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

* the start index into that input string of the portion currently
  recognized;

* the index of the last character to have been matched (so that a
  constructtor could just call `SubString`);

* the subordinate fragments (values) that were just parsed.

For convenience, some constructor functions are already provided:

```@docs
AnotherParser.identity_constructor_function
AnotherParser.substring_constructor_function
AnotherParser.value_is_from_index
AnotherParser.value_is_to_index
AnotherParser.value_is
AnotherParser.flattening_constructor_function
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


Additional examples are available in the `./examples` directory.  This
includes a grammar for parsing SemVer semantic version number format,
a grammar for BNF as specified on the [`Wikipedia BNF
page`](https://en.wikipedia.org/wiki/Backus%E2%80%93Naur_form), and
the full W3C XML grammar.


### BNF Grammar EXample

There are two grammars for parsing BNF syntax itself: a hand coded
grammar (`:BootstrapBNFGrammar`) and one that is built dorectly from
the BNF definition of BNF syntax (`:BNF) as I found it on Wikipedia.
The forner is used to bootstrap the latter.  There is some machinery
to orchestrate that.  I won't decribe it here.  I hope the
implementation is clear enough.

```
Pkg.develop(path="./examples/BNFExample")
using BNFExample
```


## Prepackages Examples

Several larger examples are also provided.  To load them all:

```
include("./examples/load_all.jl")
```


### Arithmetic Example

The arithmetic example rovides a minimal grammar for arithmetic
expressions.  It is expressed as a BNF grammar.

```
include("examples/Arithmetic/arithmetic.jl")

recognize(BNFRef(:ExampleArithmeticGrammar, "<expr>"), "2+3*5")
(true, :(2 + 3 * 5), 6)
```


### XML Grammar

This grammar parses XML text into a concrete syntax tree.

```
Pkg.develop(path="./examples/XMLExample")
using XMLExample

# Running the unit tests for XMLExample will fetch these test files:
xml = read("./examples/XMLExample/test/w3c_tests/xmlconf/xmltest/valid/sa/001.xml", String)
recognize(BNFRef(:XML, "document"), xml)
# Result was reindented for readability:
(true,
 CSTDocument(
     CSTProlog(CSTXMLDecl[],
               Any[],
               Any[
                   Any[
                       CSTDocTypeDecl(
                           CSTWhitespace(" ", false),
                           CSTName("doc", nothing),
                           Any[],
                           Any[
                               CSTWhitespace(" ", false)],
                           Any[CSTWhitespace("\r\n", false),
                               CSTElementDecl(
                                   CSTWhitespace(" ", false),
                                   CSTName("doc", nothing),
                                   CSTWhitespace(" ", false),
                                   "(#PCDATA)",
                                   CSTWhitespace("", false)),
                               CSTWhitespace("\r\n", false)],
                           CSTWhitespace("", false)),
                       Any[CSTWhitespace("\r\n", true)]]]),
     CSTElement(
         CSTName("doc", nothing),
         CSTAttribute[],
         CSTWhitespace[],
         Union{CSTNode,
               CSTAttValueFragment}[],
         CSTWhitespace[], false),
     Any[CSTWhitespace("\r\n", true)]),
 61)
```


## Utilities

```@docs
root_productions
```


## Debugging

```@docs
debug_parsing
DEBUG_BNFNODES
AnotherParser.should_enable_debug_logging_for
```


## Defining New Subtypes of BNFNode

When defining new subtypes of BNFNode, use the [`@bnfnode`](@ref) macro:

```
@bnfnode struct MyNodeType <: BNFNode
    ...
end
```

This macro adds the `uid` and `source` fields, which are common to
all noed types, and massages any internal constructor functions
accordingly.

Your new node type must also support the following methods:
[`pretty`](@ref), [`recognize`](@ref), ans [`path_to_node`](@ref).

If your type refers to another node type, it might also need to
implement [`is_left_recursive`](@ref), [`walk_nodes`](@ref), and
[`check_references`](2ref).


## Index

```@index
```

