--Creates a scroll area to hold the warlock frames.
function LA.InitLockAssignmentFrameScrollArea() --parent frame
	AssignmentFrame = CreateFrame("Frame", nil, LockAssignmentFrame)
	AssignmentFrame:SetWidth(LA.LockAssignmentWarlockFrameWidth-52)
	AssignmentFrame:SetHeight(500)
	AssignmentFrame:SetPoint("CENTER", LockAssignmentFrame, "CENTER", -9, 6)
	
	--scrollframe 
	local scrollframe = CreateFrame("ScrollFrame", "LockAssignmentScroller_ScrollFrame", AssignmentFrame)
	scrollframe:SetPoint("TOPLEFT", 2, -2) 
	scrollframe:SetPoint("BOTTOMRIGHT", -2, 2) 
	
	AssignmentFrame.scrollframe = scrollframe
	
	--scrollbar 
	local scrollbar = CreateFrame("Slider", nil, scrollframe, "UIPanelScrollBarTemplate") 
	scrollbar:SetPoint("TOPLEFT", AssignmentFrame, "TOPRIGHT", 4, -16)
	scrollbar:SetPoint("BOTTOMLEFT", AssignmentFrame, "BOTTOMRIGHT", 4, 16)
	scrollbar:SetMinMaxValues(1, 200) 
	scrollbar:SetValueStep(1) 
	scrollbar.scrollStep = 1 
	scrollbar:SetValue(0) 
	scrollbar:SetWidth(16)
	scrollbar:SetScript("OnValueChanged",
		function()
			scrollbar:GetParent():SetVerticalScroll(this:GetValue())
		end)
	local scrollbg = scrollbar:CreateTexture(nil, "BACKGROUND") 
	scrollbg:SetAllPoints(scrollbar) 
	scrollbg:SetTexture(0, 0, 0, 0.8) 
	AssignmentFrame.scrollbar = scrollbar
	--PrintMessageToMainChatFrame("Created a Scroll Bar")
	
	--content frame 	
	local content = CreateFrame("Frame", nil, scrollframe) 
	content:SetWidth(LA.LockAssignmentWarlockFrameWidth-77)
	content:SetHeight(500)
	
	content.WarlockFrames = {}
		
	--This is poorly optimized, but it is what it is.
	for i=0, 39 do
		table.insert(content.WarlockFrames, LA.CreateAssignmentFrame("Brylack", i, content, i + 1))
	end

	scrollframe.content = content 
	-- 290 is perfect for housing 6 warlock frames.
	-- 410 is perfect for housing 7
	-- 530 is perfect for housing 8
	scrollbar:SetMinMaxValues(1, LA.GetMaxValueForScrollBar(content.WarlockFrames))
	
	--PrintMessageToMainChatFrame(GetTableLength(content.WarlockFrames))
	--PrintMessageToMainChatFrame(GetMaxValueForScrollBar(content.WarlockFrames))

	scrollframe:SetScrollChild(content)

	--UpdateAllWarlockFrames()
	LockAssignmentFrame.WarningTextFrame = CreateFrame("Frame", nil, LockAssignmentFrame);
	LockAssignmentFrame.WarningTextFrame:SetWidth(250);
	LockAssignmentFrame.WarningTextFrame:SetHeight(30);
	LockAssignmentFrame.WarningTextFrame:SetPoint("BOTTOMLEFT", LockAssignmentFrame, "BOTTOMLEFT", 0, 0)
	
	LockAssignmentFrame.WarningTextFrame.value = LA.AddTextToFrame(LockAssignmentFrame.WarningTextFrame, "Warning your addon is out of date!", 240)
	LockAssignmentFrame.WarningTextFrame.value:SetPoint("LEFT", LockAssignmentFrame.WarningTextFrame, "LEFT", 0, 0);
	LockAssignmentFrame.WarningTextFrame:Hide();
end

function LA.modf(f)
  if math.modf then return math.modf(f) end
  if f > 0 then
    return math.floor(f), math.mod(f,1)
  end
  return math.ceil(f), math.mod(f,1)
end

--Will take in a table object and return a number of pixels 
function LA.GetMaxValueForScrollBar(AssignmentFrame)
	local numberOfFrames = LA.GetTableLength(AssignmentFrame)
	--total frame height is 500 we can probably survive with hardcoding this.
	local _, mod = LA.modf(500/LA.LockAssignmentWarlockFrameHeight)
	local shiftFactor = ((1-mod)*LA.LockAssignmentWarlockFrameHeight) + 13 --There is roughly a 13 pixel spacer somewhere but I am having a hard time nailing it down.
	local FrameSupports = math.floor(500/LA.LockAssignmentWarlockFrameHeight)
	local FirstClippedFrame = math.ceil(500/LA.LockAssignmentWarlockFrameHeight)

	if numberOfFrames <= FrameSupports then
		return 1
	elseif numberOfFrames == FirstClippedFrame then --this is like a partial frame that wont render all the way.
		return shiftFactor
	elseif numberOfFrames > FirstClippedFrame then
		return (numberOfFrames-FirstClippedFrame)*LA.LockAssignmentWarlockFrameHeight + shiftFactor
	end
end


