local _, ns = ...

-- UNUSED FILE

local COLOR_GREY = { r = 0.5, g = 0.5, b = 0.5 }
local COLOR_GREEN = { r = 0, g = 1, b = 0 }
local COLOR_BLUE = { r = 0, g = 0.5, b = 1 }
local COLOR_PURPLE = { r = 0.6, g = 0.2, b = 1 }
local COLOR_ORANGE = { r = 1, g = 0.5, b = 0 }

local PERCENTILE_GREY = 40
local PERCENTILE_GREEN = 75
local PERCENTILE_BLUE = 90
local PERCENTILE_PURPLE = 100

local BASE_SCORE_GREY = 0
local BASE_SCORE_GREEN = 500
local BASE_SCORE_BLUE = 1500
local BASE_SCORE_PURPLE = 2500
local BASE_SCORE_ORANGE = 4000

function ns.GetColorForScore(score)
  if not score or score <= 0 then
    return COLOR_GREY.r, COLOR_GREY.g, COLOR_GREY.b
  end

  if score >= BASE_SCORE_ORANGE then
    return COLOR_ORANGE.r, COLOR_ORANGE.g, COLOR_ORANGE.b
  elseif score >= BASE_SCORE_PURPLE then
    return COLOR_PURPLE.r, COLOR_PURPLE.g, COLOR_PURPLE.b
  elseif score >= BASE_SCORE_BLUE then
    return COLOR_BLUE.r, COLOR_BLUE.g, COLOR_BLUE.b
  elseif score >= BASE_SCORE_GREEN then
    return COLOR_GREEN.r, COLOR_GREEN.g, COLOR_GREEN.b
  else
    return COLOR_GREY.r, COLOR_GREY.g, COLOR_GREY.b
  end
end

function ns.GetColorNameForScore(score)
  if not score or score <= 0 then
    return 'Grey'
  elseif score >= BASE_SCORE_ORANGE then
    return 'Orange'
  elseif score >= BASE_SCORE_PURPLE then
    return 'Purple'
  elseif score >= BASE_SCORE_BLUE then
    return 'Blue'
  elseif score >= BASE_SCORE_GREEN then
    return 'Green'
  else
    return 'Grey'
  end
end

function ns.GetPercentileTier(percentile)
  if percentile >= 90 then
    return 'PURPLE', 4
  elseif percentile >= 75 then
    return 'BLUE', 3
  elseif percentile >= 40 then
    return 'GREEN', 2
  else
    return 'GREY', 1
  end
end

function ns.GetWoWQualityColor(quality)
  local color = ITEM_QUALITY_COLORS[quality]
  if color then
    return color.r, color.g, color.b
  end
  return 1, 1, 1
end

function ns.HSVToRGB(h, s, v)
  local r, g, b
  local i = math.floor(h * 6)
  local f = h * 6 - i
  local p = v * (1 - s)
  local q = v * (1 - f * s)
  local t = v * (1 - (1 - f) * s)

  i = i % 6
  if i == 0 then
    r, g, b = v, t, p
  elseif i == 1 then
    r, g, b = q, v, p
  elseif i == 2 then
    r, g, b = p, v, t
  elseif i == 3 then
    r, g, b = p, q, v
  elseif i == 4 then
    r, g, b = t, p, v
  else
    r, g, b = v, p, q
  end

  return r, g, b
end

function ns.GetGradientColor(score, minScore, maxScore)
  local normalized = 0
  if maxScore > minScore then
    normalized = (score - minScore) / (maxScore - minScore)
  end
  normalized = max(0, min(1, normalized))

  if normalized < 0.4 then
    return COLOR_GREY.r, COLOR_GREY.g, COLOR_GREY.b
  elseif normalized < 0.75 then
    local t = (normalized - 0.4) / 0.35
    return COLOR_GREY.r + (COLOR_GREEN.r - COLOR_GREY.r) * t,
      COLOR_GREY.g + (COLOR_GREEN.g - COLOR_GREY.g) * t,
      COLOR_GREY.b + (COLOR_GREEN.b - COLOR_GREY.b) * t
  elseif normalized < 0.9 then
    local t = (normalized - 0.75) / 0.15
    return COLOR_GREEN.r + (COLOR_BLUE.r - COLOR_GREEN.r) * t,
      COLOR_GREEN.g + (COLOR_BLUE.g - COLOR_GREEN.g) * t,
      COLOR_GREEN.b + (COLOR_BLUE.b - COLOR_GREEN.b) * t
  else
    local t = (normalized - 0.9) / 0.1
    return COLOR_BLUE.r + (COLOR_PURPLE.r - COLOR_BLUE.r) * t,
      COLOR_BLUE.g + (COLOR_PURPLE.g - COLOR_BLUE.g) * t,
      COLOR_BLUE.b + (COLOR_PURPLE.b - COLOR_BLUE.b) * t
  end
end

