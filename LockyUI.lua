
--Creates a scroll area to hold the locky friend frames. 
--This logic was lifted from a snippet from wowprogramming.com I think....
--This needs a refactor.
function NL.InitLockyFrameScrollArea()

	--parent frame 	
	LockyFrame = CreateFrame("Frame", nil, NeverLockyFrame) 
	LockyFrame:SetSize(NL.LockyFriendFrameWidth-52, 500) 
	LockyFrame:SetPoint("CENTER", NeverLockyFrame, "CENTER", -9, 6) 
	
	--scrollframe 
	local scrollframe = CreateFrame("ScrollFrame", "LockyFriendsScroller_ScrollFrame", LockyFrame) 
	scrollframe:SetPoint("TOPLEFT", 2, -2) 
	scrollframe:SetPoint("BOTTOMRIGHT", -2, 2) 
	
	LockyFrame.scrollframe = scrollframe 
	
	--scrollbar 
	local scrollbar = CreateFrame("Slider", nil, scrollframe, "UIPanelScrollBarTemplate") 
	scrollbar:SetPoint("TOPLEFT", LockyFrame, "TOPRIGHT", 4, -16) 
	scrollbar:SetPoint("BOTTOMLEFT", LockyFrame, "BOTTOMRIGHT", 4, 16) 
	scrollbar:SetMinMaxValues(1, 200) 
	scrollbar:SetValueStep(1) 
	scrollbar.scrollStep = 1 
	scrollbar:SetValue(0) 
	scrollbar:SetWidth(16) 
	scrollbar:SetScript("OnValueChanged", 
		function (self, value) 
			self:GetParent():SetVerticalScroll(value) 
		end) 
	local scrollbg = scrollbar:CreateTexture(nil, "BACKGROUND") 
	scrollbg:SetAllPoints(scrollbar) 
	scrollbg:SetTexture(0, 0, 0, 0.8) 
	LockyFrame.scrollbar = scrollbar 
	--print("Created a Scroll Bar")
	
	--content frame 	
	local content = CreateFrame("Frame", nil, scrollframe) 
	content:SetSize(NL.LockyFriendFrameWidth-77, 500) 
	
	content.LockyFriendFrames = {}
		
	--This is poorly optimized, but it is what it is.
	for i=0, 39 do
		table.insert(content.LockyFriendFrames, NL.CreateLockyFriendFrame("Brylack", i, content))
	end

	scrollframe.content = content 
	-- 290 is perfect for housing 6 locky frames.
	-- 410 is perfect for housing 7
	-- 530 is perfect for housing 8
	scrollbar:SetMinMaxValues(1, NL.GetMaxValueForScrollBar(content.LockyFriendFrames))
	
	--print(GetTableLength(content.LockyFriendFrames))
	--print(GetMaxValueForScrollBar(content.LockyFriendFrames))

	scrollframe:SetScrollChild(content)

	--UpdateAllLockyFriendFrames()
	NeverLockyFrame.WarningTextFrame = CreateFrame("Frame", nil, NeverLockyFrame);
	NeverLockyFrame.WarningTextFrame:SetSize(250, 30);
	NeverLockyFrame.WarningTextFrame:SetPoint("BOTTOMLEFT", NeverLockyFrame, "BOTTOMLEFT", 0, 0)
	
	NeverLockyFrame.WarningTextFrame.value = NL.AddTextToFrame(NeverLockyFrame.WarningTextFrame, "Warning your addon is out of date!", 240)
	NeverLockyFrame.WarningTextFrame.value:SetPoint("LEFT", NeverLockyFrame.WarningTextFrame, "LEFT", 0, 0);
	NeverLockyFrame.WarningTextFrame:Hide();
end

--Will take in a table object and return a number of pixels 
function NL.GetMaxValueForScrollBar(LockyFrames)
	local numberOfFrames = NL.GetTableLength(LockyFrames)
	--total frame height is 500 we can probably survive with hardcoding this.
	local _, mod = math.modf(500/NL.LockyFriendFrameHeight)	
	local shiftFactor = ((1-mod)*NL.LockyFriendFrameHeight) + 13 --There is roughly a 13 pixel spacer somewhere but I am having a hard time nailing it down.
	local FrameSupports = math.floor(500/NL.LockyFriendFrameHeight)
	local FirstClippedFrame = math.ceil(500/NL.LockyFriendFrameHeight)

	if numberOfFrames <= FrameSupports then
		return 1
	elseif numberOfFrames == FirstClippedFrame then --this is like a partial frame that wont render all the way.
		return shiftFactor
	elseif numberOfFrames > FirstClippedFrame then
		return (numberOfFrames-FirstClippedFrame)*NL.LockyFriendFrameHeight + shiftFactor
	end
