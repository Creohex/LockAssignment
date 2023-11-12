--Initialization logic for setting up the entire addon
function LA.LockAssignmentInit()
	if not LockAssignmentFrame_HasInitialized then
		--print("Prepping init")
		LockAssignmentFrame:SetBackdrop({
			bgFile= "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true,
			tileSize = 32,
			edgeSize = 32,
			insets = { left = 11, right = 12, top = 12, bottom = 11 }
		})
		LA.InitLockyFrameScrollArea()
		--print("ScrollFrame initialized successfully.")
		LA.RegisterForComms()
		--print("Comms initialized successfully.")
		LockAssignmentFrame_HasInitialized = true
		--LockAssignmentFriendsData = InitLockyFriendData()
		--print("LockAssignmentFriendsData initialized successfully.")
		--LockAssignmentFriendsData = SetDefaultAssignments(LockAssignmentFriendsData)
		--print("LockAssignmentFriendsData Default Assignments Set successfully.")
		LA.UpdateAllLockyFriendFrames();
		
		--print("|cff9322B5Never Locky|cFFFFFFFF has been registered to the WOW UI.")
		--print("Use |cff9322B5/nl|cFFFFFFFF or |cff9322B5/neverlocky|cFFFFFFFF to view assignment information.")
		--LockAssignmentFrame:Show()
		LA.InitLockyAssignCheckFrame();
		LA.InitPersonalMonitorFrame();
		LA.InitAnnouncerOptionFrame();
	end	
end

-- Update handler to be used for any animations, is called once per frame, but can be throttled using an update interval.
function LockAssignment_OnUpdate(self, elapsed)
	if (self.TimeSinceLastClockUpdate == nil) then self.TimeSinceLastClockUpdate = 0; end
	if (self.TimeSinceLastSSCDUpdate == nil) then self.TimeSinceLastSSCDUpdate = 0; end
	if (self.TimeSinceLastSSCDBroadcast == nil) then self.TimeSinceLastSSCDBroadcast = 0; end

	self.TimeSinceLastClockUpdate = self.TimeSinceLastClockUpdate + elapsed; 	
	if (self.TimeSinceLastClockUpdate > LA.LockAssignmentClocky_UpdateInterval) then
		self.TimeSinceLastClockUpdate = 0;
		if LA.DebugMode then
			--print("Updating the UI");
		end
		LA.UpdateLockyClockys()
	end

	self.TimeSinceLastSSCDUpdate = self.TimeSinceLastSSCDUpdate + elapsed;
	self.TimeSinceLastSSCDBroadcast = self.TimeSinceLastSSCDBroadcast + elapsed;
	if(self.TimeSinceLastSSCDUpdate > LA.LockAssignmentSSCD_UpdateInterval) then
		self.TimeSinceLastSSCDUpdate = 0;
		if LA.DebugMode then
			print("Checking SSCD");
		end
		LA.CheckSSCD(self)
	end
end

function LA.RegisterRaid()
	local raidInfo = {}
	for i=1, 40 do
		local name, rank, subgroup, level, class, fileName, 
		  zone, online, isDead, role, isML = GetRaidRosterInfo(i);
		if not (name == nil) then
			if LA.DebugMode then
				print(name .. "-" .. fileName)	
			end
			table.insert(raidInfo, name)
		end
	end
	return raidInfo
end

local TestType = {}
TestType.init = "Initialization Test"
TestType.add = "Add Test"
TestType.remove = "Remove Test"
TestType.setDefault = "Default Settings Test"
local testmode = TestType.init

function LA.InitLockyFriendData()
	if(LA.RaidMode) then
		if LA.DebugMode then
			print("Initializing Friend Data")
		end
		DEFAULT_CHAT_FRAME:AddMessage("InitLockyFriendData in raid mode")
		return LA.RegisterWarlocks()
	else
		print("Raid mode is not active, running in Test mode.")			
		if testmode == TestType.init then
			print("Initializing with Test Data.")
			testmode = TestType.add
			return LA.RegisterMyTestData()
		elseif testmode == TestType.add then
			print("testing add")
			table.insert(LA.LockAssignmentFriendsData, LA.RegisterMyTestData()[1])
			testmode = TestType.remove
			return LA.LockAssignmentFriendsData
		elseif testmode == TestType.remove then
			print("testing remove")
			local p = LA.GetLockyFriendIndexByName(LA.LockAssignmentFriendsData, "Brylack")
			if not (p==nil) then
				table.remove(LA.LockAssignmentFriendsData, p)
			end
			testmode = TestType.setDefault
			return LA.LockAssignmentFriendsData
		elseif testmode == TestType.setDefault then
			print ("Setting default selection")
			LA.LockAssignmentFriendsData = LA.SetDefaultAssignments(LA.LockAssignmentFriendsData)
			testmode = TestType.init
			return LA.LockAssignmentFriendsData
		else
			return LA.LockAssignmentFriendsData
		end		
	end
end

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

--Generates a series of test data to populate the ui.
function LA.RegisterTestData()
	local testData = {}
	for i=1, 5 do
		table.insert(testData, LA.CreateWarlock("Brylack", LA.CurseOptions[math.random(1,LA.GetTableLength(LA.CurseOptions))], LA.BanishMarkers[math.random(1,LA.GetTableLength(LA.BanishMarkers))]));
	end
	return testData
end

