-- This implements the Simplex method of Linear Programming optimization.
-- It's a classic full-tableau two-phase implementation, matrix stored dense form, and it
-- maintains the full cost row.
-- For Lua 5.2
--
-- See simplex.solve below.

local simplex = {}

--------------------------------------------------------------------------------
-- Enumerations & Constants
--------------------------------------------------------------------------------
simplex.Status = {
  OPTIMAL    = 1,
  UNBOUNDED  = 2,
  INFEASIBLE = 3,
}

local TOLERANCE = 2 ^ -20 -- tolerance for zero‐comparisons

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

-- Zero out tiny entries to avoid numerical drift
local function zero_small(T)
  for i = 1, #T do
    for j = 1, #T[i] do
      if math.abs(T[i][j]) < TOLERANCE then
        T[i][j] = 0
      end
    end
  end
end

-- Perform a pivot on T at (row = r, col = c)
local function do_pivot(T, r, c)
  local m, n = #T - 1, #T[1] - 1
  local pivot_val = T[r][c]

  -- normalize pivot row
  for j = 1, n + 1 do
    T[r][j] = T[r][j] / pivot_val
  end

  -- eliminate in other rows
  for i = 1, m + 1 do
    if i ~= r then
      local factor = T[i][c]
      if math.abs(factor) > TOLERANCE then
        for j = 1, n + 1 do
          T[i][j] = T[i][j] - factor * T[r][j]
        end
      end
    end
  end

  zero_small(T)
end

-- Choose entering column: the most negative reduced cost < –tol
local function choose_entering(T)
  local cost_row = #T
  local n = #T[1] - 1
  local best_col, best_val = nil, -TOLERANCE
  for j = 1, n do
    local rc = T[cost_row][j]
    if rc < -TOLERANCE and rc < best_val then
      best_val, best_col = rc, j
    end
  end
  return best_col
end

-- Ratio test: among rows with T[i][c] > tol, pick minimal RHS/T[i][c]
local function choose_leaving(T, c)
  local m, rhs_col = #T - 1, #T[1]
  local best_row, best_ratio = nil, math.huge
  for i = 1, m do
    local a = T[i][c]
    if a > TOLERANCE then
      local ratio = T[i][rhs_col] / a
      if ratio < best_ratio or (math.abs(ratio - best_ratio) < TOLERANCE and i < best_row) then
        best_ratio, best_row = ratio, i
      end
    end
  end
  return best_row
end

-- Core simplex loop with basis‐history detection
-- Returns (status, final_tableau, basis)
local function simplex_core(T, basis)
  local seen = {}

  -- Records the basis, and returns true if it's never been seen before, otherwise returns
  -- false. Prevents cycles
  local function record(b)
    local m = #T - 1
    local copy = {}
    for i = 1, m do
      assert(b[i] ~= nil,
        ("simplex_core: basis[%d] is nil"):format(i))
      copy[i] = b[i]
    end
    table.sort(copy)
    local key = table.concat(copy, ",")
    if seen[key] then return false end
    seen[key] = true
    return true
  end

  -- record initial basis
  if not record(basis) then
    return simplex.Status.INFEASIBLE, T, basis
  end

  while true do
    local e = choose_entering(T)
    if not e then
      return simplex.Status.OPTIMAL, T, basis
    end

    local l = choose_leaving(T, e)
    if not l then
      return simplex.Status.UNBOUNDED, T, basis
    end

    do_pivot(T, l, e)
    basis[l] = e

    if not record(basis) then
      return simplex.Status.INFEASIBLE, T, basis
    end
  end
end

--------------------------------------------------------------------------------
-- Phase I setup
--------------------------------------------------------------------------------

