using YAML
using DataFrames, CSV


function read_timeseries(filename, mappingfile, attribute=nothing)
    
    #original data
    a = DataFrame(CSV.File(filename, 
                            missingstring = "", 
                            dateformat="yyyy-mm-dd HH:MM:SS",
                            stringtype = String)
                )
    # filter original data
    if !isnothing(attribute)
        a = subset(a, attribute[1] => ByRow(==(attribute[2])))
    end

    b = DataFrame(time = a.time)

    # read the columns mapping file and select columns
    regionmap = CSV.File(mappingfile) |> Dict
    for (key, valcol) in regionmap
        insertcols!(b, key =>  a[:,valcol])
    end
            
    # filter by time
    begintime = DateTime(2010,1,1)
    endtime = DateTime(2018,1,1)
    b = subset(b, :time => ByRow(>=(begintime)), 
                    :time => ByRow(<(endtime))             
                )

    # convert values to float
    #b = transform(b, Not(:time) .=> x -> parse.(Float32, x), renamecols = false)

    return b
end


function readunits(filename, scenario, year)

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
    
    # extract the dictionary of parameters for the scenario
    params = filter(x->x["year"] == year && x["scenario"] == scenario, 
                    inputdata["parameters"])[1]["scenario_parameters"]
    println(params)
    
    # data structure for spinedb
    units_spi = Dict{Symbol,Any}()

    # internal nodes dict
    nodes = Dict()

    # for each unit create the data structure    
    for u1 in unitlist["scenario_units"]
        
        u = createunitstruct(u1)
        println(u1)
        d1 = convert_unit(u, unittypes["scenario_unittypes"], 
                            fuels["scenario_fuels"], 
                            nodes,
                            params)
        units_spi = mergedicts(units_spi,d1)
    end 


    return units_spi, nodes
end

function readlines(filename, scenario, year)

    # Load YAML data from a file
    inputdata = YAML.load_file(filename)

    # extract the list of units for the scenario
    linelist = filter(x->x["year"] == year && x["scenario"] == scenario, 
                    inputdata["lines"])[1]
    
    # data structure for spinedb
    lines_spi = Dict{Symbol,Any}()

    # for each unit create the data structure    
    for l in linelist["scenario_lines"]
        d1 = convert_line(l)
        lines_spi = mergedicts(lines_spi,d1)
    end 

    return lines_spi
end

function readparams(filename, scenario, year)

    # Load YAML data from a file
    inputdata = YAML.load_file(filename)

    # extract the list of units for the scenario
    params1 = filter(x->x["year"] == year && x["scenario"] == scenario, 
                    inputdata["parameters"])[1]
    
    return params1["scenario_parameters"]
end

