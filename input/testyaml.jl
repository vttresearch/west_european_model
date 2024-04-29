using YAML

# Load YAML data from a file
data = YAML.load_file("example.yaml")

# Print the loaded data
println(data)

filter(x->x["year"] == 2040, data["units"])