-- Build Phase I tableau, initial basis, and list of artificial columns
-- detect and reuse slack cols, add artificials only as needed
local function build_phase1(A, b, costs)
  local m, n = #A, #A[1]

  -- validate dimensions
  assert(#b == m,
    ("build_phase1: #b (%d) must equal number of rows of A (%d)"):format(#b, m))
  assert(#costs == n,
    ("build_phase1: #costs (%d) must equal number of cols of A (%d)"):format(#costs, n))

  -- ensure all RHS ≥ 0 by flipping rows when needed
  for i = 1, m do
    if b[i] < 0 then
      for j = 1, n do
        A[i][j] = -A[i][j]
      end
      b[i] = -b[i]
    end
  end


  -- 1) detect existing basic (slack) columns: unit cols with zero cost
  local basic = {} -- row -> col
  local used  = {} -- col -> true
  for j = 1, n do
    if costs[j] == 0 then
      local pivot_row
      for i = 1, m do
        if A[i][j] == 1 then
          if pivot_row then
            pivot_row = nil; break
          end
          pivot_row = i
        elseif A[i][j] ~= 0 then
          pivot_row = nil; break
        end
      end
      if pivot_row and not basic[pivot_row] then
        basic[pivot_row] = j
        used[j] = true
      end
    end
  end

  -- pre-create all tableau rows so our identity‐fill never hits nil
  local T1       = {}
  local art_of   = {} -- row -> artificial col index
  local next_col = n
  for _ = 1, m do
    table.insert(T1, {})
  end

  -- now fill each row (but don’t yet put in b)
  for i = 1, m do
    -- copy original A
    for j = 1, n do
      T1[i][j] = A[i][j]
    end
    -- if this row has no slack basic, create one artificial
    if not basic[i] then
      next_col  = next_col + 1
      art_of[i] = next_col
      basic[i]  = next_col
      -- fill identity entry in that column
      for k = 1, m do
        T1[k][next_col] = (k == i) and 1 or (T1[k][next_col] or 0)
      end
    end
  end

  -- place all RHS values in the single rightmost column
  local rhs_col = next_col + 1
  for i = 1, m do
    T1[i][rhs_col] = b[i]
  end

  -- 3) cost row: (c_j – sum_i T1[i][j])  where c_j = 1 for any art and 0 otherwise
  -- Only subtract the rows where you actually added an artificial variable (art_of),
  -- so if a row already had a slack (and no artificial), its cost‐row contribution is
  -- zero—leaving all original/slack reduced costs at 0 and Phase I immediately optimal.
  local total_cols = next_col
  T1[m + 1] = {}
  for j = 1, total_cols do
    -- Only artificial rows should contribute to the Phase I cost
    local sum = 0
    for row in pairs(art_of) do
      sum = sum + (T1[row][j] or 0)
    end
    -- mark j as artificial if it’s beyond the original n and wasn’t a reused slack
    local is_art = (j > n) and not used[j]
    local c_j    = is_art and 1 or 0
    T1[m + 1][j] = c_j - sum
  end

  -- 4) Phase I objective value = sum of b for rows with artificials
  local sum_b = 0
  for row in pairs(art_of) do
    sum_b = sum_b + b[row]
  end
  T1[m + 1][total_cols + 1] = sum_b

  -- 5) assemble basis & art_cols list
  local basis               = basic
  local art_cols            = {}
  for row, col in pairs(art_of) do
    table.insert(art_cols, col)
  end
  -- sort so {4,5,6,…} always comes back in ascending order
  table.sort(art_cols)
  T1.art_cols = art_cols
  return T1, basis, art_cols
end

-- Remove artificial columns, pivoting out any that stayed basic
local function purge_artificial(T, basis, art_cols)
  local m, old_n = #T - 1, #T[1] - 1
  local n = old_n - #art_cols

  -- pivot out any artificial still in basis
  for i = 1, m do
    if basis[i] > n then
      local pivoted = false
      for j = 1, n do
        if math.abs(T[i][j]) > TOLERANCE then
          do_pivot(T, i, j)
          basis[i] = j
          pivoted = true
          break
        end
      end
      if not pivoted then
        -- no non-zero in this row; pick first real column to preserve valid basis
        basis[i] = 1
      end
    end
  end

  -- rebuild without artificial cols
  local col_map, new_j = {}, 1
  -- build set for fast art-col testing
  local art_set = {}
  for _, ac in ipairs(art_cols) do art_set[ac] = true end

  for j = 1, old_n do
    if not art_set[j] then
      col_map[j] = new_j
      new_j = new_j + 1
    end
  end

  -- rebuild tableau without art cols
  local T2 = {}
  for i = 1, m do
    T2[i] = {}
    for oldj, newj in pairs(col_map) do
      T2[i][newj] = T[i][oldj]
    end
    T2[i][new_j] = T[i][old_n + 1] -- RHS
  end
  T2[m + 1] = {}
  for oldj, newj in pairs(col_map) do
    T2[m + 1][newj] = T[m + 1][oldj]
  end
  T2[m + 1][new_j] = T[m + 1][old_n + 1]

  -- remap basis indices
  for i = 1, m do
    basis[i] = col_map[basis[i]]
  end

  -- clean up any tiny numerical noise before Phase II
  zero_small(T2)

  return T2, basis
end

--------------------------------------------------------------------------------
-- Phase II objective reset
--------------------------------------------------------------------------------

-- Reinitialize bottom row to the true cost c, then subtract
-- basic-cost * each basic row to get correct reduced costs.
local function reset_phase2_objective(T, costs, basis)
  local m, n = #T - 1, #T[1] - 1
  -- initialize reduced costs to c_j
  for j = 1, n do
    T[m + 1][j] = costs[j]
  end
  T[m + 1][n + 1] = 0

  -- subtract basic contributions
  for i = 1, m do
    local bcol = basis[i]
    local c_b  = costs[bcol]
    if c_b ~= 0 then
      for j = 1, n + 1 do
        T[m + 1][j] = T[m + 1][j] - c_b * T[i][j]
      end
    end
  end

  zero_small(T)
end

