local addonName, ns = ...

ns.SuccessorDB = ns.SuccessorDB
	or {
		weights = {
			mythicScore = 40,
			itemLevel = 25,
			successRate = 20,
			keyLevel = 15,
		},
		enabled = true,
		showScores = true,
		showRank = true,
	}

local DEFAULT_WEIGHTS = {
	mythicScore = 40,
	itemLevel = 25,
	successRate = 20,
	keyLevel = 15,
}

function ns.LoadDefaultWeights()
	ns.SuccessorDB.weights = CopyTable(DEFAULT_WEIGHTS)
end

local frame = CreateFrame("Frame", "SuccessorFrame")
ns.frame = frame

local Events = {
	ADDON_LOADED = function(name)
		if name == addonName then
			ns.Successor.Initialize()
		end
	end,
	CHALLENGE_MODE_START = function()
		print("CHALLENGE MODE START")
	end,
	CHALLENGE_MODE_COMPLETED = function()
		print("CHALLENGE MODE COMPLETED")
	end,
	LFG_LIST_APPLICANT_UPDATED = function()
		print("LFG LIST APLPICANT UPDATED")
		-- ns.Successor.OnApplicantsUpdated()
	end,
	LFG_LIST_ACTIVE_ENTRY_UPDATE = function()
		print("LFG LIST ACTIVE ENTRY UPDATED")
		-- ns.Successor.OnEntryDeactivated()
	end,
}

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("CHALLENGE_MODE_START")
frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
frame:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
frame:RegisterEvent("LFG_LIST_APPLICANT_UPDATED")

frame:SetScript("OnEvent", function(self, event, ...)
	local handler = Events[event]
	if handler then
		handler(...)
	end
end)

-- TODO: move this to config
SLASH_SUCCESSOR1 = "/successor"
SLASH_SUCCESSOR2 = "/succ"
SlashCmdList["SUCCESSOR"] = function(msg)
	msg = msg or ""
	msg = strtrim(msg:lower())
	if msg == "config" or msg == "settings" then
		ns.Successor.OpenConfig()
	elseif msg == "reset" then
		ns.LoadDefaultWeights()
		print("Successor: Weights reset to defaults.")
	else
		print(string.concat(LightBlueText("Successor"), " Commands:"))
		print(string.concat(LightBlueText("  /successor config"), " - Open settings panel"))
		print(string.concat(LightBlueText("  /successor reset"), " - Reset weights to defaults"))
	end
end
