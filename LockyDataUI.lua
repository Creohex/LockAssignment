--All of these functions are related to updating the ui from the data or vice versa.
--Will take in the string ID and return the appropriate Locky Frame
function NL.GetLockyFriendFrameById(LockyFrameID)
	for key, value in pairs(LockyFrame.scrollframe.content.LockyFriendFrames) do
		--print(key, " -- ", value["LockyFrameID"])
		if value["LockyFrameID"] == LockyFrameID then
			return value
		end
	end
end

--Will take in a string name and return the appropriate Locky Frame.
function NL.GetLockyFriendFrameByName(LockyName)
	for key, value in pairs(LockyFrame.scrollframe.content.LockyFriendFrames) do
		--print(key, " -- ", value["LockyFrameID"])
		if value["LockyName"] == LockyName then
			return value
		end
	end
end

--Will update a locky friend frame with the warlock data passed in.
--If the warlock object is null it will clear and hide the data from the screen.
function NL.UpdateLockyFrame(Warlock, LockyFriendFrame)
	--print("Updating Locky Frame")
	if(Warlock == nil) then
		LockyFriendFrame:Hide()
		Warlock = NL.CreateWarlock("", "None", "None", 0)
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
	UIDropDownMenu_SetSelectedID(LockyFriendFrame.CurseAssignmentMenu, NL.GetIndexFromTable(NL.CurseOptions, Warlock.CurseAssignment))
	NL.UpdateCurseGraphic(LockyFriendFrame.CurseAssignmentMenu, NL.GetCurseValueFromDropDownList(LockyFriendFrame.CurseAssignmentMenu))
	UIDropDownMenu_SetText(NL.GetCurseValueFromDropDownList(LockyFriendFrame.CurseAssignmentMenu), LockyFriendFrame.CurseAssignmentMenu)

	--Set the BanishAssignmentMenu
	--print("Updating Banish to: ".. Warlock.BanishAssignment)
	UIDropDownMenu_SetSelectedID(LockyFriendFrame.BanishAssignmentMenu, NL.GetIndexFromTable(NL.BanishMarkers, Warlock.BanishAssignment))
	NL.UpdateBanishGraphic(LockyFriendFrame.BanishAssignmentMenu, NL.GetValueFromDropDownList(LockyFriendFrame.BanishAssignmentMenu, NL.BanishMarkers, ""))
	UIDropDownMenu_SetText(NL.GetValueFromDropDownList(LockyFriendFrame.BanishAssignmentMenu, NL.BanishMarkers, ""), LockyFriendFrame.BanishAssignmentMenu)

	--Set the SS Assignment
	--print("Updating SS to: ".. Warlock.SSAssignment)
	NL.UpdateDropDownMenuWithNewOptions(LockyFriendFrame.SSAssignmentMenu, NL.GetSSTargets(), "SSAssignments");
	UIDropDownMenu_SetSelectedID(LockyFriendFrame.SSAssignmentMenu, NL.GetSSIndexFromTable(NL.GetSSTargets(),Warlock.SSAssignment))
	UIDropDownMenu_SetText(NL.GetValueFromDropDownList(LockyFriendFrame.SSAssignmentMenu, NL.GetSSTargets(), "SSAssignments"), LockyFriendFrame.SSAssignmentMenu)

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
	elseif (Warlock.AddonVersion< NL.Version) then
		LockyFriendFrame.Warning.value:SetText("Warning: Addon out of date")
		LockyFriendFrame.Warning:Show();
	else
		LockyFriendFrame.Warning:Hide();
	end

	return LockyFriendFrame.LockyFrameID
end

--This will use the global locky friends data.
function NL.UpdateAllLockyFriendFrames()
	if NL.DebugMode then
		print("Updating all frames.")
	end
    NL.ClearAllLockyFrames()
   -- print("All frames Cleared")
    NL.ConsolidateFrameLocations()
    --print("Frame Locations Consolidated")
	for key, value in pairs(NL.LockyFriendsData) do
		NL.UpdateLockyFrame(value, NL.GetLockyFriendFrameById(value.LockyFrameLocation))
	end
	if NL.DebugMode then
		print("Frames updated successfully.")
	end
    LockyFrame.scrollbar:SetMinMaxValues(1, NL.GetMaxValueForScrollBar(NL.LockyFriendsData))
  --  print("ScrollRegion size updated successfully")
end


--Loops through and clears all of the data currently loaded.
function  NL.ClearAllLockyFrames()
	--print("Clearing the frames")
	for key, value in pairs(LockyFrame.scrollframe.content.LockyFriendFrames) do

		NL.UpdateLockyFrame(nil, value)
		--print(value.LockyFrameID, "successfully cleared.")
	end
