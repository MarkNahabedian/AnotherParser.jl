var documenterSearchIndex = {"docs":
[{"location":"#AnotherParser.jl","page":"Home","title":"AnotherParser.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"AnotherParser allows one to implement a parser given a grammar expressed as BNF.","category":"page"},{"location":"","page":"Home","title":"Home","text":"AnotherParser does not yet directly support a BNF grammar expressed   in BNF syntax.","category":"page"},{"location":"#Grammars","page":"Home","title":"Grammars","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"A grammar is implemented as a tree of structs that are subtypes of BNFNode.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [ AnotherParser ]\nOrder = [ :type ]\nFilter = t -> t <: AnotherParser.BNFNode","category":"page"},{"location":"#AnotherParser.Alternatives","page":"Home","title":"AnotherParser.Alternatives","text":"Alternatives(nodes...)\n\nMatches any one element of nodes.\n\n\n\n\n\n","category":"type"},{"location":"#AnotherParser.BNFNode","page":"Home","title":"AnotherParser.BNFNode","text":"BNFNode\n\nAbstract supertype for all structs that we use to implement a grammar.\n\n\n\n\n\n","category":"type"},{"location":"#AnotherParser.BNFRef","page":"Home","title":"AnotherParser.BNFRef","text":"BNFRef(grammar, name) delegates to the \"left hand side\" of the DerivationRule named name in grammar.\n\n\n\n\n\n","category":"type"},{"location":"#AnotherParser.CharacterLiteral","page":"Home","title":"AnotherParser.CharacterLiteral","text":"CharacterLiteral(c)\n\nMatches the single character c.\n\n\n\n\n\n","category":"type"},{"location":"#AnotherParser.Constructor","page":"Home","title":"AnotherParser.Constructor","text":"Constructor(node, constructor_function)\n\nApply constructor_function to rhe result of recognizing node and return that as the result.\n\n\n\n\n\n","category":"type"},{"location":"#AnotherParser.DerivationRule","page":"Home","title":"AnotherParser.DerivationRule","text":"DerivationRule(grammar, rule_name, expression)\n\nImplements a single production named name in the specified grammar. One can include expression in other expressions using BNFRef(grammar, rule_name).\n\n\n\n\n\n","category":"type"},{"location":"#AnotherParser.Sequence","page":"Home","title":"AnotherParser.Sequence","text":"Sequence(nodes...)\n\nSuccessively match each of nodes in turn.\n\n\n\n\n\n","category":"type"},{"location":"#AnotherParser.StringCollector","page":"Home","title":"AnotherParser.StringCollector","text":"StringCollector StringCollector returns the entire substrring of the input that was recognized by its subexpression.\n\n\n\n\n\n","category":"type"},{"location":"","page":"Home","title":"Home","text":"Each BNFNode implements the recognize generic function which performs the actual parsing:","category":"page"},{"location":"","page":"Home","title":"Home","text":"AnotherParser.recognize(::BNFNode, input::String; index, finish)","category":"page"},{"location":"#AnotherParser.recognize-Tuple{BNFNode, String}","page":"Home","title":"AnotherParser.recognize","text":"recognize(::BNFNode, input::String; index, finish)\n\nAttempt to parse input as the specified BNFNode. Return two values: the  value represented by the matched input, and the next index into input. If the returned index is equal to the initial index then the input did not matchthe BNFNode.\n\n\n\n\n\n","category":"method"},{"location":"","page":"Home","title":"Home","text":"AnotherParser.AllGrammars","category":"page"},{"location":"#AnotherParser.AllGrammars","page":"Home","title":"AnotherParser.AllGrammars","text":"A Dict of all defined grammars.\n\n\n\n\n\n","category":"constant"},{"location":"#Example","page":"Home","title":"Example","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"using AnotherParser\n\n# A grammar is named by a symbol\nBNFGrammar(:example)\n\n# \"text\" can be one word, or a sequence of words separated by spaces:\n# Note the two uses of Constructor so that the result will be a Tuple of\n# words:\nDerivationRule(\n    :example,\n    \"text\",\n    Alternatives(\n        Constructor(BNFRef(:example, \"word\"),\n                    x -> (x,)),\n        Constructor(\n            Sequence(BNFRef(:example, \"word\"),\n                     BNFRef(:example, \"space\"),\n                     BNFRef(:example, \"text\")),\n            x -> (x[1], x[3]...))))\n\n# Collapse the successive characters of a word into a string:\nDerivationRule(\n    :example,\n    \"word\",\n    StringCollector(BNFRef(:example, \"word1\")))\n\n# \"word1\" is a sequence of letters:\nDerivationRule(\n    :example,\n    \"word1\",\n    Alternatives(BNFRef(:example, \"letter\"),\n                 Sequence(BNFRef(:example, \"letter\"),\n                          BNFRef(:example, \"word1\"))))\n\n# Lowercase letters\nDerivationRule(\n    :example,\n    \"letter\",\n    Alternatives([CharacterLiteral(c) for c in 'a':'z']...))\n\n# Whitespace:\nDerivationRule(\n    :example,\n    \"space\",\n    Alternatives(\n        CharacterLiteral(' '),\n        Sequence(\n            CharacterLiteral(' '),\n            BNFRef(:example, \"space\"))))\n\n# recognize will return a tuple of \"word\"s and\n# the next index of the input string\nrecognize(AllGrammars[:example][\"text\"],\n          \"this  is    a test\")","category":"page"},{"location":"","page":"Home","title":"Home","text":"There is mush room for simplification and syntactic sugar.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Until I write more documentation, see test/SemVerBNF.jl for an example that implements the SemVer version number format.","category":"page"}]
}
