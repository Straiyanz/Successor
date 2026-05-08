local _, ns = ...

local reset = '|r'
local start = '|cff'

function RedText(text)
  return string.concat(start, 'ff0000', text, reset)
end

function LightBlueText(text)
  return string.concat(start, '00CCCC', text, reset)
end