--[[
    A dropdown list of curses to assign.
    
    A dropdown list of names for SoulStones... or maybe a text box for the name... 
    
    A drop down list of raid markers for banish assignments.

    A dropdown to keep track of SS targets.
    
    A timer to keep track of SS CDs.

    A status indicator to show if warlock has accepted the assignment.
]]--
function LA.CreateAssignmentFrame(WarlockName, number, scrollframe)
    --Draws the warlock Component Frame, adds the border, and positions it relative to the number of frames created.
    local AssignmentFrame = LA.CreateAssignmentContainer(scrollframe, number)
    AssignmentFrame.LockFrameID  = "AssignmentFrame_0"..tostring(number)
    AssignmentFrame.WarlockName = WarlockName
    
    --Creates a portrait to assist in identifying units.
    AssignmentFrame.Portrait = LA.CreateLockAssignmentPortrait(AssignmentFrame, WarlockName, number)
    
    -- Draws the name in the frame.
    AssignmentFrame.NamePlate = LA.CreateNamePlate(AssignmentFrame, WarlockName)

    --Draws the curse dropdown.
    AssignmentFrame.CurseAssignmentMenu = LA.CreateCurseAssignmentMenu(AssignmentFrame)

    --Draw a BanishAssignment DropDownMenu
    AssignmentFrame.BanishAssignmentMenu = LA.CreateBanishAssignmentMenu(AssignmentFrame)

    --Draw a SS Assignment Menu.
    AssignmentFrame.SSAssignmentMenu = LA.CreateSSAssignmentMenu(AssignmentFrame)

    --Draw the SSCooldownTracker
    AssignmentFrame.SSCooldownTracker = LA.CreateSSCooldownTracker(AssignmentFrame.SSAssignmentMenu)
	
	AssignmentFrame.AssignmentAcknowledgement = LA.CreateAckFrame(AssignmentFrame);

	AssignmentFrame.Warning = LA.CreateWarningFrame(AssignmentFrame);

    return AssignmentFrame
end

--Creates a textframe to display the SS cooldown.
function LA.CreateSSCooldownTracker(ParentFrame)
    local TextFrame = LA.AddTextToFrame(ParentFrame, "Available", 120)
    TextFrame:SetPoint("TOP", ParentFrame, "BOTTOM", 0,0)
    return TextFrame
end

--Creates the frame that will act as teh container for the component control.
function LA.CreateAssignmentContainer(ParentFrame, number)
	local AssignmentFrame = CreateFrame("Frame", nil, ParentFrame, BackdropTemplateMixin and "BackdropTemplate")
	AssignmentFrame:SetWidth(LA.LockAssignmentWarlockFrameWidth-67)
	AssignmentFrame:SetHeight(LA.LockAssignmentWarlockFrameHeight)
	--Set up the border around the warlock frame.
	AssignmentFrame:SetBackdrop({
		bgFile= "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", 
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	})	
	--Calculate where to draw the frame on the screen.
	local yVal = (number*(-LA.LockAssignmentWarlockFrameHeight))-10
	AssignmentFrame:SetPoint("TOPLEFT", ParentFrame, "TOPLEFT", 8, yVal)
	
	return AssignmentFrame
end

--Creates and assigns the player portrait to the individual raiders in the contrl.
function LA.CreateLockAssignmentPortrait(ParentFrame, WarlockName, number)
	local portrait = CreateFrame("Frame", nil, ParentFrame)
		portrait:SetWidth(80)
		portrait:SetHeight(80)
		portrait:SetPoint("LEFT", 13, -5)
	local texture = portrait:CreateTexture(nil, "BACKGROUND") 
	texture:SetAllPoints()
	if WarlockName == UnitName("player") then
		SetPortraitTexture(texture, "player")
	else
		SetPortraitTexture(texture, string.format("raid%d", number))
	end
	portrait.Texture = texture 
	
	return portrait
end

--Builds and sets the banish Icon assignment menu.
function LA.CreateBanishAssignmentMenu(ParentFrame)
	local BanishAssignmentMenu = LA.CreateDropDownMenu(ParentFrame, LA.BanishMarkers, "BANISH")
	BanishAssignmentMenu:SetPoint("CENTER", -50, -30)	
	BanishAssignmentMenu.Label = LA.CreateBanishAssignmentLabel(BanishAssignmentMenu)


	local BanishGraphicFrame = CreateFrame("Frame", nil, ParentFrame)
	BanishGraphicFrame:SetWidth(30)
	BanishGraphicFrame:SetHeight(30)
	BanishGraphicFrame:SetPoint("LEFT", BanishAssignmentMenu, "RIGHT", -12, 8)
	
	BanishAssignmentMenu.BanishGraphicFrame = BanishGraphicFrame
	
	return BanishAssignmentMenu
end

--Creates and sets the Banish Assignment Label as part of the banish assignment control.
function LA.CreateBanishAssignmentLabel(ParentFrame)
	local Label = LA.AddTextToFrame(ParentFrame, "Banish Assignment", 150)
	Label:SetPoint("BOTTOMLEFT", ParentFrame, "TOPLEFT", 0, 0)
	return Label
end

--Creates and sets the nameplate for the warlock Frame.
function LA.CreateNamePlate(ParentFrame, Text)
	local NameplateFrame = ParentFrame:CreateTexture(nil, "OVERLAY")
	NameplateFrame:SetWidth(205)
	NameplateFrame:SetHeight(50)
	NameplateFrame:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
	NameplateFrame:SetPoint("LEFT", ParentFrame, "TOPLEFT", -45, -20)

	local TextFrame = LA.AddTextToFrame(ParentFrame, Text, 90)
	TextFrame:SetPoint("TOPLEFT", 10,-6)

	NameplateFrame.TextFrame = TextFrame

	return NameplateFrame
