local addonName, ns = ...

local Successor = ns.Successor or {}
ns.Successor = Successor

--[[
Player Cache
---
Store of character data of past run experience.
Layout:

    Character-Realm: {
        runs = {
            timed,
            overtime,
            disband,
        },
        deaths = {
		    average,
			max,
			min,
		},
        interupts = {
            times_used,
            misssed,
			hit,
        },
		role = {},
		typing = {},
		leaver = {},

Do we constrict this to overall stats to save space?
]]
local PlayerCache = {}

--[[
Dungon Cache
---
In-run store of character data.
Layout:

    Character-Realm: {
		role : int?,
		deaths = {},
		interupts = {},
    }

Once duneon completes this aggregates and moves to PlayerCache.
Need to make sure that we take into account Mid-key runouts for various reasons (talent reset, repair, etc.).
]]
local DungeonCache = {}

local function ClearCache()
  wipe(PlayerCache)
end

local function GetOrCreateCache(name)
  if not PlayerCache[name] then
    PlayerCache[name] = {
      name = name,
      cachedAt = 0,
      data = nil,
    }
  end
  return PlayerCache[name]
end

function Successor.GetApplicantData(applicantID)
  local data = {}
  local applicants = C_LFGList.GetApplicants()

  for i = 1, #applicants do
    if applicants[i] == applicantID then
      local applicantInfo = C_LFGList.GetApplicantInfo(applicantID)
      if applicantInfo then
        data.applicantID = applicantID
        data.status = applicantInfo.applicationStatus
        data.comment = applicantInfo.comment
      end

      local applicantDetails = C_LFGList.GetApplicants(i - 1, 0, 0, 0, 0)
      local numMembers = applicantDetails and applicantDetails.numMembers or 0
      data.members = {}

      for memberIndex = 1, numMembers do
        local memberInfo = C_LFGList.GetApplicantMemberInfo(applicantID, memberIndex)
        if memberInfo and memberInfo.name then
          local cache = GetOrCreateCache(memberInfo.name)
          cache.data = {
            name = memberInfo.name,
            class = memberInfo.class,
            level = memberInfo.level,
            itemLevel = memberInfo.itemLevel,
            dungeonScore = memberInfo.dungeonScore or 0,
            tank = memberInfo.tank,
            healer = memberInfo.healer,
            damage = memberInfo.damage,
            assignedRole = memberInfo.assignedRole,
            leaver = memberInfo.isLeaver,
          }
          cache.cachedAt = GetTime()

          tinsert(data.members, {
            name = memberInfo.name,
            class = memberInfo.class,
            level = memberInfo.level,
            itemLevel = memberInfo.itemLevel,
            dungeonScore = memberInfo.dungeonScore or 0,
            tank = memberInfo.tank,
            healer = memberInfo.healer,
            damage = memberInfo.damage,
            assignedRole = memberInfo.assignedRole,
            memberIndex = memberIndex,
          })
        end
      end

      break
    end
  end

  return data
end

function Successor.GetPlayerMythicPlusData(playerToken)
  if not playerToken then
    return nil
  end

  local cache = PlayerCache[playerToken]
  if cache and cache.cachedAt and (GetTime() - cache.cachedAt < 60) then
    return cache.data and cache.data.mythicPlusData or nil
  end

  local success, result = pcall(function()
    return C_PlayerInfo.GetPlayerMythicPlusRatingSummary(playerToken)
  end)

  if success and result then
    if cache and cache.data then
      cache.data.mythicPlusData = result
    end
    return result
  end

  return nil
end

function Successor.GetPlayerItemLevel(playerToken)
  if not playerToken then
    return nil
  end

  local success, result = pcall(function()
    return C_PlayerInfo.GetPlayerCharacterData(playerToken)
  end)

  if success and result then
    return result.itemLevel or nil
  end

  return nil
end

function Successor.GetRunStats(ratingSummary)
  if not ratingSummary then
    return {
      currentSeasonScore = 0,
      totalRuns = 0,
      timedRuns = 0,
      successRate = 0,
      highestLevel = 0,
      avgLevel = 0,
    }
  end

  local runs = ratingSummary.runs or {}
  local totalRuns = #runs
  local timedRuns = 0
  local highestLevel = 0
  local levelSum = 0

  for _, run in ipairs(runs) do
    if run.finishedSuccess then
      timedRuns = timedRuns + 1
    end
    if run.bestRunLevel and run.bestRunLevel > highestLevel then
      highestLevel = run.bestRunLevel
    end
    levelSum = levelSum + (run.bestRunLevel or 0)
  end

  local successRate = totalRuns > 0 and (timedRuns / totalRuns) or 0
  local avgLevel = totalRuns > 0 and (levelSum / totalRuns) or 0

  return {
    currentSeasonScore = ratingSummary.currentSeasonScore or 0,
    totalRuns = totalRuns,
    timedRuns = timedRuns,
    successRate = successRate,
    highestLevel = highestLevel,
    avgLevel = avgLevel,
  }
end

function Successor.GetAllApplicants()
  local applicants = C_LFGList.GetApplicants()
  local result = {}

  for i = 1, #applicants do
    local applicantID = applicants[i]
    local data = Successor.GetApplicantData(applicantID)
    if data and data.members then
      for _, member in ipairs(data.members) do
        tinsert(result, {
          applicantID = applicantID,
          member = member,
          mythicData = Successor.GetPlayerMythicPlusData(member.name),
        })
      end
    end
  end

  return result
end

function Successor.ClearPlayerCache()
  ClearCache()
end

function Successor.GetCachedPlayer(name)
  return PlayerCache[name]
end
