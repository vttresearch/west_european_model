
function makemodel(filenames)

    # read the electrical load for bidding zones
    elecload = read_elecload(filenames["elecloadfile"], 
                            filenames["loadmappingfile"])

    # read the onshore wind cf for bidding zones

    units_spi, nodes = readunits(filenames["mainmodel"], "Distributed Energy", 2040)

    nodes_spi = preparenodes(nodes, elecload, nothing, nothing)
  

end

function create_spine_db(a)
    file_path_in = "output/test_in.sqlite"
    url_in = "sqlite:///$file_path_in"

    #remove old versions
    rm(file_path_in; force=true)

    _load_test_data(url_in, a)
end