end

-- Adds text to a frame that is passed in.
-- This text will not be automatically displayed and must be anchored before it will render to the screen.
function LA.AddTextToFrame(ParentFrame, Text, Width)
	local NamePlate = ParentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		NamePlate:SetText(Text)
		NamePlate:SetWidth(Width)
		NamePlate:SetJustifyH("CENTER")
		NamePlate:SetJustifyV("CENTER")
		NamePlate:SetTextColor(1,1,1,1)
	return NamePlate
end

--Creates the curse assignment menu.
function LA.CreateCurseAssignmentMenu(ParentFrame)
	local CurseAssignmentMenu = LA.CreateDropDownMenu(ParentFrame, LA.CurseOptions, "CURSE")
	CurseAssignmentMenu:SetPoint("CENTER", -50, 20)	
	CurseAssignmentMenu.Label = LA.CreateCurseAssignmentLabel(CurseAssignmentMenu)
	
	local CurseGraphicFrame = CreateFrame("Frame", nil, ParentFrame)
		CurseGraphicFrame:SetWidth(30)
		CurseGraphicFrame:SetHeight(30)
		CurseGraphicFrame:SetPoint("LEFT", CurseAssignmentMenu, "RIGHT", -12, 8)
	
	CurseAssignmentMenu.CurseGraphicFrame = CurseGraphicFrame
	
	return CurseAssignmentMenu
end

--Parent Frame is the drop down control.
--Curse List Value should be the plain text version of the selected curse option.
function LA.UpdateCurseGraphic(ParentFrame, CurseListValue)
	--PrintMessageToMainChatFrame("Updating Curse Graphic to " .. CurseListValue)
	if not (CurseListValue == nil) then
		if(ParentFrame.CurseGraphicFrame.CurseTexture == nil) then
			local CurseGraphic = ParentFrame.CurseGraphicFrame:CreateTexture(nil, "OVERLAY")
			CurseGraphic:SetAllPoints()
			CurseGraphic:SetTexture(LA.GetSpellTextureFromDropDownList(CurseListValue))
			ParentFrame.CurseGraphicFrame.CurseTexture = CurseGraphic
		else
			ParentFrame.CurseGraphicFrame.CurseTexture:SetTexture(LA.GetSpellTextureFromDropDownList(CurseListValue))
		end
	else 
		if not (ParentFrame.CurseGraphicFrame.CurseTexture == nil) then
			local CurseGraphic = ParentFrame.CurseGraphicFrame:CreateTexture(nil, "OVERLAY") 
			CurseGraphic:SetAllPoints()
			CurseGraphic:SetTexture(0,0,0,0)
			ParentFrame.CurseGraphicFrame.CurseTexture = CurseGraphic
		else
			ParentFrame.CurseGraphicFrame.CurseTexture:SetTexture(0,0,0,0)		
		end
	end
end

--Parent Frame is the drop down control.
function LA.UpdateBanishGraphic(ParentFrame, BanishListValue)
	--PrintMessageToMainChatFrame("Updating Banish Graphic to " .. BanishListValue)
	if not (BanishListValue == nil) then
		if(ParentFrame.BanishGraphicFrame.BanishTexture == nil) then
			local BanishGraphic = ParentFrame.BanishGraphicFrame:CreateTexture(nil, "OVERLAY") 
			BanishGraphic:SetAllPoints()
			BanishGraphic:SetTexture(LA.GetAssetLocationFromRaidMarker(BanishListValue))
			ParentFrame.BanishGraphicFrame.BanishTexture = BanishGraphic
		else
			--PrintMessageToMainChatFrame("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1|t")
			ParentFrame.BanishGraphicFrame.BanishTexture:SetTexture(LA.GetAssetLocationFromRaidMarker(BanishListValue))
		end
	else 
		if not (ParentFrame.BanishGraphicFrame.BanishTexture == nil) then
			local BanishGraphic = ParentFrame.BanishGraphicFrame:CreateTexture(nil, "OVERLAY") 
			BanishGraphic:SetAllPoints()
			BanishGraphic:SetColorTexture(0,0,0,0)
			ParentFrame.BanishGraphicFrame.BanishTexture = BanishGraphic
		else
			ParentFrame.BanishGraphicFrame.BanishTexture:SetColorTexture(0,0,0,0)		
		end
	end
end

--Generic function that will get called by any drop down to update the graphic that is displayed next to it.
-- This event is what is fired when a box is changed manually. 
-- This event does not fire when the dropdown selection is changed programmatically.
-- This acts as a router to determine which menu was changed, if the menu is not of a certain "DropDownType" then this function does nothing.
function LA.UpdateDropDownSideGraphic(DropDownMenu, SelectedValue, DropDownType)
	if DropDownType == "CURSE" then
		LA.UpdateCurseGraphic(DropDownMenu, SelectedValue)
	elseif DropDownType == "BANISH" then
		LA.UpdateBanishGraphic(DropDownMenu, SelectedValue)
	end
end

-- Gets the selected value of the cures from the drop down list.
-- Use GetValueFromDropDownList instead.
function LA.GetCurseValueFromDropDownList(DropDownMenu)
	local selectedValue = UIDropDownMenu_GetSelectedID(DropDownMenu)
	return LA.CurseOptions[selectedValue]
