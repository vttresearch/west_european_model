using Revise
using Nordconvert
using SpineOpt, SpineInterface

module Y
    using SpineInterface
end

#a, b = readunits("input/example.yaml","Distributed Energy",2040)

function runmodel()
    file_path_in = "output/test_in.sqlite"
    file_path_out = "output/my_test_out.sqlite"

    url_in = "sqlite:///$file_path_in"
    url_out = "sqlite:///$file_path_out"

    m = run_spineopt(url_in, url_out; log_level=0)
end

function checkresults()
    file_path_out = "output/my_test_out.sqlite"
    url_out = "sqlite:///$file_path_out"
    using_spinedb(url_out, Y)

    cost_key = (model=Y.model(:instance), report=Y.report(:report_x))
    flow_key = (
        report=Y.report(:report_x),
        unit=Y.unit(:u_OCGT_gas_FI00),
        node=Y.node(:n_FI00_elec),
        direction=Y.direction(:to_node),
        stochastic_scenario=Y.stochastic_scenario(:parent),
    )


    println(Y.unit_flow(;flow_key...))
end



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
                "hydromappingfile" => "input/regionmap-hydro.csv")


makemodel(filenames)
#m = runmodel()

