local calc_util = require("scripts.calc.util")

return function(rates, entity)
  local entity_type = entity.type
  local entity_prototype = entity.prototype

  local max_energy_usage = entity_prototype.max_energy_usage
  local electric_energy_source_prototype = entity_prototype.electric_energy_source_prototype
  if
    entity_type ~= "burner-generator"
    and entity_type ~= "electric-energy-interface"
    and electric_energy_source_prototype
    and max_energy_usage
    and max_energy_usage > 0
  then
    local consumption_bonus = (entity.consumption_bonus + 1)
    success = true
    calc_util.add_rate(
      rates.inputs,
      "entity",
      entity.name,
      entity_prototype.localised_name,
      (max_energy_usage * consumption_bonus) + electric_energy_source_prototype.drain
    )
  end

  local max_energy_production = entity_prototype.max_energy_production
  if max_energy_production > 0 then
    if max_energy_production > 0 then
      local entity_name = entity.name
      calc_util.add_rate(rates.outputs, "entity", entity_name, entity_prototype.localised_name, max_energy_production)
      success = true
    end
  end
end