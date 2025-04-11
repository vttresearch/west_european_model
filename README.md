Creation the the European energy market model for SpineOpt
===

# Preparations

Make sure you have the needed input data in input folder. This includes

* PECD CSV files for renewables capacity factors.
* summary_hydro CSV files for hydropoewr
* summary_load CSV file for electrical load
* DH time series summary CSV file

Run the scripts in **processinput** folder to render some time series in more suitable format.

# Starting the model data creation

Run **build_example.jl**. This will result in a model database saved in **output** folder.
