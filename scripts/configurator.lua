local solver = require("simplex")

-- Assists in creating a linear programming problem. Interprets the problem as a set of recipes
-- (each recipe is a column), and a recipe consumes (negative) and produces (positive) materials
-- (each material is a row).

--------------------------------------------------------------------------------
-- Enumerations
--------------------------------------------------------------------------------

local CompareType = {
  GREATER_OR_EQUAL = 1,
  EQUAL            = 2,
  LESS_OR_EQUAL    = 3,
}

local ObjectiveDirection = {
  MINIMIZE = 1,
  MAXIMIZE = 2,
}

--------------------------------------------------------------------------------
-- Internal utility functions
--------------------------------------------------------------------------------

-- Fatal error utility
local function fatal_error(msg)
  error("configurator error: " .. msg, 2)
end

-- Safely get a subtable; create if not present
local function get_or_create(tbl, key, default_constructor)
  local v = tbl[key]
  if not v then
    v = default_constructor()
    tbl[key] = v
  end
  return v
end

-- Make sure bounds are well-defined (0 and infinity by default)
local function finalize_bounds(bounds)
  if not bounds.xl then bounds.xl = 0 end
  if not bounds.xu then bounds.xu = math.huge end
end

--------------------------------------------------------------------------------
-- Create a new (empty) LP problem
--------------------------------------------------------------------------------
local function new_lp_problem()
  return {
    -- Maps each recipe name to a table holding its column index (in the LP) and its
    -- “used_materials” map of material_name -> coefficient.
    -- recipe_name -> {
    --    index: integer (column index),
    --    used_materials: { [material_name] = coeff, ... }
    -- }
    recipes = {},

    -- Preserves/Tracks the order of recipe insertion (helpful if you want to preserve order in
    -- the solution).
    recipe_list = {},

    -- Tracks lower and upper bounds for each recipe variable. Defaults to [0, +∞].
    -- recipe_name -> { xl = number, xu = number }
    recipe_bounds = {},

    next_recipe_index = 1,

    -- material_name -> {
    --   eq = number,     -- if EQUAL was specified
    --   le = number,     -- if LESS_OR_EQUAL was specified
    --   ge = number,     -- if GREATER_OR_EQUAL was specified
    -- }
    -- We'll allow at most one eq, at most one le, at most one ge per material.
    -- TODO if equal, can't have either of the others, and visa versa
    materials = {},

    -- Maps a recipe name to an objective coefficient. When minimizing the coefficient is
    -- positive; when maximizing, the coefficient is negative (since the solver is always in
    -- “minimize” mode internally).
    objectives = {},

    -- Preserves order of objective insertion if needed (though not strictly required for the
    -- final solution).
    objective_list = {},
  }
end

--------------------------------------------------------------------------------
-- Add a new recipe (column).
-- nonzero_entries is an array of { material_name, value } pairs
--------------------------------------------------------------------------------
local function add_recipe(lp, recipe_name, nonzero_entries)
  -- 3) Fatal error if this recipe name is already used
  if lp.recipes[recipe_name] then
    fatal_error(("Recipe '%s' is already defined."):format(recipe_name))
  end

  local col_index = lp.next_recipe_index
  lp.next_recipe_index = lp.next_recipe_index + 1

  -- Build a map of material->coefficient
  local used_materials = {}
  for _, entry in ipairs(nonzero_entries) do
    local mat_name, coeff = entry[1], entry[2]
    used_materials[mat_name] = coeff
  end

  lp.recipes[recipe_name] = {
    index = col_index,
    used_materials = used_materials,
  }
  table.insert(lp.recipe_list, recipe_name)

  -- Also ensure we have bounds structure prepped
  get_or_create(lp.recipe_bounds, recipe_name, function() return {} end)
end

