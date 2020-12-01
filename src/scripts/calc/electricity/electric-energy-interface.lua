local calc_util = require("scripts.calc.util")

return function(rates, entity)
  local production = entity.power_production
  local usage = entity.power_usage

  local entity_name = entity.name

  if production > 0 then
    calc_util.add_rate(rates.outputs, "entity", entity_name, entity.prototype.localised_name, production)
  end
  if usage > 0 then
    calc_util.add_rate(rates.inputs, "entity", entity_name, entity.prototype.localised_name, usage)
  end
end
