using Revise

using SpineOpt, SpineInterface
using Infiltrator

module Y
    using SpineInterface
end


function runmodel()
    file_path_in = "output/test_in.sqlite"
    file_path_out = "output/my_test_out.sqlite"

    url_in = "sqlite:///$file_path_in"
    url_out = "sqlite:///$file_path_out"

    m = run_spineopt(url_in, url_out; log_level=3)
end

function checkresults()
    file_path_out = "output/my_test_out.sqlite"
    url_out = "sqlite:///$file_path_out"
    using_spinedb(url_out, Y)

    cost_key = (model=Y.model(:instance), report=Y.report(:report_x))
    flow_key = (
        report=Y.report(:report_x),
        unit=Y.unit(:u_OCGT_gas_FI00),
        node=Y.node(:n_FI00_elec),
        direction=Y.direction(:to_node),
        stochastic_scenario=Y.stochastic_scenario(:parent),
    )


    println(Y.unit_flow(;flow_key...))
end




m = runmodel()



