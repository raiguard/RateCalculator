local calc_util = require("scripts.calc.util")

return function(rates, entity, emissions_per_second)
  local entity_prototype = entity.prototype
  local added_emissions = 0

  -- electric energy interfaces can have their settings adjusted at runtime, so checking the energy source is pointless
  -- they also don't produce pollution whatsoever, despite their energy source emissions setting
  if entity.type == "electric-energy-interface" then
    local production = entity.power_production
    local usage = entity.power_usage

    local entity_name = entity.name

    if production > 0 then
      calc_util.add_rate(rates, "output", "entity", entity_name, entity.prototype.localised_name, production)
    end
    if usage > 0 then
      calc_util.add_rate(rates, "input", "entity", entity_name, entity.prototype.localised_name, usage)
    end
  else
    local electric_energy_source_prototype = entity_prototype.electric_energy_source_prototype

    local max_energy_usage = entity_prototype.max_energy_usage or 0
    if electric_energy_source_prototype and max_energy_usage > 0 then
      local consumption_bonus = (entity.consumption_bonus + 1)
      local drain = electric_energy_source_prototype.drain
      local amount = max_energy_usage * consumption_bonus
      if max_energy_usage ~= drain then
        amount = amount + drain
      end
      calc_util.add_rate(
        rates,
        "input",
        "entity",
        entity.name,
        entity_prototype.localised_name,
        amount
      )
      added_emissions = electric_energy_source_prototype.emissions * (max_energy_usage * consumption_bonus) * 60
    end

    local max_energy_production = entity_prototype.max_energy_production
    if max_energy_production > 0 then
      if max_energy_production > 0 then
        local entity_name = entity.name
        calc_util.add_rate(
          rates,
          "output",
          "entity",
          entity_name,
          entity_prototype.localised_name,
          max_energy_production
        )
      end
    end
  end

  return emissions_per_second + added_emissions
end