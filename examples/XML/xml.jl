# This is not the full BNF for XML.  It is provided here as an example
# of how to use AnotherParser.

BNFGrammar(:XML)

# [1]  https://www.w3.org/TR/xml/#NT-document
# document	   ::=   	prolog element Misc*
DerivationRule(:XML, "document",
               Sequence(BNFRef(:XML, "prolog"),
                        BNFRef(:XML, "element"),
                        Repeat(BNFRef(:XML, "Misc"))))

# [2]  https://www.w3.org/TR/xml/#NT-Char
# Char	   ::=   	#x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF]

function is_xml_char(c)
    (codepoint(c) == 0x9
     || codepoint(c) == 0xA
     || codepoint(c) == 0xD
     || codepoint(c) in 0x20 : 0xD7FF
     || codepoint(c) in 0xE000 : 0xFFFD
     || codepoint(c) in 0x10000 : 0x10FFFF)
end

DerivationRule(:XML, "Char",
               CharacterSatisfiesPredicate(is_xml_char))

# [3]  https://www.w3.org/TR/xml/#NT-S
# S	   ::=   	(#x20 | #x9 | #xD | #xA)+
DerivationRule(:XML, "S",
               Repeat(Alternatives(
                   CharacterLiteral(Char(0x20)),
                   CharacterLiteral(Char(0x9)),
                   CharacterLiteral(Char(0xD)),
                   CharacterLiteral(Char(0xA)));
                      min=1))

# [4]  https://www.w3.org/TR/xml/#NT-NameStartChar
# NameStartChar ::= ":" | [A-Z] | "_" | [a-z] | [#xC0-#xD6] |
# [#xD8-#xF6] | [#xF8-#x2FF] | [#x370-#x37D] | [#x37F-#x1FFF] |
# [#x200C-#x200D] | [#x2070-#x218F] | [#x2C00-#x2FEF] |
# [#x3001-#xD7FF] | [#xF900-#xFDCF] | [#xFDF0-#xFFFD] |
# [#x10000-#xEFFFF]

function is_xml_name_start_char(c)
    (c == ':'
     || c in 'A':'Z'
     || c == '_'
     || c in 'a':'z'
     || codepoint(c) in 0xC0 : 0xD6
     || codepoint(c) in 0xD8 : 0xF6
     || codepoint(c) in 0xF8 : 0x2FF
     || codepoint(c) in 0x370 : 0x37D
     || codepoint(c) in 0x37F : 0x1FFF
     || codepoint(c) in 0x200C : 0x200D
     || codepoint(c) in 0x2070 : 0x218F
     || codepoint(c) in 0x2C00 : 0x2FEF
     || codepoint(c) in 0x3001 : 0xD7FF
     || codepoint(c) in 0xF900 : 0xFDCF
     || codepoint(c) in 0xFDF0 : 0xFFFD
     || codepoint(c) in 0x10000 : 0xEFFFF)
end

DerivationRule(:XML, "NameStartChar",
               CharacterSatisfiesPredicate(is_xml_name_start_char))

# [4a]  https://www.w3.org/TR/xml/#NT-NameChar
# NameChar   ::=  NameStartChar | "-" | "." | [0-9] | #xB7 | [#x0300-#x036F] | [#x203F-#x2040]

function is_xml_name_char(c)
    (is_xml_name_start_char(c)
     || c == '-'
     || c == '.'
     || c in '0':'9'
     || c == Char(0xB7)
     || codepoint(c) in 0x0300 : 0x036F
     || codepoint(c) in 0x203F : 0x2040)
end

# NameStartChar | "-" | "." | [0-9] | #xB7 | [#x0300-#x036F] | [#x203F-#x2040]
DerivationRule(:XML, "NameChar",
               CharacterSatisfiesPredicate(is_xml_name_char))
                                
# [5]  https://www.w3.org/TR/xml/#NT-Name
# Name	::=  NameStartChar (NameChar)*
DerivationRule(:XML, "Name",
               Sequence(BNFRef(:XML, "NameStartChar"),
                        Repeat(BNFRef(:XML, "NameChar")))
               ).constructor = substring_constructor_function

# [6]  https://www.w3.org/TR/xml/#NT-Names
# Names	 ::=  Name (#x20 Name)*

ignore_leading_separator_constructor_function(context, input::AbstractString,
                                              from::Int, to::Int, value) =
    value[2]

DerivationRule(:XML, "Names",
               Sequence(BNFRef(:XML, "Name"),
                        Repeat(Constructor(Sequence(CharacterLiteral(' '),
                                                    BNFRef(:XML, "Name")),
                                           ignore_leading_separator_constructor_function)))
               ).constructor =
                   function (context, input::AbstractString, from::Int, to::Int, value)
                       [ value[1], value[2]... ]
                   end

# [7]  https://www.w3.org/TR/xml/#NT-Nmtoken
# Nmtoken  ::=  (NameChar)+
DerivationRule(:XML, "Nmtoken", Repeat(BNFRef(:XML, "NameChar"); min=0)
               ).constructor = substring_constructor_function

# [8]  https://www.w3.org/TR/xml/#NT-Nmtokens
DerivationRule(:XML, "Nmtokens",
               Sequence(BNFRef(:XML, "Nmtoken"),
                        Repeat(Constructor(Sequence(CharacterLiteral(' '),
                                                    BNFRef(:XML, "Nmtoken")),
                                           ignore_leading_separator_constructor_function)))
               ).constructor = AllGrammars[:XML]["Names"].constructor

