
using SpineInterface

function preparenodes(nodes, elecload, heatload, cf_onshore)


    # data structure for spinedb
    nodes_spi = Dict{Symbol,Any}()

    for (n,value) in nodes
        
        if value["type"] == "elec"
            d1 = make_commoditynode(n, elecload)
        elseif value["type"] == "fuel"
            d1 = make_fuelnode(n)
        elseif value["type"] == "vre"
            d1 = make_vrenode(n, nothing)
        end
        nodes_spi = mergedicts(nodes_spi,d1)
    end
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
            ["node", node, "demand", unparse_db_value(-1.0 * a)],
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

function make_vrenode(node, cf)
end