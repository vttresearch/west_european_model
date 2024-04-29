
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