end


--[[
    A dropdown list of curses to assign.
    
    A dropdown list of names for SoulStones... or maybe a text box for the name... 
    
    A drop down list of raid markers for banish assignments.

    A dropdown to keep track of SS targets.
    
    A timer to keep track of SS CDs.

    A status indicator to show if locky friend has accepted the assignment.
]]--
function NL.CreateLockyFriendFrame(LockyName, number, scrollframe)	
    --Draws the Locky Friend Component Frame, adds the border, and positions it relative to the number of frames created.
    local LockyFrame = NL.CreateLockyFriendContainer(scrollframe, number)
    LockyFrame.LockyFrameID  = "LockyFriendFrame_0"..tostring(number)
    LockyFrame.LockyName = LockyName
    
    --Creates a portrait to assist in identifying units.
    LockyFrame.Portrait = NL.CreateLockyFriendPortrait(LockyFrame, LockyName) 
    
    -- Draws the name in the frame.
    LockyFrame.NamePlate = NL.CreateNamePlate(LockyFrame, LockyName)

    --Draws the curse dropdown.
    LockyFrame.CurseAssignmentMenu = NL.CreateCurseAssignmentMenu(LockyFrame)

    --Draw a BanishAssignment DropDownMenu
    LockyFrame.BanishAssignmentMenu = NL.CreateBanishAssignmentMenu(LockyFrame)	

    --Draw a SS Assignment Menu.
    LockyFrame.SSAssignmentMenu = NL.CreateSSAssignmentMenu(LockyFrame)

    --Draw the SSCooldownTracker
    LockyFrame.SSCooldownTracker = NL.CreateSSCooldownTracker(LockyFrame.SSAssignmentMenu)
	
	LockyFrame.AssignmentAcknowledgement = NL.CreateAckFrame(LockyFrame);

	LockyFrame.Warning = NL.CreateWarningFrame(LockyFrame);

    return LockyFrame
end

--Creates a textframe to display the SS cooldown.
function NL.CreateSSCooldownTracker(ParentFrame)
    local TextFrame = NL.AddTextToFrame(ParentFrame, "Available", 120)
    TextFrame:SetPoint("TOP", ParentFrame, "BOTTOM", 0,0)
    return TextFrame
end

--Creates the frame that will act as teh container for the component control.
function NL.CreateLockyFriendContainer(ParentFrame, number)
	local LockyFriendFrame = CreateFrame("Frame", nil, ParentFrame) 
	LockyFriendFrame:SetSize(NL.LockyFriendFrameWidth-67, NL.LockyFriendFrameHeight) 
	--Set up the border around the locky frame.
	LockyFriendFrame:SetBackdrop({
		bgFile= "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", 
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	})	
	--Calculate where to draw the frame on the screen.
	local yVal = (number*(-NL.LockyFriendFrameHeight))-10
	LockyFriendFrame:SetPoint("TOPLEFT", ParentFrame, "TOPLEFT", 8, yVal)
	
	return LockyFriendFrame
end

--Creates and assigns the player portrait to the individual raiders in the contrl.
function NL.CreateLockyFriendPortrait(ParentFrame, UnitName)
	local portrait = CreateFrame("Frame", nil, ParentFrame) 
		portrait:SetSize(80,80)
		portrait:SetPoint("LEFT", 13, -5)
	local texture = portrait:CreateTexture(nil, "BACKGROUND") 
	texture:SetAllPoints() 
	--texture:SetTexture("Interface\\GLUES\\MainMenu\\Glues-BlizzardLogo") 
	--SetPortraitTexture(texture, UnitName)
	portrait.Texture = texture 
	
	return portrait
end

--Builds and sets the banish Icon assignment menu.
function NL.CreateBanishAssignmentMenu(ParentFrame)
	local BanishAssignmentMenu = NL.CreateDropDownMenu(ParentFrame, NL.BanishMarkers, "BANISH")
	BanishAssignmentMenu:SetPoint("CENTER", -50, -30)	
	BanishAssignmentMenu.Label = NL.CreateBanishAssignmentLabel(BanishAssignmentMenu)


	local BanishGraphicFrame = CreateFrame("Frame", nil, ParentFrame)
	BanishGraphicFrame:SetSize(30,30)
	BanishGraphicFrame:SetPoint("LEFT", BanishAssignmentMenu, "RIGHT", -12, 8)
	
	BanishAssignmentMenu.BanishGraphicFrame = BanishGraphicFrame
	
	return BanishAssignmentMenu
