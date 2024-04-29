
using SpineOpt
using SpineInterface
using Dates
#using PyCall
using CSV
using Plots

include("utils.jl")

# load model definition
include("connectdef.jl")


# ----------- -----------
# Run model

rm(file_path_out; force=true)
m = run_spineopt(url_in, url_out; log_level=0)

using_spinedb(url_out, Y)

cost_key = (model=Y.model(:instance), report=Y.report(:report_x))
flow_key = (
    report=Y.report(:report_x),
    unit=Y.unit(:u_chp1),
    node=Y.node(:n_elec),
    direction=Y.direction(:to_node),
    stochastic_scenario=Y.stochastic_scenario(:parent),
)

connflowkey = (
    report=Y.report(:report_x),
    connection=Y.connection(:c_elemar),
    node=Y.node(:n_elec),
    direction=Y.direction(:to_node),
    stochastic_scenario=Y.stochastic_scenario(:parent)
)
connflowkey2 = (
    report=Y.report(:report_x),
    connection=Y.connection(:c_elemar),
    node=Y.node(:n_elecmarket),
    direction=Y.direction(:to_node),
    stochastic_scenario=Y.stochastic_scenario(:parent)
)


#println(Y.connection_flow(;connflowkey...))
#println(Y.connection_flow(;connflowkey2...))

    
println( connection_flow_cost[(connection=connection(:"c_elemar"),
                             node=node(:n_elecmarket), 
                             direction=direction(:to_node), 
                             stochastic_scenario=stochastic_scenario(:parent)
                             )] )

println( connection_flow_cost[(connection=connection(:"c_elemar"),
                             node=node(:n_elecmarket), 
                             direction=direction(:from_node), 
                             stochastic_scenario=stochastic_scenario(:parent)
                             )] )
    
            

println("variable_om_costs $(tssum(Y.objective_variable_om_costs(;report=Y.report(:report_x)) ))")
println("connection_Flow_costs $(tssum(Y.objective_connection_flow_costs(;report=Y.report(:report_x)) ))")

totcost = tssum(Y.objective_connection_flow_costs(;report=Y.report(:report_x)) ) +
     tssum(Y.objective_variable_om_costs(;report=Y.report(:report_x)) ) +
     tssum(Y.objective_start_up_costs(;report=Y.report(:report_x)) )

println("totcost $totcost")


#=
flow_key1 = (
    report=Y.report(:report_x),
    unit=Y.unit(:u_chp1),
    node=Y.node(:n_elec),
    direction=Y.direction(:to_node),
    stochastic_scenario=Y.stochastic_scenario(:parent),
)

flow_key2 = (
    report=Y.report(:report_x),
    unit=Y.unit(:u_lpturbine),
    node=Y.node(:n_elec),
    direction=Y.direction(:to_node),
    stochastic_scenario=Y.stochastic_scenario(:parent),
)

temp = plot_stackedTimeSeries((Y.unit_flow(; flow_key1...),
                        Y.unit_flow(; flow_key2...),
                        ),
                        ("mp turbine", "lp tubrine"))
=#

#=
units_started_key = (
    report=Y.report(:report_x),
    unit=Y.unit(:u_chp1),
    stochastic_scenario=Y.stochastic_scenario(:parent),
)

units_on_key = (
    report=Y.report(:report_x),
    unit=Y.unit(:u_chp1),
    stochastic_scenario=Y.stochastic_scenario(:parent),
)

plot_TimeSeries(Y.units_on(; units_on_key...))
=#
#Y.units_started_up(; units_started_key...)


#=
Ways to create time series inputs

index = Dict("start" => "2022-01-01T00:00:00", "resolution" => "1 hour")
vom_cost_data = [21.0 for k in 0:100]
vom_cost = Dict("type" => "time_series", "data" => PyVector(vom_cost_data), "index" => index)

["unit__to_node", ["u_heatpump", "n_heat"], "vom_cost", vom_cost]

demand_vals = [2 * k for k in 0:72]
demand_inds = collect(DateTime(1999, 12, 31):Hour(1):DateTime(2000, 1, 3))
demand = TimeSeries(demand_inds, demand_vals, false, false)
["node", "n_heat", "demand", unparse_db_value(demand)],


=#