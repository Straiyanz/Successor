local _, ns = ...

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

function ns.GetPartyUnits()
  return { 'player', 'party1', 'party2', 'party3', 'party4' }
end

function ns.CreateClassLookup()
  SuccessorDB.ClassLookup = {
    -- DK
    [250] = 'Blood',
    [251] = 'Frost',
    [252] = 'Unholy',
    -- DH
    [577] = 'Havoc',
    [581] = 'Vengeance',
    [1480] = 'Devourer',
    -- Druid
    [102] = 'Balance',
    [103] = 'Feral',
    [104] = 'Guardian',
    [105] = 'Restoration',
    -- Evoker
    [1467] = 'Devastation',
    [1468] = 'Preservation',
    [1473] = 'Augmentation',
    -- Hunter
    [253] = 'Beast Mastery',
    [254] = 'Marksmanship',
    [255] = 'Survival',
    -- Mage
    [62] = 'Arcane',
    [63] = 'Fire',
    [64] = 'Frost',
    -- Monk
    [268] = 'Brewmaster',
    [270] = 'Mistweaver',
    [269] = 'Windwalker',
    -- Paladin
    [65] = 'Holy',
    [66] = 'Protection',
    [67] = 'Retribution',
    -- Priest
    [256] = 'Discipline',
    [257] = 'Holy',
    [258] = 'Shadow',
    -- Rogue
    [259] = 'Assassination',
    [260] = 'Assassination',
    [261] = 'Assassination',
    -- Shaman
    [262] = 'Elemental',
    [263] = 'Enhancement',
    [264] = 'Restoration',
    -- Warlock
    [265] = 'Affliction',
    [266] = 'Demonology',
    [267] = 'Destruction',
    -- Warrior
    [71] = 'Arms',
    [72] = 'Fury',
    [73] = 'Protection',
  }
end

---Start Tracking of M+ Run
---@return nil
function ns.StartDungeon()
  if SuccessorDB.in_run then
    return
  end

  print(LightBlueText 'Successor: ' .. 'Dungeon Run Started')
  DungeonCache = {}
  SuccessorDB.DungeonCache = DungeonCache

  SuccessorDB.in_run = true

  local units = ns.GetPartyUnits()

  DungeonCache.playerData = {}
  DungeonCache.keyLevel = C_ChallengeMode.GetActiveKeystoneInfo()
  DungeonCache.dungeonID = C_ChallengeMode.GetActiveChallengeMapID()
  -- add dungeon name? requires dungeon lookup?
  -- not really important for what we want here
  local _, playerServer = UnitFullName 'player'

  for _, who in ipairs(units) do
    if UnitExists(who) then
      local name, server = UnitFullName(who)
      local fullName = server and (name .. '-' .. server) or (name .. '-' .. playerServer)
      local guid = UnitGUID(who)
      local className, classFile, classId = UnitClass(who)

      if guid then
        DungeonCache.playerData[guid] = {
          name = name,
          server = server,
          fullName = fullName,
          guid = guid,
          className = className,
          classFile = classFile,
          classId = classId,
          role = UnitGroupRolesAssigned(who) or nil,
          roleEnum = UnitGroupRolesAssignedEnum(who) or nil,
          rating = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(who) or nil,
          deaths = 0,
          interupts = {
            cast = 0,
            succeed = 0,
            fail = 0,
          },
        }
        NotifyInspect(guid)
      end
    end
  end
end

---Within M+ Run: Gather class info and add to DungeonCache
---@param guid string
---@return nil
function ns.Inspect(guid)
  if not SuccessorDB.in_run then
    return
  end
  if not SuccessorDB.ClassLookup then
    ns.CreateClassLookup()
  end

  local units = ns.GetPartyUnits()
  local playerData = SuccessorDB.DungeonCache.playerData
  SuccessorDB.DungeonCache.playerData = playerData -- is this actually required? isnt the local variable mapped to the global?

  for _, unit in pairs(units) do
    if UnitExists(unit) and UnitGUID(unit) == guid and CanInspect(unit) then
      local specId = GetInspectSpecialization(unit)
      playerData[guid].specId = specId
      playerData[guid].specName = SuccessorDB.ClassLookup[specId]
      ClearInspectPlayer()
    end
  end
end

---Within M+ Run: check if unit dies, update DungeonCache if so
---@param unit string
---@return nil
function ns.CheckHealth(unit)
  if not SuccessorDB.in_run then
    return
  end

  local DungeonCache = SuccessorDB.DungeonCache
  SuccessorDB.DungeonCache = DungeonCache

  if UnitIsDead(unit) and UnitExists(unit) then
    local guid = UnitGUID(unit)

    if not DungeonCache[guid].deaths then
      DungeonCache[guid].deaths = 0
    end

    DungeonCache[guid].deaths = DungeonCache[guid].deaths + 1
  end
end

---@return nil
function ns.FinishDungeon()
  if not SuccessorDB.in_run then
    return
  end
  local DungeonCache = SuccessorDB.DungeonCache
  local PlayerCache = SuccessorDB.PlayerCache or {}
  SuccessorDB.PlayerCache = PlayerCache

  -- Get dungeon run stats
  local runStatus = C_ChallengeMode.GetActiveKeystoneInfo()
  local totalDeaths, _ = C_ChallengeMode.GetDeathCount()

  --[[ Update PlayerCache
  -- NOTE: Stats to track / save
  -- Death %
  -- Deaths per run
  -- Successful interupts per run
  -- Role seen
  -- Timed percemtage
  -- Per spec or per role stats?
     PlayerCache = {
      guid = {
        DAMAGER = {
          seenCount
          interuptsPerRun
          deathsPerRun
        }
      }
    }
  --]]

  for guid, tab in pairs(DungeonCache.playerData) do
    local p = ns.GetOrCreateCache(guid)

    if type(tab) == 'table' then
      for k, v in pairs(tab) do
        print(k .. ' = ' .. v)

        -- Add to PlayerCache
        -- Dont need to loop here - we can get attributes as is
      end
    end
  end

  SuccessorDB.in_run = false
  print(LightBlueText 'Successor: ' .. 'Dungeon Run Ended')
end

function ns.GetOrCreateCache(guid)
  local PlayerCache = SuccessorDB.PlayerCache or {}
  -- Reassigned to DB later

  if not PlayerCache[guid] then
    PlayerCache[guid] = {
      guid = guid,
      firstSeen = date(),
      runs = 1,
    }
  end
  return PlayerCache[guid]
end

function ns.GetApplicantData(applicantID)
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

function ns.GetPlayerMythicPlusData(playerToken)
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

function ns.GetPlayerItemLevel(playerToken)
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

function ns.GetRunStats(ratingSummary)
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

function ns.GetAllApplicants()
  local applicants = C_LFGList.GetApplicants()
  local result = {}

  for i = 1, #applicants do
    local applicantID = applicants[i]
    local data = ns.GetApplicantData(applicantID)
    if data and data.members then
      for _, member in ipairs(data.members) do
        tinsert(result, {
          applicantID = applicantID,
          member = member,
          mythicData = ns.GetPlayerMythicPlusData(member.name),
        })
      end
    end
  end

  return result
end

function ns.ClearPlayerCache()
  wipe(Player)
end

function ns.GetCachedPlayer(name)
  return PlayerCache[name]
end
