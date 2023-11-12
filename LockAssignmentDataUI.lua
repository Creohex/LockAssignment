--All of these functions are related to updating the ui from the data or vice versa.
--Will take in the string ID and return the appropriate Locky Frame
function LA.GetLockyFriendFrameById(LockyFrameID)
	for key, value in pairs(LockyFrame.scrollframe.content.LockyFriendFrames) do
		--print(key, " -- ", value["LockyFrameID"])
		if value["LockyFrameID"] == LockyFrameID then
			return value
		end
	end
end

--Will take in a string name and return the appropriate Locky Frame.
function LA.GetLockyFriendFrameByName(LockyName)
	for key, value in pairs(LockyFrame.scrollframe.content.LockyFriendFrames) do
		--print(key, " -- ", value["LockyFrameID"])
		if value["LockyName"] == LockyName then
			return value
		end
	end
end

--Will update a locky friend frame with the warlock data passed in.
--If the warlock object is null it will clear and hide the data from the screen.
function LA.UpdateLockyFrame(Warlock, LockyFriendFrame)
	--print("Updating Locky Frame")
	if(Warlock == nil) then
		LockyFriendFrame:Hide()
		Warlock = LA.CreateWarlock("", "None", "None", 0)
	else
		LockyFriendFrame:Show()
	end
	--Set the nametag
    --print("Updating Nameplate Text to: ".. Warlock.Name)
    LockyFriendFrame.LockyName = Warlock.Name
	LockyFriendFrame.NamePlate.TextFrame:SetText(Warlock.Name)
	--Set the CurseAssignment
	--print("Updating Curse to: ".. Warlock.CurseAssignment) -- this may need to be done by index.....
	--GetIndexFromTable(CurseOptions, Warlock.CurseAssignment)
	UIDropDownMenu_SetSelectedID(LockyFriendFrame.CurseAssignmentMenu, LA.GetIndexFromTable(LA.CurseOptions, Warlock.CurseAssignment))
	LA.UpdateCurseGraphic(LockyFriendFrame.CurseAssignmentMenu, LA.GetCurseValueFromDropDownList(LockyFriendFrame.CurseAssignmentMenu))
	UIDropDownMenu_SetText(LA.GetCurseValueFromDropDownList(LockyFriendFrame.CurseAssignmentMenu), LockyFriendFrame.CurseAssignmentMenu)

	--Set the BanishAssignmentMenu
	--print("Updating Banish to: ".. Warlock.BanishAssignment)
	UIDropDownMenu_SetSelectedID(LockyFriendFrame.BanishAssignmentMenu, LA.GetIndexFromTable(LA.BanishMarkers, Warlock.BanishAssignment))
	LA.UpdateBanishGraphic(LockyFriendFrame.BanishAssignmentMenu, LA.GetValueFromDropDownList(LockyFriendFrame.BanishAssignmentMenu, LA.BanishMarkers, ""))
	UIDropDownMenu_SetText(LA.GetValueFromDropDownList(LockyFriendFrame.BanishAssignmentMenu, LA.BanishMarkers, ""), LockyFriendFrame.BanishAssignmentMenu)

	--Set the SS Assignment
	--print("Updating SS to: ".. Warlock.SSAssignment)
	LA.UpdateDropDownMenuWithNewOptions(LockyFriendFrame.SSAssignmentMenu, LA.GetSSTargets(), "SSAssignments");
	UIDropDownMenu_SetSelectedID(LockyFriendFrame.SSAssignmentMenu, LA.GetSSIndexFromTable(LA.GetSSTargets(),Warlock.SSAssignment))
	UIDropDownMenu_SetText(LA.GetValueFromDropDownList(LockyFriendFrame.SSAssignmentMenu, LA.GetSSTargets(), "SSAssignments"), LockyFriendFrame.SSAssignmentMenu)

	--Update the Portrait picture	
	if Warlock.Name=="" then
		LockyFriendFrame.Portrait:Hide()		
	else
		--print("Trying to set diff portrait")
		if(LockyFriendFrame.Portrait.Texture == nil) then
			--print("The obj never existed")
			local PortraitGraphic = LockyFriendFrame.Portrait:CreateTexture(nil, "OVERLAY") 
			PortraitGraphic:SetAllPoints()
			if Warlock.LockyName == UnitName("player") then
				SetPortraitTexture(texture, "player")
			else
				if Warlock.RaidIndex ~= nil then
					SetPortraitTexture(LockyFriendFrame.Portrait.Texture, string.format("raid%d", Warlock.RaidIndex))
				end
			end
			LockyFriendFrame.Portrait.Texture = PortraitGraphic
		else
			if Warlock.LockyName == UnitName("player") then
				SetPortraitTexture(texture, "player")
			else
				if Warlock.RaidIndex ~= nil then
					SetPortraitTexture(LockyFriendFrame.Portrait.Texture, string.format("raid%d", Warlock.RaidIndex))
				end
			end

		end
		LockyFriendFrame.Portrait:Show()
	end

	--Update acknowledged Update that text:
	if(Warlock.AcceptedAssignments == "true")then
		LockyFriendFrame.AssignmentAcknowledgement.value:SetText("Yes")
	elseif Warlock.AcceptedAssignments == "false" then
		LockyFriendFrame.AssignmentAcknowledgement.value:SetText("No")
	else
		LockyFriendFrame.AssignmentAcknowledgement.value:SetText("Not Received")
	end

	if(Warlock.AddonVersion == 0) then
		LockyFriendFrame.Warning.value:SetText("Warning: Addon not installed")
		LockyFriendFrame.Warning:Show();		
	elseif (Warlock.AddonVersion< LA.Version) then
		LockyFriendFrame.Warning.value:SetText("Warning: Addon out of date")
		LockyFriendFrame.Warning:Show();
	else
		LockyFriendFrame.Warning:Hide();
	end

	return LockyFriendFrame.LockyFrameID