end

--Creates and sets the Banish Assignment Label as part of the banish assignment control.
function NL.CreateBanishAssignmentLabel(ParentFrame)
	local Label = NL.AddTextToFrame(ParentFrame, "Banish Assignment", 150)
	Label:SetPoint("BOTTOMLEFT", ParentFrame, "TOPLEFT", 0, 0)
	return Label
end

--Creates and sets the nameplate for the Locky Friends Frame.
function NL.CreateNamePlate(ParentFrame, Text)
	local NameplateFrame = ParentFrame:CreateTexture(nil, "OVERLAY")
	NameplateFrame:SetSize(205, 50)
	NameplateFrame:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
	NameplateFrame:SetPoint("LEFT", ParentFrame, "TOPLEFT", -45, -20)

	local TextFrame = NL.AddTextToFrame(ParentFrame, Text, 90)
	TextFrame:SetPoint("TOPLEFT", 10,-6)

	NameplateFrame.TextFrame = TextFrame

	return NameplateFrame
end

-- Adds text to a frame that is passed in.
-- This text will not be automatically displayed and must be anchored before it will render to the screen.
function NL.AddTextToFrame(ParentFrame, Text, Width)
	local NamePlate = ParentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		NamePlate:SetText(Text)
		NamePlate:SetWidth(Width)
		NamePlate:SetJustifyH("CENTER")
		NamePlate:SetJustifyV("CENTER")
		NamePlate:SetTextColor(1,1,1,1)
	return NamePlate
end

--Creates the curse assignment menu.
function NL.CreateCurseAssignmentMenu(ParentFrame)			
	local CurseAssignmentMenu = NL.CreateDropDownMenu(ParentFrame, NL.CurseOptions, "CURSE")
	CurseAssignmentMenu:SetPoint("CENTER", -50, 20)	
	CurseAssignmentMenu.Label = NL.CreateCurseAssignmentLabel(CurseAssignmentMenu)
	
	local CurseGraphicFrame = CreateFrame("Frame", nil, ParentFrame)
		CurseGraphicFrame:SetSize(30,30)
		CurseGraphicFrame:SetPoint("LEFT", CurseAssignmentMenu, "RIGHT", -12, 8)
	
	CurseAssignmentMenu.CurseGraphicFrame = CurseGraphicFrame
	
	return CurseAssignmentMenu
end

--Parent Frame is the drop down control.
--Curse List Value should be the plain text version of the selected curse option.
function NL.UpdateCurseGraphic(ParentFrame, CurseListValue)
	--print("Updating Curse Graphic to " .. CurseListValue)
	if not (CurseListValue == nil) then
		if(ParentFrame.CurseGraphicFrame.CurseTexture == nil) then
			local CurseGraphic = ParentFrame.CurseGraphicFrame:CreateTexture(nil, "OVERLAY") 
			CurseGraphic:SetAllPoints()
			CurseGraphic:SetTexture(GetSpellTexture(NL.GetSpellIdFromDropDownList(CurseListValue)))
			ParentFrame.CurseGraphicFrame.CurseTexture = CurseGraphic
		else
			ParentFrame.CurseGraphicFrame.CurseTexture:SetTexture(GetSpellTexture(NL.GetSpellIdFromDropDownList(CurseListValue)))		
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
function NL.UpdateBanishGraphic(ParentFrame, BanishListValue)
	--print("Updating Banish Graphic to " .. BanishListValue)
	if not (BanishListValue == nil) then
		if(ParentFrame.BanishGraphicFrame.BanishTexture == nil) then
			local BanishGraphic = ParentFrame.BanishGraphicFrame:CreateTexture(nil, "OVERLAY") 
			BanishGraphic:SetAllPoints()
			BanishGraphic:SetTexture(NL.GetAssetLocationFromRaidMarker(BanishListValue))
			ParentFrame.BanishGraphicFrame.BanishTexture = BanishGraphic
		else
			--print("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1|t")
			ParentFrame.BanishGraphicFrame.BanishTexture:SetTexture(NL.GetAssetLocationFromRaidMarker(BanishListValue))
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
function NL.UpdateDropDownSideGraphic(DropDownMenu, SelectedValue, DropDownType)
	if DropDownType == "CURSE" then
		NL.UpdateCurseGraphic(DropDownMenu, SelectedValue)
	elseif DropDownType == "BANISH" then
		NL.UpdateBanishGraphic(DropDownMenu, SelectedValue)
	end
