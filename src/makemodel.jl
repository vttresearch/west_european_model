

function basic_model()
    # Set up basic model

    # temporal block
    r = ones(24) * Hour(1)
    r = [r; ones(6) * Day(1)]
    r = [r; ones(12) * Day(30)]

    println(sum(r))
    test_data = Dict(
        :objects => [
            ["model", "instance"],
            ["temporal_block", "hourly"],
            ["stochastic_structure", "deterministic"],
            ["stochastic_scenario", "parent"],
            ["report", "report_x"],
            ["output", "unit_flow"],
            ["output", "units_on"],
            ["output", "units_started_up"],
            ["output", "connection_flow"],
            ["output", "variable_om_costs"],
            ["output", "start_up_costs"],
            ["output", "connection_flow_costs"],
            ["output", "node_state"]
        ],
        :relationships => [
            #["model__temporal_block", ["instance", "hourly"]],
            #["model__stochastic_structure", ["instance", "deterministic"]],
            ["stochastic_structure__stochastic_scenario", ["deterministic", "parent"]],
        ],
        :object_parameter_values => [
            #["model", "instance", "model_start", Dict("type" => "date_time", "data" => "2022-01-01T00:00:00")],
            ["model", "instance", "model_start", unparse_db_value(DateTime(2015,2,10))],
            ["model", "instance", "model_end", unparse_db_value(DateTime(2015,2,10) + sum(r))],
            ["model", "instance", "duration_unit", "hour"],
            ["model", "instance", "roll_forward", nothing],
            
            ["temporal_block", "hourly", "resolution", unparse_db_value(r)],
            #["temporal_block", "hourly", "resolution", Dict("type" => "duration", "data" => "1h")],
            #["temporal_block", "hourly", "block_end", Dict("type" => "duration", "data" => "12D")],
            
            #["output", "unit_flow", "output_resolution", Dict("type" => "duration", "data" => "1h")],
            #["output", "variable_om_costs", "output_resolution", Dict("type" => "duration", "data" => "2D")],
            ["model", "instance", "db_mip_solver", "HiGHS.jl"],
            ["model", "instance", "db_lp_solver", "HiGHS.jl"],
        ]
    )
end

function read_ts(filenames)

    ts_data = Dict()

    # read the electrical load for bidding zones
    ts_data["elecload"] = read_timeseries(filenames["elecloadfile"], 
                            filenames["loadmappingfile"])
    
    ts_data["heatload"] = read_timeseries(filenames["heatloadfile"], 
                            filenames["heatmappingfile"])

    # read the onshore wind cf for bidding zones
    ts_data["cf_onshore"] = read_timeseries(filenames["windonshorefile"], 
                                filenames["onshoremappingfile"])

    # read the offshore wind cf for bidding zones
    ts_data["cf_offshore"] = read_timeseries(filenames["windoffshorefile"], 
                                filenames["offshoremappingfile"])

    # read the PV cf for bidding zones
    ts_data["cf_pv"] = read_timeseries(filenames["pvfile"], 
                                filenames["pvmappingfile"])

    # read hydro inflow profiles
    ts_data["hydroinflow"] = read_timeseries(filenames["hydroinflowfile"], 
                                    filenames["hydromappingfile"],
                                    allowmissings = true)

    ts_data["hydrolowerlimits"] = read_timeseries(filenames["hydrolimitsfile"],
                                    filenames["hydromappingfile"],
                                    :boundarytype => "downwardLimit",
                                    allowmissings = true)

    ts_data["hydroupperlimits"] = read_timeseries(filenames["hydrolimitsfile"],
                                    filenames["hydromappingfile"],
                                    :boundarytype => "upwardLimit",
                                    allowmissings = true)

    ts_data["units_unavailable"] = read_timeseries(filenames["unitsofflinefile"],
                                    filenames["offlinemappingfile"],
                                    allowmissings = true)

    return ts_data
end

function makemodel(filenames)

    ts_data = read_ts(filenames)

    # read units from the model specification file and create spineopt strucutres
    units, unittypes, fuels, params = readmodelfile(filenames["mainmodel"], "Distributed Energy", 2040)
    units_spi, nodes = makeunits(units, unittypes, fuels, ts_data, params)

    # create spineopt strucutres for nodes
    nodes_spi = preparenodes(nodes, ts_data, params)

    # create spineopt structures for transmission lines
    lines_spi = readlines(filenames["mainmodel"], "Distributed Energy", 2040)

    mdata = mergedicts(units_spi, nodes_spi, lines_spi)
    mdata = mergedicts(mdata, basic_model())

    create_spine_db(mdata)
end

function create_spine_db(a)
    file_path_in = "output/test_in.sqlite"
    url_in = "sqlite:///$file_path_in"

    #remove old versions
    rm(file_path_in; force=true)

    _load_test_data(url_in, a)
end

