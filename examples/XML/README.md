# Example: an XML Parser

This directory includes an example of how `AnotherParser` was used to
implement a parser for XML.  XML is parsed to a Concrete Syntax Tree
(CST) whose data structure is defoned in the file `cst.jl`.  The
original XML can be faithfully reconstructed by calling `Base.print`
the `CSTDocument` returned by the parser.

This parser has been tested on all of the W3C conformance test files
in the "valid standalone" suite (`xmlconf/xmltest/valid/sa`).  Each
file was parsed and the resulting document printed, yeillding
identical XML content.

Several of the files in the W3C conformance test suite make use of
alternate encodings with byte order amrks.  The file
`byte_order_decoding.jl` implements the function `read_decoded` to
read such files.