--Generates test data that more closly mimics what one could see in an actual raid.
function LA.RegisterRealisicTestData()
	local testData = {}
	--table.insert(testData, AddAWarlock("Brylack", CurseOptions[math.random(1,GetTableLength(CurseOptions))], BanishMarkers[math.random(1,GetTableLength(BanishMarkers))]));
	table.insert(testData, LA.CreateWarlock("Giandy", LA.CurseOptions[math.random(1,LA.GetTableLength(LA.CurseOptions))], LA.BanishMarkers[math.random(1,LA.GetTableLength(LA.BanishMarkers))]));
	table.insert(testData, LA.CreateWarlock("Melon", LA.CurseOptions[math.random(1,LA.GetTableLength(LA.CurseOptions))], LA.BanishMarkers[math.random(1,LA.GetTableLength(LA.BanishMarkers))]));
	table.insert(testData, LA.CreateWarlock("Brylack", LA.CurseOptions[math.random(1,LA.GetTableLength(LA.CurseOptions))], LA.BanishMarkers[math.random(1,LA.GetTableLength(LA.BanishMarkers))]));
	table.insert(testData, LA.CreateWarlock("Itsyrekt", LA.CurseOptions[math.random(1,LA.GetTableLength(LA.CurseOptions))], LA.BanishMarkers[math.random(1,LA.GetTableLength(LA.BanishMarkers))]));
	table.insert(testData, LA.CreateWarlock("Dessian", LA.CurseOptions[math.random(1,LA.GetTableLength(LA.CurseOptions))], LA.BanishMarkers[math.random(1,LA.GetTableLength(LA.BanishMarkers))]));
	table.insert(testData, LA.CreateWarlock("Sociopath", LA.CurseOptions[math.random(1,LA.GetTableLength(LA.CurseOptions))], LA.BanishMarkers[math.random(1,LA.GetTableLength(LA.BanishMarkers))]));
	return testData
end

--Generates just my data and returns it in a table.
function LA.RegisterMyTestData()
	local testData = {}
	table.insert(testData, LA.CreateWarlock("Brylack", LA.CurseOptions[math.random(1,LA.GetTableLength(LA.CurseOptions))], LA.BanishMarkers[math.random(1,LA.GetTableLength(LA.BanishMarkers))]));
	return testData
end

function LA.RegisterMySoloData()
	local localizedClass, englishClass, classIndex = UnitClass("player");

	local soloData = {}
	if englishClass == "WARLOCK" then
		table.insert(soloData, LA.CreateWarlock(UnitName("player"), "None", "None"));
	end
	return soloData
end

--This is wired to a button click at present.
function LA.LockAssignment_HideFrame()
	if LA.IsUIDirty(LA.LockAssignmentFriendsData) then
		print("Changes were not saved.")
		--PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
		LockAssignmentFrame:Hide()
	else
		--PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
		LockAssignmentFrame:Hide()
	end
end

function LA.LockAssignment_Commit()
	LA.LockAssignmentFriendsData = LA.CommitChanges(LA.LockAssignmentFriendsData)
	LA.UpdateAllLockyFriendFrames();
	LA.SendAssignmentReset();
	LA.BroadcastTable(LA.LockAssignmentFriendsData)
	--print("Changes were sent out.");

	LA.AnnounceAssignments();
	--PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
	--LockAssignmentFrame:Hide()
end

--At this time this is just a test function.
function LA.Test()
	print("Updating a frame....")				
	LA.LockAssignmentFriendsData = LA.InitLockyFriendData();
	NLTest_Button.Text:SetText(testmode)
	--UpdateAllLockyFriendFrames();	
	LA.BroadcastTable(LA.LockAssignmentFriendsData);
end

-- Event for handling the frame showing.
function LA.LockAssignment_OnShowFrame()
	if not LockAssignmentData_HasInitialized then
		LA.LockAssignmentFriendsData = LA.InitLockyFriendData()
		
		--LockAssignmentData_Timestamp = 0
		LockAssignmentData_HasInitialized = true
		if LA.DebugMode then
			print("Initialization complete");
			
			print("Found " .. LA.GetTableLength(LA.LockAssignmentFriendsData) .. " Warlocks in raid." );
		end		
	end

	if LA.DebugMode then
		print("Frame should be showing now.")	
	end
	
	--PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
	--print("Updating SS targets")
	LA.UpdateSSTargets()
	LA.LockAssignmentFriendsData = LA.UpdateWarlocks(LA.LockAssignmentFriendsData);
	LA.UpdateAllLockyFriendFrames();
	LA.RequestAssignments()
	if LA.DebugMode then
		print("Found " .. LA.GetTableLength(LA.LockAssignmentFriendsData) .. " Warlocks in raid." );
	end	
	if LA.GetTableLength(LA.LockAssignmentFriendsData) == 0 then
		LA.RaidMode = false;
		LA.LockAssignmentFriendsData = LA.RegisterMySoloData();
	end
	LA.SetExtraChats();
end

-- /command for opening the ui.
SLASH_LA1 = "/la"
SLASH_LA2 = "/lockassignment"
SlashCmdList["LA"] = function(msg)

	if msg == "debug" then
		if(LA.DebugMode) then
			LA.DebugMode = false
			print("Never Locky Debug Mode OFF")
		else
			LA.DebugMode = true
			print("Never Locky Debug Mode ON")
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