# [9]  https://www.w3.org/TR/xml/#NT-EntityValue
# EntityValue ::= '"' ([^%&"] | PEReference | Reference)* '"' | "'"
# ([^%&'] | PEReference | Reference)* "'"
DerivationRule(:XML, "EntityValue",
               Alternatives(
                   Sequence(CharacterLiteral('"'),
                            Repeat(
                                Alternatives(
                                    RegexNode(r"[^%&\"]"),
                                    BNFRef(:XML, "PEReference"),
                                    BNFRef(:XML, "Reference"))),
                            CharacterLiteral('"')),
                   Sequence(CharacterLiteral('\''),
                            Repeat(
                                Alternatives(
                                    RegexNode(r"[^%&']"),
                                    BNFRef(:XML, "PEReference"),
                                    BNFRef(:XML, "Reference"))),
                            CharacterLiteral('\''))))

# [10]  https://www.w3.org/TR/xml/#NT-AttValue
# AttValue  ::=  '"' ([^<&"] | Reference)* '"' |  "'" ([^<&'] | Reference)* "'"
DerivationRule(:XML, "AttValue",
               Alternatives(
                   Sequence(CharacterLiteral('"'),
                            Repeat(
                                Alternatives(
                                    RegexNode(r"[^<&\"]"),
                                    BNFRef(:XML, "Reference"))),
                            CharacterLiteral('"')),
                   Sequence(CharacterLiteral('\''),
                            Repeat(
                                Alternatives(
                                    RegexNode(r"[^<&']"),
                                    BNFRef(:XML, "Reference"))),
                            CharacterLiteral('\'')))
               ).constructor = function (context, input::AbstractString,
                                         from::Int, to::Int, value)
                   SubString(input, from + 1, to - 1)
               end

# [11]  https://www.w3.org/TR/xml/#NT-SystemLiteral
# SystemLiteral	 ::=  ('"' [^"]* '"') | ("'" [^']* "'")
DerivationRule(:XML, "SystemLiteral",
               Alternatives(
                   RegexNode(r"\"[^\"]*\""),
                   RegexNode(r"'[^']*'")))

# [12]  https://www.w3.org/TR/xml/#NT-PubidLiteral
# PubidLiteral	::=  '"' PubidChar* '"' | "'" (PubidChar - "'")* "'"
DerivationRule(:XML, "PubidLiteral",
               Alternatives(
                   Sequence(CharacterLiteral('"'),
                            Repeat(BNFRef(:XML, "PubidChar")),
                            CharacterLiteral('"')),
                   Sequence(CharacterLiteral('"'),
                            Repeat(BNFRef(:XML, "PubidChar")),
                            CharacterLiteral('"'))))

# [13]  https://www.w3.org/TR/xml/#NT-PubidChar
# PubidChar  ::=  #x20 | #xD | #xA | [a-zA-Z0-9] | [-'()+,./:=?;!*#@$_%]
function is_xml_PubidChar(c)
    (codepoint(c) == 0x20
     || codepoint(c) == 0xD
     || codepoint(c) == 0xA
     || c in 'a' : 'z'
     || c in 'A' : 'Z'
     || c in '0' : '9'
     || c in raw"-'()+,./:=?;!*#@$_%")
end

DerivationRule(:XML, "PubidChar",
               CharacterSatisfiesPredicate(is_xml_PubidChar)
               ).constructor = substring_constructor_function

# [14]  https://www.w3.org/TR/xml/#NT-CharData
# CharData  ::=  [^<&]* - ([^<&]* ']]>' [^<&]*)

DerivationRule(:XML, "CharData",
               Excluding(
                   Sequence(
                       RegexNode(r"[^<&]*"),
                       StringLiteral("]]>"),
                       RegexNode(r"[^<&]*")),
                   RegexNode(r"[^<&]*"))
               ).constructor = substring_constructor_function

# [15]  https://www.w3.org/TR/xml/#NT-Comment
# Comment  ::=  '<!--' ((Char - '-') | ('-' (Char - '-')))* '-->'
DerivationRule(:XML, "Comment",
               Sequence(StringLiteral("<!--"),
                        Constructor(
                            Repeat(
                                Alternatives(
                                    Excluding(CharacterLiteral('-'),
                                              BNFRef(:XML, "Char")),
                                    Sequence(CharacterLiteral('-'),
                                             Excluding(CharacterLiteral('-'),
                                                       BNFRef(:XML, "Char"))))),
                            substring_constructor_function),
                        StringLiteral("-->"))
               ).constructor = function(context, input::AbstractString,
                                        from::Int, to::Int, value)
                   xmlComment(context, value[2])
               end

# [16]  https://www.w3.org/TR/xml/#NT-PI
# PI  ::=  '<?' PITarget (S (Char* - (Char* '?>' Char*)))? '?>'
DerivationRule(:XML, "PI",
               Sequence(StringLiteral("<?"),
                        BNFRef(:XML, "PITarget"),
                        Repeat(
                            Sequence(BNFRef(:XML, "S"),
                                     Excluding(
                                         Sequence(Repeat(BNFRef(:XML, "Char")),
                                                  StringLiteral("?>"),
                                                  Repeat(BNFRef(:XML, "Char"))),
                                         Repeat(BNFRef(:XML, "Char"))));
                            max=1),
                        StringLiteral("?>"))
               )

