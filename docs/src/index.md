# AnotherParser.jl

AnotherParser allows one to implement a parser given a
hierarchical grammar expressed as
[BNF](https://en.wikipedia.org/wiki/Backus%E2%80%93Naur_form).

**AnotherParser does not yet directly support a BNF grammar expressed
  in BNF syntax.**


## Grammars

A grammar is implemented as a tree of structs that are subtypes of
`BNFNode`.

```@docs
BNFGrammar
```

The tree can be broken up into named `DerivationRule`s which can be
referred to by name via `BNFRef`, and thus shared among different parts
of the grammar..
```@docs
DerivationRule
```


```@autodocs
Modules = [ AnotherParser ]
Order = [ :type ]
Filter = t -> t <: AnotherParser.BNFNode
```

Each BNFNode implements the `recognize` generic function which
performs the actual parsing:

```@docs
AnotherParser.recognize(::BNFNode, input::String; index, finish)
```

```@docs
AnotherParser.AllGrammars
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
                    x -> (x,)),
        Constructor(
            Sequence(BNFRef(:example, "word"),
                     BNFRef(:example, "space"),
                     BNFRef(:example, "text")),
            x -> (x[1], x[3]...))))

# Collapse the successive characters of a word into a string:
DerivationRule(
    :example,
    "word",
    StringCollector(BNFRef(:example, "word1")))

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

Until I write more documentation, see test/SemVerBNF.jl for an example
that implements the SemVer version number format.
