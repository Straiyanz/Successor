local addonName, ns = ...

local Successor = ns.Successor or {}
ns.Successor = Successor

function Successor.Initialize()
	Successor.mythicScoreWeights = ns.SuccessorDB and ns.SuccessorDB.weights
		or {
			mythicScore = 40,
			itemLevel = 25,
			successRate = 20,
			keyLevel = 15,
		}
	if ns.SuccessorUI then
		ns.SuccessorUI.Initialize()
	else
		C_Timer.After(0.1, function()
			if ns.SuccessorUI then
				ns.SuccessorUI.Initialize()
			end
		end)
	end
end

function Successor.OnApplicantsUpdated()
	if not ns.SuccessorDB or not ns.SuccessorDB.enabled then
		return
	end
	if ns.SuccessorUI then
		ns.SuccessorUI.RefreshApplicantScores()
	end
end

function Successor.OnEntryDeactivated()
	if ns.SuccessorUI then
		ns.SuccessorUI.ClearScores()
	end
end

function Successor.UpdateWeights()
	if ns.SuccessorDB and ns.SuccessorDB.weights then
		Successor.mythicScoreWeights = ns.SuccessorDB.weights
	end
	if ns.SuccessorUI and ns.SuccessorUI.UpdateWeights then
		ns.SuccessorUI.UpdateWeights()
	end
end

function Successor.OpenConfig()
	if ns.SuccessorUI then
		ns.SuccessorUI.OpenConfigPanel()
	end
end
