--Initialization logic for setting up the entire addon
function NL.NeverLockyInit()
	if not LockyFrame_HasInitialized then
		--print("Prepping init")
		NeverLockyFrame:SetBackdrop({
			bgFile= "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true,
			tileSize = 32,
			edgeSize = 32,
			insets = { left = 11, right = 12, top = 12, bottom = 11 }
		})
		NL.InitLockyFrameScrollArea()
		--print("ScrollFrame initialized successfully.")
		NL.RegisterForComms()
		--print("Comms initialized successfully.")
		LockyFrame_HasInitialized = true
		--LockyFriendsData = InitLockyFriendData()
		--print("LockyFriendsData initialized successfully.")
		--LockyFriendsData = SetDefaultAssignments(LockyFriendsData)
		--print("LockyFriendsData Default Assignments Set successfully.")
		NL.UpdateAllLockyFriendFrames();
		
		--print("|cff9322B5Never Locky|cFFFFFFFF has been registered to the WOW UI.")
		--print("Use |cff9322B5/nl|cFFFFFFFF or |cff9322B5/neverlocky|cFFFFFFFF to view assignment information.")
		--NeverLockyFrame:Show()
		NL.InitLockyAssignCheckFrame();
		NL.InitPersonalMonitorFrame();
		NL.InitAnnouncerOptionFrame();
	end	
end

-- Update handler to be used for any animations, is called once per frame, but can be throttled using an update interval.
function NeverLocky_OnUpdate(self, elapsed)
	if (self.TimeSinceLastClockUpdate == nil) then self.TimeSinceLastClockUpdate = 0; end
	if (self.TimeSinceLastSSCDUpdate == nil) then self.TimeSinceLastSSCDUpdate = 0; end
	if (self.TimeSinceLastSSCDBroadcast == nil) then self.TimeSinceLastSSCDBroadcast = 0; end

	self.TimeSinceLastClockUpdate = self.TimeSinceLastClockUpdate + elapsed; 	
	if (self.TimeSinceLastClockUpdate > NL.NeverLockyClocky_UpdateInterval) then
		self.TimeSinceLastClockUpdate = 0;
		if NL.DebugMode then
			--print("Updating the UI");
		end
		NL.UpdateLockyClockys()
	end

	self.TimeSinceLastSSCDUpdate = self.TimeSinceLastSSCDUpdate + elapsed;
	self.TimeSinceLastSSCDBroadcast = self.TimeSinceLastSSCDBroadcast + elapsed;
	if(self.TimeSinceLastSSCDUpdate > NL.NeverLockySSCD_UpdateInterval) then		
		self.TimeSinceLastSSCDUpdate = 0;
		if NL.DebugMode then
			print("Checking SSCD");
		end
		NL.CheckSSCD(self)
	end
end

function NL.RegisterRaid()
	local raidInfo = {}
	for i=1, 40 do
		local name, rank, subgroup, level, class, fileName, 
		  zone, online, isDead, role, isML = GetRaidRosterInfo(i);
		if not (name == nil) then
			if NL.DebugMode then
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

function NL.InitLockyFriendData()
	if(NL.RaidMode) then
		if NL.DebugMode then
			print("Initializing Friend Data")
		end
		DEFAULT_CHAT_FRAME:AddMessage("InitLockyFriendData in raid mode")
		return NL.RegisterWarlocks()
	else
		print("Raid mode is not active, running in Test mode.")			
		if testmode == TestType.init then
			print("Initializing with Test Data.")
			testmode = TestType.add
			return NL.RegisterMyTestData()
		elseif testmode == TestType.add then
			print("testing add")
			table.insert(NL.LockyFriendsData, NL.RegisterMyTestData()[1])
			testmode = TestType.remove
			return NL.LockyFriendsData
		elseif testmode == TestType.remove then
			print("testing remove")
			local p = NL.GetLockyFriendIndexByName(NL.LockyFriendsData, "Brylack")
			if not (p==nil) then
				table.remove(NL.LockyFriendsData, p)
			end
			testmode = TestType.setDefault
			return NL.LockyFriendsData
		elseif testmode == TestType.setDefault then
			print ("Setting default selection")
			NL.LockyFriendsData = NL.SetDefaultAssignments(NL.LockyFriendsData)
			testmode = TestType.init
			return NL.LockyFriendsData
		else
			return NL.LockyFriendsData
		end		
	end
end

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

--Generates a series of test data to populate the ui.
function NL.RegisterTestData()
	local testData = {}
	for i=1, 5 do
		table.insert(testData, NL.CreateWarlock("Brylack", NL.CurseOptions[math.random(1,NL.GetTableLength(NL.CurseOptions))], NL.BanishMarkers[math.random(1,NL.GetTableLength(NL.BanishMarkers))]));
	end
	return testData
end

