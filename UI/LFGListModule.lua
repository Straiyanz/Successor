local addonName, ns = ...

local Successor = ns.Successor or {}
local SuccessorUI = {}
ns.Successor = Successor
ns.SuccessorUI = SuccessorUI

local ApplicantScores = {}
local ApplicantFrames = {}
local RefreshedFrames = {}

local LFGListFrame = LFGListFrame

function SuccessorUI.Initialize()
	if SuccessorUI.initialized then
		return
	end
	SuccessorUI.initialized = true
	SuccessorUI.HookLFGList()
	SuccessorUI.CreateConfigPanel()
end

function SuccessorUI.HookLFGList()
	if not LFGListFrame or not LFGListFrame.ApplicationViewer then
		return
	end

	local viewer = LFGListFrame.ApplicationViewer

	hooksecurefunc(viewer, "UpdateApplicant", function(self, applicantID)
		SuccessorUI.UpdateApplicantRow(applicantID)
	end)
end

function SuccessorUI.UpdateApplicantRow(applicantID)
	if not ns.SuccessorDB or not ns.SuccessorDB.enabled then
		return
	end

	local applicants = C_LFGList.GetApplicants()
	local applicantIndex = nil

	for i = 1, #applicants do
		if applicants[i] == applicantID then
			applicantIndex = i - 1
			break
		end
	end

	if applicantIndex == nil then
		return
	end

	local applicantInfo = C_LFGList.GetApplicantInfo(applicantID)
	if not applicantInfo then
		return
	end

	local applicantDetails = C_LFGList.GetApplicants(applicantIndex, 0, 0, 0, 0)
	local numMembers = applicantDetails and applicantDetails.numMembers or 0
	if numMembers and numMembers > 0 then
		for memberIndex = 1, numMembers do
			SuccessorUI.ColorApplicantMember(applicantID, memberIndex)
		end
	else
		SuccessorUI.ColorApplicantMember(applicantID, 1)
	end
end

function SuccessorUI.ColorApplicantMember(applicantID, memberIndex)
	local memberInfo = C_LFGList.GetApplicantMemberInfo(applicantID, memberIndex)
	if not memberInfo or not memberInfo.name then
		return
	end

	local scoreData = Successor.GetSuccessScoreForApplicant(applicantID, memberIndex)
	if not scoreData then
		return
	end

	ApplicantScores[memberInfo.name] = scoreData

	local r, g, b = Successor.GetColorForScore(scoreData.dungeonScore or 0)

	SuccessorUI.FindAndColorApplicantFrame(memberInfo.name, r, g, b, scoreData)
end

function SuccessorUI.FindAndColorApplicantFrame(name, r, g, b, scoreData)
	local baseName = "LFGListGroupPreviewFrame"
	if not _G[baseName] then
		return
	end

	local function ProcessFrame(frame, depth)
		if not frame then
			return
		end

		local frameName = frame.GetName and frame:GetName() or ""
		local nameText = frame.name or (frame.GetName and frame:GetName())

		if frameName:find("Applicant") and frame.ApplicantName then
			local applicantName = frame.ApplicantName:GetText()
			if applicantName and applicantName:find(name, 1, true) then
				SuccessorUI.ApplyColorToFrame(frame, r, g, b, scoreData)
				RefreshedFrames[frame] = true
			end
		end

		if frame.GetChildren then
			local children = { frame:GetChildren() }
			for _, child in ipairs(children) do
				ProcessFrame(child, depth + 1)
			end
		end
	end

	ProcessFrame(_G[baseName], 0)

	for i = 1, 20 do
		local scrollFrame = _G["LFGListGroupPreviewFrameScrollFrame" .. i]
		if scrollFrame then
			ProcessFrame(scrollFrame, 0)
		end
	end

	for i = 1, 50 do
		local button = _G["LFGListGroupPreviewFrameApplicant" .. i]
		if button and button.ApplicantName then
			local applicantName = button.ApplicantName:GetText()
			if applicantName and applicantName:find(name, 1, true) then
				SuccessorUI.ApplyColorToFrame(button, r, g, b, scoreData)
				RefreshedFrames[button] = true
			end
		end
	end
end

