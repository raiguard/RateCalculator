local calc_util = require("scripts.calc.util")

return function(rates, entity, emissions_per_second, prototypes)
  local entity_prototype = entity.prototype
  local entity_productivity_bonus = entity.productivity_bonus
  local entity_speed_bonus = entity.speed_bonus

  -- look for resource entities under the drill
  local position = entity.position
  local radius = entity_prototype.mining_drill_radius + 0.01
  local resource_entities = entity.surface.find_entities_filtered{
    area = {
      left_top = {
        x = position.x - radius,
        y = position.y - radius
      },
      right_bottom = {
        x = position.x + radius,
        y = position.y + radius
      }
    },
    type = "resource"
  }
  local resource_entities_len = #resource_entities
  if resource_entities_len == 0 then return emissions_per_second end

  -- process entities
  local resources = {}
  local num_resource_entities = 0
  for i = 1, resource_entities_len do
    local resource = resource_entities[i]
    local resource_name = resource.name

    -- check if this resource has already been processed
    local resource_data = resources[resource_name]
    if resource_data then
      resource_data.occurrences = resource_data.occurrences + 1
      num_resource_entities = num_resource_entities + 1
    else
      local resource_prototype = resource.prototype

      -- check if this resource can be mined by this drill
      if entity_prototype.resource_categories[resource_prototype.resource_category] then
        num_resource_entities = num_resource_entities + 1
        local mineable_properties = resource_prototype.mineable_properties

        -- add data to table
        resources[resource_name] = {
          occurrences = 1,
          products = mineable_properties.products,
          required_fluid = nil,
          mining_time = mineable_properties.mining_time
        }
        resource_data = resources[resource_name]

        -- account for infinite resource yield
        if resource_prototype.infinite_resource then
          resource_data.mining_time = (
            resource_data.mining_time / (resource.amount / resource_prototype.normal_resource_amount)
          )
        end

        -- add required fluid
        local required_fluid = mineable_properties.required_fluid
        if required_fluid then
          resource_data.required_fluid = {
            name = required_fluid,
            amount = mineable_properties.fluid_amount / 10 -- ten mining operations per consumed
          }
        end
      end
    end
  end

  -- process resource entities
  if num_resource_entities > 0 then
    local drill_multiplier = (
      entity_prototype.mining_speed * (entity_speed_bonus + 1) * (entity_productivity_bonus + 1)
    )

    -- iterate each resource
    for _, resource_data in pairs(resources) do
      local resource_multiplier =  (
        (drill_multiplier / resource_data.mining_time) * (resource_data.occurrences / num_resource_entities)
      )

      -- add required fluid to inputs
      local required_fluid = resource_data.required_fluid
      if required_fluid then
        -- productivity does not apply to ingredients
        local fluid_per_second = required_fluid.amount * resource_multiplier / (entity_productivity_bonus + 1)

        -- add to inputs table
        local fluid_name = required_fluid.name
        calc_util.add_rate(
          rates.materials,
          "input",
          "fluid",
          fluid_name,
          prototypes.fluid[fluid_name].localised_name,
          fluid_per_second
        )
      end

      -- iterate each product
      for _, product in pairs(resource_data.products) do
        -- get rate per second for this product on this drill
        local product_per_second
        if product.amount then
          product_per_second = product.amount * resource_multiplier
        else
          product_per_second = (
            (product.amount_max - ((product.amount_max - product.amount_min) / 2)) * resource_multiplier
          )
        end

        -- add to outputs table
        local product_type = product.type
        local product_name = product.name
        local product_localised_name = prototypes[product_type][product_name].localised_name
        calc_util.add_rate(
          rates.materials,
          "output",
          product_type,
          product_name,
          product_localised_name,
          product_per_second
        )
      end
    end
  end

  return emissions_per_second
end
