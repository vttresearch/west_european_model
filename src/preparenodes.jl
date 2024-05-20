
using SpineInterface

function preparenodes(nodes, ts_data)

    # data structure for spinedb
    nodes_spi = Dict{Symbol,Any}()

    for (n,value) in nodes
        if value["type"] == "elec"
            d1 = make_commoditynode(n, ts_data["elecload"])
        elseif value["type"] == "dheat"
            d1 = make_commoditynode(n, ts_data["heatload"])
        elseif value["type"] == "fuel"
            d1 = make_fuelnode(n)
        elseif value["type"] == "onshore"
            d1 = make_vrenode(n, value, ts_data["cf_onshore"])
        elseif value["type"] == "offshore"
            d1 = make_vrenode(n, value, ts_data["cf_offshore"])
        elseif value["type"] == "PV"
            d1 = make_vrenode(n, value, ts_data["cf_pv"])
        elseif value["type"] == "reservoir" || value["type"] == "open-loop" || 
                value["type"] == "ror" || 
                value["type"] == "closed-loop"
            d1 = make_hydronode(n, value, ts_data["hydroinflow"], 
                                ts_data["hydrolowerlimits"],
                                ts_data["hydroupperlimits"])
        else
            throw(ArgumentError(" the node type was not recognized."))
        
        end

        nodes_spi = mergedicts(nodes_spi,d1)
    end

    return nodes_spi
end

function make_commoditynode(node, loads)

    if hasproperty(loads, node)
        a = loads[:,["time", node]]
        a = convert_timeseries(a, node)
    else
        a = 0
    end

    data1 = Dict(
        :objects => [
            ["node", node],
        ],
        :relationships => [
            ["node__temporal_block", [node, "hourly"]],
            ["node__stochastic_structure", [node, "deterministic"]],
        ],
        :object_parameter_values => [
            ["node", node, "demand", unparse_db_value(1.0 * a)],
        ]
    )

    return data1
end

function make_vrenode(node, nodeprops, cf)

    if hasproperty(cf, node)
        a = cf[:,["time", node]]
        a = convert_timeseries(a, node)
    else
        a = 0
    end

    # calculate inflow to node
    a = -1.0 * a * nodeprops["unit_capacity"]

    data1 = Dict(
        :objects => [
            ["node", node],
        ],
        :relationships => [
            ["node__temporal_block", [node, "hourly"]],
            ["node__stochastic_structure", [node, "deterministic"]],
        ],
        :object_parameter_values => [
            ["node", node, "demand", unparse_db_value(a)],
            ["node", node, "nodal_balance_sense", ">="]
        ]
    )

    return data1
end

function make_fuelnode(node)

    data1 = Dict(
        :objects => [
            ["node", node],
        ],
        :relationships => [
            ["node__temporal_block", [node, "hourly"]],
            ["node__stochastic_structure", [node, "deterministic"]],
        ],
        :object_parameter_values => [
            ["node", node, "balance_type", "balance_type_none"],
        ]
    )

    return data1
end

function make_hydronode(node, nodeprops, inflow::DataFrame,
                        lowerlimits::DataFrame,
                        upperlimits::DataFrame)

    # search reservoir inflow from data
    if hasproperty(inflow, node)
        a = inflow[:,["time", node]]
        a = -1.0 * convert_timeseries(a, node)
    else
        a = 0
    end

    # search also the minimum and maximum time-dependent reservoir levels
    # these have not been given for ror units, so the capacity from the model file 
    # will be used (=0)
    if hasproperty(lowerlimits, node)
        lolim = lowerlimits[:,["time", node]]
        lolim = convert_timeseries(lolim, node)
    else
        lolim = 0
    end
    if hasproperty(upperlimits, node)
        ulim = upperlimits[:,["time", node]]
        ulim = convert_timeseries(ulim, node)
    else
        ulim = get(nodeprops, "reservoir_capacity", 0)
    end

    data1 = Dict(
        :objects => [
            ["node", node],
        ],
        :relationships => [
            ["node__temporal_block", [node, "hourly"]],
            ["node__stochastic_structure", [node, "deterministic"]],
        ],
        :object_parameter_values => [
            ["node", node, "demand", unparse_db_value(a)],
            ["node", node, "has_state", true],
            ["node", node, "node_state_cap", unparse_db_value(ulim)],
            ["node", node, "node_state_min", unparse_db_value(lolim)]
        ]
    )

    return data1
end