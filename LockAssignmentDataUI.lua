--All of these functions are related to updating the ui from the data or vice versa.
--Will take in the string ID and return the appropriate Lock Frame
function LA.GetWarlockFrameById(LockFrameID)
	for key, value in pairs(AssignmentFrame.scrollframe.content.WarlockFrames) do
		--LA.print(key, " -- ", value["LockFrameID"])
		if value["LockFrameID"] == LockFrameID then
			return value
		end
	end
end

--Will take in a string name and return the appropriate frame.
function LA.GetWarlockFrameByName(WarlockName)
	for key, value in pairs(AssignmentFrame.scrollframe.content.WarlockFrames) do
		--LA.print(key, " -- ", value["LockFrameID"])
		if value["WarlockName"] == WarlockName then
			return value
		end
	end
end

--Will update a warlock frame with the warlock data passed in.
--If the warlock object is null it will clear and hide the data from the screen.
function LA.UpdateAssignmentFrame(Warlock, AssignmentFrame)
	if(Warlock == nil) then
		AssignmentFrame:Hide()
		Warlock = LA.CreateWarlock("", "None", "None", 0)
	else
		AssignmentFrame:Show()
	end
	--Set the nametag
    AssignmentFrame.WarlockName = Warlock.Name
	AssignmentFrame.NamePlate.TextFrame:SetText(Warlock.Name)
	--Set the CurseAssignment
	UIDropDownMenu_SetSelectedID(AssignmentFrame.CurseAssignmentMenu, LA.GetIndexFromTable(LA.CurseOptions, Warlock.CurseAssignment))
	LA.UpdateCurseGraphic(AssignmentFrame.CurseAssignmentMenu, LA.GetCurseValueFromDropDownList(AssignmentFrame.CurseAssignmentMenu))
	UIDropDownMenu_SetText(LA.GetCurseValueFromDropDownList(AssignmentFrame.CurseAssignmentMenu), AssignmentFrame.CurseAssignmentMenu)

	--Set the BanishAssignmentMenu
	UIDropDownMenu_SetSelectedID(AssignmentFrame.BanishAssignmentMenu, LA.GetIndexFromTable(LA.BanishMarkers, Warlock.BanishAssignment))
	LA.UpdateBanishGraphic(AssignmentFrame.BanishAssignmentMenu, LA.GetValueFromDropDownList(AssignmentFrame.BanishAssignmentMenu, LA.BanishMarkers, ""))
	UIDropDownMenu_SetText(LA.GetValueFromDropDownList(AssignmentFrame.BanishAssignmentMenu, LA.BanishMarkers, ""), AssignmentFrame.BanishAssignmentMenu)

	--Set the SS Assignment
	LA.UpdateSoulstoneDropDownMenuWithNewOptions(AssignmentFrame.SSAssignmentMenu, LA.GetSSTargets(), "SSAssignments");
	UIDropDownMenu_SetSelectedID(AssignmentFrame.SSAssignmentMenu, LA.GetSSIndexFromTable(LA.GetSSTargets(), Warlock.SSAssignment))
	
	local selecedSSTarget = UIDropDownMenu_GetSelectedID(AssignmentFrame.SSAssignmentMenu)
	if selecedSSTarget ~= nil then
		local ssAssignment = LA.GetSSTargets()[selecedSSTarget]
		UIDropDownMenu_SetText("|c" .. ssAssignment.Color .. ssAssignment.Name, AssignmentFrame.SSAssignmentMenu)
	else
		UIDropDownMenu_SetText(LA.GetValueFromDropDownList(AssignmentFrame.SSAssignmentMenu, LA.GetSSTargets(), "SSAssignments"), AssignmentFrame.SSAssignmentMenu)
	end

	--Update the Portrait picture	
	if Warlock.Name=="" then
		AssignmentFrame.Portrait:Hide()
	else
		if(AssignmentFrame.Portrait.Texture == nil) then
			local PortraitGraphic = AssignmentFrame.Portrait:CreateTexture(nil, "OVERLAY")
			PortraitGraphic:SetAllPoints()
			if Warlock.WarlockName == UnitName("player") then
				SetPortraitTexture(PortraitGraphic, "player")
			elseif Warlock.RaidIndex ~= nil then
				SetPortraitTexture(PortraitGraphic, string.format("raid%d", Warlock.RaidIndex))
			else
				SetPortraitTexture(PortraitGraphic, "player")
			end
			AssignmentFrame.Portrait.Texture = PortraitGraphic
		else
			if Warlock.WarlockName == UnitName("player") then
				SetPortraitTexture(AssignmentFrame.Portrait.Texture, "player")
			elseif Warlock.RaidIndex ~= nil then
				SetPortraitTexture(AssignmentFrame.Portrait.Texture, string.format("raid%d", Warlock.RaidIndex))
			else
				SetPortraitTexture(AssignmentFrame.Portrait.Texture, "player")
			end
		end
		AssignmentFrame.Portrait:Show()
	end

	--Update acknowledged Update that text:
	if(Warlock.AcceptedAssignments == "true")then
		AssignmentFrame.AssignmentAcknowledgement.value:SetText("Yes")
	elseif Warlock.AcceptedAssignments == "false" then
		AssignmentFrame.AssignmentAcknowledgement.value:SetText("No")
	else
		AssignmentFrame.AssignmentAcknowledgement.value:SetText("Not Received")
	end

	if(Warlock.AddonVersion == 0) then
		AssignmentFrame.Warning.value:SetText("Warning: Addon not installed")
		AssignmentFrame.Warning:Show();
	elseif (Warlock.AddonVersion< LA.Version) then
		AssignmentFrame.Warning.value:SetText("Warning: Addon out of date")
		AssignmentFrame.Warning:Show();
	else
		AssignmentFrame.Warning:Hide();
	end

	return AssignmentFrame.LockFrameID