end

--This will use the global locky friends data.
function LA.UpdateAllLockyFriendFrames()
	if LA.DebugMode then
		print("Updating all frames.")
	end
    LA.ClearAllLockyFrames()
   -- print("All frames Cleared")
    LA.ConsolidateFrameLocations()
    --print("Frame Locations Consolidated")
	for key, value in pairs(LA.LockAssignmentFriendsData) do
		LA.UpdateLockyFrame(value, LA.GetLockyFriendFrameById(value.LockyFrameLocation))
	end
	if LA.DebugMode then
		print("Frames updated successfully.")
	end
    LockyFrame.scrollbar:SetMinMaxValues(1, LA.GetMaxValueForScrollBar(LA.LockAssignmentFriendsData))
  --  print("ScrollRegion size updated successfully")
end


--Loops through and clears all of the data currently loaded.
function  LA.ClearAllLockyFrames()
	--print("Clearing the frames")
	for key, value in pairs(LockyFrame.scrollframe.content.LockyFriendFrames) do

		LA.UpdateLockyFrame(nil, value)
		--print(value.LockyFrameID, "successfully cleared.")
	end
end

--This function will take in the warlock table object and update the frame assignment to make sense.
function  LA.ConsolidateFrameLocations()
	--Need to loop through and assign a locky frame id to a locky friend.
	--print("Setting up FrameLocations for the locky friend data.")
	for key, value in pairs(LA.LockAssignmentFriendsData) do
		--print(value.Name, "will be assigned a frame.")
		value.LockyFrameLocation = LockyFrame.scrollframe.content.LockyFriendFrames[key].LockyFrameID;
		--print("Assigned Frame:",value.LockyFrameLocation)
	end
end

--[[
	Go through each lock.
	if SS is on CD then
	Update the CD Tracker Text
	else do nothing.
	]]--
function LA.UpdateLockyClockys()
	for k,v in pairs(LA.LockAssignmentFriendsData) do
		if (LA.DebugMode) then
			--print(v.Name, "on cooldown =", v.SSonCD)
		end
		if(v.SSonCD=="true") then
			-- We have the table item for the SSCooldown			
			local CDLength = 30*60
			local timeShift = 0
			
			timeShift = v.MyTime - v.LocalTime;
			
			local absCD = v.SSCooldown+timeShift;

			

			local secondsRemaining = math.floor(absCD + CDLength - GetTime())
			local result = SecondsToTime(secondsRemaining)			
			if(LA.DebugMode and v.SSCooldown~=0) then
				--print(v.Name,"my time:", v.MyTime, "localtime:", v.LocalTime, "timeShift:", timeShift, "LocalCD", v.SSCooldown, "Abs CD:",absCD, "Time Remaining:",secondsRemaining)
			end
			local frame = LA.GetLockyFriendFrameById(v.LockyFrameLocation)
			frame.SSCooldownTracker:SetText("CD "..result)

			if secondsRemaining <=0 or v.SSCooldown == 0 then
				v.SSonCD = "false"
				frame.SSCooldownTracker:SetText("Available")
			end
		end
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
function  LA.GetLockyFriendIndexByName(table, name)

	for key, value in pairs(table) do
		--print(key, " -- ", value["LockyFrameID"])
		--print(value.Name)
		if value.Name == name then
			if LA.DebugMode then
				print(value.Name, "is in position", key)
			end
			return key
		end
	end
	if LA.DebugMode then
		print(name, "is not in the list.")
	end
	return nil
end

--Checks to see if the SS is on CD, and broadcasts if it is to all everyone.
function LA.CheckSSCD(self)
    local startTime, duration, enable = GetItemCooldown(16896)
    --if my CD in never locky is different from the what I am aware of then I need to update.
	local myself = LA.GetMyLockyData()
	if myself ~= nil then
		if(myself.SSCooldown~=startTime) then
			if LA.DebugMode then
				print("Personal SSCD detected.")
			end
			myself.SSCooldown = startTime
			myself.LocalTime = GetTime()
			myself.SSonCD = "true"
		end    	
		--print(startTime, duration, enable, myself.Name)
		--If the SS is on CD then we broadcast that.
		
		--If the CD is on cooldown AND we have not broadcast in the last minute we will broadcast.
		if(startTime > 0 and self.TimeSinceLastSSCDBroadcast > LA.LockAssignmentSSCD_BroadcastInterval) then
			self.TimeSinceLastSSCDBroadcast=0
			LA.BroadcastSSCooldown(myself)
		end
	else
		if LA.DebugMode then
			print("Something went horribly wrong.")
		end
	end