end

-- Gets the selected value of the cures from the drop down list.
-- Use GetValueFromDropDownList instead.
function NL.GetCurseValueFromDropDownList(DropDownMenu)
	local selectedValue = L_UIDropDownMenu_GetSelectedID(DropDownMenu)
	return NL.CurseOptions[selectedValue]
end

-- Gets the selected value of the banish target from the drop down list.
-- This is arguably an easier way than referencing the getvalue from dropdown list function.
function NL.GetBanishValueFromDropDownList(DropDownMenu)
	local selectedValue = L_UIDropDownMenu_GetSelectedID(DropDownMenu)
	return NL.BanishMarkers[selectedValue]
end

-- Returns the value of the selected option in a drop down menu.
-- This exists because the built in UIDropDownMenu_GetSelectedValue appears to be broken.
-- Of course, it is probable that I am using the drop down menu incorrectly in this case.
function NL.GetValueFromDropDownList(DropDownMenu, OptionList, DropDownType)
	local selectedValue = L_UIDropDownMenu_GetSelectedID(DropDownMenu)
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
-- Acts as a converter from our "Locky Spell Name" to the actual in-game name.
function NL.GetSpellNameFromDropDownList(ListValue)
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
-- Acts as a converter from our "Locky Spell Name" to the actual in-game name.
function NL.GetSpellIdFromDropDownList(ListValue)
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

-- Function provides the asset location of the raid targetting icon.
-- E.X. Converts "Star" to - Interface\\TargetingFrame\\UI-RaidTargetingIcon_1
function NL.GetAssetLocationFromRaidMarker(raidMarker)
	if(raidMarker == "Skull") then
		return "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8"
	elseif raidMarker == "Star" then
		return "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1"
	elseif raidMarker == "Circle" then
		return "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2"
	elseif raidMarker == "Diamond" then
		return "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3"
	elseif raidMarker == "Triangle" then
		return "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4"
	elseif raidMarker == "Moon" then
		return "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5"
	elseif raidMarker == "Square" then
		return "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6"
	elseif raidMarker == "Cross" then
		return "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7"
	end
	return nil
end

--Creates the label for the curse assignment. This may not need to have been encapsulated as such but it made sense to me at the time.
function NL.CreateCurseAssignmentLabel(ParentFrame)
	local Label = NL.AddTextToFrame(ParentFrame, "Curse Assignment", 150)
	Label:SetPoint("BOTTOMLEFT", ParentFrame, "TOPLEFT", 0, 0)
	return Label
end


--Builds and sets the banish Icon assignment menu.
--Parent Frame refers to a "LockyFriendFrame"
function NL.CreateSSAssignmentMenu(ParentFrame)

	local SSTargets = NL.GetSSTargets();

	local SSAssignmentMenu = NL.CreateDropDownMenu(ParentFrame, SSTargets, "SSAssignments")
	SSAssignmentMenu:SetPoint("CENTER", 140, 20)	
	SSAssignmentMenu.Label = NL.CreateSSAssignmentLabel(SSAssignmentMenu)
	
	return SSAssignmentMenu
end

--Builds the acknowledgment frame that attaches to the main window to display if assignments have been accepted or not.
function NL.CreateAckFrame(ParentFrame)
	local AckFrame = CreateFrame("Frame", nil, ParentFrame)
	AckFrame:SetSize(150,30)
	AckFrame:SetPoint("CENTER", ParentFrame, "CENTER",80,-25)

	AckFrame.label = NL.AddTextToFrame(AckFrame, "Accepted:", 150)
	AckFrame.label:SetPoint("LEFT", AckFrame, "LEFT", 0, 0)

	AckFrame.value = NL.AddTextToFrame(AckFrame, "Not Recieved", 120)
	AckFrame.value:SetPoint("LEFT", AckFrame, "LEFT", 85, 0)
	return AckFrame;
end

-- Builds a warning fram that shows if the addon is out of date.
function NL.CreateWarningFrame(ParentFrame)
	local NoteFrame = CreateFrame("Frame", nil, ParentFrame)
	NoteFrame:SetSize(150, 30)
	NoteFrame:SetPoint("BOTTOMLEFT", ParentFrame, "BOTTOMLEFT",0,0)
	NoteFrame.value = NL.AddTextToFrame(NoteFrame, "Warning: Addon out of date", 250)
	NoteFrame.value:SetPoint("LEFT", NoteFrame, "LEFT", 0, 0)
	NoteFrame:Hide();
	return NoteFrame;