# [17]  https://www.w3.org/TR/xml/#NT-PITarget
# PITarget  ::=  Name - (('X' | 'x') ('M' | 'm') ('L' | 'l'))
DerivationRule(:XML, "PITarget",
               Excluding(
                   RegexNode(r"[Xx]{Mm][Ll]"),
                   BNFRef(:XML, "Name"))
               )

# [18]  https://www.w3.org/TR/xml/#NT-CDSect
# CDSect  ::=  CDStart CData CDEnd
DerivationRule(:XML, "CDSect",
               Sequence(BNFRef(:XML, "CDStart"),
                        BNFRef(:XML, "CData"),
                        BNFRef(:XML, "CDEnd"))
               )

# [19]  https://www.w3.org/TR/xml/#NT-CDStart
# CDStart  ::=  '<![CDATA['
DerivationRule(:XML, "CDStart",
               StringLiteral("<![CDATA["))


# [20]  https://www.w3.org/TR/xml/#NT-CData
# CData  ::=  (Char* - (Char* ']]>' Char*))
DerivationRule(:XML, "CData",
               Excluding(
                   Sequence(
                       Repeat(BNFRef(:XML, "Char")),
                       StringLiteral("]]>"),
                       Repeat(BNFRef(:XML, "Char"))),
                   Repeat(BNFRef(:XML, "Char")))
               ).constructor = substring_constructor_function

# [21]  https://www.w3.org/TR/xml/#NT-CDEnd
# CDEnd  ::=   	']]>'
DerivationRule(:XML, "CDEnd",
               StringLiteral("]]>"))

# [22]  https://www.w3.org/TR/xml/#NT-prolog
#  prolog  ::=  XMLDecl? Misc* (doctypedecl Misc*)?
DerivationRule(:XML, "prolog",
               Sequence(
                   Repeat(BNFRef(:XML, "XMLDecl"); max=1),
                   Repeat(BNFRef(:XML, "Misc")),
                   Repeat(
                       Sequence(
                           BNFRef(:XML, "doctypedecl"),
                           Repeat(BNFRef(:XML, "Misc")));
                       max=1))
               )

# [23]  https://www.w3.org/TR/xml/#NT-XMLDecl
# XMLDecl  ::=  '<?xml' VersionInfo EncodingDecl? SDDecl? S? '?>'
DerivationRule(:XML, "XMLDecl",
               Sequence(
                   StringLiteral("<?xml"),
                   BNFRef(:XML, "VersionInfo"),
                   Repeat(BNFRef(:XML, "EncodingDecl");
                          max=1),
                   Repeat(BNFRef(:XML, "SDDecl");
                          max=1),
                   Repeat(BNFRef(:XML, "S");
                          max=1),
                   StringLiteral("?>"))
               )

# [24]  https://www.w3.org/TR/xml/#NT-VersionInfo
#  VersionInfo  ::=  S 'version' Eq ("'" VersionNum "'" | '"' VersionNum '"')
DerivationRule(:XML, "VersionInfo",
               Sequence(
                   BNFRef(:XML, "S"),
                   StringLiteral("version"),
                   BNFRef(:XML, "Eq"),
                   Alternatives(
                       Sequence(
                           CharacterLiteral('\''),
                           BNFRef(:XML, "VersionNum"),
                           CharacterLiteral('\'')),
                       Sequence(
                           CharacterLiteral('"'),
                           BNFRef(:XML, "VersionNum"),
                           CharacterLiteral('"'))))
               )

# [25]  https://www.w3.org/TR/xml/#NT-Eq
#  Eq  ::=  S? '=' S?
DerivationRule(:XML, "Eq",
               Sequence(
                   Repeat(BNFRef(:XML, "S"); max=1),
                   CharacterLiteral('='),
                   Repeat(BNFRef(:XML, "S"); max=1))
               )

# [26]  https://www.w3.org/TR/xml/#NT-VersionNum
#  VersionNum  ::=  '1.' [0-9]+
DerivationRule(:XML, "VersionNum",
               Sequence(
                   StringLiteral("1."),
                   RegexNode(r"[0-9]+"))
               ).constructor = substring_constructor_function
               
# [27]  https://www.w3.org/TR/xml/#NT-Misc
#  Misc   ::=   Comment | PI | S
DerivationRule(:XML, "Misc",
               Alternatives(
                   BNFRef(:XML, "Comment"),
                   BNFRef(:XML, "PI"),
                   BNFRef(:XML, "S"))
               )

# [28]  https://www.w3.org/TR/xml/#NT-doctypedecl
# doctypedecl   ::=   '<!DOCTYPE' S Name (S ExternalID)? S? ('[' intSubset ']' S?)? '>'
DerivationRule(:XML, "doctypedecl",
               Sequence(
                   StringLiteral("<!DOCTYPE"),
                   BNFRef(:XML, "S"),
                   BNFRef(:XML, "Name"),
                   Repeat(
                       Sequence(
                           BNFRef(:XML, "S"),
                           BNFRef(:XML, "ExternalID"));
                       max=1),
                   Repeat(BNFRef(:XML, "S"); max=1),
                   Repeat(
                       Sequence(
                           CharacterLiteral('['),
                           BNFRef(:XML, "intSubset"),
                           CharacterLiteral(']'),
                           Repeat(BNFRef(:XML, "S"); max=1));
                       max=1),
                   CharacterLiteral('>'))
               )

