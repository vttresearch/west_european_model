
abstract type unit end

struct backpressure_unit <: unit
    data::Dict
end

struct boiler_unit <: unit
    data::Dict
end

struct hp_unit <: unit
    data::Dict
end

struct nuclear_unit <: unit
    data::Dict
end

struct pv_unit <: unit
    data::Dict
end

struct onshore_unit <: unit
    data::Dict
end

struct condensing_unit <: unit
    data::Dict
end

struct hydro_reservoir_unit <: unit
    data::Dict
end

struct hydro_openloop_unit <: unit
    data::Dict
end

struct battery_unit <: unit
    data::Dict
end

struct drcurtail_unit <: unit
    data::Dict
end

struct mustrun_unit <: unit
    data::Dict
end

function createunitstruct(u1::Dict)

    if u1["type"] == "nuclear" return nuclear_unit(u1)
    elseif u1["type"] == "PV" return pv_unit(u1)
    elseif u1["type"] == "onshore" return onshore_unit(u1)
    elseif u1["type"] == "offshore" return onshore_unit(u1)
    elseif u1["type"] == "OCGT" return condensing_unit(u1)
    elseif u1["type"] == "CCGT" return condensing_unit(u1)
    elseif u1["type"] == "steam-turbine" return condensing_unit(u1)
    elseif u1["type"] == "reservoir" return hydro_reservoir_unit(u1)
    elseif u1["type"] == "open-loop" return hydro_openloop_unit(u1)
    elseif u1["type"] == "closed-loop" return hydro_openloop_unit(u1)    
    elseif u1["type"] == "ror" return hydro_reservoir_unit(u1)
    elseif u1["type"] == "boiler" return boiler_unit(u1)
    elseif u1["type"] == "backpressure" return backpressure_unit(u1)
    elseif u1["type"] == "combined-cycle-chp" return backpressure_unit(u1)
    elseif u1["type"] == "elecboiler" return hp_unit(u1)
    elseif u1["type"] == "heatpump" return hp_unit(u1)
    elseif u1["type"] == "battery" return battery_unit(u1)
    elseif u1["type"] == "DR-curtail-elec" return drcurtail_unit(u1)
    elseif u1["type"] == "industrial-CHP" return mustrun_unit(u1)
    else
        throw(ArgumentError(u1["type"] ))
    end

end

function createunitname(type, bzone)
    return "u_" * bzone * "_" * type 
end

function createunitname(type, bzone, fuel)
    return "u_" * bzone * "_" * type * "_" * fuel 
end

function createbzone_elecname(bzone)
    return "n_" * bzone * "_elec"
end

function createbzone_fuelname(bzone, fuel)
    return "n_" * fuel
end

function createheatnodename(bzone, heatarea)
    return "n_" * bzone * (isnothing(heatarea) ? "" : "_" * heatarea) * "_dheat"
end

function makeunits(unitlist, unittypes, fuels, ts_data, params)

    # data structure for spinedb
    units_spi = Dict{Symbol,Any}()

    # internal nodes dict
    nodes = Dict()

    # for each unit create the data structure    
    for u1 in unitlist["scenario_units"]
        
        u = createunitstruct(u1)
        d1 = convert_unit(u, unittypes["scenario_unittypes"], 
                            fuels["scenario_fuels"], 
                            ts_data,
                            nodes,
                            params)
        units_spi = mergedicts(units_spi,d1)
    end 


    return units_spi, nodes
end

