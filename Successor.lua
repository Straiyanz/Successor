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

local commands = {
  config = {
    command = 'config',
    command2 = 'settings',
    help = 'Open settings panel',
  },
  reset = {
    command = 'reset',
    help = 'Reset weights to defaults',
  },
  start = {
    command = 'start',
    help = 'Start test dungeon run',
  },
  finish = {
    command = 'end',
    help = 'End test dungeon run',
  },
  hardReset = {
    command = 'hardreset',
    help = string.format('Reset all %s data', addonName),
  },
}

SlashCmdList['SUCCESSOR'] = function(msg)
  msg = strtrim(msg:lower() or '')

  if msg == commands.config.command or msg == commands.config.command2 then
    ns.SuccessorUI.OpenConfigPanel()
  elseif msg == commands.reset.command then
    ns.LoadDefaultWeights()
    print(LightBlueText(addonName) .. ': Weights reset to defaults.')
  elseif msg == commands.start.command then
    ns.StartDungeon()
  elseif msg == commands.finish.command then
    ns.FinishDungeon()
  elseif msg == commands.hardReset.command then
    ns.ResetDB()
    print(LightBlueText(addonName) .. ': DB reset')
  else
    print(string.concat(LightBlueText(addonName) .. ' Commands:'))
    for _, c in pairs(commands) do
      print(string.concat(LightBlueText(string.format(' %s %s', SLASH_SUCCESSOR1, c.command)), string.format(' - %s', c.help)))
    end
  end
end