end

-- Gets the selected value of the banish target from the drop down list.
-- This is arguably an easier way than referencing the getvalue from dropdown list function.
function LA.GetBanishValueFromDropDownList(DropDownMenu)
	local selectedValue = UIDropDownMenu_GetSelectedID(DropDownMenu)
	return LA.BanishMarkers[selectedValue]
end

-- Returns the value of the selected option in a drop down menu.
-- This exists because the built in UIDropDownMenu_GetSelectedValue appears to be broken.
-- Of course, it is probable that I am using the drop down menu incorrectly in this case.
function LA.GetValueFromDropDownList(DropDownMenu, OptionList, DropDownType)
	local selectedValue = UIDropDownMenu_GetSelectedID(DropDownMenu)
	if DropDownType == "SSAssignments" then
		if OptionList[selectedValue] == nil then
			return "None"
		else
			return OptionList[selectedValue].Name
		end
	else
		return OptionList[selectedValue]
	end
end

-- Function that converts the Option Value to the Spell Name.
-- This is used for setting the appropriate texture in in the sidebar graphic.
-- Acts as a converter from "Assignment Spell Name" to the actual in-game name.
function LA.GetSpellNameFromDropDownList(ListValue)
	if ListValue == "Elements" then
		return "Curse of the Elements"
	elseif ListValue == "Shadows" then
		return "Curse of Shadow"
	elseif ListValue == "Recklessness" then
		return "Curse of Recklessness"
	elseif ListValue == "Doom LOL" then
		return "Curse of Doom"
	elseif ListValue == "Agony" then
		return "Curse of Agony"
	elseif ListValue == "Tongues" then
		return "Curse of Tongues"
	elseif ListValue == "Weakness" then
		return "Curse of Weakness"
	end
	return nil
end

-- Function that converts the Option Value to the Spell Name.
-- This is used for setting the appropriate texture in in the sidebar graphic.
-- Acts as a converter from "Assignment Spell Name" to the actual in-game name.
function LA.GetSpellIdFromDropDownList(ListValue)
	if ListValue == "Elements" then
		return 11722
	elseif ListValue == "Shadows" then
		return 17937
	elseif ListValue == "Recklessness" then
		return 11717
	elseif ListValue == "Doom LOL" then
		return 603
	elseif ListValue == "Agony" then
		return 11713
	elseif ListValue == "Tongues" then
		return 11719
	elseif ListValue == "Weakness" then
		return 11708
	end
	return nil
end

function LA.GetSpellTextureFromDropDownList(ListValue)
local spellName = LA.GetSpellNameFromDropDownList(ListValue)
local spellsTable = {
	["Curse of the Elements"] = "Interface\\Icons\\Spell_Shadow_ChillTouch",
	["Curse of Shadow"] = "Interface\\Icons\\Spell_Shadow_CurseOfAchimonde",
	["Curse of Recklessness"] = "Interface\\Icons\\Spell_Shadow_UnholyStrength",
	["Curse of Doom"] = "Interface\\Icons\\Spell_Shadow_AuraOfDarkness",
	["Curse of Agony"] = "Interface\\Icons\\Spell_Shadow_CurseOfSargeras",
	["Curse of Tongues"] = "Interface\\Icons\\Spell_Shadow_CurseOfTounges",
	["Curse of Weakness"] = "Interface\\Icons\\Spell_Shadow_CurseOfMannoroth",
}
return spellsTable[spellName]
end

-- Function provides the asset location of the raid targetting icon.
-- E.X. Converts "Star" to - Interface\\TargetingFrame\\UI-RaidTargetingIcon_1
function LA.GetAssetLocationFromRaidMarker(raidMarker)
	if(raidMarker == "Skull") then
		return "Interface\\Addons\\LockAssignment\\assets\\UI-RaidTargetingIcon_8"
	elseif raidMarker == "Star" then
		return "Interface\\Addons\\LockAssignment\\assets\\UI-RaidTargetingIcon_1"
	elseif raidMarker == "Circle" then
		return "Interface\\Addons\\LockAssignment\\assets\\UI-RaidTargetingIcon_2"
	elseif raidMarker == "Diamond" then
		return "Interface\\Addons\\LockAssignment\\assets\\UI-RaidTargetingIcon_3"
	elseif raidMarker == "Triangle" then
		return "Interface\\Addons\\LockAssignment\\assets\\UI-RaidTargetingIcon_4"
	elseif raidMarker == "Moon" then
		return "Interface\\Addons\\LockAssignment\\assets\\UI-RaidTargetingIcon_5"
	elseif raidMarker == "Square" then
		return "Interface\\Addons\\LockAssignment\\assets\\UI-RaidTargetingIcon_6"
	elseif raidMarker == "Cross" then
		return "Interface\\Addons\\LockAssignment\\assets\\UI-RaidTargetingIcon_7"
	end
	return nil
end

--Creates the label for the curse assignment. This may not need to have been encapsulated as such but it made sense to me at the time.
function LA.CreateCurseAssignmentLabel(ParentFrame)
	local Label = LA.AddTextToFrame(ParentFrame, "Curse Assignment", 150)
	Label:SetPoint("BOTTOMLEFT", ParentFrame, "TOPLEFT", 0, 0)
	return Label
end


