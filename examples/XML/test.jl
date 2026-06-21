using AnotherParser

include("cst.jl")
include("xml.jl")

include("cst_unit_tests.jl")

include("zip_file_doenload.jl")
include("cst_conformance_testing.jl")
ensure_w3c_test_files()
run_conformance_tests()