end

--This will use the global warlocks data.
function LA.UpdateAllWarlockFrames()
	if LA.DebugMode then
		LA.print("Updating all frames.")
	end
    LA.ClearAllAssignmentFrames()
   -- LA.print("All frames Cleared")
    LA.ConsolidateFrameLocations()
    --LA.print("Frame Locations Consolidated")
	for key, value in pairs(LA.LockAssignmentsData) do
		LA.UpdateAssignmentFrame(value, LA.GetWarlockFrameById(value.AssignmentFrameLocation))
	end
	if LA.DebugMode then
		LA.print("Frames updated successfully.")
	end
    AssignmentFrame.scrollbar:SetMinMaxValues(1, LA.GetMaxValueForScrollBar(LA.LockAssignmentsData))
  --  print("ScrollRegion size updated successfully")
end


--Loops through and clears all of the data currently loaded.
function  LA.ClearAllAssignmentFrames()
	--print("Clearing the frames")
	for key, value in pairs(AssignmentFrame.scrollframe.content.WarlockFrames) do

		LA.UpdateAssignmentFrame(nil, value)
		--print(value.LockFrameID, "successfully cleared.")
	end
end

--This function will take in the warlock table object and update the frame assignment to make sense.
function  LA.ConsolidateFrameLocations()
	--Need to loop through and assign a frame id to a warlock.
	--print("Setting up FrameLocations for the warlock data.")
	for key, value in pairs(LA.LockAssignmentsData) do
		--print(value.Name, "will be assigned a frame.")
		value.AssignmentFrameLocation = AssignmentFrame.scrollframe.content.WarlockFrames[key].LockFrameID;
		--print("Assigned Frame:",value.AssignmentFrameLocation)
	end
end

--[[
	Go through each lock.
	if SS is on CD then
	Update the CD Tracker Text
	else do nothing.
	]]--
function LA.UpdateAllLocksAssignmentClock()
	for k,v in pairs(LA.LockAssignmentsData) do
		LA.UpdateLockClock(v)
	end
end

function LA.UpdateLockClock(warlock)
	if (LA.DebugMode) then
		LA.print(warlock.Name, "on cooldown =", warlock.SSonCD)
	end

	local frame = LA.GetWarlockFrameById(warlock.AssignmentFrameLocation)

	if(warlock.SSonCD == "true" and warlock.SSCooldown ~= nil) then
		-- We have the table item for the SSCooldown
		local CDLength = 30*60
		local timeShift = 0

		if (warlock.MyTime ~= 0) then
			timeShift = warlock.MyTime - warlock.LocalTime;
		end

		local absCD = warlock.SSCooldown+timeShift;

		local secondsRemaining = math.floor(absCD + CDLength - GetTime())
		local result = SecondsToTime(secondsRemaining)
		if(LA.DebugMode) then
			LA.print(warlock.Name,"my time:", warlock.MyTime, "localtime:", warlock.LocalTime, "timeShift:", timeShift, "LocalCD", warlock.SSCooldown, "Abs CD:",absCD, "Time Remaining:",secondsRemaining)
		end
		frame.SSCooldownTracker:SetText("CD "..result)

		if secondsRemaining <=0 or warlock.SSCooldown == 0 then
			warlock.SSonCD = "false"
			frame.SSCooldownTracker:SetText("Available")
		end
	elseif (warlock.SSonCD == "unknown") then
		frame.SSCooldownTracker:SetText("Unknown")
	end
