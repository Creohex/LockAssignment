--Initialization logic for setting up the entire addon
function LA.LockAssignmentInit()
	if not LockAssignmentFrame_HasInitialized then
		--LA.print("Prepping init")
		LockAssignmentFrame:SetBackdrop({
			bgFile= "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true,
			tileSize = 32,
			edgeSize = 32,
			insets = { left = 11, right = 12, top = 12, bottom = 11 }
		})
		LA.InitLockAssignmentFrameScrollArea()
		LA.RegisterForComms()
		LockAssignmentFrame_HasInitialized = true
		LA.UpdateAllWarlockFrames();
		LA.InitLockAssignmentCheckFrame();
		LA.InitPersonalMonitorFrame();
		LA.InitAnnouncerOptionFrame();
		LA.ShowMinimapButton()
		LockAssignmentFrame:Hide()
		tinsert(UISpecialFrames, "LockAssignmentFrame");
	end	
end

function LA.ShowMinimapButton()
	LockAssignmentMinimapButton:Show();
end

-- Update handler to be used for any animations, is called once per frame, but can be throttled using an update interval.
function LockAssignment_OnUpdate(self, elapsed)
	if (self.TimeSinceLastClockUpdate == nil) then self.TimeSinceLastClockUpdate = 0; end
	if (self.TimeSinceLastSSCDUpdate == nil) then self.TimeSinceLastSSCDUpdate = 0; end
	if (self.TimeSinceLastSSCDBroadcast == nil) then self.TimeSinceLastSSCDBroadcast = 0; end

	self.TimeSinceLastClockUpdate = self.TimeSinceLastClockUpdate + elapsed; 	
	if (self.TimeSinceLastClockUpdate > LA.LockAssignmentClock_UpdateInterval) then
		self.TimeSinceLastClockUpdate = 0;
		if LA.DebugMode then
			--LA.print("Updating the UI");
		end
		LA.UpdateLockAssignmentClock()
	end

	self.TimeSinceLastSSCDUpdate = self.TimeSinceLastSSCDUpdate + elapsed;
	self.TimeSinceLastSSCDBroadcast = self.TimeSinceLastSSCDBroadcast + elapsed;
	if(self.TimeSinceLastSSCDUpdate > LA.LockAssignmentSSCD_UpdateInterval) then
		self.TimeSinceLastSSCDUpdate = 0;
		if LA.DebugMode then
			LA.print("Checking SSCD");
		end
		LA.CheckSSCD(self)
	end
end

function LA.RegisterRaid()
	local raidInfo = {}
	for i=1, 40 do
		local name, _, _, _, _, fileName, _, _, _, _, _ = GetRaidRosterInfo(i);
		if not (name == nil) then
			if LA.DebugMode then
				LA.print(name .. "-" .. fileName)
			end
			table.insert(raidInfo, name)
		end
	end
	return raidInfo
end

function LA.InitLockAssignmentData()
	if(LA.RaidMode) then
		if LA.DebugMode then
			LA.print("Initializing Warlock Data")
		end
		return LA.RegisterWarlocks()
	else
		return LA.LockAssignmentsData
	end
end

function  LA.GetAssignmentIndexByName(table, name)

	for key, value in pairs(table) do
		--LA.print(key, " -- ", value["LockFrameID"])
		--LA.print(value.Name)
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

function LA.RegisterMySoloData()
	local _, englishClass, _ = UnitClass("player");

	local soloData = {}
	if englishClass == "WARLOCK" then
		table.insert(soloData, LA.CreateWarlock(UnitName("player"), "None", "None"));
	end
	return soloData
end

--This is wired to a button click at present.
function LA.LockAssignment_HideFrame()
	if LA.IsUIDirty(LA.LockAssignmentsData) then
		LA.print("Changes were not saved.")
		--PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
		LockAssignmentFrame:Hide()
	else
		--PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
		LockAssignmentFrame:Hide()
	end
end

function LA.LockAssignment_Commit()
	if LA.FindMyRaidRank() < 1 then
		LACommit_Button:Disable();
	else
		LA.LockAssignmentsData = LA.CommitChanges(LA.LockAssignmentsData)
		LA.UpdateAllWarlockFrames();
		LA.SendAssignmentReset();
		LA.BroadcastTable(LA.LockAssignmentsData)

		LA.AnnounceAssignments();
		--PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
		--LockAssignmentFrame:Hide()
	end
end

-- Returns my rank to determine whether we should disable commit button
function LA.FindMyRaidRank()
	for i=1, 40 do
		local name, rank, _, _, _, fileName, _, _, _, _, _ = GetRaidRosterInfo(i);
		if not (name == nil) then
			if fileName == "WARLOCK" and name == UnitName("player") then
				return rank
			end
		end
	end
	return 0
end

-- Event for handling the frame showing.
function LA.LockAssignment_OnShowFrame()
	if not LockAssignmentData_HasInitialized then
		LA.LockAssignmentsData = LA.InitLockAssignmentData()
		
		--LockAssignmentData_Timestamp = 0
		LockAssignmentData_HasInitialized = true
		if LA.DebugMode then
			LA.print("Initialization complete");
			
			LA.print("Found " .. LA.GetTableLength(LA.LockAssignmentsData) .. " Warlocks in raid." );
		end		
	end

	if LA.DebugMode then
		LA.print("Frame should be showing now.")
	end
	
	--PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
	--LA.print("Updating SS targets")
	LA.UpdateSSTargets()
	LA.LockAssignmentsData = LA.UpdateWarlocks(LA.LockAssignmentsData);
	LA.UpdateAllWarlockFrames();
	LA.RequestAssignments()
	if LA.DebugMode then
		LA.print("Found " .. LA.GetTableLength(LA.LockAssignmentsData) .. " Warlocks in raid." );
	end	
	if LA.GetTableLength(LA.LockAssignmentsData) == 0 then
		LA.RaidMode = false;
		LA.LockAssignmentsData = LA.RegisterMySoloData();
	end
	LA.SetExtraChats();
	if LA.FindMyRaidRank() >= 1 then
		LACommit_Button:Enable();
	end
end

-- /command for opening the ui.
SLASH_LA1 = "/la"
SLASH_LA2 = "/lockassignment"
SlashCmdList["LA"] = function(msg)

	if msg == "debug" then
		if(LA.DebugMode) then
			LA.DebugMode = false
			LA.print("Lock Assignment Debug Mode OFF")
		else
			LA.DebugMode = true
			LA.print("Lock Assignment Debug Mode ON")
		end		
	elseif msg == "test" then
		LockAssignmentAssignCheckFrame:Show();
	else
		LockAssignmentFrame:Show()
	end	
end

--Short hand /command for reloading the ui.
SLASH_RL1 = "/rl"
SlashCmdList["RL"]= function(msg)
	ReloadUI();
end