end

--Create's the "Soul Stone" Label that appears above the soul stone target drop down menu.
function  NL.CreateSSAssignmentLabel(ParentFrame)
	local Label = NL.AddTextToFrame(ParentFrame, "Soul Stone", 130)
	Label:SetPoint("BOTTOMLEFT", ParentFrame, "TOPLEFT", 0, 0)
	return Label
end

local dropdowncount = 0

--Creates and adds a dropdown menu with the passed in option list. 
--Adding a dropdown type further allows for the sidebar graphic to update as well, but is not required.
function NL.CreateDropDownMenu(ParentFrame, OptionList, DropDownType)
    dropdowncount = dropdowncount + 1
    local NewDropDownMenu = CreateFrame("Button", "NL_DropDown0"..dropdowncount, ParentFrame, "L_UIDropDownMenuTemplate")

    local function OnClick(self)		
		
		
		L_UIDropDownMenu_SetSelectedID(NewDropDownMenu, self:GetID())
    
		local selection = NL.GetValueFromDropDownList(NewDropDownMenu, OptionList, DropDownType)
		if NL.DebugMode then
			print("User changed selection to " .. selection)
		end
        NL.UpdateDropDownSideGraphic(NewDropDownMenu, selection, DropDownType)
    end
    
    local function initialize(self, level)
		local info = L_UIDropDownMenu_CreateInfo()
		for k,v in pairs(OptionList) do
			info = L_UIDropDownMenu_CreateInfo()
			if DropDownType == "SSAssignments" then
				info.text = v.Name
				info.value = v.Name
				
			else
				info.text = v
				info.value = v
			end
			info.func = OnClick
			L_UIDropDownMenu_AddButton(info, level)
		end		
    end
    L_UIDropDownMenu_Initialize(NewDropDownMenu, initialize)
    L_UIDropDownMenu_SetWidth(NewDropDownMenu, 100);
    L_UIDropDownMenu_SetButtonWidth(NewDropDownMenu, 124)
    L_UIDropDownMenu_SetSelectedID(NewDropDownMenu, 1)
    L_UIDropDownMenu_JustifyText(NewDropDownMenu, "LEFT")
    
    return NewDropDownMenu
end

function NL.UpdateDropDownMenuWithNewOptions(DropDownMenu, OptionList, DropDownType)
	local function OnClick(self)		
        L_UIDropDownMenu_SetSelectedID(DropDownMenu, self:GetID())
    
		local selection = NL.GetValueFromDropDownList(DropDownMenu, OptionList, DropDownType)
		if NL.DebugMode then
			print("User changed selection to " .. selection)
		end
        NL.UpdateDropDownSideGraphic(DropDownMenu, selection, DropDownType)
    end
    
    local function initialize(self, level)
		local info = L_UIDropDownMenu_CreateInfo()
		for k,v in pairs(OptionList) do
			info = L_UIDropDownMenu_CreateInfo()
			
			if DropDownType == "SSAssignments" then
				info.text = v.Name
				info.value = v.Name
			else
				info.text = v
				info.value = v
			end
			
			info.func = OnClick
			
			if DropDownType == "SSAssignments" then
				if v.Color ~= nil then
					info.colorCode = "|c"..v.Color							
				end
			end
			L_UIDropDownMenu_AddButton(info, level)
		end
	end
	
	L_UIDropDownMenu_Initialize(DropDownMenu, initialize)
    L_UIDropDownMenu_SetWidth(DropDownMenu, 100);
    L_UIDropDownMenu_SetButtonWidth(DropDownMenu, 124)
    L_UIDropDownMenu_SetSelectedID(DropDownMenu, 1)
	L_UIDropDownMenu_JustifyText(DropDownMenu, "LEFT")
	--print(DropDownMenu.colorCode);
end

