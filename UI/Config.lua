local addonName, ns = ...

function ns.SuccessorUI.OpenConfigPanel()
	if SuccessorConfigPanel then
		if SuccessorConfigPanel:IsShown() then
			SuccessorConfigPanel:Hide()
		else
			SuccessorConfigPanel:Show()
		end
	end
end

function ns.SuccessorUI.CreateConfigPanel()
	local panel = CreateFrame("Frame", "SuccessorConfigPanel", UIParent, "BasicFrameTemplate")
	panel:SetSize(400, 350)
	panel:SetPoint("CENTER")
	panel:SetFrameStrata("DIALOG")

	panel:EnableMouse(true)
	panel:RegisterForDrag("LeftButton")
	panel:SetScript("OnDragStart", function(self, button)
		panel:SetMovable(true)
		panel:StartMoving()
	end)
	panel:SetScript("OnDragStop", function(self, button)
		panel:StopMovingOrSizing()
		panel:SetMovable(false)
	end)

	local title = panel:CreateFontString("SuccessorConfigTitle", "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOP", panel, "TOP", 0, -2)
	title:SetText(string.format("%s Settings", addonName))

	local enableCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
	enableCheck:SetPoint("TOPLEFT", panel, "TOPLEFT", 5, -20)
	enableCheck.text:SetText("Enable Successor Scoring")
	enableCheck:SetChecked(ns.SuccessorDB.enabled)
	enableCheck:SetScript("OnClick", function(self)
		ns.SuccessorDB.enabled = self:GetChecked()
	end)

	local scoreCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
	scoreCheck:SetPoint("TOPLEFT", enableCheck, "BOTTOMLEFT")
	scoreCheck.text:SetText("Show Score Values")
	scoreCheck:SetChecked(ns.SuccessorDB.showScores)
	scoreCheck:SetScript("OnClick", function(self)
		ns.SuccessorDB.showScores = self:GetChecked()
	end)

	local weightLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	weightLabel:SetPoint("TOPLEFT", scoreCheck, "BOTTOMLEFT")
	weightLabel:SetText("Scoring Weights:")

	local weightNames = {
		{ key = "mythicScore", label = "Mythic+ Score" },
		{ key = "itemLevel", label = "Item Level" },
		{ key = "successRate", label = "Success Rate" },
		{ key = "keyLevel", label = "Highest Key Level" },
	}

	local sliders = {}

	local currentY = -5
	for _, w in ipairs(weightNames) do
		local label = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		label:SetPoint("TOPLEFT", weightLabel, "BOTTOMLEFT", 20, currentY)
		label:SetText(w.label)

		local valueText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		valueText:SetPoint("LEFT", label, "RIGHT", 5, 0)
		valueText:SetText(string.format("%d%%", ns.SuccessorDB.weights[w.key]))

		local slider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
		slider:SetPoint("TOPLEFT", label, "BOTTOMLEFT")
		slider:SetSize(200, 20)
		slider:SetMinMaxValues(0, 100)
		slider:SetValue(ns.SuccessorDB.weights[w.key])
		local valueStep = 5
		slider:SetValueStep(valueStep)
		slider:Disable()

		sliders[w.key] = slider

		slider:SetScript("OnValueChanged", function(self, value)
			local rounded = math.floor(value / valueStep) * valueStep
			ns.SuccessorDB.weights[w.key] = rounded
			valueText:SetText(string.format("%d%%", rounded))
			ns.Successor.UpdateWeights()
		end)

		currentY = currentY - 55
	end

	local closeButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	closeButton:SetPoint("BOTTOM", panel, "BOTTOM", 0, 15)
	closeButton:SetSize(80, 25)
	closeButton:SetText("Close")
	closeButton:SetScript("OnClick", function()
		panel:Hide()
	end)

	local resetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	resetButton:SetPoint("RIGHT", closeButton, "LEFT", -10, 0)
	resetButton:SetSize(80, 25)
	resetButton:SetText("Reset")
	resetButton:SetScript("OnClick", function()
		ns.LoadDefaultWeights()
		for _, w in ipairs(weightNames) do
			local slider = sliders[w.key]
			if slider then
				slider:SetValue(ns.SuccessorDB.weights[w.key])
			end
		end
	end)

	panel:SetScript("OnShow", function(self)
		enableCheck:SetChecked(ns.SuccessorDB.enabled)
		scoreCheck:SetChecked(ns.SuccessorDB.showScores)
	end)

	SuccessorConfigPanel = panel
end