--Builds and sets the banish Icon assignment menu.
--Parent Frame refers to a "AssignmentFrame"
function LA.CreateSSAssignmentMenu(ParentFrame)

	local SSTargets = LA.GetSSTargets();

	local SSAssignmentMenu = LA.CreateDropDownMenu(ParentFrame, SSTargets, "SSAssignments")
	SSAssignmentMenu:SetPoint("CENTER", 140, 20)	
	SSAssignmentMenu.Label = LA.CreateSSAssignmentLabel(SSAssignmentMenu)
	
	return SSAssignmentMenu
end

--Builds the acknowledgment frame that attaches to the main window to display if assignments have been accepted or not.
function LA.CreateAckFrame(ParentFrame)
	local AckFrame = CreateFrame("Frame", nil, ParentFrame)
	AckFrame:SetWidth(150)
	AckFrame:SetHeight(30)
	AckFrame:SetPoint("CENTER", ParentFrame, "CENTER",80,-25)

	AckFrame.label = LA.AddTextToFrame(AckFrame, "Accepted:", 150)
	AckFrame.label:SetPoint("LEFT", AckFrame, "LEFT", 0, 0)

	AckFrame.value = LA.AddTextToFrame(AckFrame, "Not Recieved", 120)
	AckFrame.value:SetPoint("LEFT", AckFrame, "LEFT", 85, 0)
	return AckFrame;
end

-- Builds a warning fram that shows if the addon is out of date.
function LA.CreateWarningFrame(ParentFrame)
	local NoteFrame = CreateFrame("Frame", nil, ParentFrame)
	NoteFrame:SetWidth(150)
	NoteFrame:SetHeight(30)
	NoteFrame:SetPoint("BOTTOMLEFT", ParentFrame, "BOTTOMLEFT",0,0)
	NoteFrame.value = LA.AddTextToFrame(NoteFrame, "Warning: Addon out of date", 250)
	NoteFrame.value:SetPoint("LEFT", NoteFrame, "LEFT", 0, 0)
	NoteFrame:Hide();
	return NoteFrame;
end

--Create's the "Soul Stone" Label that appears above the soul stone target drop down menu.
function  LA.CreateSSAssignmentLabel(ParentFrame)
	local Label = LA.AddTextToFrame(ParentFrame, "Soul Stone", 130)
	Label:SetPoint("BOTTOMLEFT", ParentFrame, "TOPLEFT", 0, 0)
	return Label
end

local dropdowncount = 0

--Creates and adds a dropdown menu with the passed in option list. 
--Adding a dropdown type further allows for the sidebar graphic to update as well, but is not required.
function LA.CreateDropDownMenu(ParentFrame, OptionList, DropDownType)
    dropdowncount = dropdowncount + 1
    local NewDropDownMenu = CreateFrame("Frame", "NL_DropDown0"..dropdowncount, ParentFrame, "UIDropDownMenuTemplate")

    local function OnClick(_)
		UIDropDownMenu_SetSelectedID(NewDropDownMenu, this:GetID())

		local selection = LA.GetValueFromDropDownList(NewDropDownMenu, OptionList, DropDownType)
		if LA.DebugMode then
			print("User changed selection to " .. selection)
		end
        LA.UpdateDropDownSideGraphic(NewDropDownMenu, selection, DropDownType)
    end

    local function initialize()
		local info = {}
		for k,v in pairs(OptionList) do
			info = {}
			if DropDownType == "SSAssignments" then
				info.text = v.Name

			else
				info.text = v
			end
			info.func = OnClick
			UIDropDownMenu_AddButton(info)
		end
	end
--
    UIDropDownMenu_Initialize(NewDropDownMenu, initialize)
    UIDropDownMenu_SetWidth(100, NewDropDownMenu);
    UIDropDownMenu_SetButtonWidth(124, NewDropDownMenu)
    UIDropDownMenu_SetSelectedID(NewDropDownMenu, 1)
    UIDropDownMenu_JustifyText("LEFT", NewDropDownMenu)

    return NewDropDownMenu
end

function LA.UpdateDropDownMenuWithNewOptions(DropDownMenu, OptionList, DropDownType)
	local function OnClick(self)		
        UIDropDownMenu_SetSelectedID(DropDownMenu, this:GetID())
    
		local selection = LA.GetValueFromDropDownList(DropDownMenu, OptionList, DropDownType)
		if LA.DebugMode then
			print("User changed selection to " .. selection)
		end
        LA.UpdateDropDownSideGraphic(DropDownMenu, selection, DropDownType)
    end
    
    local function initialize()
		local info = {}
		for k,v in pairs(OptionList) do
			info = {}
			
			if DropDownType == "SSAssignments" then
				info.text = v.Name
			else
				info.text = v
			end
			
			info.func = OnClick
			
			if DropDownType == "SSAssignments" then
				if v.Color ~= nil then
					info.colorCode = "|c"..v.Color							
				end
			end
			UIDropDownMenu_AddButton(info)
		end
	end
	
	UIDropDownMenu_Initialize(DropDownMenu, initialize)
    UIDropDownMenu_SetWidth(100, DropDownMenu);
    UIDropDownMenu_SetButtonWidth(124, DropDownMenu)
    UIDropDownMenu_SetSelectedID(DropDownMenu, 1)
	UIDropDownMenu_JustifyText("LEFT", DropDownMenu)
	--print(DropDownMenu.colorCode);
end