function NL.InitLockyAssignCheckFrame()
	LockyAssignCheckFrame =  CreateFrame("Frame", nil, UIParent);

	LockyAssignCheckFrame:SetSize(200, 175) 
	LockyAssignCheckFrame:SetPoint("CENTER", UIParent, "CENTER",0,0) 
	LockyAssignCheckFrame:SetBackdrop({
		bgFile= "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", 
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 5, right = 5, top = 5, bottom = 5 }
	});

	LockyAssignCheckFrame:RegisterForDrag("LeftButton");
	LockyAssignCheckFrame:SetMovable(true);
	LockyAssignCheckFrame:EnableMouse(true);

	LockyAssignCheckFrame:SetScript("OnDragStart", LockyAssignCheckFrame.StartMoving);
	LockyAssignCheckFrame:SetScript("OnDragStop", LockyAssignCheckFrame.StopMovingOrSizing);

	LockyAssignRejectButton = CreateFrame("Button", nil, LockyAssignCheckFrame, "GameMenuButtonTemplate");
	LockyAssignRejectButton:SetSize(70,20);
	LockyAssignRejectButton:SetPoint("BOTTOMRIGHT", LockyAssignCheckFrame, "BOTTOMRIGHT",-15,15)
	LockyAssignRejectButton:SetText("No");
	LockyAssignRejectButton:SetScript("OnClick", NL.LockyAssignRejectClick);

	LockyAssignAcceptButton = CreateFrame("Button", nil, LockyAssignCheckFrame, "GameMenuButtonTemplate");
	LockyAssignAcceptButton:SetSize(70,20);
	LockyAssignAcceptButton:SetPoint("RIGHT", LockyAssignRejectButton, "LEFT",-5,0)
	LockyAssignAcceptButton:SetText("Yes");
	LockyAssignAcceptButton:SetScript("OnClick", NL.LockyAssignAcceptClick);

	LockyAssignCheckFrame.AcceptButton = LockyAssignAcceptButton;
	LockyAssignCheckFrame.RejectButton = LockyAssignRejectButton;

	LockyAssignCheckFrame.Label = NL.AddTextToFrame(LockyAssignCheckFrame, "Your new assignments:", 140)
	LockyAssignCheckFrame.Label:SetPoint("TOPLEFT", LockyAssignCheckFrame, "TOPLEFT", 10, -15)

	LockyAssignCheckFrame.CurseLabel = NL.AddTextToFrame(LockyAssignCheckFrame, "Curse:", 130)
	LockyAssignCheckFrame.CurseLabel:SetPoint("TOPLEFT", LockyAssignCheckFrame, "TOPLEFT", 0, -37)


	local CurseGraphicFrame = CreateFrame("Frame", nil, LockyAssignCheckFrame)
	CurseGraphicFrame:SetSize(30,30)
	CurseGraphicFrame:SetPoint("CENTER", LockyAssignCheckFrame, "LEFT", 105, 42)
	
	LockyAssignCheckFrame.CurseGraphicFrame = CurseGraphicFrame

	LockyAssignCheckFrame.BanishLabel = NL.AddTextToFrame(LockyAssignCheckFrame, "Banish:", 130)
	LockyAssignCheckFrame.BanishLabel:SetPoint("TOPLEFT", LockyAssignCheckFrame, "TOPLEFT", 0, -67)

	local BanishGraphicFrame = CreateFrame("Frame", nil, LockyAssignCheckFrame)
	BanishGraphicFrame:SetSize(30,30)
	BanishGraphicFrame:SetPoint("CENTER", LockyAssignCheckFrame, "LEFT", 105, 12)
	LockyAssignCheckFrame.BanishGraphicFrame = BanishGraphicFrame;

	LockyAssignCheckFrame.SoulStoneLabel = NL.AddTextToFrame(LockyAssignCheckFrame, "SoulStone:", 130)
	LockyAssignCheckFrame.SoulStoneLabel:SetPoint("TOPLEFT", LockyAssignCheckFrame, "TOPLEFT", -8, -97)

	LockyAssignCheckFrame.SoulStoneAssignment = NL.AddTextToFrame(LockyAssignCheckFrame, "", 130)
	LockyAssignCheckFrame.SoulStoneAssignment:SetPoint("TOPLEFT", LockyAssignCheckFrame, "TOPLEFT", 65, -97)

	LockyAssignCheckFrame.Prompt = NL.AddTextToFrame(LockyAssignCheckFrame, "Do you accept?", 130)
	LockyAssignCheckFrame.Prompt:SetPoint("TOPLEFT", LockyAssignCheckFrame, "TOPLEFT", 0, -120)
	
	
	LockyAssignCheckFrame:SetScript("OnShow", NL.LockyAssignFrameOnShow);

	
	LockyAssignCheckFrame:Hide();

	
	--This needs to be removed.	
	--LockyAssignCheckFrame:Show();
end

