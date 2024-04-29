using Revise
using Nordconvert

#a, b = readunits("input/example.yaml","Distributed Energy",2040)

filenames = Dict("elecloadfile" => "input/summary_load_2011-2020-1h.csv",
                "loadmappingfile" => "input/regionmap.csv",
                "mainmodel" => "input/example.yaml"  )

makemodel(filenames)