local heating_boiler = table.deepcopy(data.raw["boiler"]["boiler"])
heating_boiler.name = "heating-boiler"
heating_boiler.mode = "heat-water-inside"
data:extend({ heating_boiler })
