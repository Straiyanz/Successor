local addonName, ns = ...

local Successor = ns.Successor or {}
ns.Successor = Successor

local ILVL_MIN = 200
local ILVL_MAX = 300
local SCORE_MIN = 0
local SCORE_MAX = 4000

function Successor.CalculateSuccessScore(playerData)
	if not playerData or not playerData.name then
		return 0, { mythicScore = 0, itemLevel = 0, successRate = 0, keyLevel = 0 }
	end

	local weights = ns.SuccessorDB and ns.SuccessorDB.weights
	if not weights then
		weights = { mythicScore = 40, itemLevel = 25, successRate = 20, keyLevel = 15 }
	end

	local mythicScore = playerData.dungeonScore or 0
	local mythicPlusData = playerData.mythicPlusData
	local runStats = Successor.GetRunStats(mythicPlusData)

	local itemLevel = playerData.itemLevel or 0

	local mythicScoreNorm = 0
	if SCORE_MAX > SCORE_MIN then
		mythicScoreNorm = (mythicScore - SCORE_MIN) / (SCORE_MAX - SCORE_MIN)
	end
	mythicScoreNorm = max(0, min(1, mythicScoreNorm))

	local itemLevelNorm = 0
	if ILVL_MAX > ILVL_MIN then
		itemLevelNorm = (itemLevel - ILVL_MIN) / (ILVL_MAX - ILVL_MIN)
	end
	itemLevelNorm = max(0, min(1, itemLevelNorm))

	local successRateNorm = max(0, min(1, runStats.successRate))

	local keyLevelNorm = 0
	if runStats.highestLevel > 0 then
		keyLevelNorm = min(1, runStats.highestLevel / 25)
	end
	keyLevelNorm = max(0, min(1, keyLevelNorm))

	local score = (mythicScoreNorm * weights.mythicScore / 100)
		+ (itemLevelNorm * weights.itemLevel / 100)
		+ (successRateNorm * weights.successRate / 100)
		+ (keyLevelNorm * weights.keyLevel / 100)

	local components = {
		mythicScore = mythicScoreNorm * 100,
		itemLevel = itemLevelNorm * 100,
		successRate = successRateNorm * 100,
		keyLevel = keyLevelNorm * 100,
	}

	return score * 100, components
end

function Successor.GetSuccessScoreForApplicant(applicantID, memberIndex)
	local memberInfo = C_LFGList.GetApplicantMemberInfo(applicantID, memberIndex)

	if not memberInfo or not memberInfo.name then
		return nil
	end

	local playerData = {
		name = memberInfo.name,
		class = memberInfo.class,
		level = memberInfo.level,
		itemLevel = memberInfo.itemLevel or 0,
		dungeonScore = memberInfo.dungeonScore or 0,
		tank = memberInfo.tank,
		healer = memberInfo.healer,
		damage = memberInfo.damage,
		assignedRole = memberInfo.assignedRole,
		mythicPlusData = Successor.GetPlayerMythicPlusData(memberInfo.name),
	}

	local score, components = Successor.CalculateSuccessScore(playerData)

	return {
		name = memberInfo.name,
		score = score,
		components = components,
		itemLevel = memberInfo.itemLevel,
		dungeonScore = memberInfo.dungeonScore,
		mythicPlusData = playerData.mythicPlusData,
	}
end

function Successor.GetSuccessTier(score)
	if score >= 90 then
		return "Elite", 5
	elseif score >= 75 then
		return "High", 4
	elseif score >= 50 then
		return "Medium", 3
	elseif score >= 25 then
		return "Low", 2
	else
		return "Poor", 1
	end
end

function Successor.GetFormattedScore(score)
	return string.format("%.0f", math.floor(score))
end

function Successor.GetScoreBreakdownText(playerData)
	local score, components = Successor.CalculateSuccessScore(playerData)

	local lines = {
		string.format("M+ Score: %d (%.1f%%)", playerData.dungeonScore or 0, components.mythicScore),
		string.format("Item Level: %d (%.1f%%)", playerData.itemLevel or 0, components.itemLevel),
	}

	if playerData.mythicPlusData then
		local runStats = Successor.GetRunStats(playerData.mythicPlusData)
		table.insert(
			lines,
			string.format("Success Rate: %.0f%% (%.1f%%)", runStats.successRate * 100, components.successRate)
		)
		table.insert(lines, string.format("Highest Key: +%d (%.1f%%)", runStats.highestLevel, components.keyLevel))
	else
		table.insert(lines, string.format("Success Rate: N/A (%.1f%%)", components.successRate))
		table.insert(lines, string.format("Highest Key: N/A (%.1f%%)", components.keyLevel))
	end

	table.insert(lines, "")
	table.insert(lines, string.format("Total Score: %.0f", score))

	return table.concat(lines, "\n")
end

