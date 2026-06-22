
using StringEncodings

export determine_file_encoding, read_decoded

BOM_MAP = [ UInt8[0x00, 0x00, 0xFE, 0xFF] => "UTF-32BE",
            UInt8[0xFF, 0xFE, 0x00, 0x00] => "UTF-32LE",
            UInt8[0xEF, 0xBB, 0xBF] => "UTF-8",
            UInt8[0xFE, 0xFF] => "UTF-16BE",
            UInt8[0xFF, 0xFE] => "UTF-16LE",
            [] => "UTF-8"
            ]

function lookup_bom(bom::Vector{UInt8})
    function isprefix(prefix)
        if length(prefix) > length(bom)
            return false
        end
        for i in 1:length(prefix)
            if prefix[i] != bom[i]
                return false
            end
        end
        return true
    end
    for p in BOM_MAP
        if isprefix(p.first)
            return p
        end
    end
    [] => "UTF-8"    
end


"""
    determine_file_encoding(::IO)

Determine stream encoding from byte order mark.

Seeks to the beginning of the IO, reads the byte order mark, seems to
the end of the byte order mark and then returns the name of the file
encoding as it appears in `StringEncodings.endodiings()`.
 """
function determine_file_encoding(io::IO)
    seekstart(io)
    bom = read(io, 4)
    p = lookup_bom(bom)
    seek(io, length(p.first))
    return p.second
end

function determine_file_encoding(filename::AbstractString)
    open(filename, "r") do io
        return(determine_file_encoding(io))
    end
end


"""
    read_decoded(filename)

Decode the contents of `filename` based on its byte order mark, if any.
"""
function read_decoded(filename)
    open(filename, "r") do io
        encoding = determine_file_encoding(io)
        read(StringDecoder(io, encoding), String)
    end
end


#=
open("/Users/MarkNahabedian/Downloads/xmlconf/xmltest/valid/sa/049.xml", "r") do io
    read(io, 4)
end

=#

