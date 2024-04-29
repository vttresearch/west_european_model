module Y
    using SpineInterface
end

#url_in = "sqlite://"
#url_in = "sqlite:///test_in.sqlite"
file_path_out = "$(@__DIR__)/test_out.sqlite"
file_path_in = "$(@__DIR__)/test_in.sqlite"
url_out = "sqlite:///$file_path_out"
url_in = "sqlite:///$file_path_in"

#remove old versions
rm(file_path_in; force=true)

#db_api.create_new_spine_database(url_in)

# set other input data
elysis_heat_capture =  0 #0.16
elysis_capa_h2 = 150
h2_demand = 100
pri_elec_factor = 1.0
capa_bioboil_factor = 1.0
capa_chp_bp_elec = 170 - (capa_bioboil_factor - 1) * 50
storage_factor = 1

# Set up basic systems
test_data = Dict(
    :objects => [
        ["model", "instance"],
        ["temporal_block", "hourly"],
        ["stochastic_structure", "deterministic"],
        ["node", "n_biomass"],
        ["node", "n_oil"],
        ["node", "n_elec"],
        ["node", "n_heat"],
        ["node", "n_hydrogen"],
        ["node", "n_elecmarket"],
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
       
        ["model__temporal_block", ["instance", "hourly"]],
        ["model__stochastic_structure", ["instance", "deterministic"]],
        ["node__temporal_block", ["n_biomass", "hourly"]],
        ["node__temporal_block", ["n_oil", "hourly"]],
        ["node__temporal_block", ["n_elec", "hourly"]],
        ["node__temporal_block", ["n_heat", "hourly"]],
        ["node__temporal_block", ["n_hydrogen", "hourly"]],
        ["node__temporal_block", ["n_elecmarket", "hourly"]],
        ["node__stochastic_structure", ["n_biomass", "deterministic"]],
        ["node__stochastic_structure", ["n_oil", "deterministic"]],
        ["node__stochastic_structure", ["n_elec", "deterministic"]],
        ["node__stochastic_structure", ["n_heat", "deterministic"]],
        ["node__stochastic_structure", ["n_hydrogen", "deterministic"]],
        ["node__stochastic_structure", ["n_elecmarket", "deterministic"]],
        ["stochastic_structure__stochastic_scenario", ["deterministic", "parent"]],
       

    ],
    :object_parameter_values => [
        #["model", "instance", "model_start", Dict("type" => "date_time", "data" => "2022-01-01T00:00:00")],
        ["model", "instance", "model_start", unparse_db_value(DateTime(2019,1,1))],
        ["model", "instance", "model_end", unparse_db_value(DateTime(2019,1,5))],
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
       
        ["node", "n_elecmarket", "balance_type", "balance_type_none"],
     
    ]

)

_load_test_data(url_in, test_data)


# -----------
# Add unit u_1
data1 = Dict(
    :objects => [["unit", "u_1"], ],
    :relationships => [
        ["unit__to_node", ["u_1", "n_elec"]],
        ["units_on__temporal_block", ["u_1", "hourly"]],
        ["units_on__stochastic_structure", ["u_1", "deterministic"]],
    ],
   
    :relationship_parameter_values => [
        ["unit__to_node", ["u_1", "n_elec"], "unit_capacity", 5], 
    ]
)

SpineInterface.import_data(url_in; data1...)

# ----------- -----------
# Add connections to electricity market
numconnections = 2

if numconnections == 1
    
    data1 = Dict(
        :objects => [["connection", "c_elemar"]],
        :relationships => [
            ["connection__from_node", ["c_elemar", "n_elec"]],
            ["connection__from_node", ["c_elemar", "n_elecmarket"]],
            ["connection__to_node", ["c_elemar", "n_elecmarket"]],
            ["connection__to_node", ["c_elemar", "n_elec"]],
            ["connection__node__node", ["c_elemar", "n_elecmarket", "n_elec"]],
            ["connection__node__node", ["c_elemar", "n_elec", "n_elecmarket"]],
        ],
        :relationship_parameter_values => [
            ["connection__node__node", ["c_elemar", "n_elecmarket", "n_elec"], "fix_ratio_out_in_connection_flow", 1.0],
            ["connection__node__node", ["c_elemar", "n_elec", "n_elecmarket"], "fix_ratio_out_in_connection_flow", 1.0],
            ["connection__to_node", ["c_elemar", "n_elec"], "connection_capacity", 500],
            ["connection__to_node", ["c_elemar", "n_elec"], "connection_conv_cap_to_flow", 1.0],
            ["connection__to_node", ["c_elemar", "n_elecmarket"], "connection_capacity", 500],
            ["connection__to_node", ["c_elemar", "n_elecmarket"], "connection_conv_cap_to_flow", 1.0],
            ["connection__to_node", ["c_elemar", "n_elecmarket"], "connection_flow_cost", -1.0],
            ["connection__from_node", ["c_elemar", "n_elecmarket"], "connection_flow_cost", 0],

            ["connection__from_node", ["c_elemar", "n_elecmarket"], "connection_capacity", 500],
            ["connection__from_node", ["c_elemar", "n_elec"], "connection_capacity", 500],  
        ]
    )
elseif numconnections == 2
    data1 = Dict(
        :objects => [["connection", "c_elemar_export"],
                    ["connection", "c_elemar_import"]],
        :relationships => [
            ["connection__from_node", ["c_elemar_export", "n_elec"]],
            ["connection__from_node", ["c_elemar_import", "n_elecmarket"]],
            ["connection__to_node", ["c_elemar_export", "n_elecmarket"]],
            ["connection__to_node", ["c_elemar_import", "n_elec"]],
            ["connection__node__node", ["c_elemar_export", "n_elecmarket", "n_elec"]],
            ["connection__node__node", ["c_elemar_import", "n_elec", "n_elecmarket"]],
        ],
        :relationship_parameter_values => [
            ["connection__node__node", ["c_elemar_export", "n_elecmarket", "n_elec"], "fix_ratio_out_in_connection_flow", 1.0],
            ["connection__node__node", ["c_elemar_import", "n_elec", "n_elecmarket"], "fix_ratio_out_in_connection_flow", 1.0],
            ["connection__to_node", ["c_elemar_import", "n_elec"], "connection_capacity", 500],
            ["connection__to_node", ["c_elemar_import", "n_elec"], "connection_conv_cap_to_flow", 1.0],
            ["connection__to_node", ["c_elemar_export", "n_elecmarket"], "connection_capacity", 500],
            ["connection__to_node", ["c_elemar_export", "n_elecmarket"], "connection_conv_cap_to_flow", 1.0],
            ["connection__to_node", ["c_elemar_export", "n_elecmarket"], "connection_flow_cost", -1.0],
            ["connection__from_node", ["c_elemar_import", "n_elecmarket"], "connection_flow_cost", 0], 

            ["connection__from_node", ["c_elemar_export", "n_elec"], "connection_capacity", 500],
        ]
    )
end

SpineInterface.import_data(url_in; data1...)