end

--This function will take in the warlock table object and update the frame assignment to make sense.
function  NL.ConsolidateFrameLocations()
	--Need to loop through and assign a locky frame id to a locky friend.
	--print("Setting up FrameLocations for the locky friend data.")
	for key, value in pairs(NL.LockyFriendsData) do		
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
function NL.UpdateLockyClockys()
	for k,v in pairs(NL.LockyFriendsData) do
		if (NL.DebugMode) then
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
			if(NL.DebugMode and v.SSCooldown~=0) then
				--print(v.Name,"my time:", v.MyTime, "localtime:", v.LocalTime, "timeShift:", timeShift, "LocalCD", v.SSCooldown, "Abs CD:",absCD, "Time Remaining:",secondsRemaining)
			end
			local frame = NL.GetLockyFriendFrameById(v.LockyFrameLocation)
			frame.SSCooldownTracker:SetText("CD "..result)

			if secondsRemaining <=0 or v.SSCooldown == 0 then
				v.SSonCD = "false"
				frame.SSCooldownTracker:SetText("Available")
			end
		end
	end
end

--Will set default assignments for curses / banishes and SS.
function NL.SetDefaultAssignments(warlockTable)	
	for k, y in pairs(warlockTable) do
		if(k<=3)then
			y.CurseAssignment = NL.CurseOptions[k+1]
		else
			y.CurseAssignment = NL.CurseOptions[1]
		end

		if(k<=7) then
			y.BanishAssignment = NL.BanishMarkers[k+1]
		else
			y.BanishAssignment = NL.BanishMarkers[1]
		end

		if(k<=2) then
			local strSS = NL.GetSSTargets()[k]
			--print(strSS)
			y.SSAssignment = strSS
		else
			local targets = NL.GetSSTargets()
			y.SSAssignment = targets[NL.GetTableLength(targets)]
		end
	end	
	return warlockTable
end

-- Gets the index of the frame that currently houses a particular warlock. 
-- This is used for force removal and not much else that I can recall.
function  NL.GetLockyFriendIndexByName(table, name)

	for key, value in pairs(table) do
		--print(key, " -- ", value["LockyFrameID"])
		--print(value.Name)
		if value.Name == name then
			if NL.DebugMode then
				print(value.Name, "is in position", key)
			end
			return key
		end
	end
	if NL.DebugMode then
		print(name, "is not in the list.")
	end
	return nil
end

--Checks to see if the SS is on CD, and broadcasts if it is to all everyone.
function NL.CheckSSCD(self)
    local startTime, duration, enable = GetItemCooldown(16896)
    --if my CD in never locky is different from the what I am aware of then I need to update.
	local myself = NL.GetMyLockyData()
	if myself ~= nil then
		if(myself.SSCooldown~=startTime) then
			if NL.DebugMode then
				print("Personal SSCD detected.")
			end
			myself.SSCooldown = startTime
			myself.LocalTime = GetTime()
			myself.SSonCD = "true"
		end    	
		--print(startTime, duration, enable, myself.Name)
		--If the SS is on CD then we broadcast that.
		
		--If the CD is on cooldown AND we have not broadcast in the last minute we will broadcast.
		if(startTime > 0 and self.TimeSinceLastSSCDBroadcast > NL.NeverLockySSCD_BroadcastInterval) then
			self.TimeSinceLastSSCDBroadcast=0
			NL.BroadcastSSCooldown(myself)
		end
	else
		if NL.DebugMode then
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

function NL.ForceUpdateSSCD()
	if NL.DebugMode then
		print("Forcing SSCD cache update.")
	end

	local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType,
	itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(16896)
	local bag, slot = GetBagPosition(itemName)
	if bag ~= nil and slot ~= nil then
		local startTime, duration, enable = GetContainerItemCooldown(bag, slot)
		local myself = NL.GetMyLockyData()
		if myself ~= nil then
			if(myself.SSCooldown~=startTime) then
				if NL.DebugMode then
					print("Personal SSCD detected.")
				end
				myself.SSCooldown = startTime
				myself.LocalTime = GetTime()
				myself.SSonCD = "true"
			end
		else
			if NL.DebugMode then
				print("Something went horribly wrong.")
			end
		end
	end
end