function LA.InitLockAssignmentCheckFrame()
	LockAssignmentAssignCheckFrame =  CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate");

	LockAssignmentAssignCheckFrame:SetWidth(200)
	LockAssignmentAssignCheckFrame:SetHeight(175)
	LockAssignmentAssignCheckFrame:SetPoint("CENTER", UIParent, "CENTER",0,0)
	LockAssignmentAssignCheckFrame:SetBackdrop({
		bgFile= "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", 
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 5, right = 5, top = 5, bottom = 5 }
	});

	LockAssignmentAssignCheckFrame:RegisterForDrag("LeftButton");
	LockAssignmentAssignCheckFrame:SetMovable(true);
	LockAssignmentAssignCheckFrame:EnableMouse(true);

	LockAssignmentAssignCheckFrame:SetScript("OnDragStart", LockAssignmentAssignCheckFrame.StartMoving);
	LockAssignmentAssignCheckFrame:SetScript("OnDragStop", LockAssignmentAssignCheckFrame.StopMovingOrSizing);

	AssignmentAssignRejectButton = CreateFrame("Button", nil, LockAssignmentAssignCheckFrame, "GameMenuButtonTemplate");
	AssignmentAssignRejectButton:SetWidth(70);
	AssignmentAssignRejectButton:SetHeight(20);
	AssignmentAssignRejectButton:SetPoint("BOTTOMRIGHT", LockAssignmentAssignCheckFrame, "BOTTOMRIGHT",-15,15)
	AssignmentAssignRejectButton:SetText("No");
	AssignmentAssignRejectButton:SetScript("OnClick", LA.LockAssignmentAssignRejectClick);

	AssignmentAcceptButton = CreateFrame("Button", nil, LockAssignmentAssignCheckFrame, "GameMenuButtonTemplate");
	AssignmentAcceptButton:SetWidth(70);
	AssignmentAcceptButton:SetHeight(20);
	AssignmentAcceptButton:SetPoint("RIGHT", AssignmentAssignRejectButton, "LEFT",-5,0)
	AssignmentAcceptButton:SetText("Yes");
	AssignmentAcceptButton:SetScript("OnClick", LA.LockAssignmentAssignAcceptClick);

	LockAssignmentAssignCheckFrame.AcceptButton = AssignmentAcceptButton;
	LockAssignmentAssignCheckFrame.RejectButton = AssignmentAssignRejectButton;

	LockAssignmentAssignCheckFrame.Label = LA.AddTextToFrame(LockAssignmentAssignCheckFrame, "Your new assignments:", 140)
	LockAssignmentAssignCheckFrame.Label:SetPoint("TOPLEFT", LockAssignmentAssignCheckFrame, "TOPLEFT", 10, -15)

	LockAssignmentAssignCheckFrame.CurseLabel = LA.AddTextToFrame(LockAssignmentAssignCheckFrame, "Curse:", 130)
	LockAssignmentAssignCheckFrame.CurseLabel:SetPoint("TOPLEFT", LockAssignmentAssignCheckFrame, "TOPLEFT", 0, -37)


	local CurseGraphicFrame = CreateFrame("Frame", nil, LockAssignmentAssignCheckFrame)
	CurseGraphicFrame:SetWidth(30)
	CurseGraphicFrame:SetHeight(30)
	CurseGraphicFrame:SetPoint("CENTER", LockAssignmentAssignCheckFrame, "LEFT", 105, 42)
	
	LockAssignmentAssignCheckFrame.CurseGraphicFrame = CurseGraphicFrame

	LockAssignmentAssignCheckFrame.BanishLabel = LA.AddTextToFrame(LockAssignmentAssignCheckFrame, "Banish:", 130)
	LockAssignmentAssignCheckFrame.BanishLabel:SetPoint("TOPLEFT", LockAssignmentAssignCheckFrame, "TOPLEFT", 0, -67)

	local BanishGraphicFrame = CreateFrame("Frame", nil, LockAssignmentAssignCheckFrame)
	BanishGraphicFrame:SetWidth(30)
	BanishGraphicFrame:SetHeight(30)
	BanishGraphicFrame:SetPoint("CENTER", LockAssignmentAssignCheckFrame, "LEFT", 105, 12)
	LockAssignmentAssignCheckFrame.BanishGraphicFrame = BanishGraphicFrame;

	LockAssignmentAssignCheckFrame.SoulStoneLabel = LA.AddTextToFrame(LockAssignmentAssignCheckFrame, "SoulStone:", 130)
	LockAssignmentAssignCheckFrame.SoulStoneLabel:SetPoint("TOPLEFT", LockAssignmentAssignCheckFrame, "TOPLEFT", -8, -97)

	LockAssignmentAssignCheckFrame.SoulStoneAssignment = LA.AddTextToFrame(LockAssignmentAssignCheckFrame, "", 130)
	LockAssignmentAssignCheckFrame.SoulStoneAssignment:SetPoint("TOPLEFT", LockAssignmentAssignCheckFrame, "TOPLEFT", 65, -97)

	LockAssignmentAssignCheckFrame.Prompt = LA.AddTextToFrame(LockAssignmentAssignCheckFrame, "Do you accept?", 130)
	LockAssignmentAssignCheckFrame.Prompt:SetPoint("TOPLEFT", LockAssignmentAssignCheckFrame, "TOPLEFT", 0, -120)
	
	
	LockAssignmentAssignCheckFrame:SetScript("OnShow", LA.LockAssignmentPersonalFrameOnShow);

	
	LockAssignmentAssignCheckFrame:Hide();

	
	--This needs to be removed.	
	--LockAssignmentAssignCheckFrame:Show();
