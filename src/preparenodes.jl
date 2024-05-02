
using SpineInterface

function preparenodes(nodes, elecload::DataFrame, heatload, cf_onshore::DataFrame, hydroinflow::DataFrame)

    # data structure for spinedb
    nodes_spi = Dict{Symbol,Any}()

    for (n,value) in nodes
        
        if value["type"] == "elec"
            d1 = make_commoditynode(n, elecload)
        elseif value["type"] == "fuel"
            d1 = make_fuelnode(n)
        elseif value["type"] == "onshore"
            d1 = make_vrenode(n, value, cf_onshore)
        elseif value["type"] == "pv"
            d1 = make_vrenode(n, value, cf_pv)
        elseif value["type"] == "reservoir"
            d1 = make_hydronode(n, value, hydroinflow)
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

function make_hydronode(node, nodeprops, inflow::DataFrame)

    if hasproperty(inflow, node)
        a = inflow[:,["time", node]]
        a = -1.0 * convert_timeseries(a, node)
    else
        a = 0
    end

    # search also the minimum and maximum time-dependent reservoir levels

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
            ["node", node, "node_state_cap", get(nodeprops, "reservoir_capacity", 0) ],
        ]
    )

    return data1
end