function NL.SetLockyCheckFrameAssignments(curse, banish, sstarget)
	if NL.DebugMode then
		print(curse,banish, sstarget);
	end
	NL.UpdateCurseGraphic(LockyAssignCheckFrame, curse)
	LockyAssignCheckFrame.pendingCurse = curse;
	NL.UpdateBanishGraphic(LockyAssignCheckFrame, banish)
	NL.UpdateSoulStoneAssignment(sstarget)
	LockyAssignCheckFrame:Show();
end

function NL.LockyAssignFrameOnShow()	
	PlaySound(SOUNDKIT.READY_CHECK)
	if NL.DebugMode then	
		print("Assignment ready check recieved. Assignment check frame should be showing now.");
	end	
end



function NL.LockyAssignAcceptClick()
	PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE);
	LockyAssignCheckFrame:Hide()
	
	if NL.DebugMode then
		print("You clicked Yes.")
	end
	LockyAssignCheckFrame.activeCurse = LockyAssignCheckFrame.pendingCurse;
	if NL.DebugMode then
		print("Attempting to create macro for curse: ".. LockyAssignCheckFrame.activeCurse);		
	end

	NL.SetupAssignmentMacro(LockyAssignCheckFrame.activeCurse);
	NL.SendAssignmentAcknowledgement("true");
end

function NL.LockyAssignRejectClick()
	PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE);
	LockyAssignCheckFrame:Hide()
	if NL.DebugMode then
		print("You clicked No.")
	end
	NL.SendAssignmentAcknowledgement("false");
end

function NL.UpdateSoulStoneAssignment(Assignment)
	LockyAssignCheckFrame.SoulStoneAssignment:SetText(Assignment);
end


function NL.UpdateAssignedCurseGraphic(CurseGraphicFrame, CurseListValue)
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

function NL.InitPersonalMonitorFrame()
	--LockyPersonalAnchorButton = CreateFrame("Button", nil, UIParent)
	--LockyPersonalAnchorButton:SetSize(30,30)
	--LockyPersonalAnchorButton:SetPoint("CENTER", UIParent, "CENTER")


	LockyPersonalMonitorFrame = CreateFrame("Frame", nil, UIParent);

	LockyPersonalMonitorFrame:SetSize(66, 34) 
	LockyPersonalMonitorFrame:SetPoint("TOP", UIParent, "TOP",0,-25) 

	--LockyPersonalMonitorFrame:SetBackdrop({
	-- 	bgFile= "Interface\\DialogFrame\\UI-DialogBox-Background",
	-- 	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", 
	-- 	tile = true,
	-- 	tileSize = 32,
	-- 	edgeSize = 12,
	-- 	insets = { left = 0, right = 0, top = 0, bottom = 0 }
	-- });

	LockyPersonalMonitorFrame:RegisterForDrag("LeftButton");
	LockyPersonalMonitorFrame:SetMovable(true);
	LockyPersonalMonitorFrame:EnableMouse(true);

	LockyPersonalMonitorFrame:SetScript("OnDragStart", LockyPersonalMonitorFrame.StartMoving);
	LockyPersonalMonitorFrame:SetScript("OnDragStop", LockyPersonalMonitorFrame.StopMovingOrSizing);

	LockyPersonalMonitorFrame.CurseGraphicFrame = CreateFrame("Frame", nil, LockyPersonalMonitorFrame)
	LockyPersonalMonitorFrame.CurseGraphicFrame:SetSize(30,30)
	LockyPersonalMonitorFrame.CurseGraphicFrame:SetPoint("LEFT", LockyPersonalMonitorFrame, "LEFT", 2, 0)

	LockyPersonalMonitorFrame.BanishGraphicFrame = CreateFrame("Frame", nil, LockyPersonalMonitorFrame)
	LockyPersonalMonitorFrame.BanishGraphicFrame:SetSize(30,30)
	LockyPersonalMonitorFrame.BanishGraphicFrame:SetPoint("LEFT", LockyPersonalMonitorFrame.CurseGraphicFrame, "RIGHT", 2, 0)

	LockyPersonalMonitorFrame.SSAssignmentText = NL.AddTextToFrame(LockyPersonalMonitorFrame, "", 75);
	LockyPersonalMonitorFrame.SSAssignmentText:SetPoint("LEFT", LockyPersonalMonitorFrame.BanishGraphicFrame,"RIGHT", 5, 0)
	LockyPersonalMonitorFrame.SSAssignmentText:SetJustifyH("LEFT")

	LockyPersonalMonitorFrame.MainLabel = NL.AddTextToFrame(LockyPersonalMonitorFrame,"Lock Assigns:", 125);
	LockyPersonalMonitorFrame.MainLabel:SetPoint("BOTTOM", LockyPersonalMonitorFrame, "TOP");

	LockyPersonalMonitorFrame:Hide();
	--UpdateCurseGraphic(LockyPersonalMonitorFrame, "Agony")
	--print("Personal Monitor loaded.")
	--print(LockyPersonalMonitorFrame.CurseGraphicFrame.CurseTexture)