# [28a]  https://www.w3.org/TR/xml/#NT-DeclSep
#  DeclSep  ::=  PEReference | S
DerivationRule(:XML, "DeclSep",
               Alternatives(BNFRef(:XML, "PEReference"),
                            BNFRef(:XML, "S"))
               )

# [28b]  https://www.w3.org/TR/xml/#NT-intSubset
#  intSubset  ::=  (markupdecl | DeclSep)*
DerivationRule(:XML, "intSubset",
               Repeat(Alternatives(
                   BNFRef(:XML, "markupdecl"),
                   BNFRef(:XML, "DeclSep")))
               )

# [29]  https://www.w3.org/TR/xml/#NT-markupdecl
#  markupdecl  ::=  elementdecl | AttlistDecl | EntityDecl | NotationDecl | PI | Comment
DerivationRule(:XML, "markupdecl",
               Alternatives(
                   BNFRef(:XML, "elementdecl"),
                   BNFRef(:XML, "AttlistDecl"),
                   BNFRef(:XML, "EntityDecl"),
                   BNFRef(:XML, "NotationDecl"),
                   BNFRef(:XML, "PI"),
                   BNFRef(:XML, "Comment"))
               )

# [30]  https://www.w3.org/TR/xml/#NT-extSubset
#  extSubset  ::=  TextDecl? extSubsetDecl
DerivationRule(:XML, "extSubset",
               Sequence(
                   Repeat(BNFRef(:XML, "TextDecl"); max=1),
                   BNFRef(:XML, "extSubsetDecl"))
               )

# [31]  https://www.w3.org/TR/xml/#NT-extSubsetDecl
#  extSubsetDecl  ::=  ( markupdecl | conditionalSect | DeclSep)*
DerivationRule(:XML, "extSubsetDecl",
               Repeat(Alternatives(
                   BNFRef(:XML, "markupdecl"),
                   BNFRef(:XML, "conditionalSect"),
                   BNFRef(:XML, "DeclSep")))
               )

# [32]  
#  SDDecl  ::=  S 'standalone' Eq (("'" ('yes' | 'no') "'") | ('"' ('yes' | 'no') '"'))
DerivationRule(:XML, "SDDecl",
               Sequence(
                   BNFRef(:XML, "S"),
                   StringLiteral("standalone"),
                   BNFRef(:XML, "Eq"),
                   Alternatives(
                       Sequence(
                           CharacterLiteral('\''),
                           Alternatives(
                               StringLiteral("yes"),
                               StringLiteral("no")),
                           CharacterLiteral('\'')),
                       Sequence(
                           CharacterLiteral('"'),
                           Alternatives(
                               StringLiteral("yes"),
                               StringLiteral("no")),
                           CharacterLiteral('"'))))
               )

# I don't see [33] through [38]

# [39]  https://www.w3.org/TR/xml/#NT-element
#  element  ::=  EmptyElemTag | STag content ETag
DerivationRule(:XML, "element",
               Alternatives(
                   BNFRef(:XML, "EmptyElemTag"),
                   Sequence(
                       BNFRef(:XML, "STag"),
                       BNFRef(:XML, "content"),
                       BNFRef(:XML, "ETag")))
               ).constructor = function(context, input::AbstractString,
                                         from::Int, to::Int, value)
                   if length(value) == 1     # EmptyElemTag
                       return xmlElement(context, value.name, value.attributes, [])
                   end
                   starttag, content, endtag = value
                   @assert starttag.name == endtag.name
                   xmlElement(context, starttag.name, starttag.attributes, content)
               end

# [40]  https://www.w3.org/TR/xml/#NT-STag
#  STag  ::=  '<' Name (S Attribute)* S? '>'
DerivationRule(:XML, "STag",
               Sequence(
                   CharacterLiteral('<'),
                   BNFRef(:XML, "Name"),
                   Repeat(Sequence(
                       BNFRef(:XML, "S"),
                       BNFRef(:XML, "Attribute"))),
                   Repeat(BNFRef(:XML, "S"); max=1),
                   CharacterLiteral('>'))
               ).constructor = function(context, input::AbstractString,
                                        from::Int, to::Int, value)
                   ( name = value[2],
                     attributes = map(s -> s[2], value[3]))
               end

# [41]  https://www.w3.org/TR/xml/#NT-Attribute
#  Attribute  ::=  Name Eq AttValue
DerivationRule(:XML, "Attribute",
               Sequence(
                   BNFRef(:XML, "Name"),
                   BNFRef(:XML, "Eq"),
                   BNFRef(:XML, "AttValue"))
               ).constructor = function(context, input::AbstractString,
                                        from::Int, to::Int, value)
                   Symbol(value[1]) => value[3]
               end

# [42]  https://www.w3.org/TR/xml/#NT-ETag
#  ETag  ::=  '</' Name S? '>'
DerivationRule(:XML, "ETag",
               Sequence(
                   StringLiteral("</"),
                   BNFRef(:XML, "Name"),
                   Repeat(BNFRef(:XML, "S"); max=1),
                   CharacterLiteral('>'))
               ).constructor = function(context, input::AbstractString,
                                        from::Int, to::Int, value)
                   (name = value[2],)
               end