--Updates the cooldown of a warlock in the ui.
function NL.UpdateLockySSCDByName(name, cd)
	local warlock = NL.GetLockyDataByName(name)
	if NL.DebugMode then
		print("Attempting to update SS CD for", name);
	end
    --if warlock.SSCooldown~=cd then
		warlock.SSCooldown = cd      
		if NL.DebugMode then
			print("Updated SS CD for", name,"successfully.");
		end  
	--end
end

--Returns a warlock table object from the LockyFrame
--This function is used to determine if unsaved UI changes have been made.
--This will be used by the is dirty function to determine if the frame is dirty.
function NL.GetWarlockFromLockyFrame(LockyName)
    local LockyFriendFrame = NL.GetLockyFriendFrameByName(LockyName)
    local Warlock = NL.CreateWarlock(LockyFriendFrame.LockyName,
	NL.GetCurseValueFromDropDownList(LockyFriendFrame.CurseAssignmentMenu),
	NL.GetValueFromDropDownList(LockyFriendFrame.BanishAssignmentMenu, NL.BanishMarkers, ""))                
    Warlock.SSAssignment = NL.GetValueFromDropDownList(LockyFriendFrame.SSAssignmentMenu, NL.GetSSTargets(), "SSAssignments")         
    Warlock.LockyFrameLocation = LockyFriendFrame.LockyFrameID       
    return Warlock   
end

--Returns true if changes have been made but have not been saved.
function NL.IsUIDirty(LockyData)
	if(not LockyData_HasInitialized) then	
		NL.LockyFriendsData = NL.InitLockyFriendData();
		LockyData_HasInitialized = true;
		return true;
	end
    for k, v in pairs(LockyData) do
        local uiLock = NL.GetWarlockFromLockyFrame(v.Name)
        if(v.CurseAssignment~=uiLock.CurseAssignment or
        v.BanishAssignment ~= uiLock.BanishAssignment or
        v.SSAssignment ~= uiLock.SSAssignment) then
            return true
        end        
    end
    return false
end

--Commits any UI changes to the global LockyFriendsDataModel
function NL.CommitChanges(LockyFriendsData)
    
    for k, v in pairs(LockyFriendsData) do
        local uiLock = NL.GetWarlockFromLockyFrame(v.Name)
        if NL.DebugMode then
			print("Old: ", v.CurseAssignment, "New: ", uiLock.CurseAssignment)
			print("Old: ", v.BanishAssignment, "New: ", uiLock.BanishAssignment)
			print("Old",v.SSAssignment , "New:", uiLock.SSAssignment)
		end
        v.CurseAssignment = uiLock.CurseAssignment
        v.BanishAssignment = uiLock.BanishAssignment
		v.SSAssignment = uiLock.SSAssignment
		v.AcceptedAssignments = "nil"
    end
    LockyData_Timestamp = GetTime()
    return LockyFriendsData
end

function NL.AnnounceAssignments()
	local AnnounceOption = 	NL.GetValueFromDropDownList(LockyAnnouncerOptionMenu, NL.AnnouncerOptions, "");
	for k, v in pairs(NL.LockyFriendsData) do
		local message = ""
		if v.CurseAssignme1nt ~= "None"  or v.BanishAssignment ~= "None" or v.SSAssignment~="None" then
			message = v.Name .. ": ";
		end
		if v.CurseAssignment~="None" then
			message = message.."Curse -> ".. v.CurseAssignment .." ";
			NL.SendAnnounceMent(AnnounceOption, message, v);
		end
		if v.BanishAssignment~="None" then
			message = v.Name .. ": ".."Banish -> {".. v.BanishAssignment .."} ";
			NL.SendAnnounceMent(AnnounceOption, message, v);
		end
		if v.SSAssignment~="None" then
			message = v.Name .. ": ".."SS -> "..v.SSAssignment .." ";
			NL.SendAnnounceMent(AnnounceOption, message, v);
		end		
	end		
end

function NL.SendAnnounceMent(AnnounceOption, message, v)
	if AnnounceOption == "Addon Only" then
		if NL.DebugMode then					
			print(message)
		end
	elseif AnnounceOption == "Raid" then
		SendChatMessage(message, "RAID", nil, nil)
	elseif AnnounceOption == "Party" then
		SendChatMessage(message, "PARTY", nil, nil)
	elseif AnnounceOption == "Whisper" then
		SendChatMessage(message, "WHISPER", nil, v.Name)
	else
		if(NL.DebugMode) then
			print("Should send the announce here: " .. AnnounceOption)
		end
		
		local index = GetChannelName(AnnounceOption) -- It finds General is a channel at index 1
		if (index~=nil) then 
			SendChatMessage(message , "CHANNEL", nil, index); 
		end
	end
end
