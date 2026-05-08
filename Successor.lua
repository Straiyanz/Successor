local addonName, ns = ...

-- Allows use of namespace across files
ns.SuccessorUI = {}
ns.SuccessorDB = SuccessorDB or {}
ns.L = {}

function ns.ResetDB()
  SuccessorDB = {
    in_run = false,
    enabled = true,
    showScores = true,
    showRank = true,
  }
  ns.LoadDefaultWeights()
  ns.CreateClassLookup()
end

function ns.Initialize()
  if not SuccessorDB then
    ns.ResetDB()
  end
  ns.SuccessorUI.CreateConfigPanel()
end

function ns.LoadDefaultWeights()
  SuccessorDB.weights = {
    mythicScore = 40,
    itemLevel = 25,
    successRate = 20,
    keyLevel = 15,
  }
end

local frame = CreateFrame('Frame', 'SuccessorFrame')
frame = frame

local Events = {
  ADDON_LOADED = function(name)
    if name == addonName then
      ns.Initialize()
    end
  end,
  CHALLENGE_MODE_START = function()
    print 'CHALLENGE MODE START'
    ns.StartDungeon()
  end,
  INSPECT_READY = function(guid)
    print 'INSPECT READY'

    -- NOTE: Get unit info:
    -- - Specialization

    ns.Inspect(guid)
  end,
  UNIT_HEALTH = function(unit)
    print 'UNIT HEALTH'

    -- NOTE: Check for deaths
    --
    ns.CheckHealth(unit)
  end,
  CHALLENGE_MODE_RESET = function()
    print 'CHALLENGE MODE RESET'

    -- NOTE: Check for failure?

    -- ns.FinishDungeon()
  end,
  CHALLENGE_MODE_COMPLETED = function()
    print 'CHALLENGE MODE COMPLETED'

    -- NOTE: Is this all completions?
    -- Pass / fail / reset?

    ns.FinishDungeon()
  end,
  CHALLENGE_MODE_COMPLETED_REWARDS = function(mapID, medal, timeMS, money, rewards)
    print 'CHALLENGE MODE COMPLETED REWARDS'

    -- NOTE: Is this better than above for getting success?

    -- ns.FinishDungeon()
  end,
  LFG_LIST_APPLICANT_UPDATED = function()
    print 'LFG LIST APLPICANT UPDATED'
    -- Successor.OnApplicantsUpdated()
  end,
  LFG_LIST_ACTIVE_ENTRY_UPDATE = function()
    print 'LFG LIST ACTIVE ENTRY UPDATED'
    -- Successor.OnEntryDeactivated()
  end,
}

frame:RegisterEvent 'ADDON_LOADED'
frame:RegisterEvent 'INSPECT_READY'
frame:RegisterEvent 'CHALLENGE_MODE_START'
frame:RegisterEvent 'CHALLENGE_MODE_COMPLETED'
frame:RegisterEvent 'CHALLENGE_MODE_COMPLETED_REWARDS'
frame:RegisterEvent 'CHALLENGE_MODE_RESET'
frame:RegisterEvent 'LFG_LIST_ACTIVE_ENTRY_UPDATE'
frame:RegisterEvent 'LFG_LIST_APPLICANT_UPDATED'

frame:SetScript('OnEvent', function(self, event, ...)
  local handler = Events[event]
  if handler then
    handler(...)
  end
end)

-- TODO: move this to config?
SLASH_SUCCESSOR1 = '/successor'
SLASH_SUCCESSOR2 = '/succ'
SlashCmdList['SUCCESSOR'] = function(msg)
  msg = strtrim(msg:lower() or '')

  if msg == 'config' or msg == 'settings' then
    ns.SuccessorUI.OpenConfigPanel()
  elseif msg == 'reset' then
    ns.LoadDefaultWeights()
    print 'Successor: Weights reset to defaults.'
  elseif msg == 'start' then
    ns.StartDungeon()
  elseif msg == 'end' then
    ns.FinishDungeon()
  elseif msg == 'hardreset' then
    ns.ResetDB()
    print 'Successor: DB reset'
  else
    print(string.concat(LightBlueText 'Successor', ' Commands:'))
    print(string.concat(LightBlueText '  /successor config', ' - Open settings panel'))
    print(string.concat(LightBlueText '  /successor reset', ' - Reset weights to defaults'))
    print(string.concat(LightBlueText '  /successor start', ' - Start test dungeon run'))
    print(string.concat(LightBlueText '  /successor end', ' - End test dungeon run'))
    print(string.concat(LightBlueText '  /successor hardreset', ' - Reset all Successor data'))
  end
end