function basic_generator_unit(u::unit, unittypes, fuels, params; 
                addfuelname = false, outputvector = "elec")

    unitname = addfuelname ? createunitname(u.data["type"], u.data["bidding_zone"], u.data["fuel"]) :
                        createunitname(u.data["type"], u.data["bidding_zone"])
    elecnode = createbzone_elecname(u.data["bidding_zone"])
    fuelnode = createbzone_fuelname(u.data["bidding_zone"], u.data["fuel"])

    vom_cost = unittypes[u.data["type"]]["vom_cost"]
    fuelcost = fuels[u.data["fuel"]]["price"] +
                 params["co2_price"] * fuels[u.data["fuel"]]["co2_content"] * 3600 * 1e-6 #from g/MJ to t/MWh

    subunits = get(u.data, "subunits",1)
    subunitcapa = u.data["eleccapa"] / subunits

    efficiency = get(unittypes[u.data["type"]], "efficiency", nothing)

    # min stable generation level
    minoppoint = get(unittypes[u.data["type"]], "min_oper_point", nothing)

    # ramp limit (up and down)
    ramp_limit = get(unittypes[u.data["type"]], "ramp_limit", nothing)

    onlinetype = get(u.data, "unit_commitment","unit_online_variable_type_linear")
    if onlinetype == "integer"
        onlinetype = "unit_online_variable_type_integer"
    end

    # for this type, startup cost is given per MW elec (default is zero)
    startupcost = subunitcapa * get(unittypes[u.data["type"]], "startup_cost", 0)

    data1 = Dict(
        :objects => [["unit", unitname], ],
        :object_parameter_values => [
            ["unit", unitname, "start_up_cost", startupcost],
            ["unit", unitname, "online_variable_type", onlinetype],
        ],
        :relationships => [
            ["unit__to_node", [unitname, elecnode]],
            ["unit__from_node", [unitname, fuelnode]],
            ["unit__node__node", [unitname, elecnode, fuelnode]],
            ["units_on__temporal_block", [unitname, "hourly"]],
            ["units_on__stochastic_structure", [unitname, "deterministic"]],
        ],
        :relationship_parameter_values => [
            ["unit__to_node", [unitname, elecnode], "unit_capacity", subunitcapa],
            ["unit__to_node", [unitname, elecnode], "vom_cost", vom_cost],    
        ]
    )

    rpv = []

    if !isnothing(minoppoint)
        push!(rpv, ["unit__to_node", [unitname, elecnode], "minimum_operating_point", minoppoint])
    end

    if fuelcost != 0
        push!(rpv, ["unit__from_node", [unitname, fuelnode], "vom_cost", fuelcost])
    end

    if !isnothing(ramp_limit)
        push!(rpv, ["unit__to_node", [unitname, elecnode], "ramp_up_limit", ramp_limit])
        push!(rpv, ["unit__to_node", [unitname, elecnode], "ramp_down_limit", ramp_limit])
    end

    if !isnothing(efficiency)
        push!(rpv, ["unit__node__node", [unitname, elecnode, fuelnode], 
        "fix_ratio_out_in_unit_flow", efficiency] )
    else
        # set piecewise heat rate
        heat_rate = get(unittypes[u.data["type"]], "heat_rate", nothing)
        op_points = get(unittypes[u.data["type"]], "op_points", nothing)
        if !isnothing(heat_rate)
            push!(rpv, ["unit__node__node", [unitname, fuelnode, elecnode], 
                "fix_ratio_in_out_unit_flow",  
                Dict("type" => "array", "value_type" => "float", "data" => heat_rate)] )
            push!(rpv, ["unit__to_node", [unitname, elecnode], "operating_points", 
                Dict("type" => "array", "value_type" => "float", "data" => op_points)])
        end
    end

    data1 = mergedicts(data1, Dict(:relationship_parameter_values => rpv))

    return unitname, elecnode, fuelnode, data1
end

function basic_boiler_unit(u::unit, unittypes, fuels, nodes, params; addfuelname = false)

    unitname = addfuelname ? createunitname(u.data["type"], u.data["bidding_zone"], u.data["fuel"]) :
                    createunitname(u.data["type"], u.data["bidding_zone"])
    heatnode = createheatnodename(u.data["bidding_zone"], u.data["heat_area"])
    fuelnode = createbzone_fuelname(u.data["bidding_zone"], u.data["fuel"])

    vom_cost = unittypes[u.data["type"]]["vom_cost"]
    fuelcost = fuels[u.data["fuel"]]["price"]
    efficiency = unittypes[u.data["type"]]["efficiency_heat"]

    data1 = Dict(
        :objects => [["unit", unitname], ],
        :relationships => [
            ["unit__to_node", [unitname, heatnode]],
            ["unit__from_node", [unitname, fuelnode]],
            ["unit__node__node", [unitname, heatnode, fuelnode]],
            ["units_on__temporal_block", [unitname, "hourly"]],
            ["units_on__stochastic_structure", [unitname, "deterministic"]],
        ],
        :relationship_parameter_values => [
            ["unit__to_node", [unitname, heatnode], "unit_capacity", u.data["heatcapa"]],
            ["unit__to_node", [unitname, heatnode], "vom_cost", vom_cost],    
            ["unit__from_node", [unitname, fuelnode], "vom_cost", fuelcost],
            ["unit__node__node", [unitname, heatnode, fuelnode], 
                "fix_ratio_out_in_unit_flow", efficiency],
        ]
    )

    # specify the nodes related to this unit
    if !haskey(nodes, heatnode)
        nodes[heatnode] = Dict("type" => "dheat")
    end
    if !haskey(nodes, fuelnode)
        nodes[fuelnode] = Dict("type" => "fuel")
    end

    return data1
end


