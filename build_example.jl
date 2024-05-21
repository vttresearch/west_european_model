using Revise
using Nordconvert
using Infiltrator

filenames = Dict("elecloadfile" => "input/summary_load_2011-2020-1h.csv",
                "loadmappingfile" => "input/regionmap.csv",
                "heatloadfile" => "input/DH_2025_timeseries_summary.csv",
                "heatmappingfile" => "input/regionmap-dheat.csv",
                "mainmodel" => "input/example.yaml",  
                "windonshorefile" => "input/PECD_2021_WindOnshore_byarea.csv", 
                "onshoremappingfile" => "input/regionmap-onshore.csv",
                "windoffshorefile" => "input/PECD_2021_WindOffshore_byarea.csv", 
                "offshoremappingfile" => "input/regionmap-offshore.csv",
                "pvfile" => "input/PECD-MAF2019-PV_byarea.csv",
                "pvmappingfile" => "input/regionmap-pv.csv",
                "hydroinflowfile" => "input/summary_hydro_inflow_1982-2020_1h_MWh.csv",
                "hydrolimitsfile" => "input/summary_hydro_reservoir_limits_2015_2016_1h_MWh.csv",
                "hydropowlimitsfile" => "input/summary_hydro_reservoir_minmax_generation_1982_2020_1h_MWh.csv",
                "hydromappingfile" => "input/regionmap-hydro.csv",
                "unitsofflinefile" => "input/ts_units_unavailable.csv",
                "offlinemappingfile" => "input/unitmap-offline.csv")


makemodel(filenames)