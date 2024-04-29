
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
        ]
    )

    return unitname, elecnode, fuelnode, data1
end


function convert_unit(u::nuclear_unit, unittypes, fuels, nodes)

    unitname = createunitname(u.data["type"], u.data["bidding_zone"])
    elecnode = createbzone_elecname(u.data["bidding_zone"])
    fuelnode = createbzone_fuelname(u.data["bidding_zone"], u.data["fuel"])

    unitname, elecnode, fuelnode, data2 = basic_generator_unit(u, unittypes, fuels)
    
    data1 = Dict(
        :objects => [["unit", unitname], ],
        :relationships => [
            ["unit__to_node", [unitname, elecnode]],
            ["unit__from_node", [unitname, fuelnode]],
            ["unit__node__node", [unitname, elecnode, fuelnode]],
            ["units_on__temporal_block", [unitname, "hourly"]],
            ["units_on__stochastic_structure", [unitname, "deterministic"]],
        ],
        :object_parameter_values => [
            ["unit", unitname, "start_up_cost", 7000]
        ],
        :relationship_parameter_values => [
            ["unit__to_node", [unitname, elecnode], "unit_capacity", u.data["eleccapa"]],
            ["unit__to_node", [unitname, elecnode], "minimum_operating_point", 0.4],
            ["unit__node__node", [unitname, elecnode, fuelnode], 
                "fix_ratio_out_in_unit_flow", 0.9] 
        ]
    )

    # specify the nodes related to this unit
    if !haskey(nodes, elecnode)
        nodes[elecnode] = Dict("nodal_balance_sense" => "==", 
                                "balance_type" => "balance_type_node")
    end
    if !haskey(nodes, fuelnode)
        nodes[fuelnode] = Dict("nodal_balance_sense" => "==", 
                                "balance_type" => "balance_type_none")
    end

    return data1
end


function convert_unit(u::ocgt_unit, unittypes, fuels, nodes)
    return Dict{Symbol,Any}()
end