function convert_unit(u::boiler_unit, unittypes, fuels, ts_data, nodes, params)

    return basic_boiler_unit(u, unittypes, fuels, nodes, params, addfuelname = true)

end

function convert_unit(u::hp_unit, unittypes, fuels, ts_data, nodes, params)

    unitname = createunitname(u.data["type"], u.data["bidding_zone"])
    heatnode = createheatnodename(u.data["bidding_zone"], u.data["heat_area"])
    elecnode = createbzone_elecname(u.data["bidding_zone"])

    vom_cost = unittypes[u.data["type"]]["vom_cost"]
    efficiency = unittypes[u.data["type"]]["efficiency_heat"]

    data1 = Dict(
        :objects => [["unit", unitname], ],
        :relationships => [
            ["unit__to_node", [unitname, heatnode]],
            ["unit__from_node", [unitname, elecnode]],
            ["unit__node__node", [unitname, heatnode, elecnode]],
            ["units_on__temporal_block", [unitname, "hourly"]],
            ["units_on__stochastic_structure", [unitname, "deterministic"]],
        ],
        :relationship_parameter_values => [
            ["unit__to_node", [unitname, heatnode], "unit_capacity", u.data["heatcapa"]],
            ["unit__to_node", [unitname, heatnode], "vom_cost", vom_cost],    
            ["unit__node__node", [unitname, heatnode, elecnode], 
                "fix_ratio_out_in_unit_flow", efficiency],
        ]
    )

    # specify the nodes related to this unit
    if !haskey(nodes, heatnode)
        nodes[elecnode] = Dict("type" => "dheat")
    end
    if !haskey(nodes, elecnode)
        nodes[fuelnode] = Dict("type" => "elec")
    end

    return data1
end