# [43]  https://www.w3.org/TR/xml/#NT-content
#  content   ::=   CharData? ((element | Reference | CDSect | PI | Comment) CharData?)*
    DerivationRule(:XML, "content",
                   Sequence(
                       Repeat(BNFRef(:XML, "CharData"); max=1),
                       Repeat(
                           Sequence(
                               Alternatives(
                                   BNFRef(:XML, "element"),
                                   BNFRef(:XML, "Reference"),
                                   BNFRef(:XML, "CDSect"),
                                   BNFRef(:XML, "PI"),
                                   BNFRef(:XML, "Comment")),
                               Repeat(BNFRef(:XML, "CharData"); max=1))))
                   ).constructor = function (context, input::AbstractString,
                                             from::Int, to::Int, value)
                       content = []
                       if !isempty(value[1])
                           push!(content, value[1][1])
                       end
                       for (a, cd) in value[2]
                           push!(content, a)
                           if !isempty(cd)
                               push!(content, cd[1])
                           end
                       end
                       content
                   end

# [44]  https://www.w3.org/TR/xml/#NT-EmptyElemTag
#  EmptyElemTag  ::=  '<' Name (S Attribute)* S? '/>'
DerivationRule(:XML, "EmptyElemTag",
               Sequence(
                   CharacterLiteral('<'),
                   BNFRef(:XML, "Name"),
                   Repeat(
                       Sequence(
                           BNFRef(:XML, "S"),
                           BNFRef(:XML, "Attribute"))),
                   Repeat(BNFRef(:XML, "S"); max=1),
                   StringLiteral("/>"))
               ).constructor = function(context, input::AbstractString,
                                        from::Int, to::Int, value)
                   (name = value[2],
                    ttributes = map(s -> s[2], value[3]))
               end

# [45]  https://www.w3.org/TR/xml/#NT-elementdecl
#  elementdecl  ::=  '<!ELEMENT' S Name S contentspec S? '>'
DerivationRule(:XML, "elementdecl",
               Sequence(
                   StringLiteral("<!ELEMENT"),
                   BNFRef(:XML, "S"),
                   BNFRef(:XML, "Name"),
                   BNFRef(:XML, "S"),
                   BNFRef(:XML, "contentspec"),
                   Repeat(BNFRef(:XML, "S"); max=1),
                   CharacterLiteral('>'))
               )

# [46]  https://www.w3.org/TR/xml/#NT-contentspec
#  contentspec  ::=  'EMPTY' | 'ANY' | Mixed | children
DerivationRule(:XML, "contentspec",
               Alternatives(
                   StringLiteral("EMPTY"),
                   StringLiteral("ANY"),
                   BNFRef(:XML, "Mixed"),
                   BNFRef(:XML, "children"))
               )

# [47]  https://www.w3.org/TR/xml/#NT-children
#  children  ::=  (choice | seq) ('?' | '*' | '+')?
DerivationRule(:XML, "children",
               Sequence(
                   Alternatives(
                       BNFRef(:XML, "choice"),
                       BNFRef(:XML, "seq")),
                   RegexNode(r"[?*+]?"))
               )

# [48]  https://www.w3.org/TR/xml/#NT-cp
#  cp  ::=  (Name | choice | seq) ('?' | '*' | '+')?
DerivationRule(:XML, "cp",
               Sequence(
                   Alternatives(
                       BNFRef(:XML, "Name"),
                       BNFRef(:XML, "choice"),
                       BNFRef(:XML, "seq")),
                   RegexNode(r"[?*+]?"))
               )

# [49]  https://www.w3.org/TR/xml/#NT-choice
#  choice  ::=  '(' S? cp ( S? '|' S? cp )+ S? ')'
DerivationRule(:XML, "choice",
               Sequence(
                   CharacterLiteral('('),
                   Repeat(BNFRef(:XML, "S"); max=1),
                   BNFRef(:XML, "cp"),
                   Repeat(
                       Sequence(
                           Repeat(BNFRef(:XML, "S"); max=1),
                           CharacterLiteral('|'),
                           Repeat(BNFRef(:XML, "S"); max=1),
                           BNFRef(:XML, "cp"));
                       min=1),
                   Repeat(BNFRef(:XML, "S"); max=1),
                   CharacterLiteral(')'))
               )

# [50]  https://www.w3.org/TR/xml/#NT-seq
#  seq  ::=  '(' S? cp ( S? ',' S? cp )* S? ')'
DerivationRule(:XML, "seq",
               Sequence(
                   CharacterLiteral('('),
                   Repeat(BNFRef(:XML, "S"); max=1),
                   BNFRef(:XML, "cp"),
                   Repeat(
                       Sequence(
                           Repeat(BNFRef(:XML, "S"); max=1),
                           CharacterLiteral(','),
                           Repeat(BNFRef(:XML, "S"); max=1),
                           BNFRef(:XML, "cp"))),
                   Repeat(BNFRef(:XML, "S"); max=1),
                   CharacterLiteral(')'))
               )


# [51]  https://www.w3.org/TR/xml/#NT-Mixed
#  Mixed  ::=  '(' S? '#PCDATA' (S? '|' S? Name)* S? ')*' | '(' S? '#PCDATA' S? ')'
DerivationRule(:XML, "Mixed",
               Alternatives(
                   Sequence(
                       CharacterLiteral('('),
                       Repeat(BNFRef(:XML, "S"); max=1),
                       StringLiteral("#PCDATA"),
                       Repeat(
                           Sequence(
                               Repeat(BNFRef(:XML, "S"); max=1),
                               CharacterLiteral('|'),
                               Repeat(BNFRef(:XML, "S"); max=1),
                               BNFRef(:XML, "Name"))),
                       Repeat(BNFRef(:XML, "S"); max=1),
                       StringLiteral(")*")),
                   Sequence(
                       CharacterLiteral('('),
                       Repeat(BNFRef(:XML, "S"); max=1),
                       StringLiteral("#PCDATA"),
                       Repeat(BNFRef(:XML, "S"); max=1),
                       CharacterLiteral(')')))
               )