--------------------------------------------------------------------------------
-- Constrain a material with one of: ≥, =, ≤
-- 2) We allow two constraints on the same material only if one is ≥ and one is ≤.
--    If eq is used, it can't be combined with ge or le for that material.
--------------------------------------------------------------------------------
local function constrain_material(lp, material_name, compare_type, value)
  local mt = get_or_create(lp.materials, material_name, function() return {} end)

  if compare_type == CompareType.EQUAL then
    if mt.eq then
      fatal_error(("Material '%s' already has an EQUAL constraint"):format(material_name))
    end
    -- If eq is set, cannot also have ge or le
    if mt.ge or mt.le then
      fatal_error(("Material '%s' cannot have EQUAL plus GE/LE"):format(material_name))
    end
    mt.eq = value
  elseif compare_type == CompareType.LESS_OR_EQUAL then
    if mt.eq or mt.le then
      fatal_error(("Material '%s' already has LE or EQ constraint"):format(material_name))
    end
    mt.le = value
  elseif compare_type == CompareType.GREATER_OR_EQUAL then
    if mt.eq or mt.ge then
      fatal_error(("Material '%s' already has GE or EQ constraint"):format(material_name))
    end
    mt.ge = value
  else
    fatal_error(("Unknown compare_type '%s' for material '%s'"):format(
      tostring(compare_type), material_name
    ))
  end
end

--------------------------------------------------------------------------------
-- Build up the objective function.
-- If direction == MINIMIZE, we add +weight to that recipe's coefficient.
-- If direction == MAXIMIZE, we add -weight to that recipe's coefficient.
--
-- Note: if optimize(some_recipe) is called more than once, the last call 'wins'
--------------------------------------------------------------------------------
local function optimize(lp, recipe_name, weight, direction)
  -- Determine coefficient based on direction
  local coeff
  if direction == ObjectiveDirection.MINIMIZE then
    coeff = weight
  elseif direction == ObjectiveDirection.MAXIMIZE then
    coeff = -weight
  else
    fatal_error(("Invalid objective direction for recipe '%s'"):format(recipe_name))
  end

  -- Overwrite any existing objective value
  lp.objectives[recipe_name] = coeff

  -- Only add to the ordered list on first optimization call
  local seen = false
  for _, name in ipairs(lp.objective_list) do
    if name == recipe_name then
      seen = true
      break
    end
  end
  if not seen then
    table.insert(lp.objective_list, recipe_name)
  end
end

--------------------------------------------------------------------------------
-- Set upper bound for a recipe
--------------------------------------------------------------------------------
local function set_upper(lp, recipe_name, limit)
  local b = get_or_create(lp.recipe_bounds, recipe_name, function() return {} end)
  b.xu = limit
end

--------------------------------------------------------------------------------
-- Set lower bound for a recipe
--------------------------------------------------------------------------------
local function set_lower(lp, recipe_name, limit)
  local b = get_or_create(lp.recipe_bounds, recipe_name, function() return {} end)
  b.xl = limit
end

--------------------------------------------------------------------------------
-- Constrain all materials that don't already have a constraint.
-- compare_type must be CompareType.GREATER_OR_EQUAL or CompareType.EQUAL.
-- at_least must be >= 0.
--------------------------------------------------------------------------------
local function constrain_unconstrained_materials(lp, compare_type, at_least)
  -- Validate at_least
  if at_least < 0 then
    fatal_error(("constrain_all_materials: at_least (%s) must be >= 0"):format(tostring(at_least)))
  end
  -- Validate compare_type
  if compare_type ~= CompareType.GREATER_OR_EQUAL
      and compare_type ~= CompareType.EQUAL then
    fatal_error(("constrain_all_materials: invalid compare_type (%s)"):format(tostring(compare_type)))
  end

  -- For each material seen in any recipe, if it has no constraint yet, add one
  for _, rdata in pairs(lp.recipes) do
    for mat_name in pairs(rdata.used_materials) do
      if not lp.materials[mat_name] then
        constrain_material(lp, mat_name, compare_type, at_least)
      end
    end
  end
end

