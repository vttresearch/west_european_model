Creation of the European energy market model for SpineOpt
===

# Preparations

Install Julia version 1.10 or greater.

Make sure you have the needed input data in input folder. This includes

* PECD CSV files for renewables capacity factors.

You can get them from Koivisto, Matti Juhani; Murcia Leon, Juan Pablo (2022). Pan-European wind and solar generation time series (PECD 2021 update). Technical University of Denmark. Collection. https://doi.org/10.11583/DTU.c.5939581.v3

* summary_hydro CSV files for hydropower
* summary_load CSV file for electrical load
* DH time series summary CSV file

You can get them from the vttresearch/north_european_model repository.

Run the command
```
>using Pkg
>Pkg.instantiate()
```

to install dependencies.

Run the scripts in **processinput** folder to render some time series in more suitable format.

# Starting the model data creation

Run **build_example.jl**. This will result in a model database saved in **output** folder.