end

--Will set default assignments for curses / banishes and SS.
function LA.SetDefaultAssignments(warlockTable)
	for k, y in pairs(warlockTable) do
		if(k<=3)then
			y.CurseAssignment = LA.CurseOptions[k+1]
		else
			y.CurseAssignment = LA.CurseOptions[1]
		end

		if(k<=7) then
			y.BanishAssignment = LA.BanishMarkers[k+1]
		else
			y.BanishAssignment = LA.BanishMarkers[1]
		end

		if(k<=2) then
			local strSS = LA.GetSSTargets()[k]
			--print(strSS)
			y.SSAssignment = strSS
		else
			local targets = LA.GetSSTargets()
			y.SSAssignment = targets[LA.GetTableLength(targets)]
		end
	end	
	return warlockTable
end

-- Gets the index of the frame that currently houses a particular warlock. 
-- This is used for force removal and not much else that I can recall.
function  LA.GetAssignmentIndexByName(table, name)

	for key, value in pairs(table) do
		--print(key, " -- ", value["LockFrameID"])
		--print(value.Name)
		if value.Name == name then
			if LA.DebugMode then
				LA.print(value.Name, "is in position", key)
			end
			return key
		end
	end
	if LA.DebugMode then
		LA.print(name, "is not in the list.")
	end
	return nil
end

--Checks to see if the SS is on CD, and broadcasts if it is to all everyone.
function LA.CheckSSCD(self)
    local startTime, duration, enable = GetItemCooldown("Major Soulstone")
    --if my CD in lock assignments is different from the what I am aware of then I need to update.
	local myself = LA.GetMyData()
	if myself ~= nil then
		if(myself.SSCooldown~=startTime) then
			LA.UpdateSSCD(myself, startTime)
		end    	
		--print(startTime, duration, enable, myself.Name)
		--If the SS is on CD then we broadcast that.
		
		--If the CD is on cooldown AND we have not broadcast in the last minute we will broadcast.
		if(startTime ~= nil and startTime > 0 and self.TimeSinceLastSSCDBroadcast > LA.LockAssignmentSSCD_BroadcastInterval) then
			self.TimeSinceLastSSCDBroadcast=0
			LA.BroadcastSSCooldown(myself)
		end
	else
		if LA.DebugMode then
			LA.print("Something went horribly wrong.")
		end
	end
end

function LA.ForceUpdateSSCD()
	if LA.DebugMode then
		LA.print("Forcing SSCD cache update.")
	end

	local startTime, _, _ = GetItemCooldown("Major Soulstone")
	local myself = LA.GetMyData()
	if myself ~= nil then
		if(myself.SSCooldown~=startTime) then
			LA.UpdateSSCD(myself, startTime)
		end
	else
		if LA.DebugMode then
			LA.print("Something went horribly wrong.")
		end
	end
end

function LA.UpdateSSCD(myself, startTime)
	if LA.DebugMode then
		LA.print("Personal SSCD detected.")
	end
	if (startTime == nil) then
		if (myself.SSCooldown ~= nil) then
			if (myself.SSCooldown == 0) then
				myself.SSCooldown = nil
				myself.SSonCD = "unknown"
			else
				myself.SSonCD = "true"
			end
		else
			myself.SSCooldown = nil
			myself.SSonCD = "unknown"
		end
		myself.LocalTime = GetTime()
	else
		myself.SSCooldown = startTime
		myself.LocalTime = GetTime()
		myself.SSonCD = "true"
	end
	--LA.UpdateLockClock(myself)
end

--Updates the cooldown of a warlock in the ui.
function LA.UpdateAssignmentSSCDByName(name, cd)
	local warlock = LA.GetAssignmentDataByName(name)
	if LA.DebugMode then
		LA.print("Attempting to update SS CD for", name);
	end
    --if warlock.SSCooldown~=cd then
		warlock.SSCooldown = cd      
		if LA.DebugMode then
			LA.print("Updated SS CD for", name,"successfully.");
		end  
	--end
