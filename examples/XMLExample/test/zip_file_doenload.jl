
using Downloads
using ZipArchives


# Where was the conformance test suite from
# https://www.w3.org/XML/Test/xmlts20130923.zip downloaded?
XML_CONFORMANCE_TEST_ROOT = joinpath(@__DIR__, "w3c_tests")

function ensure_w3c_test_files()
    mkpath(XML_CONFORMANCE_TEST_ROOT)
    temp_zip = Downloads.download("https://www.w3.org/XML/Test/xmlts20130923.zip")
    println(temp_zip)
    try
        zipdata = read(temp_zip)
        archive = ZipReader(zipdata)
        for i in 1 : zip_nentries(archive)
            path = joinpath(XML_CONFORMANCE_TEST_ROOT, zip_name(archive, i))
            if startswith(zip_name(archive, i), "xmlconf/xmltest/valid/sa/")
                if zip_isdir(archive, i)
                    mkpath(path)
                else
                    println("unzipping $(zip_name(archive, i))")
                    open(path, "w") do io
                        write(io, zip_readentry(archive, i))
                    end
                end
            end
        end
    finally
        rm(temp_zip)
    end
    XML_CONFORMANCE_TEST_ROOT
end