end

function LA.SetLockAssignmentCheckFrame(curse, banish, sstarget)
	if LA.DebugMode then
		print(curse,banish, sstarget);
	end
	LA.UpdateCurseGraphic(LockAssignmentAssignCheckFrame, curse)
	LockAssignmentAssignCheckFrame.pendingCurse = curse;
	LA.UpdateBanishGraphic(LockAssignmentAssignCheckFrame, banish)
	LA.UpdateSoulStoneAssignment(sstarget)
	LockAssignmentAssignCheckFrame:Show();
end

function LA.LockAssignmentPersonalFrameOnShow()
	--PlaySound(SOUNDKIT.READY_CHECK)
	if LA.DebugMode then
		print("Assignment ready check recieved. Assignment check frame should be showing now.");
	end	
end

function LA.LockAssignmentAssignAcceptClick()
	--PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE);
	LockAssignmentAssignCheckFrame:Hide()
	
	if LA.DebugMode then
		print("You clicked Yes.")
	end
	LockAssignmentAssignCheckFrame.activeCurse = LockAssignmentAssignCheckFrame.pendingCurse;
	if LA.DebugMode then
		print("Attempting to create macro for curse: ".. LockAssignmentAssignCheckFrame.activeCurse);
	end

	LA.SetupAssignmentMacro(LockAssignmentAssignCheckFrame.activeCurse);
	LA.SendAssignmentAcknowledgement("true");
end

function LA.LockAssignmentAssignRejectClick()
	--PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE);
	LockAssignmentAssignCheckFrame:Hide()
	if LA.DebugMode then
		print("You clicked No.")
	end
	LA.SendAssignmentAcknowledgement("false");
end

function LA.UpdateSoulStoneAssignment(Assignment)
	LockAssignmentAssignCheckFrame.SoulStoneAssignment:SetText(Assignment);
end


function LA.UpdateAssignedCurseGraphic(CurseGraphicFrame, CurseListValue)
	--print("Updating Curse Graphic to " .. CurseListValue)
	if not (CurseListValue == nil) then
		if(CurseGraphicFrame.CurseTexture == nil) then
			local CurseGraphic = CurseGraphicFrame:CreateTexture(nil, "OVERLAY") 
			CurseGraphic:SetAllPoints()
			CurseGraphic:SetTexture(GetSpellTexture(11713))
			CurseGraphicFrame.CurseTexture = CurseGraphic
		else
			CurseGraphicFrame.CurseTexture:SetTexture(GetSpellTexture(11713))		
		end		
	else 
		if (CurseGraphicFrame.CurseTexture == nil) then
			local CurseGraphic = CurseGraphicFrame:CreateTexture(nil, "OVERLAY") 
			CurseGraphic:SetAllPoints()
			CurseGraphic:SetTexture(1,0,0,0)
			CurseGraphicFrame.CurseTexture = CurseGraphic
		else
			CurseGraphicFrame.CurseTexture:SetTexture(1,0,0,0);	
		end
	end
end

function LA.InitPersonalMonitorFrame()
	AssignmentPersonalMonitorFrame = CreateFrame("Frame", nil, UIParent);

	AssignmentPersonalMonitorFrame:SetWidth(66)
	AssignmentPersonalMonitorFrame:SetHeight(34)
	AssignmentPersonalMonitorFrame:SetPoint("TOP", UIParent, "TOP",0,-25)

	AssignmentPersonalMonitorFrame:SetBackdrop({
	 	bgFile= "Interface\\DialogFrame\\UI-DialogBox-Background",
	 	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	 	tile = true,
	 	tileSize = 32,
	 	edgeSize = 12,
	 	insets = { left = 0, right = 0, top = 0, bottom = 0 }
	 });

	AssignmentPersonalMonitorFrame:RegisterForDrag("LeftButton");
	AssignmentPersonalMonitorFrame:SetMovable(true);
	AssignmentPersonalMonitorFrame:EnableMouse(true);

	AssignmentPersonalMonitorFrame:SetScript("OnDragStart", function()
		AssignmentPersonalMonitorFrame:StartMoving()
	end);
	AssignmentPersonalMonitorFrame:SetScript("OnDragStop", function()
		AssignmentPersonalMonitorFrame:StopMovingOrSizing()
	end);

	AssignmentPersonalMonitorFrame.CurseGraphicFrame = CreateFrame("Frame", nil, AssignmentPersonalMonitorFrame)
	AssignmentPersonalMonitorFrame.CurseGraphicFrame:SetWidth(30)
	AssignmentPersonalMonitorFrame.CurseGraphicFrame:SetHeight(30)
	AssignmentPersonalMonitorFrame.CurseGraphicFrame:SetPoint("LEFT", AssignmentPersonalMonitorFrame, "LEFT", 2, 0)

	AssignmentPersonalMonitorFrame.BanishGraphicFrame = CreateFrame("Frame", nil, AssignmentPersonalMonitorFrame)
	AssignmentPersonalMonitorFrame.BanishGraphicFrame:SetWidth(30)
	AssignmentPersonalMonitorFrame.BanishGraphicFrame:SetHeight(30)
	AssignmentPersonalMonitorFrame.BanishGraphicFrame:SetPoint("LEFT", AssignmentPersonalMonitorFrame.CurseGraphicFrame, "RIGHT", 2, 0)

	AssignmentPersonalMonitorFrame.SSAssignmentText = LA.AddTextToFrame(AssignmentPersonalMonitorFrame, "", 75);
	AssignmentPersonalMonitorFrame.SSAssignmentText:SetPoint("LEFT", AssignmentPersonalMonitorFrame.BanishGraphicFrame,"RIGHT", 5, 0)
	AssignmentPersonalMonitorFrame.SSAssignmentText:SetJustifyH("LEFT")

	AssignmentPersonalMonitorFrame.MainLabel = LA.AddTextToFrame(AssignmentPersonalMonitorFrame,"Lock Assigns:", 125);
	AssignmentPersonalMonitorFrame.MainLabel:SetPoint("BOTTOM", AssignmentPersonalMonitorFrame, "TOP");

	AssignmentPersonalMonitorFrame:Hide();
	--UpdateCurseGraphic(AssignmentPersonalMonitorFrame, "Agony")
	--print("Personal Monitor loaded.")
	--print(AssignmentPersonalMonitorFrame.CurseGraphicFrame.CurseTexture)