end

--Returns a warlock table object from the AssignmentFrame
--This function is used to determine if unsaved UI changes have been made.
--This will be used by the is dirty function to determine if the frame is dirty.
function LA.GetWarlockFromAssignmentFrame(WarlockName)
    local AssignmentFrame = LA.GetWarlockFrameByName(WarlockName)
    local Warlock = LA.CreateWarlock(AssignmentFrame.WarlockName,
	LA.GetCurseValueFromDropDownList(AssignmentFrame.CurseAssignmentMenu),
	LA.GetValueFromDropDownList(AssignmentFrame.BanishAssignmentMenu, LA.BanishMarkers, ""))
    Warlock.SSAssignment = LA.GetValueFromDropDownList(AssignmentFrame.SSAssignmentMenu, LA.GetSSTargets(), "SSAssignments")
    Warlock.AssignmentFrameLocation = AssignmentFrame.LockFrameID
    return Warlock   
end

--Returns true if changes have been made but have not been saved.
function LA.IsUIDirty(AssignmentData)
	if(not LockAssignmentData_HasInitialized) then
		LA.LockAssignmentsData = LA.InitLockAssignmentData();
		LockAssignmentData_HasInitialized = true;
		return true;
	end
    for k, v in pairs(AssignmentData) do
        local uiLock = LA.GetWarlockFromAssignmentFrame(v.Name)
        if(v.CurseAssignment~=uiLock.CurseAssignment or
        v.BanishAssignment ~= uiLock.BanishAssignment or
        v.SSAssignment ~= uiLock.SSAssignment) then
            return true
        end        
    end
    return false
end

--Commits any UI changes to the global LockAssignmentsData
function LA.CommitChanges(LockAssignmentsData)
    
    for k, v in pairs(LockAssignmentsData) do
        local uiLock = LA.GetWarlockFromAssignmentFrame(v.Name)
        if LA.DebugMode then
			LA.print("Old: ", v.CurseAssignment, "New: ", uiLock.CurseAssignment)
			LA.print("Old: ", v.BanishAssignment, "New: ", uiLock.BanishAssignment)
			LA.print("Old",v.SSAssignment , "New:", uiLock.SSAssignment)
		end
        v.CurseAssignment = uiLock.CurseAssignment
        v.BanishAssignment = uiLock.BanishAssignment
		v.SSAssignment = uiLock.SSAssignment
		v.AcceptedAssignments = "nil"
    end
    LockAssignmentData_Timestamp = GetTime()
    return LockAssignmentsData
end

function LA.AnnounceAssignments()
	local AnnounceOption = 	LA.GetValueFromDropDownList(LockAssignmentAnnouncerOptionMenu, LA.AnnouncerOptions, "");
	for k, v in pairs(LA.LockAssignmentsData) do
		local message = ""
		if v.CurseAssignme1nt ~= "None"  or v.BanishAssignment ~= "None" or v.SSAssignment~="None" then
			message = v.Name .. ": ";
		end
		if v.CurseAssignment~="None" then
			message = message.."Curse -> ".. v.CurseAssignment .." ";
			LA.SendAnnounceMent(AnnounceOption, message, v);
		end
		if v.BanishAssignment~="None" then
			message = v.Name .. ": ".."Banish -> {".. v.BanishAssignment .."} ";
			LA.SendAnnounceMent(AnnounceOption, message, v);
		end
		if v.SSAssignment~="None" then
			message = v.Name .. ": ".."SS -> "..v.SSAssignment .." ";
			LA.SendAnnounceMent(AnnounceOption, message, v);
		end		
	end		
end

function LA.SendAnnounceMent(AnnounceOption, message, v)
	if AnnounceOption == "Addon Only" then
		if LA.DebugMode then
			LA.print(message)
		end
	elseif AnnounceOption == "Raid" then
		SendChatMessage(message, "RAID", nil, nil)
	elseif AnnounceOption == "Party" then
		SendChatMessage(message, "PARTY", nil, nil)
	elseif AnnounceOption == "Whisper" then
		SendChatMessage(message, "WHISPER", nil, v.Name)
	else
		if(LA.DebugMode) then
			LA.print("Should send the announce here: " .. AnnounceOption)
		end
		
		local index = GetChannelName(AnnounceOption) -- It finds General is a channel at index 1
		if (index~=nil) then 
			SendChatMessage(message , "CHANNEL", nil, index); 
		end
	end
end