function convert_unit(u::backpressure_unit, unittypes, fuels, ts_data, nodes, params)

    unitname, elecnode, fuelnode, data1 = basic_generator_unit(u, unittypes, fuels, params, addfuelname = true)
    heatnode = createheatnodename(u.data["bidding_zone"], u.data["heat_area"])
    efficiency_elec = unittypes[u.data["type"]]["efficiency_elec"]
    p_h_ratio = unittypes[u.data["type"]]["power_heat_ratio"]

    # additional unit data related to this unittype
    data2 = Dict(
        :relationships => [["unit__to_node", [unitname, heatnode]],
                            ["unit__node__node", [unitname, elecnode, heatnode]],
        ],
        :relationship_parameter_values => [
            ["unit__node__node", [unitname, elecnode, fuelnode], 
                "fix_ratio_out_in_unit_flow", efficiency_elec],
            ["unit__node__node", [unitname, elecnode, heatnode], 
                "fix_ratio_out_out_unit_flow", p_h_ratio]  
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
    if !haskey(nodes, heatnode)
        nodes[heatnode] = Dict("type" => "dheat")
    end
    return data1
end

function convert_unit(u::nuclear_unit, unittypes, fuels, ts_data, nodes, params)

    unitname, elecnode, fuelnode, data1 = basic_generator_unit(u, unittypes, fuels, params)
    
    subunits = get(u.data, "subunits",1)
    
    # check if units_unavailable has been defined
    if hasproperty(ts_data["units_unavailable"], unitname)
        units_unavailable = convert_timeseries(ts_data["units_unavailable"], unitname)
    else
        units_unavailable = 0
    end

    # additional unit data related to this unittype
    data2 = Dict(
        :object_parameter_values => [
            ["unit", unitname, "number_of_units", subunits],
            ["unit", unitname, "units_unavailable", unparse_db_value(units_unavailable)],
        ],
     
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


function convert_unit(u::condensing_unit, unittypes, fuels, ts_data, nodes, params)

    unitname, elecnode, fuelnode, data1 = basic_generator_unit(u, unittypes, fuels, params, addfuelname = true)
 

    #data2 = Dict(:relationship_parameter_values => rpv)
    
    #data1 = mergedicts(data1, data2)

    # specify the nodes related to this unit
    if !haskey(nodes, elecnode)
        nodes[elecnode] = Dict("type" => "elec")
    end
    if !haskey(nodes, fuelnode)
        nodes[fuelnode] = Dict("type" => "fuel")
    end

    return data1
end


function storage_unit_wo_charge(u::unit, unittypes, nodes, params; outputvector = "elec")

    unitname = createunitname(u.data["type"], u.data["bidding_zone"])
    if outputvector == "elec"
        outputnode = createbzone_elecname(u.data["bidding_zone"])
    elseif outputvector == "heat"
        outputnode = createheatnodename(u.data["bidding_zone"], u.data["heat_area"])
    else
        throw(ArgumentError(outputvector ))
    end
    reservoirnode = "n_" * u.data["bidding_zone"] * "_" * u.data["type"]

    vom_cost = unittypes[u.data["type"]]["vom_cost"]

    # check if reservoir initial status has been defined
    a = filter(x->x["bidding_zone"] == u.data["bidding_zone"] && x["type"] == u.data["type"], 
                    params["unit_initial_status"])
    if length(a) == 1
        inilevel = a[1]["reservoir_level"]
    elseif length(a) == 0
        inilevel = nothing
    else
        throw(DomainError(a, "ambiguous unit initial status!"))
    end

    data1 = Dict(
        :objects => [["unit", unitname], ],
        :relationships => [
            ["unit__to_node", [unitname, outputnode]],
            ["unit__from_node", [unitname, reservoirnode]],
            ["unit__node__node", [unitname, outputnode, reservoirnode]],
            ["units_on__temporal_block", [unitname, "hourly"]],
            ["units_on__stochastic_structure", [unitname, "deterministic"]],
        ],
        :relationship_parameter_values => [
            ["unit__to_node", [unitname, outputnode], "unit_capacity", u.data["eleccapa"]],
            ["unit__to_node", [unitname, outputnode], "vom_cost", vom_cost], 
            ["unit__node__node", [unitname, outputnode, reservoirnode], 
                "fix_ratio_out_in_unit_flow", 1.0]    
        ]
    )

    # specify the nodes related to this unit
    # node type is according to the specific hydro type
    if !haskey(nodes, outputnode)
        nodes[outputnode] = Dict("type" => outputvector)
    end
    if !haskey(nodes, reservoirnode)
        nodes[reservoirnode] = Dict("type" => u.data["type"],
                                "reservoir_capacity" => u.data["reservoir_capacity"],
                                "reservoir_initial_level" => inilevel
        )
    end

    return data1, unitname, outputnode, reservoirnode
end

function storage_unit(u::unit, unittypes, fuels, ts_data, nodes, params; outputvector = "elec")

    data1, unitname, elecnode, reservoirnode = storage_unit_wo_charge(u, unittypes, nodes, params, outputvector = outputvector)

    # next add the pump unit
    unitname = "u_" * u.data["bidding_zone"] * "_" * u.data["type"] * "_pump" 
    efficiency = unittypes[u.data["type"]]["efficiency"]
    pumpcapa = get(u.data, "pumpcapa", 0)

    data2 = Dict(
        :objects => [["unit", unitname], ],
        :relationships => [
            ["unit__to_node", [unitname, reservoirnode]],
            ["unit__from_node", [unitname, elecnode]],
            ["unit__node__node", [unitname, reservoirnode, elecnode]],
            ["units_on__temporal_block", [unitname, "hourly"]],
            ["units_on__stochastic_structure", [unitname, "deterministic"]],
        ],
        :relationship_parameter_values => [
            ["unit__to_node", [unitname, reservoirnode], "unit_capacity", pumpcapa],
            ["unit__node__node", [unitname, reservoirnode, elecnode], 
                "fix_ratio_out_in_unit_flow", efficiency]    
        ]
    )

    data1 = mergedicts(data1, data2)
end

function convert_unit(u::hydro_openloop_unit, unittypes, fuels, ts_data, nodes, params)
    storage_unit(u, unittypes, fuels, ts_data, nodes, params)
end

function convert_unit(u::battery_unit, unittypes, fuels, ts_data, nodes, params)
    
    if haskey(u.data, "chargingcapa")
        u.data["pumpcapa"] = u.data["chargingcapa"]
    end
    storage_unit(u, unittypes, fuels, ts_data, nodes, params)
end

function convert_unit(u::hydro_reservoir_unit, unittypes, fuels, ts_data, nodes, params)

    data1,_,_,_ = storage_unit_wo_charge(u, unittypes, nodes, params)

    return data1
end

function convert_unit(u::drcurtail_unit, unittypes, fuels, ts_data, nodes, params)

    if !haskey(fuels, "drfuel")
        drfuel = Dict("price" => 0, "co2_content" => 0 )
        fuels["drfuel"] = drfuel
    end

    u.data["fuel"] = "drfuel"
    outputvector = unittypes[u.data["type"]]["vector"]
    base_cost = unittypes[u.data["type"]]["base_cost"]

    unitname, outputnode, fuelnode, data1 = basic_generator_unit(u, unittypes, fuels, params, outputvector = outputvector)
 
    rpv = [["unit__from_node", [unitname, fuelnode], "vom_cost", base_cost]]
    rships = [["unit__node__node", [unitname, fuelnode, outputnode]] ]
    data1 = mergedicts(data1, Dict(:relationship_parameter_values => rpv))
    data1 = mergedicts(data1, Dict(:relationships => rships))

    # specify the nodes related to this unit
    if !haskey(nodes, outputnode)
        nodes[outputnode] = Dict("type" => outputvector)
    end
    if !haskey(nodes, fuelnode)
        nodes[fuelnode] = Dict("type" => "fuel")
    end
    
    return data1
end

function convert_unit(u::mustrun_unit, unittypes, fuels, ts_data, nodes, params)

    outputvector = get(unittypes[u.data["type"]], "vector", "elec")
    minoppoint = get(unittypes[u.data["type"]], "min_oper_point", 0) 

    unitname, outputnode, fuelnode, data1 = basic_generator_unit(u, unittypes, fuels, params, outputvector = outputvector)
 
    #rpv = [["unit__to_node", [unitname, outputnode], "minimum_operating_point", minoppoint],
     #       ]
    #data1 = mergedicts(data1, Dict(:relationship_parameter_values => rpv))
   
    opv = [["unit", unitname, "fix_units_on", 1],
            ["unit", unitname, "min_down_time", Dict("type" => "duration", "data" => "1h")]
        ]
    data1 = mergedicts(data1, Dict(:object_parameter_values => opv))

    # specify the nodes related to this unit
    if !haskey(nodes, outputnode)
        nodes[outputnode] = Dict("type" => outputvector)
    end
    if !haskey(nodes, fuelnode)
        nodes[fuelnode] = Dict("type" => "fuel")
    end
    
    return data1
end

function basic_vre_unit(u::unit, unittypes, nodes, params)

    unitname = createunitname(u.data["type"], u.data["bidding_zone"])
    elecnode = createbzone_elecname(u.data["bidding_zone"])
    vrenode = "n_" * u.data["bidding_zone"] * "_" * u.data["type"]

    vom_cost = unittypes[u.data["type"]]["vom_cost"]

    data1 = Dict(
        :objects => [["unit", unitname], ],
        :relationships => [
            ["unit__to_node", [unitname, elecnode]],
            ["unit__from_node", [unitname, vrenode]],
            ["unit__node__node", [unitname, elecnode, vrenode]],
            ["units_on__temporal_block", [unitname, "hourly"]],
            ["units_on__stochastic_structure", [unitname, "deterministic"]],
        ],
        :relationship_parameter_values => [
            ["unit__to_node", [unitname, elecnode], "unit_capacity", u.data["eleccapa"]],
            ["unit__to_node", [unitname, elecnode], "vom_cost", vom_cost], 
            ["unit__node__node", [unitname, elecnode, vrenode], 
                "fix_ratio_out_in_unit_flow", 1.0]    
        ]
    )

    # specify the nodes related to this unit
    if !haskey(nodes, elecnode)
        nodes[elecnode] = Dict("type" => "elec")
    end
    if !haskey(nodes, vrenode)
        nodes[vrenode] = Dict("type" => u.data["type"],
                            "unit_capacity" => u.data["eleccapa"]
                                )
    end

    return data1
end

function convert_unit(u::onshore_unit, unittypes, fuels, ts_data, nodes, params)
    return basic_vre_unit(u, unittypes, nodes, params)
end

function convert_unit(u::pv_unit, unittypes, fuels, ts_data, nodes, params)
    return basic_vre_unit(u, unittypes, nodes, params)
end


function convert_line(line)

    linename = "L_" * line["from_zone"] * "_" * line["to_zone"] 
    to_zone_node = createbzone_elecname(line["to_zone"])
    from_zone_node = createbzone_elecname(line["from_zone"])

    data1 = Dict(
        :objects => [["connection", linename]],
        :relationships => [
            ["connection__from_node", [linename, from_zone_node]],
            ["connection__from_node", [linename, to_zone_node]],
            ["connection__to_node", [linename, to_zone_node]],
            ["connection__to_node", [linename, from_zone_node]],
            ["connection__node__node", [linename, from_zone_node, to_zone_node]],
            ["connection__node__node", [linename, to_zone_node, from_zone_node]],
        ],
        :relationship_parameter_values => [
            ["connection__node__node", [linename, to_zone_node, from_zone_node], "fix_ratio_out_in_connection_flow", 0.99],
            ["connection__node__node", [linename, from_zone_node, to_zone_node], "fix_ratio_out_in_connection_flow", 0.99],
            ["connection__to_node", [linename, to_zone_node], "connection_capacity", line["export_capacity"]],
            ["connection__to_node", [linename, from_zone_node], "connection_capacity", line["import_capacity"]],
     
        ]
    )
end