end

local function GetBagPosition(itemName)
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local containerLink = GetContainerItemLink(bag, slot)
			if containerLink ~= nil then
				if string.find(containerLink, itemName) then
					return bag, slot
				end
			end
		end
	end
end

function LA.ForceUpdateSSCD()
	if LA.DebugMode then
		print("Forcing SSCD cache update.")
	end

	local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType,
	itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(16896)
	local bag, slot = GetBagPosition(itemName)
	if bag ~= nil and slot ~= nil then
		local startTime, duration, enable = GetContainerItemCooldown(bag, slot)
		local myself = LA.GetMyLockyData()
		if myself ~= nil then
			if(myself.SSCooldown~=startTime) then
				if LA.DebugMode then
					print("Personal SSCD detected.")
				end
				myself.SSCooldown = startTime
				myself.LocalTime = GetTime()
				myself.SSonCD = "true"
			end
		else
			if LA.DebugMode then
				print("Something went horribly wrong.")
			end
		end
	end
end

--Updates the cooldown of a warlock in the ui.
function LA.UpdateLockySSCDByName(name, cd)
	local warlock = LA.GetLockyDataByName(name)
	if LA.DebugMode then
		print("Attempting to update SS CD for", name);
	end
    --if warlock.SSCooldown~=cd then
		warlock.SSCooldown = cd      
		if LA.DebugMode then
			print("Updated SS CD for", name,"successfully.");
		end  
	--end
end

--Returns a warlock table object from the LockyFrame
--This function is used to determine if unsaved UI changes have been made.
--This will be used by the is dirty function to determine if the frame is dirty.
function LA.GetWarlockFromLockyFrame(LockyName)
    local LockyFriendFrame = LA.GetLockyFriendFrameByName(LockyName)
    local Warlock = LA.CreateWarlock(LockyFriendFrame.LockyName,
	LA.GetCurseValueFromDropDownList(LockyFriendFrame.CurseAssignmentMenu),
	LA.GetValueFromDropDownList(LockyFriendFrame.BanishAssignmentMenu, LA.BanishMarkers, ""))
    Warlock.SSAssignment = LA.GetValueFromDropDownList(LockyFriendFrame.SSAssignmentMenu, LA.GetSSTargets(), "SSAssignments")
    Warlock.LockyFrameLocation = LockyFriendFrame.LockyFrameID       
    return Warlock   
end

--Returns true if changes have been made but have not been saved.
function LA.IsUIDirty(LockyData)
	if(not LockAssignmentData_HasInitialized) then
		LA.LockAssignmentFriendsData = LA.InitLockyFriendData();
		LockAssignmentData_HasInitialized = true;
		return true;
	end
    for k, v in pairs(LockyData) do
        local uiLock = LA.GetWarlockFromLockyFrame(v.Name)
        if(v.CurseAssignment~=uiLock.CurseAssignment or
        v.BanishAssignment ~= uiLock.BanishAssignment or
        v.SSAssignment ~= uiLock.SSAssignment) then
            return true
        end        
    end
    return false
end

--Commits any UI changes to the global LockyFriendsDataModel
function LA.CommitChanges(LockAssignmentFriendsData)
    
    for k, v in pairs(LockAssignmentFriendsData) do
        local uiLock = LA.GetWarlockFromLockyFrame(v.Name)
        if LA.DebugMode then
			print("Old: ", v.CurseAssignment, "New: ", uiLock.CurseAssignment)
			print("Old: ", v.BanishAssignment, "New: ", uiLock.BanishAssignment)
			print("Old",v.SSAssignment , "New:", uiLock.SSAssignment)
		end
        v.CurseAssignment = uiLock.CurseAssignment
        v.BanishAssignment = uiLock.BanishAssignment
		v.SSAssignment = uiLock.SSAssignment
		v.AcceptedAssignments = "nil"
    end
    LockAssignmentData_Timestamp = GetTime()
    return LockAssignmentFriendsData
end

function LA.AnnounceAssignments()
	local AnnounceOption = 	LA.GetValueFromDropDownList(LockyAnnouncerOptionMenu, LA.AnnouncerOptions, "");
	for k, v in pairs(LA.LockAssignmentFriendsData) do
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
			print(message)
		end
	elseif AnnounceOption == "Raid" then
		SendChatMessage(message, "RAID", nil, nil)
	elseif AnnounceOption == "Party" then
		SendChatMessage(message, "PARTY", nil, nil)
	elseif AnnounceOption == "Whisper" then
		SendChatMessage(message, "WHISPER", nil, v.Name)
	else
		if(LA.DebugMode) then
			print("Should send the announce here: " .. AnnounceOption)
		end
		
		local index = GetChannelName(AnnounceOption) -- It finds General is a channel at index 1
		if (index~=nil) then 
			SendChatMessage(message , "CHANNEL", nil, index); 
		end
	end
end