--------------------------------------------------------------------------------
-- Builds the data structures expected by simplex.solve(), calls it, and
-- returns { objective = <number>, solution = { {recipe_name, rate}, ... } }.
--------------------------------------------------------------------------------
local function finalize(lp)

  -- It would also be reasonable to do =0. However, the user can do that, if they desire =0
  -- instead of >= 0.
  constrain_unconstrained_materials(lp, CompareType.GREATER_OR_EQUAL, 0)

  -- 1) Build material‐based constraints (eq + inequalities)
  local constraints = {}
  local function add_row(coeffs, rhs, is_eq)
    constraints[#constraints + 1] = { coeffs = coeffs, rhs = rhs, is_eq = is_eq }
  end

  -- Convert each material constraint into one or two rows
  for mat_name, cinfo in pairs(lp.materials) do
    if cinfo.eq then
      local row = {}
      for rname, rdata in pairs(lp.recipes) do
        local idx, v = rdata.index, (rdata.used_materials[mat_name] or 0)
        if math.abs(v) > 1e-14 then row[idx] = v end
      end
      add_row(row, cinfo.eq, true)
    else
      if cinfo.ge then
        local row = {}
        for rname, rdata in pairs(lp.recipes) do
          local idx, v = rdata.index, (rdata.used_materials[mat_name] or 0)
          if math.abs(v) > 1e-14 then row[idx] = -v end
        end
        add_row(row, -cinfo.ge, false)
      end
      if cinfo.le then
        local row = {}
        for rname, rdata in pairs(lp.recipes) do
          local idx, v = rdata.index, (rdata.used_materials[mat_name] or 0)
          if math.abs(v) > 1e-14 then row[idx] = v end
        end
        add_row(row, cinfo.le, false)
      end
    end
  end

  -- 2) Translate custom xl/xu bounds into extra rows
  for rname, rdata in pairs(lp.recipes) do
    local col = rdata.index
    local bnds = lp.recipe_bounds[rname]
    finalize_bounds(bnds)
    if bnds.xl > 0 then
      add_row({ [col] = -1 }, -bnds.xl, false)
    end
    if bnds.xu < math.huge then
      add_row({ [col] = 1 }, bnds.xu, false)
    end
  end

  -- 3) Build dense A matrix, RHS bvec, and slack variables for all ≤‐rows
  local nrec = lp.next_recipe_index - 1
  local slack_off = nrec
  local slack_cnt = 0
  for _, row in ipairs(constraints) do
    if not row.is_eq then slack_cnt = slack_cnt + 1 end
  end

  local nvars = nrec + slack_cnt
  local A, bvec = {}, {}

  -- assign slack column indices
  local sc = 0
  for _, row in ipairs(constraints) do
    if not row.is_eq then
      sc = sc + 1
      row.slack_col = slack_off + sc
    end
  end

  -- populate A and bvec
  for i, row in ipairs(constraints) do
    local Ai = {}
    for j = 1, nvars do Ai[j] = 0 end
    for col, v in pairs(row.coeffs) do
      Ai[col] = v
    end
    if not row.is_eq then
      Ai[row.slack_col] = 1
    end
    A[i], bvec[i] = Ai, row.rhs
  end

  -- 4) Build cost vector
  local c_vals = {}
  for j = 1, nvars do c_vals[j] = 0 end
  for rname, coeff in pairs(lp.objectives) do
    local col = lp.recipes[rname].index
    c_vals[col] = coeff
  end

  -- 5) Call the dense Simplex solver
  local status, x_sol, obj = solver.solve(A, bvec, c_vals)

  -- 6) Map back to recipe‐name → rate
  local solution = {}
  for _, rname in ipairs(lp.recipe_list) do
    local col = lp.recipes[rname].index
    solution[rname] = x_sol[col]
  end

  return status, solution, obj
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------
return {
  new_lp_problem     = new_lp_problem,
  add_recipe         = add_recipe,
  constrain_material = constrain_material,
  optimize           = optimize,
  set_upper          = set_upper,
  set_lower          = set_lower,
  finalize           = finalize,
  CompareType        = CompareType,
  ObjectiveDirection = ObjectiveDirection,
}
