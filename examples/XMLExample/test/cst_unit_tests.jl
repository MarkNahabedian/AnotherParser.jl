
function test_round_trip(rulename, input)
    matches, value, i = recognize1(AllGrammars[:XML][rulename], input)
    got = string(value)
    @assert input == got "$input == $got"
end

# CSTWhitespace
test_round_trip("S", " ")
test_round_trip("S", "\t")
test_round_trip("S", "\r")
test_round_trip("S", "\n")

# CSTName
test_round_trip("Name", "foo")

# CSTCharData
test_round_trip("CharData", "jghfrcgf_y")

# CSTComment
test_round_trip("Comment", "<!-- foobar -->")

# CSTProcessingInstruction
test_round_trip("PI", "<?foo bar baz?>")

# CSTEntityRef
test_round_trip("EntityRef", "&amp;")

# CSTPEReference
test_round_trip("PEReference", "%foo;")

# CSTCharRef
test_round_trip("CharRef", "&#x531;")

# CSTAttribute
test_round_trip("Attribute", "attr='foobar'")
test_round_trip("Attribute", "attr=\"foobar\"")
test_round_trip("Attribute", "attr='foo&amp;bar'")
test_round_trip("<AttributeList>", " attr=\"foobar\"    at2='jhgjyj87yt8'")

# CSTDeclAttr
test_round_trip("VersionInfo", "  version='1.0'")
test_round_trip("EncodingDecl", "\tencoding='utf-8'")
test_round_trip("SDDecl", "  standalone=\"yes\"")

# CSTXMLDecl
test_round_trip("XMLDecl", "<?xml version=\"1.0\"?>")
test_round_trip("XMLDecl", "<?xml version='1.0'?>")
test_round_trip("XMLDecl", "<?xml version = \"1.0\"?>")
test_round_trip("XMLDecl", "<?xml version='1.0' encoding=\"UTF-8\"?>")
test_round_trip("XMLDecl", "<?xml version='1.0' standalone='yes'?>")
test_round_trip("XMLDecl", "<?xml version='1.0' encoding=\"UTF-8\" standalone='yes'?>")
test_round_trip("XMLDecl", "<?xml version=\"1.0\" encoding=\"utf-8\"?>")

# CSTElement
test_round_trip("element", """<doc>
            <e a3="v3"/>
            <e a1="w1"/>
            <e a2="w2" a3="v3"/>
            </doc>""")

# CSTNotationDecl
test_round_trip("NotationDecl", "<!NOTATION n PUBLIC \"whatever\">")
test_round_trip("NotationDecl", "<!NOTATION n1 SYSTEM \"http://www.w3.org/\">")

# CSTPublicID
test_round_trip("PublicID", "PUBLIC 'ABC123'")

# CSTExternalId
test_round_trip("ExternalID", "SYSTEM 'foo'")
test_round_trip("ExternalID", "PUBLIC 'abc' 'foo'")

# CSTElementDecl
test_round_trip("elementdecl", "<!ELEMENT doc (#PCDATA)>")
test_round_trip("elementdecl", "<!ELEMENT doc (foo)>")
test_round_trip("elementdecl", "<!ELEMENT foo EMPTY>")

# CSTAttlistDecl
test_round_trip("AttlistDecl", "<!ATTLIST doc a1 CDATA \"v1\">")
test_round_trip("AttlistDecl", "<!ATTLIST doc a1 CDATA #IMPLIED a2 CDATA #IMPLIED>")
test_round_trip("AttlistDecl", "<!ATTLIST e a1 CDATA #IMPLIED a2 CDATA #IMPLIED a3 CDATA #IMPLIED>")

# CSTPEDecl
test_round_trip("PEDecl", "<!ENTITY % e \"<!ELEMENT doc (#PCDATA)>\">")
test_round_trip("PEDecl", "<!ENTITY % e SYSTEM \"e.dtd\">")
test_round_trip("PEDecl", "<!ENTITY % e PUBLIC 'whatever' \"e.dtd\">")
test_round_trip("PEDecl", "<!ENTITY % e \"<foo>\">")


