
using SpineInterface, SpineOpt
using Dates
using DataFrames
using Printf
using Plots

function mergedicts(dicts...)
    n = length(dicts)

    a = mergedicts(dicts[1],dicts[2])

    for i = 3:n
        a = mergedicts(a, dicts[i])
    end
    
    return a
end


function mergedicts(dict1,dict2)

    # Find keys in dict1 only
    d1keys = setdiff(keys(dict1), keys(dict2))
    combined_dict = Dict{Symbol,Any}(key => dict1[key] for key in d1keys)

    
    # Find keys in dict2 only
    d2keys = setdiff(keys(dict2), keys(dict1))
    for key in d2keys
        combined_dict[key] = dict2[key] 
    end

    # Find the common keys between the two dictionaries
    common_keys = intersect(keys(dict1), keys(dict2))

    # Create a new dictionary with the common keys and their concatenated values
    for key in common_keys
        combined_dict[key] = [dict1[key]; dict2[key]] 
    end

    return combined_dict
end

function load_template(db_url, outputs)
    data = Dict(Symbol(key) => value for (key, value) in SpineOpt.template())
    filter_v07_template_by_output(data, outputs)
    _load_test_data_without_template(db_url, data)
end

# Convenience function for resetting the test in-memory db with the `SpineOpt.template`.
function _load_test_data(db_url, test_data)
    #data = Dict(Symbol(key) => value for (key, value) in SpineOpt.template())
    #merge!(data, test_data)
    outputs = [d[2] for d in test_data[:objects] if d[1] == "output"]
    load_template(db_url, outputs)
    #filter_v07_template_by_output(data, outputs)
    #println(data[:objects])

    #for d in data[:relationship_classes]
    #    if in("output", d[2])
    #        println(d)
    #    end
    #end
    _load_test_data_without_template(db_url, test_data)
end

function _load_test_data_without_template(db_url, test_data)
    SpineInterface.close_connection(db_url)
    SpineInterface.open_connection(db_url)
    SpineInterface.import_data(db_url, test_data, "importing")
end

function filter_v07_template_by_output(data::Dict, outputs::Array{String,1})

    data[:objects] = filter(vec -> vec[1] != "output" || (vec[1] == "output" && in(vec[2], outputs)), 
        data[:objects])
end

function convert_timeseries(x::DataFrame, valcol = :value)

    x.time = DateTime.(x.time)
    y = TimeSeries(x[:,:time], x[:,valcol], false, false)     
end

function plot_TimeSeries(x::TimeSeries)
    plot(x.indexes, x.values)
end

function tssum(x::TimeSeries)
    return sum(x.values)
end