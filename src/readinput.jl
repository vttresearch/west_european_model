using YAML




function readinput(filename, scenario, year)

    # Load YAML data from a file
    inputdata = YAML.load_file(filename)

    # extract the list of units for the scenario
    unitlist = filter(x->x["year"] == year && x["scenario"] == scenario, 
        inputdata["units"])[1]
    # extract the list of unit type definitions for the scenario
    unittypes = filter(x->x["year"] == year && x["scenario"] == scenario, 
        inputdata["unittypes"])[1]
    # extract the list of fuel definitions for the scenario
    fuels = filter(x->x["year"] == year && x["scenario"] == scenario, 
        inputdata["fuels"])[1]

    # data structure for spinedb
    units_spi = Dict{Symbol,Any}()

    # internal nodes dict
    nodes = Dict()

    # for each unit create the data structure    
    for u1 in unitlist["scenario_units"]
        
        u = createunitstruct(u1)
        print(u)
        d1 = convert_unit(u, unittypes["scenario_unittypes"], 
                            fuels["scenario_fuels"], 
                            nodes)
        units_spi = mergedicts(units_spi,d1)
    end 

    return units_spi
end