# [52]  https://www.w3.org/TR/xml/#NT-AttlistDecl
#  AttlistDecl  ::=  '<!ATTLIST' S Name AttDef* S? '>'
DerivationRule(:XML, "AttlistDecl",
               Sequence(
                   StringLiteral("<!ATTLIST"),
                   BNFRef(:XML, "S"),
                   BNFRef(:XML, "Name"),
                   Repeat(BNFRef(:XML, "AttDef")),
                   Repeat(BNFRef(:XML, "S"); max=1),
                   CharacterLiteral('>'))
               )

# [53]  https://www.w3.org/TR/xml/#NT-AttDef
#  AttDef  ::=  S Name S AttType S DefaultDecl
DerivationRule(:XML, "AttDef",
               Sequence(
                   BNFRef(:XML, "S"),
                   BNFRef(:XML, "Name"),
                   BNFRef(:XML, "S"),
                   BNFRef(:XML, "AttType"),
                   BNFRef(:XML, "S"),
                   BNFRef(:XML, "DefaultDecl"))
               )

# [54]  https://www.w3.org/TR/xml/#NT-AttType
#  AttType  ::=  StringType | TokenizedType | EnumeratedType
DerivationRule(:XML, "AttType",
               Alternatives(
                   BNFRef(:XML, "StringType"),
                   BNFRef(:XML, "TokenizedType"),
                   BNFRef(:XML, "EnumeratedType"))
               )

#[55]  https://www.w3.org/TR/xml/#NT-StringType
#  StringType  ::=  'CDATA'
DerivationRule(:XML, "StringType",
               StringLiteral("StringType"))

# [56]  https://www.w3.org/TR/xml/#NT-TokenizedType
# TokenizedType  ::=  'ID' | 'IDREF' | 'IDREFS' | 'ENTITY' | 'ENTITIES' | 'NMTOKEN' | 'NMTOKENS'
DerivationRule(:XML, "TokenizedType",
               Alternatives(
                   StringLiteral("ID"),
                   StringLiteral("IDREF"),
                   StringLiteral("IDREFS"),
                   StringLiteral("ENTITY"),
                   StringLiteral("ENTITIES"),
                   StringLiteral("NMTOKEN"),
                   StringLiteral("NMTOKENS"))
               ).constructor = substring_constructor_function

# [57]  https://www.w3.org/TR/xml/#NT-EnumeratedType
#  EnumeratedType  ::=  NotationType | Enumeration
DerivationRule(:XML, "EnumeratedType",
               Alternatives(
                   BNFRef(:XML, "NotationType"),
                   BNFRef(:XML, "Enumeration"))
               )

# [58]  https://www.w3.org/TR/xml/#NT-NotationType
#  NotationType  ::=  'NOTATION' S '(' S? Name (S? '|' S? Name)* S? ')'
DerivationRule(:XML, "NotationType",
               Sequence(
                   StringLiteral("NOTATION"),
                   BNFRef(:XML, "S"),
                   CharacterLiteral('('),
                   Repeat(BNFRef(:XML, "S"); max=1),
                   BNFRef(:XML, "Name"),
                   Repeat(
                       Sequence(
                           Repeat(BNFRef(:XML, "S"); max=1),
                           CharacterLiteral('|'),
                           Repeat(BNFRef(:XML, "S"); max=1),
                           BNFRef(:XML, "Name"))),
                   Repeat(BNFRef(:XML, "S"); max=1),
                   CharacterLiteral(')'))
               )

# [59]  https://www.w3.org/TR/xml/#NT-Enumeration
#  Enumeration  ::=  '(' S? Nmtoken (S? '|' S? Nmtoken)* S? ')'
DerivationRule(:XML, "Enumeration",
               Sequence(
                   CharacterLiteral('('),
                   Repeat(BNFRef(:XML, "S"); max=1),
                   BNFRef(:XML, "Nmtoken"),
                   Repeat(
                       Sequence(
                           Repeat(BNFRef(:XML, "S"); max=1),
                           CharacterLiteral('|'),
                           Repeat(BNFRef(:XML, "S"); max=1),
                           BNFRef(:XML, "Nmtoken"))),
                   Repeat(BNFRef(:XML, "S"); max=1),
                   CharacterLiteral(')'))
               )

# [60]  https://www.w3.org/TR/xml/#NT-DefaultDecl
#  DefaultDecl  ::=  '#REQUIRED' | '#IMPLIED' | (('#FIXED' S)? AttValue)
DerivationRule(:XML, "DefaultDecl",
               Alternatives(
                   StringLiteral("#REQUIRED"),
                   StringLiteral("#IMPLIED"),
                   Sequence(
                       Repeat(
                           Sequence(
                               StringLiteral("#FIXED"),
                               BNFRef(:XML, "S")); max=1),
                       BNFRef(:XML, "AttValue")))
               )