--Generates test data that more closly mimics what one could see in an actual raid.
function NL.RegisterRealisicTestData()
	local testData = {}
	--table.insert(testData, AddAWarlock("Brylack", CurseOptions[math.random(1,GetTableLength(CurseOptions))], BanishMarkers[math.random(1,GetTableLength(BanishMarkers))]));
	table.insert(testData, NL.CreateWarlock("Giandy", NL.CurseOptions[math.random(1,NL.GetTableLength(NL.CurseOptions))], NL.BanishMarkers[math.random(1,NL.GetTableLength(NL.BanishMarkers))]));
	table.insert(testData, NL.CreateWarlock("Melon", NL.CurseOptions[math.random(1,NL.GetTableLength(NL.CurseOptions))], NL.BanishMarkers[math.random(1,NL.GetTableLength(NL.BanishMarkers))]));
	table.insert(testData, NL.CreateWarlock("Brylack", NL.CurseOptions[math.random(1,NL.GetTableLength(NL.CurseOptions))], NL.BanishMarkers[math.random(1,NL.GetTableLength(NL.BanishMarkers))]));	
	table.insert(testData, NL.CreateWarlock("Itsyrekt", NL.CurseOptions[math.random(1,NL.GetTableLength(NL.CurseOptions))], NL.BanishMarkers[math.random(1,NL.GetTableLength(NL.BanishMarkers))]));
	table.insert(testData, NL.CreateWarlock("Dessian", NL.CurseOptions[math.random(1,NL.GetTableLength(NL.CurseOptions))], NL.BanishMarkers[math.random(1,NL.GetTableLength(NL.BanishMarkers))]));
	table.insert(testData, NL.CreateWarlock("Sociopath", NL.CurseOptions[math.random(1,NL.GetTableLength(NL.CurseOptions))], NL.BanishMarkers[math.random(1,NL.GetTableLength(NL.BanishMarkers))]));
	return testData
end

--Generates just my data and returns it in a table.
function NL.RegisterMyTestData()
	local testData = {}
	table.insert(testData, NL.CreateWarlock("Brylack", NL.CurseOptions[math.random(1,NL.GetTableLength(NL.CurseOptions))], NL.BanishMarkers[math.random(1,NL.GetTableLength(NL.BanishMarkers))]));	
	return testData
end

function NL.RegisterMySoloData()
	local localizedClass, englishClass, classIndex = UnitClass("player");

	local soloData = {}
	if englishClass == "WARLOCK" then
		table.insert(soloData, NL.CreateWarlock(UnitName("player"), "None", "None"));	
	end
	return soloData
end

--This is wired to a button click at present.
function NL.NeverLocky_HideFrame()	
	if NL.IsUIDirty(NL.LockyFriendsData) then
		print("Changes were not saved.")
		--PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
		NeverLockyFrame:Hide()
	else
		--PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
		NeverLockyFrame:Hide()
	end
end

function NL.NeverLocky_Commit()
	NL.LockyFriendsData = NL.CommitChanges(NL.LockyFriendsData)
	NL.UpdateAllLockyFriendFrames();
	NL.SendAssignmentReset();
	NL.BroadcastTable(NL.LockyFriendsData)
	--print("Changes were sent out.");

	NL.AnnounceAssignments();
	--PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
	--NeverLockyFrame:Hide()
end

--At this time this is just a test function.
function NL.Test()
	print("Updating a frame....")				
	NL.LockyFriendsData = NL.InitLockyFriendData();
	NLTest_Button.Text:SetText(testmode)
	--UpdateAllLockyFriendFrames();	
	NL.BroadcastTable(NL.LockyFriendsData);
end

-- Event for handling the frame showing.
function NL.NeverLocky_OnShowFrame()
	if not LockyData_HasInitialized then
		NL.LockyFriendsData = NL.InitLockyFriendData()
		
		--LockyData_Timestamp = 0
		LockyData_HasInitialized = true
		if NL.DebugMode then
			print("Initialization complete");
			
			print("Found " .. NL.GetTableLength(NL.LockyFriendsData) .. " Warlocks in raid." );
		end		
	end

	if NL.DebugMode then
		print("Frame should be showing now.")	
	end
	
	--PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
	--print("Updating SS targets")
	NL.UpdateSSTargets()
	NL.LockyFriendsData = NL.UpdateWarlocks(NL.LockyFriendsData);
	NL.UpdateAllLockyFriendFrames();	
	NL.RequestAssignments()
	if NL.DebugMode then
		print("Found " .. NL.GetTableLength(NL.LockyFriendsData) .. " Warlocks in raid." );
	end	
	if NL.GetTableLength(NL.LockyFriendsData) == 0 then
		DEFAULT_CHAT_FRAME:AddMessage("NL.NeverLocky_OnShowFrame table empty")
		NL.RaidMode = false;
		NL.LockyFriendsData = NL.RegisterMySoloData();
	end
	NL.SetExtraChats();
end

-- /command for opening the ui.
SLASH_NL1 = "/nl"
SLASH_NL2 = "/neverlocky"
SlashCmdList["NL"] = function(msg)

	if msg == "debug" then
		if(NL.DebugMode) then
			NL.DebugMode = false
			print("Never Locky Debug Mode OFF")
		else
			NL.DebugMode = true
			print("Never Locky Debug Mode ON")
		end		
	elseif msg == "test" then
		LockyAssignCheckFrame:Show();
	else
		NeverLockyFrame:Show()
	end	
end

--Short hand /command for reloading the ui.
SLASH_RL1 = "/rl"
SlashCmdList["RL"]= function(msg)
	ReloadUI();
end
