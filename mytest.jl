using Revise
using Nordconvert

#a, b = readunits("input/example.yaml","Distributed Energy",2040)

filenames = Dict("elecloadfile" => "input/summary_load_2011-2020-1h.csv",
                "loadmappingfile" => "input/regionmap.csv",
                "mainmodel" => "input/example.yaml",  
                "windonshorefile" => "input/PECD_2021_WindOnshore_byarea.csv", 
                "windmappingfile" => "input/regionmap-onshore.csv",
                "reservoirfile" => "input/summary_hydro_inflow_1982-2020_1h_MWh.csv")

makemodel(filenames)