local function init_phase2(T1f, basis1f, art_cols, costs)
  local T2, basis2 = purge_artificial(T1f, basis1f, art_cols)
  reset_phase2_objective(T2, costs, basis2)
  return T2, basis2
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--- Solves a linear programming problem:
-- mininimze 𝐜ᵀ·x  subject to  𝐀𝐱 = 𝐛, 𝐱 ≥ 0.
-- @param 𝐀  dense matrix as 𝐀[row][col], 1-based indices, size m×n
-- @param 𝐛  target vector, length m
-- @param 𝐜  cost vector, length n
-- @return   simplex.Status, 𝐱, objective value (𝐜ᵀ·x)
--
-- Note: 𝐱 is a vector of length n
--
-- See simplex_spec for examples
function simplex.solve(A, b, costs)
  -- validate dimensions
  assert(type(A) == "table" and #A > 0,
    "solve: A must be a non-empty matrix")
  assert(#b == #A,
    ("solve: #b (%d) must equal number of rows of A (%d)"):format(#b, #A))
  assert(#costs == #A[1],
    ("solve: #costs (%d) must equal number of cols of A (%d)"):format(#costs, #A[1]))

  -- build Phase I (now reuses any existing slack cols)
  local T1, basis1, art_cols = build_phase1(A, b, costs)
  -- run Phase I
  local status1, T1f, basis1f = simplex_core(T1, basis1)
  -- recompute art‐sum objective
  do
    local m = #A
    local n = #T1f[1] - 1
    local art_sum = 0
    for _, art in ipairs(art_cols) do
      for i = 1, m do
        if basis1f[i] == art then
          art_sum = art_sum + T1f[i][n + 1]
          break
        end
      end
    end
    T1f[m + 1][n + 1] = art_sum
  end
  if status1 ~= simplex.Status.OPTIMAL or T1f[#A + 1][#T1f[1]] > TOLERANCE then
    return simplex.Status.INFEASIBLE
  end

  local T2, basis2 = init_phase2(T1f, basis1f, art_cols, costs)

  -- run Phase II
  local status2, Tf, basisf = simplex_core(T2, basis2)
  if status2 == simplex.Status.UNBOUNDED then
    return simplex.Status.UNBOUNDED
  elseif status2 ~= simplex.Status.OPTIMAL then
    return simplex.Status.INFEASIBLE
  end

  -- extract solution
  local n = #T2[1] - 1
  local x = {}
  for j = 1, n do x[j] = 0 end
  for i = 1, #A do
    x[basisf[i]] = Tf[i][n + 1]
  end
  local raw_obj = Tf[#A + 1][n + 1]
  -- bottom‐right holds –(cᵀ x), so flip sign
  return simplex.Status.OPTIMAL, x, -raw_obj
end

--------------------------------------------------------------------------------
-- Debug namespace (expose internals for testing)
--------------------------------------------------------------------------------
simplex.debug = {
  zero_small             = zero_small,
  do_pivot               = do_pivot,
  choose_entering        = choose_entering,
  choose_leaving         = choose_leaving,
  purge_artificial       = purge_artificial,
  init_phase2            = init_phase2,
  reset_phase2_objective = reset_phase2_objective,
}

-- Debug wrapper for build_phase1: tags each artificial column with its row.
function simplex.debug.build_phase1(A, b, costs)
  local T1, basis, art_cols = build_phase1(A, b, costs)
  -- only constraint rows 1..m (cost row is m+1)
  local m = #T1 - 1
  local art_rows = {}
  for _, ac in ipairs(art_cols) do
    for i = 1, m do
      if T1[i][ac] == 1 then
        art_rows[#art_rows + 1] = i
        break
      end
    end
  end
  T1.art_rows = art_rows
  return T1, basis, art_cols
end

-- Wrap simplex_core to recompute Phase I objective when art_cols present
do
  local core = simplex_core
  function simplex.debug.simplex_core(T, basis)
    local status, T2, basis2 = core(T, basis)
    if T.art_cols then
      local m = #T2 - 1
      local n = #T2[1] - 1
      -- recompute all reduced costs for Phase I
      for j = 1, n do
        local sum = 0
        for _, i in ipairs(T.art_rows) do
          sum = sum + (T2[i][j] or 0)
        end
        -- cost is 1 for artificial cols, 0 otherwise
        local is_art = false
        for _, ac in ipairs(T.art_cols) do
          if ac == j then
            is_art = true; break
          end
        end
        T2[m + 1][j] = (is_art and 1 or 0) - sum
      end
      -- now recompute RHS as sum of basic‐artificial bᵢ
      local art_sum = 0
      for _, art in ipairs(T.art_cols) do
        for i = 1, m do
          if basis2[i] == art then
            art_sum = art_sum + T2[i][n + 1]
            break
          end
        end
      end
      T2[m + 1][n + 1] = art_sum
    end
    return status, T2, basis2
  end
end

return simplex