end

function NL.UpdatePersonalSSAssignment(ParentFrame, SSAssignment)
	if SSAssignment ~= "None" then
		ParentFrame.SSAssignmentText:SetText(SSAssignment);
		else
			ParentFrame.SSAssignmentText:SetText("");
	end
end

function NL.UpdatePersonalMonitorFrame()
	local myData = NL.GetMyLockyData()
	NL.UpdateBanishGraphic(LockyPersonalMonitorFrame, myData.BanishAssignment);
	NL.UpdateCurseGraphic(LockyPersonalMonitorFrame, myData.CurseAssignment);
	NL.UpdatePersonalSSAssignment(LockyPersonalMonitorFrame, myData.SSAssignment);

	--Need to resize the frame accordingly.
	NL.UpdatePersonalMonitorSize(myData);

	--Need to shift stuff around since this display is wrong.
	--if myData.CurseAssignment ~= "None" and myData.BanishAssignment ~= "None" then
	--This just resets to default locations.
		LockyPersonalMonitorFrame.CurseGraphicFrame:SetPoint("LEFT", LockyPersonalMonitorFrame, "LEFT", 2, 0)
		LockyPersonalMonitorFrame.BanishGraphicFrame:SetPoint("LEFT", LockyPersonalMonitorFrame.CurseGraphicFrame, "RIGHT", 2, 0)
		LockyPersonalMonitorFrame.SSAssignmentText:SetPoint("LEFT", LockyPersonalMonitorFrame.BanishGraphicFrame,"RIGHT", 5, 0)
	--end
	if myData.CurseAssignment == "None" and myData.BanishAssignment ~= "None" then
		-- We shift stuff left.
		LockyPersonalMonitorFrame.BanishGraphicFrame:SetPoint("LEFT", LockyPersonalMonitorFrame, "LEFT", 2, 0)
		LockyPersonalMonitorFrame.SSAssignmentText:SetPoint("LEFT", LockyPersonalMonitorFrame.BanishGraphicFrame,"RIGHT", 5, 0)
	end
	if myData.BanishAssignment == "None" and myData.CurseAssignment ~= "None" then
		--we only need to shift the SSAssignmentText to be next to the curse graphic.
		LockyPersonalMonitorFrame.SSAssignmentText:SetPoint("LEFT", LockyPersonalMonitorFrame.CurseGraphicFrame,"RIGHT", 5, 0)
	end

	if myData.CurseAssignment == "None" and myData.BanishAssignment == "None" then
		-- we can make the SSAssignmentText shif all the way left.
		LockyPersonalMonitorFrame.SSAssignmentText:SetPoint("LEFT", LockyPersonalMonitorFrame, "LEFT", 2, 0)
	end

	
end

function NL.UpdatePersonalMonitorSize(myData)
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
	LockyPersonalMonitorFrame:SetSize((picframesize*buffcount)+textLength, 34)

	
end

function NL.InitAnnouncerOptionFrame()
		--print("Creating Announcer menu");
		LockyAnnouncerOptionMenu = NL.CreateDropDownMenu(NLAnnouncerContainer, NL.AnnouncerOptions, "CHAT")	
		LockyAnnouncerOptionMenu:SetPoint("CENTER", NLAnnouncerContainer, "CENTER", 0,0);	
end

function NL.SetExtraChats()
	NL.AnnouncerOptions ={
		"Addon Only",
		"Raid",
		"Party",
		"Whisper"
	}
	local channels = { }
	local chanList = { GetChannelList() }
	for i=1, #chanList, 3 do			
		local chanName = string.upper(chanList[i+1]);
		
		if chanName~= string.upper("General") 
		and chanName ~= string.upper("Trade")
		and chanName ~= string.upper("LocalDefense")
		and chanName ~= string.upper("WorldDefense") 
		and chanName ~= string.upper("LookingForGroup")
		and chanName ~= "LFG" then
			table.insert(NL.AnnouncerOptions, chanList[i+1]);
		end
	end
	--print("Updating Announcer Menu")
	NL.UpdateDropDownMenuWithNewOptions(LockyAnnouncerOptionMenu, NL.AnnouncerOptions, "CHAT")
end