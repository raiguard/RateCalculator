--
-- FixedPrecisionFormat v4.0.0 by SilverAzide
--
-- This work is licensed under a Creative Commons Attribution-Noncommercial-Share Alike 3.0 License.
--
-- This work has been modified from its original form to work as a Lua module, and remove Rainmeter-
-- specific documentation.
----------------------------------------------------------------------------------------------------

local math = math
local string = string

local asSuffix = { " ", " k", " M", " G", " T", " P", " E", " Z", " Y" }

return function(sInputValue, sPrecision, sFactor)
  --
  -- This function formats a number using a "fixed precision, variable scale" methodology.
  --
  -- Where:  sInputValue = value to be formatted
  --         sPrecision  = numeric scale
  --         sFactor     = scale factor ("0", "1", "1k", "2", "2k")
  --
  -- Examples:  sInputValue = 3.141592654, sPrecision = 7, sFactor = "1":  output = "3.141593 "
  --            sInputValue = 31.41592654, sPrecision = 7, sFactor = "1":  output = "31.41593 "
  --            sInputValue = 314.1592654, sPrecision = 7, sFactor = "1":  output = "314.1593 "
  --            sInputValue = 3141.592654, sPrecision = 7, sFactor = "1":  output = "3.141593 k"
  --            sInputValue = 31415926.54, sPrecision = 7, sFactor = "1":  output = "31.41593 M"
  --            sInputValue = 31415926.54, sPrecision = 4, sFactor = "1":  output = "31.42 M"
  --            sInputValue = 31415926.54, sPrecision = 3, sFactor = "1":  output = "31.4 M"
  --            sInputValue = 31415926.54, sPrecision = 2, sFactor = "1":  output = "31 M"
  --            sInputValue = 31415926.54, sPrecision = 1, sFactor = "1":  output = "31 M" (precision too small)
  --            sInputValue = 3141.592654, sPrecision = 7, sFactor = "0":  output = "3141.593 "
  --

  -- initialize local vars
  local nDigitsAfterDecimal = 0
  local nDigitsBeforeDecimal = 0
  local nDivCount = 1
  local nDivisor = 1024.0
  local sPattern = ""
  local sText = ""

  --
  -- validate input parameters
  --
  local nValue = tonumber(sInputValue)

  -- validate Scale
  local nPrecision = math.floor(tonumber(sPrecision)) or 3
  if nPrecision > 0 then
    -- OK
  else
    -- invalid input
    nPrecision = 3
  end

  -- validate Factor and set divisor if needed
  if sFactor == "1" or sFactor == "1k" then
    -- OK
  elseif sFactor == "2" or sFactor == "2k" then
    nDivisor = 1000.0
  else
    sFactor = "0"
    nDivisor = 1.0
  end

  --
  -- format the value as text
  --

  -- if minimum value is K, divide value by divisor
  if sFactor == "1k" or sFactor == "2k" then
    nValue = nValue / nDivisor
    nDivCount = nDivCount + 1
  end

  while (math.abs(nValue) > nDivisor and nDivCount < 9 and nDivisor > 1.0) do
    nValue = nValue / nDivisor
    nDivCount = nDivCount + 1
  end

  nDigitsBeforeDecimal = math.max(1, math.floor(math.log10(math.abs(nValue))) + 1)
  nDigitsAfterDecimal = math.max(0, nPrecision - nDigitsBeforeDecimal)

  -- get formatting directive
  sPattern = "%." .. nDigitsAfterDecimal .. "f"

  -- format the number
  sText = string.format(sPattern, nValue) .. asSuffix[nDivCount]

  return sText
end