# [61]  https://www.w3.org/TR/xml/#NT-conditionalSect
#  conditionalSect  ::=  includeSect | ignoreSect
DerivationRule(:XML, "conditionalSect",
               Alternatives(
                   BNFRef(:XML, "includeSect"),
                   BNFRef(:XML, "ignoreSect"))
               )

# [62]  https://www.w3.org/TR/xml/#NT-includeSect
#  includeSect  ::=  '<![' S? 'INCLUDE' S? '[' extSubsetDecl ']]>'
DerivationRule(:XML, "includeSect",
               Sequence(
                   StringLiteral("<!['"),
                   Repeat(BNFRef(:XML, "S"); max=1),
                   StringLiteral("INCLUDE"),
                   Repeat(BNFRef(:XML, "S"); max=1),
                   CharacterLiteral('['),
                   BNFRef(:XML, "extSubsetDecl"),
                   StringLiteral("]]>"))
               )

# [63]  https://www.w3.org/TR/xml/#NT-ignoreSect
#  ignoreSect  ::=  '<![' S? 'IGNORE' S? '[' ignoreSectContents* ']]>'
DerivationRule(:XML, "ignoreSect",
               Sequence(
                   StringLiteral("<!['"),
                   Repeat(BNFRef(:XML, "S"); max=1),
                   StringLiteral("IGNORE"),
                   Repeat(BNFRef(:XML, "S"); max=1),
                   CharacterLiteral('['),
                   Repeat(BNFRef(:XML, "ignoreSectContents")),
                   StringLiteral("]]>"))
               )

# [64]  https://www.w3.org/TR/xml/#NT-ignoreSectContents
#  ignoreSectContents  ::=  Ignore ('<![' ignoreSectContents ']]>' Ignore)*
DerivationRule(:XML, "ignoreSectContents",
               Sequence(
                   BNFRef(:XML, "Ignore"),
                   Repeat(
                       Sequence(
                           StringLiteral("<!["),
                           BNFRef(:XML, "ignoreSectContents"),
                           StringLiteral("]]>"),
                           BNFRef(:XML, "Ignore"))))
               )

# [65]  https://www.w3.org/TR/xml/#NT-Ignore
#  Ignore  ::=  Char* - (Char* ('<![' | ']]>') Char*)
DerivationRule(:XML, "Ignore",
               Excluding(
                   Sequence(
                       Repeat(BNFRef(:XML, "Char")),
                       Alternatives(
                           StringLiteral("<!["),
                           StringLiteral("]]>")),
                       Repeat(BNFRef(:XML, "Char"))),
                   Repeat(BNFRef(:XML, "Char")))
               )

# [66]  https://www.w3.org/TR/xml/#NT-CharRef
#  CharRef   ::=   '&#' [0-9]+ ';' | '&#x' [0-9a-fA-F]+ ';'
DerivationRule(:XML, "CharRef",
               Alternatives(
                   RegexNode(r"&#[0-9]+;"),
                   RegexNode(r"&#x[0-9a-fA-F]+;"))
               )
# [67]  https://www.w3.org/TR/xml/#NT-Reference
#  Reference  ::=  EntityRef | CharRef
DerivationRule(:XML, "Reference",
               Alternatives(
                   BNFRef(:XML, "EntityRef"),
                   BNFRef(:XML, "CharRef"))
               )

# [68]  https://www.w3.org/TR/xml/#NT-EntityRef
#  EntityRef   ::=   '&' Name ';'
DerivationRule(:XML, "EntityRef",
               Sequence(CharacterLiteral('&'),
                        BNFRef(:XML, "Name"),
                        CharacterLiteral(';'))
               )

# [69]  https://www.w3.org/TR/xml/#NT-PEReference
#  PEReference  ::=  '%' Name ';'
DerivationRule(:XML, "PEReference",
               Sequence(CharacterLiteral('%'),
                        BNFRef(:XML, "Name"),
                        CharacterLiteral(';'))
               )

# [70]  https://www.w3.org/TR/xml/#NT-EntityDecl
#  EntityDecl   ::=   GEDecl | PEDecl
DerivationRule(:XML, "EntityDecl",
               Alternatives(
                   BNFRef(:XML, "GEDecl"),
                   BNFRef(:XML, "PEDecl")))

# [71]  https://www.w3.org/TR/xml/#NT-GEDecl
#  GEDecl   ::=   '<!ENTITY' S Name S EntityDef S? '>'
DerivationRule(:XML, "GEDecl",
               Sequence(
                   StringLiteral("<!ENTITY"),
                   BNFRef(:XML, "S"),
                   BNFRef(:XML, "Name"),
                   BNFRef(:XML, "S"),
                   BNFRef(:XML, "EntityDef"),
                   Repeat(BNFRef(:XML, "S"); max=1),
                   CharacterLiteral('>'))
               )

# [72]  https://www.w3.org/TR/xml/#NT-PEDecl
#  PEDecl   ::=   '<!ENTITY' S '%' S Name S PEDef S? '>'
DerivationRule(:XML, "PEDecl",
               Sequence(
                   StringLiteral("<!ENTITY"),
                   BNFRef(:XML, "S"),
                   CharacterLiteral('%'),
                   BNFRef(:XML, "S"),
                   BNFRef(:XML, "Name"),
                   BNFRef(:XML, "S"),
                   BNFRef(:XML, "PEDef"),
                   Repeat(BNFRef(:XML, "S"); max=1),
                   CharacterLiteral('>'))
               )

