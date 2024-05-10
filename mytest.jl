using Revise
using Nordconvert
using SpineOpt

#a, b = readunits("input/example.yaml","Distributed Energy",2040)

function runmodel()
    file_path_in = "output/test_in.sqlite"
    url_in = "sqlite:///$file_path_in"

    m = run_spineopt(url_in, nothing; log_level=0)
end

#runmodel()

filenames = Dict("elecloadfile" => "input/summary_load_2011-2020-1h.csv",
                "loadmappingfile" => "input/regionmap.csv",
                "heatloadfile" => "input/DH_2025_timeseries_summary.csv",
                "heatmappingfile" => "input/regionmap-dheat.csv",
                "mainmodel" => "input/example.yaml",  
                "windonshorefile" => "input/PECD_2021_WindOnshore_byarea.csv", 
                "windmappingfile" => "input/regionmap-onshore.csv",
                "hydroinflowfile" => "input/summary_hydro_inflow_1982-2020_1h_MWh.csv",
                "hydrolimitsfile" => "input/summary_hydro_reservoir_limits_2015_2016_1h_MWh.csv",
                "hydropowlimitsfile" => "input/summary_hydro_reservoir_minmax_generation_1982_2020_1h_MWh.csv",
                "hydromappingfile" => "input/regionmap-hydro.csv")

makemodel(filenames)

