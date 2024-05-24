using DataFrames
using CSV, Dates


function create_series_constant(starttime, timestep, length, val)
    a = DataFrame(time = collect(range(starttime, step = timestep, length = length)),
                    value = val)    
    return a
end

function calc_hourofyear(x::DataFrame;_year = nothing)

    if isnothing(_year)
        x = transform(x, :time => ByRow(x -> Int(Year(x)/Year(1))) => :year)
        x = transform(x, AsTable([:time, :year]) 
            => ByRow(x -> (convert(Dates.Hour, x[1] - DateTime(x[2], 1, 1)) ) )
            => :hourofyear)
        x = select(x, Not([:year]))
    else
        x = transform(x, AsTable([:time]) 
            => ByRow(x -> (convert(Dates.Hour, x[1] - DateTime(_year, 1, 1)) ) )
            => :hourofyear)
    end

    return x
end

"""
 Extend time series data by copying existing data
"""
function extend_series(d, begintime, copyyear; endtime = nothing, includeorig = false)

    # select a single year (and a bit more for leap years) 
    # from original data for copying
    d2 = subset(d, :time => ByRow(>=(DateTime(copyyear,1,1))), 
                    :time => ByRow(<(DateTime(copyyear,1,1) + Day(367)))             
                )
    d2 = calc_hourofyear(d2, _year = copyyear)

    # determine the time period to be covered
    if isnothing(endtime)
        endtime = minimum(d[:,:time]) - Hour(1)
    end
    a = DataFrame(time = collect(begintime:Hour(1):endtime) )
    
    # join series based on hour of year
    a = calc_hourofyear(a)
    d2 = select(d2, Not([:time]))
    a = leftjoin(a, d2, on = :hourofyear)
    a = select(a, Not([:hourofyear]))
    
    # combine the extended part
    if includeorig == true
        a = vcat(a,d)
    end
    
    return a
end

"""
 Convert the Italy and some other load areas
 for this you need the ts_load_IT.csv, which you can download 
 from entso-e using the entsoe-py library
"""
function process_IT_load(;write = false)

    elecloadfile = "input/ts_load_IT.csv"

    #original data
    a = DataFrame(CSV.File(elecloadfile, 
                            missingstring = "", 
                            dateformat="yyyy-mm-dd HH:MM:SS",
                            stringtype = String))

    b = extend_series(a, DateTime(2010,1,1), 2017, includeorig = true)
    println(first(b,6))

    if write == true
        CSV.write("input/ts_load_IT_ext.csv", b,  dateformat="yyyy-mm-dd HH:MM:SS")
    end
    return b
end


function convertload()

    elecloadfile = "input/summary_load_2011-2020-1h.csv"
    outputfile = "input/ts_load_all.csv"

    #original data
    a = DataFrame(CSV.File(elecloadfile, 
                            missingstring = "", 
                            dateformat="yyyy-mm-dd HH:MM:SS",
                            stringtype = String)
                )
    
    #convert the Norway load areas
    transform!(a, [:NO_1, :NO_2, :NO_5] => (+) => :NOS0)
    transform!(a, :NO_3 => identity => :NOM1)
    transform!(a, :NO_4  => identity => :NON1)

    #denmark
    transform!(a, :DK_1 => identity => :DKW1)
    transform!(a, :DK_2 => identity => :DKE1)

    # combine Italy and some others into the same table
    b = process_IT_load()
    a = innerjoin(a, b, on = :time)

    # write result
    CSV.write(outputfile, a,  dateformat="yyyy-mm-dd HH:MM:SS")
end

function process_hydrolimits()

    filename = "input/summary_hydro_reservoir_limits_2015_2016_1h_MWh.csv"
    outputfile = "input/ts_reservoir_limits.csv"

       #original data
       a = DataFrame(CSV.File(filename, 
        missingstring = "", 
        dateformat="yyyy-mm-dd HH:MM:SS",
        stringtype = String))

    b = extend_series(a, DateTime(2010,1,1), 2015, endtime = DateTime(2019,12,31))
    println(first(b[:,1:5],6))

    # write result
    CSV.write(outputfile, b,  dateformat="yyyy-mm-dd HH:MM:SS")

end




#convertload()
process_hydrolimits()