# [73]  https://www.w3.org/TR/xml/#NT-EntityDef
#  EntityDef   ::=   EntityValue | (ExternalID NDataDecl?)
DerivationRule(:XML, "EntityDef",
               Alternatives(
                   BNFRef(:XML, "EntityValue"),
                   Sequence(
                       BNFRef(:XML, "ExternalID"),
                       Repeat(Repeat(BNFRef(:XML, "NDataDecl");
                                     max=1))))
               )

# [74]  https://www.w3.org/TR/xml/#NT-PEDef
#  PEDef   ::=   EntityValue | ExternalID
DerivationRule(:XML, "PEDef",
               Alternatives(
                   BNFRef(:XML, "EntityValue"),
                   BNFRef(:XML, "ExternalID")))

# [75]  https://www.w3.org/TR/xml/#NT-ExternalID
#  ExternalID  ::=  'SYSTEM' S SystemLiteral | 'PUBLIC' S PubidLiteral S SystemLiteral
DerivationRule(:XML, "ExternalID",
               Alternatives(
                   Sequence(
                       StringLiteral("SYSTEM"),
                       BNFRef(:XML, "S"),
                       BNFRef(:XML, "SystemLiteral")),
                   Sequence(
                       StringLiteral("PUBLIC"),
                       BNFRef(:XML, "S"),
                       BNFRef(:XML, "PubidLiteral"),
                       BNFRef(:XML, "S"),
                       BNFRef(:XML, "SystemLiteral")))
               )

# [76]  https://www.w3.org/TR/xml/#NT-NDataDecl
#  NDataDecl  ::=  S 'NDATA' S Name
DerivationRule(:XML, "NDataDecl",
               Sequence(
                   StringLiteral("NDATA"),
                   BNFRef(:XML, "S"),
                   BNFRef(:XML, "Name"))
               )

# [77]
#  TextDecl  ::=  '<?xml' VersionInfo? EncodingDecl S? '?>'
DerivationRule(:XML, "TextDecl",
               Sequence(
                   StringLiteral("<?xml"),
                   Repeat(BNFRef(:XML, "VersionInfo");
                          max=1),
                   BNFRef(:XML, "EncodingDecl"),
                   Repeat(BNFRef(:XML, "S"); max=1),
                   StringLiteral("?>"))
               )

# [78]
#  extParsedEnt  ::=  TextDecl? content
DerivationRule(:XML, "extParsedEnt",
               Sequence(
                   Repeat(BNFRef(:XML, "TextDecl"); max=1),
                   BNFRef(:XML, "content"))
               )

# [80]  https://www.w3.org/TR/xml/#NT-EncodingDecl
#  EncodingDecl   ::=   S 'encoding' Eq ('"' EncName '"' | "'" EncName "'" )
DerivationRule(:XML, "EncodingDecl",
               Sequence(
                   BNFRef(:XML, "S"),
                   StringLiteral("encoding"),
                   BNFRef(:XML, "Eq"),
                   Alternatives(
                       Sequence(
                           CharacterLiteral('"'),
                           BNFRef(:XML, "EncName"),
                           CharacterLiteral('"')),
                       Sequence(
                           CharacterLiteral('\''),
                           BNFRef(:XML, "EncName"),
                           CharacterLiteral('"'))))
               )

# [81]  https://www.w3.org/TR/xml/#NT-EncName
#  EncName  ::=  [A-Za-z] ([A-Za-z0-9._] | '-')*
DerivationRule(:XML, "EncName",
               RegexNode(r"[A-Za-z][A-Za-z0-9_-]*")
               ).constructor = substring_constructor_function



# [82]  https://www.w3.org/TR/xml/#NT-NotationDecl
#  NotationDecl  ::=  '<!NOTATION' S Name S (ExternalID | PublicID) S? '>'
DerivationRule(:XML, "NotationDecl",
               Sequence(
                   StringLiteral("<!NOTATION"),
                   BNFRef(:XML, "S"),
                   BNFRef(:XML, "Name"),
                   BNFRef(:XML, "S"),
                   Alternatives(
                       BNFRef(:XML, "ExternalID"),
                       BNFRef(:XML, "PublicID")),
                   Repeat(BNFRef(:XML, "S"); max=1),
                   CharacterLiteral('>'))
               )

# [83]  https://www.w3.org/TR/xml/#NT-PublicID
#  PublicID  ::=  'PUBLIC' S PubidLiteral
DerivationRule(:XML, "PublicID",
               Sequence(
                   StringLiteral("PUBLIC"),
                   BNFRef(:XML, "S"),
                   BNFRef(:XML, "PubidLiteral"))
               )


##### ANY USEFUL CONSTRUCTORS BELOW?

#=
DerivationRule(:XML, "<String>",
               @Alternatives(
                   @Sequence(
                       CharacterLiteral('"'),
                       Repeat(
                           Alternatives(
                               BNFRef(:XML, "<Char>"),
                               CharacterLiteral('\''))),
                       CharacterLiteral('"')),
                   @Sequence(
                       CharacterLiteral('\''),
                       Repeat(
                           Alternatives(
                               BNFRef(:XML, "<Char>"),
                               CharacterLiteral('"'))),
                       CharacterLiteral('\''),))
               ).constructor =
                   function(context, input::AbstractString,
                            from::Int, to::Int, value)
                       SubString(input, from + 1, to - 1)
                   end
=#


check_references(AllGrammars[:XML])

