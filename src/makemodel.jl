

function basic_model()
    # Set up basic model
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
            ["model", "instance", "model_start", unparse_db_value(DateTime(2016,1,1))],
            ["model", "instance", "model_end", unparse_db_value(DateTime(2016,1,5))],
            ["model", "instance", "duration_unit", "hour"],
            ["model", "instance", "roll_forward", nothing],
            ["temporal_block", "hourly", "resolution", Dict("type" => "duration", "data" => "1h")],
            ["temporal_block", "hourly", "block_end", 
                    Dict("type" => "duration",                    
                        "data" => "12D")],
            ["output", "unit_flow", "output_resolution", Dict("type" => "duration", "data" => "1h")],
            #["output", "variable_om_costs", "output_resolution", Dict("type" => "duration", "data" => "2D")],
            ["model", "instance", "db_mip_solver", "HiGHS.jl"],
            ["model", "instance", "db_lp_solver", "HiGHS.jl"],
        ]
    )
end


function makemodel(filenames)

    # read the electrical load for bidding zones
    elecload = read_timeseries(filenames["elecloadfile"], 
                            filenames["loadmappingfile"])

    # read the onshore wind cf for bidding zones
    cf_onshore = read_timeseries(filenames["windonshorefile"], 
                                filenames["windmappingfile"])

    # read hydro inflow profiles
    hydroinflow = read_timeseries(filenames["hydroinflowfile"], 
                                    filenames["hydromappingfile"])

    println(first(hydroinflow, 6))

    # read units from the model specification file and create spineopt strucutres
    units_spi, nodes = readunits(filenames["mainmodel"], "Distributed Energy", 2040)

    # create spineopt strucutres for nodes
    nodes_spi = preparenodes(nodes, elecload, nothing, cf_onshore, hydroinflow)

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