function SuccessorUI.ApplyColorToFrame(frame, r, g, b, scoreData)
	if not frame then
		return
	end

	if frame.ApplicantName then
		frame.ApplicantName:SetTextColor(r, g, b)
	end

	if frame.Name then
		frame.Name:SetTextColor(r, g, b)
	end

	if frame.name then
		frame.name:SetTextColor(r, g, b)
	end

	if frame.Header then
		if frame.Header.SetTextColor then
			frame.Header:SetTextColor(r, g, b)
		end
	end

	for _, child in ipairs({ frame:GetChildren() or {} }) do
		if child.SetTextColor and child:GetObjectType() == "FontString" then
			local text = child:GetText()
			if text and text:match(scoreData.name) then
				child:SetTextColor(r, g, b)
			end
		end
	end

	if not frame.SuccessorScoreFrame then
		local scoreFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
		scoreFrame:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
		scoreFrame:SetSize(50, 20)

		local scoreText = scoreFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		scoreText:SetPoint("CENTER", scoreFrame, "CENTER")
		scoreText:SetText(string.format("%.0f", scoreData.score))

		local icon = scoreFrame:CreateTexture(nil, "OVERLAY")
		icon:SetPoint("RIGHT", scoreText, "LEFT", -2, 0)
		icon:SetSize(12, 12)
		icon:SetColorTexture(r, g, b)

		frame.SuccessorScoreFrame = scoreFrame
		scoreFrame:Hide()
	end

	if frame.SuccessorScoreFrame then
		frame.SuccessorScoreFrame:Show()
		local scoreText = frame.SuccessorScoreFrame:GetChildren()
		if scoreText then
			scoreText:SetText(string.format("%.0f", scoreData.score))
		end
	end
end

function SuccessorUI.RefreshApplicantScores()
	if not ns.SuccessorDB or not ns.SuccessorDB.enabled then
		return
	end

	wipe(RefreshedFrames)

	local applicants = C_LFGList.GetApplicants()
	for i = 1, #applicants do
		SuccessorUI.UpdateApplicantRow(applicants[i])
	end
end

function SuccessorUI.ClearScores()
	wipe(ApplicantScores)

	local baseName = "LFGListGroupPreviewFrame"
	if _G[baseName] then
		for _, child in ipairs({ _G[baseName]:GetChildren() or {} }) do
			if child.SuccessorScoreFrame then
				child.SuccessorScoreFrame:Hide()
			end
		end
	end

	for i = 1, 50 do
		local button = _G["LFGListGroupPreviewFrameApplicant" .. i]
		if button and button.SuccessorScoreFrame then
			button.SuccessorScoreFrame:Hide()
		end
	end
end

function SuccessorUI.OnApplicantClick(applicantID)
	local applicants = C_LFGList.GetApplicants()
	local applicantIndex = nil

	for i = 1, #applicants do
		if applicants[i] == applicantID then
			applicantIndex = i - 1
			break
		end
	end

	if applicantIndex == nil then
		return
	end

	local applicantDetails = C_LFGList.GetApplicants(applicantIndex, 0, 0, 0, 0)
	local numMembers = applicantDetails and applicantDetails.numMembers or 0
	if numMembers and numMembers > 0 then
		for memberIndex = 1, numMembers do
			local memberInfo = C_LFGList.GetApplicantMemberInfo(applicantID, memberIndex)
			if memberInfo and memberInfo.name and ApplicantScores[memberInfo.name] then
				SuccessorUI.ShowApplicantTooltip(memberInfo.name, applicantID, memberIndex)
			end
		end
	end
end

function SuccessorUI.ShowApplicantTooltip(name, applicantID, memberIndex)
	local scoreData = Successor.GetSuccessScoreForApplicant(applicantID, memberIndex)
	if not scoreData then
		return
	end

	GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
	GameTooltip:ClearLines()

	local r, g, b = Successor.GetColorForScore(scoreData.dungeonScore or 0)
	GameTooltip:AddLine(name, r, g, b)
	GameTooltip:AddLine(" ")

	local tierName, tierLevel = Successor.GetSuccessTier(scoreData.score)
	GameTooltip:AddLine(string.format("Successor Score: %.0f (%s)", scoreData.score, tierName), 1, 1, 1)

	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine("M+ Score:", string.format("%d", scoreData.dungeonScore or 0), 1, 1, 1, r, g, b)
	GameTooltip:AddDoubleLine("Item Level:", string.format("%d", scoreData.itemLevel or 0), 1, 1, 1, 1, 1, 1)

	if scoreData.mythicPlusData then
		local runStats = Successor.GetRunStats(scoreData.mythicPlusData)
		GameTooltip:AddDoubleLine(
			"Success Rate:",
			string.format("%.0f%%", runStats.successRate * 100),
			1,
			1,
			1,
			1,
			1,
			1
		)
		GameTooltip:AddDoubleLine("Highest Key:", string.format("+%d", runStats.highestLevel), 1, 1, 1, 1, 1, 1)
	end

	GameTooltip:Show()
end

function SuccessorUI.GetApplicantScore(name)
	return ApplicantScores[name]
end