end

function LA.UpdatePersonalSSAssignment(ParentFrame, SSAssignment)
	if SSAssignment ~= "None" then
		ParentFrame.SSAssignmentText:SetText(SSAssignment);
		else
			ParentFrame.SSAssignmentText:SetText("");
	end
end

function LA.UpdatePersonalMonitorFrame()
	local myData = LA.GetMyData()
	LA.UpdateBanishGraphic(AssignmentPersonalMonitorFrame, myData.BanishAssignment);
	LA.UpdateCurseGraphic(AssignmentPersonalMonitorFrame, myData.CurseAssignment);
	LA.UpdatePersonalSSAssignment(AssignmentPersonalMonitorFrame, myData.SSAssignment);

	--Need to resize the frame accordingly.
	LA.UpdatePersonalMonitorSize(myData);

	--Need to shift stuff around since this display is wrong.
	--if myData.CurseAssignment ~= "None" and myData.BanishAssignment ~= "None" then
	--This just resets to default locations.
		AssignmentPersonalMonitorFrame.CurseGraphicFrame:SetPoint("LEFT", AssignmentPersonalMonitorFrame, "LEFT", 2, 0)
		AssignmentPersonalMonitorFrame.BanishGraphicFrame:SetPoint("LEFT", AssignmentPersonalMonitorFrame.CurseGraphicFrame, "RIGHT", 2, 0)
		AssignmentPersonalMonitorFrame.SSAssignmentText:SetPoint("LEFT", AssignmentPersonalMonitorFrame.BanishGraphicFrame,"RIGHT", 5, 0)
	--end
	if myData.CurseAssignment == "None" and myData.BanishAssignment ~= "None" then
		-- We shift stuff left.
		AssignmentPersonalMonitorFrame.BanishGraphicFrame:SetPoint("LEFT", AssignmentPersonalMonitorFrame, "LEFT", 2, 0)
		AssignmentPersonalMonitorFrame.SSAssignmentText:SetPoint("LEFT", AssignmentPersonalMonitorFrame.BanishGraphicFrame,"RIGHT", 5, 0)
	end
	if myData.BanishAssignment == "None" and myData.CurseAssignment ~= "None" then
		--we only need to shift the SSAssignmentText to be next to the curse graphic.
		AssignmentPersonalMonitorFrame.SSAssignmentText:SetPoint("LEFT", AssignmentPersonalMonitorFrame.CurseGraphicFrame,"RIGHT", 5, 0)
	end

	if myData.CurseAssignment == "None" and myData.BanishAssignment == "None" then
		-- we can make the SSAssignmentText shif all the way left.
		AssignmentPersonalMonitorFrame.SSAssignmentText:SetPoint("LEFT", AssignmentPersonalMonitorFrame, "LEFT", 2, 0)
	end

	
end

function LA.UpdatePersonalMonitorSize(myData)
	local picframesize = 34
	local buffcount = 0;
	if myData.CurseAssignment ~= "None" then
		buffcount = buffcount+1;
	end
	if myData.BanishAssignment ~= "None" then
		buffcount = buffcount+1;
	end
	local textLength = 0
	if myData.SSAssignment ~="None" then
		textLength = 75;
	end
	AssignmentPersonalMonitorFrame:SetWidth((picframesize*buffcount)+textLength)
	AssignmentPersonalMonitorFrame:SetHeight(34)
end

function LA.InitAnnouncerOptionFrame()
		--print("Creating Announcer menu");
		LockAssignmentAnnouncerOptionMenu = LA.CreateDropDownMenu(NLAnnouncerContainer, LA.AnnouncerOptions, "CHAT")
		LockAssignmentAnnouncerOptionMenu:SetPoint("CENTER", NLAnnouncerContainer, "CENTER", 0,0);
end

function GetTableLng(tbl)
		local getN = 0
		for n in pairs(tbl) do
		getN = getN + 1
		end
		return getN
	end

function LA.SetExtraChats()
	LA.AnnouncerOptions ={
		"Addon Only",
		"Raid",
		"Party",
		"Whisper"
	}

	LA.UpdateDropDownMenuWithNewOptions(LockAssignmentAnnouncerOptionMenu, LA.AnnouncerOptions, "CHAT")
end
