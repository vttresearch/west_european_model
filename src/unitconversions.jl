
abstract type unit end

struct nuclear_unit <: unit
    data::Dict
end

struct pv_unit <: unit
    data::Dict
end

struct ocgt_unit <: unit
    data::Dict
end

struct hydro_reservoir_unit <: unit
    data::Dict
end

function createunitstruct(u1::Dict)
    if u1["type"] == "nuclear" return nuclear_unit(u1)
    elseif u1["type"] == "PV" return pv_unit(u1)
    elseif u1["type"] == "OCGT" return ocgt_unit(u1)
    end

end

function createunitname(type, bzone)
    return "u_" * type * "_" * bzone
end

function createbzone_elecname(bzone)
    return "n_" * bzone * "_elec"
end

function createbzone_fuelname(bzone, fuel)
    return "n_" * fuel
end

function basic_generator_unit(u::unit, unittypes, fuels)

    unitname = createunitname(u.data["type"], u.data["bidding_zone"])
    elecnode = createbzone_elecname(u.data["bidding_zone"])
    fuelnode = createbzone_fuelname(u.data["bidding_zone"], u.data["fuel"])

    vom_cost = unittypes[u.data["type"]]["vom_cost"]

    data1 = Dict(
        :objects => [["unit", unitname], ],
        :relationships => [
            ["unit__to_node", [unitname, elecnode]],
            ["unit__from_node", [unitname, fuelnode]],
            ["unit__node__node", [unitname, elecnode, fuelnode]],
            ["units_on__temporal_block", [unitname, "hourly"]],
            ["units_on__stochastic_structure", [unitname, "deterministic"]],
        ],
        :relationship_parameter_values => [
            ["unit__to_node", [unitname, elecnode], "unit_capacity", u.data["eleccapa"]],
            ["unit__to_node", [unitname, elecnode], "vom_cost", vom_cost],    
        ]
    )

    return unitname, elecnode, fuelnode, data1
end


function convert_unit(u::nuclear_unit, unittypes, fuels, nodes)

    unitname, elecnode, fuelnode, data1 = basic_generator_unit(u, unittypes, fuels)

    efficiency = unittypes[u.data["type"]]["efficiency"]
    fuelcost = fuels[u.data["fuel"]]["price"]
    

    # additional unit data related to this unittype
    data2 = Dict(
        :object_parameter_values => [
            ["unit", unitname, "start_up_cost", 7000]
        ],
        :relationship_parameter_values => [
            ["unit__to_node", [unitname, elecnode], "minimum_operating_point", 0.7],
            ["unit__from_node", [unitname, fuelnode], "vom_cost", fuelcost],
            ["unit__node__node", [unitname, elecnode, fuelnode], 
                "fix_ratio_out_in_unit_flow", efficiency] 
        ]
    )

    data1 = mergedicts(data1, data2)

    # specify the nodes related to this unit
    if !haskey(nodes, elecnode)
        nodes[elecnode] = Dict("type" => "elec")
    end
    if !haskey(nodes, fuelnode)
        nodes[fuelnode] = Dict("type" => "fuel")
    end

    return data1
end


function convert_unit(u::ocgt_unit, unittypes, fuels, nodes)

    unitname, elecnode, fuelnode, data1 = basic_generator_unit(u, unittypes, fuels)

    efficiency = unittypes[u.data["type"]]["efficiency"]
    fuelcost = fuels[u.data["fuel"]]["price"]

      # additional unit data related to this unittype
      data2 = Dict(
        :object_parameter_values => [
            ["unit", unitname, "start_up_cost", 7000]
        ],
        :relationship_parameter_values => [
            ["unit__to_node", [unitname, elecnode], "minimum_operating_point", 0.4],
            ["unit__from_node", [unitname, fuelnode], "vom_cost", fuelcost],
            ["unit__node__node", [unitname, elecnode, fuelnode], 
                "fix_ratio_out_in_unit_flow", efficiency] 
        ]
    )

    data1 = mergedicts(data1, data2)

    # specify the nodes related to this unit
    if !haskey(nodes, elecnode)
        nodes[elecnode] = Dict("type" => "elec")
    end
    if !haskey(nodes, fuelnode)
        nodes[fuelnode] = Dict("type" => "fuel")
    end

    return data1
end

function convert_unit(u::hydro_reservoir_unit, unittypes, fuels, nodes)

    unitname = createunitname(u.data["type"], u.data["bidding_zone"])
    elecnode = createbzone_elecname(u.data["bidding_zone"])
    hydronode = "n_" * u.data["bidding_zone"] * "_reservoir"

    vom_cost = unittypes[u.data["type"]]["vom_cost"]

    data1 = Dict(
        :objects => [["unit", unitname], ],
        :relationships => [
            ["unit__to_node", [unitname, elecnode]],
            ["unit__from_node", [unitname, hydronode]],
            ["unit__node__node", [unitname, elecnode, hydronode]],
            ["units_on__temporal_block", [unitname, "hourly"]],
            ["units_on__stochastic_structure", [unitname, "deterministic"]],
        ],
        :relationship_parameter_values => [
            ["unit__to_node", [unitname, elecnode], "unit_capacity", u.data["eleccapa"]],
            ["unit__to_node", [unitname, elecnode], "vom_cost", vom_cost], 
            ["unit__node__node", [unitname, elecnode, hydronode], 
                "fix_ratio_out_in_unit_flow", 1.0]    
        ]
    )

    # specify the nodes related to this unit
    if !haskey(nodes, elecnode)
        nodes[elecnode] = Dict("type" => "elec")
    end
    if !haskey(nodes, hydronode)
        nodes[hydronode] = Dict("type" => "reservoir",
                                "reservoir_capacity" => u.data["reservoir_capacity"]
        )
    end

end

