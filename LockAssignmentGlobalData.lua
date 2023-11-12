--General global variables
LA = {};
LA.RaidMode = true;
LA.DebugMode = false;
LA.Version = 113
LA.LockAssignmentFriendFrameWidth = 500;
LA.LockAssignmentFriendFrameHeight = 128
LA.LockAssignmentFrame_HasInitialized = false; -- Used to prevent reloads from redrawing the ui.
LA.LockAssignmentData_HasInitialized = false;
LA.LockAssignmentData_Timestamp = 0.0;
LA.LockAssignmentFriendsData = {}; -- Global for storing the warlocks and thier assignements.
LA.LockAssignmentClocky_UpdateInterval = 1.0; -- How often the OnUpdate code will run (in seconds)
LA.LockAssignmentSSCD_UpdateInterval = 5.0; -- How often to broadcast / check our SS cooldown.
LA.LockAssignmentSSCD_BroadcastInterval = 60.0; -- How often to broadcast / check our SS cooldown.
if LockAssignment == nil then
	LockAssignment = LibStub("AceAddon-3.0"):NewAddon("LockAssignment", "AceComm-3.0")
end
LA.LockAssignmentAssignCheckFrame={}
LA.IsMyAddonOutOfDate=false;
LA.MacroName =  "CurseAssignment";


function  LA.CreateWarlock(name, curse, banish, raidIndex)
	local Warlock = {}
			Warlock.Name = name
			Warlock.CurseAssignment = curse
			Warlock.BanishAssignment = banish
			Warlock.SSAssignment = "None"
			Warlock.SSCooldown=0
			Warlock.AcceptedAssignments = "nil"
			Warlock.LockyFrameLocation = ""
			Warlock.SSonCD = "false"
			Warlock.LocalTime= 0
			Warlock.MyTime = 0
			Warlock.AddonVersion = 0
			Warlock.RaidIndex = raidIndex
	return Warlock
end

--Pulls all of the warlocks in the raid and initilizes thier assignment data.
function LA.RegisterWarlocks()
	local raidInfo = {}
	for i=1, 40 do
		local name, rank, subgroup, level, class, fileName, 
		  zone, online, isDead, role, isML = GetRaidRosterInfo(i);
		if not (name == nil) then
			if fileName == "WARLOCK" then
				if LA.DebugMode then
					print(name .. "-" .. fileName)
				end
				table.insert(raidInfo, LA.CreateWarlock(name, "None", "None", i))
			end
		end		
	end
	if LA.GetTableLength(raidInfo) == 0 then
		LA.RaidMode = false;
		return LA.RegisterMySoloData();
	else
		LA.RaidMode = true;
	end

	return raidInfo
end

function  LA.IsLockyTableDirty(LockyData)
	for k,v in pairs(LockyData) do
		local lock = LA.GetLockyDataByName(v.Name);
		if lock.CurseAssignment ~= v.CurseAssignment or
		lock.BanishAssignment ~= v.BanishAssignment or 
		lock.SSAssignment ~= v.SSAssignment then
			return true;
		end
	end
	return false;
end


function LA.IsMyDataDirty(lockyData)
	local myData = LA.GetMyLockyData();
	if myData.CurseAssignment ~= lockyData.CurseAssignment or
		myData.BanishAssignment ~= lockyData.BanishAssignment or
		myData.SSAssignment ~= lockyData.SSAssignment then
			return true;
	end

	return false;
end

-- will merge any newcomers or remove any deserters from the table and return it while leaving assignments intact.
function LA.UpdateWarlocks(LockyTable)
	local Newcomers = LA.RegisterWarlocks();
	--Register Newcomers
	for k, v in pairs(Newcomers) do
		if LA.WarlockIsInTable(v.Name, LockyTable) then
			--Do nothing I think...
		else
			if LA.DebugMode then
				print("Newcomer detected")
			end

			--Add the newcomer to the data.
			table.insert(LockyTable, LA.CreateWarlock(v.Name, "None", "None"));
		end
	end
	--De-register deserters
	for k, v in pairs(LockyTable) do
		if LA.WarlockIsInTable(v.Name, Newcomers) then
			--Do nothing I think...
		else
			--Remove the Deserter
			if LA.DebugMode then
				print("Deserter detected")
			end
			local p = LA.GetLockyFriendIndexByName(LA.LockAssignmentFriendsData, v.Name)
			if not (p==nil) then
				table.remove(LA.LockAssignmentFriendsData, p)
			end
		end
	end
	return LockyTable;
end

function LA.MergeAssignments(LockyTable)
	for k,v in pairs(LockyTable) do 
		local lock = LA.GetLockyDataByName(v.Name);
		if lock~=nil then
			lock.SSAssignment = v.SSAssignment;
			lock.CurseAssignment = v.CurseAssignment;
			lock.BanishAssignment = v.BanishAssignment;
		end
	end
end

function  LA.ResetAssignmentAcks(LockyTable)
	for k,v in pairs(LockyTable) do 
		local lock = LA.GetLockyDataByName(v.Name);
		lock.AcceptedAssignments = "nil";
	end
end

function LA.WarlockIsInTable(LockyName, LockyTable)
	for k, v in pairs(LockyTable) do
		if (v.Name == LockyName) then
			return true;
		end
	end
	return false;
end

--Global List of banish markers
LA.BanishMarkers = {
	"None",
	"Diamond",
	"Star",
	"Triangle",
	"Circle",
	"Square",
	"Moon",	
	"Skull",
	"Cross"
}

--Global list of curse options to be displayed in the curse assignment menu.
LA.CurseOptions = {
	"None",
   "Elements",
   "Shadows",
   "Recklessness",
   "Tongues",
   "Weakness",
   "Doom LOL",
   "Agony"
}

LA.AnnouncerOptions = {
	"Addon Only",
	"Raid",
	"Party",
	"Whisper"
}

LA.SSTargets = {};

LA.SSTargetFlipperTester = true;

--Function will find main healers in the raid and add them to the SS target dropdown
--Need to make test mode dynamic.

function LA.GetClassColor(fileName)
return 1, 1, 1, "ffffffff"
end

function LA.GetSSTargetsFromRaid()
	if LA.RaidMode then
		--print("Raid MODE!!")
		--I need to implement this next time I am in a raid.
		local results = {}	
		for i=1, 40 do
			local name, rank, subgroup, level, class, fileName, 
				zone, online, isDead, role, isML, combatRole = GetRaidRosterInfo(i);

			local rPerc, gPerc, bPerc, argbHex = LA.GetClassColor(fileName);
			if not (name == nil) then
				--print(name .. "-" .. fileName .. "-" .. rank .. role)
				--if fileName == "PRIEST" or fileName == "PALADIN" or fileName == "SHAMAN" or role == "MAINTANK" then
					local ssWithColor = {};
					ssWithColor.Name = name;
					ssWithColor.Color = argbHex;
					table.insert(results, ssWithColor)
					--table.insert(boostedResults, ssWithColor)
				--end
			end		
		end
		local function compare(a,b)
			return a.Color > b.Color or (a.Color == b.Color and a.Name < b.Name)
		  end
		  table.sort(results, compare)
		--table.sort(results);
		local ssWithColor = {};
			ssWithColor.Name = "None";
			ssWithColor.Color = nil;
		table.insert(results,ssWithColor)
		return results
	else
		-- if LA.DebugMode then
		-- 	print("Registering Test SS target data.");
		-- 	if LA.SSTargetFlipperTester then
		-- 		LA.SSTargetFlipperTester = false
		-- 		if LA.DebugMode then
		-- 			print("Setting SS target set 1.");
		-- 		end
		-- 		return {
		-- 			"Priest1",
		-- 			"Priest2",
		-- 			"Priest3",
		-- 			"Paladin1",
		-- 			"Paladin2",				
		-- 			"WarriorTank1",
		-- 			"None"
		-- 		}
		-- 	else
		-- 		LA.SSTargetFlipperTester = true
		-- 		if LA.DebugMode then
		-- 			print("Setting SS target set 2.");
		-- 		end
		-- 		return {
		-- 			"PriestA",
		-- 			"PriestB",
		-- 			"PriestC",
		-- 			"PaladinA",
		-- 			"PaladinB",				
		-- 			"WarriorTankA",
		-- 			"None"
		-- 		}
		-- 	end	
		-- else
			--print("Not in debug mode, solo mode enabled no targets");
			local ssWithColor = {};
					ssWithColor.Name = "None";
					ssWithColor.Color = nil;
			return {ssWithColor};
		-- end
	end
end

LA.SSTargets = LA.GetSSTargetsFromRaid();

function LA.GetSSTargets()
	return LA.SSTargets;
end

function LA.UpdateSSTargets()
	LA.SSTargets = LA.GetSSTargetsFromRaid();
--	print ("SS Targets Updated success.")
end

function LA.GetMyLockyData()
	for k, v in pairs(LA.LockAssignmentFriendsData) do
		if LA.DebugMode then
			--print(v.Name, " vs ", UnitName("player"));
		end
        if v.Name == UnitName("player") then
            return v
        end
	end	
end

function LA.GetMyLockyDataFromTable(lockyDataTable)
	for k, v in pairs(lockyDataTable) do
		if LA.DebugMode then
			--print(v.Name, " vs ", UnitName("player"));
		end
        if v.Name == UnitName("player") then
            return v
        end
    end
end

function  LA.GetLockyDataByName(name)
    for k, v in pairs(LA.LockAssignmentFriendsData) do
        if v.Name == name then
            return v
        end
    end
end

function LA.SetupAssignmentMacro(CurseAssignment)
	
	-- If macro exists?
	local macroIndex = GetMacroIndexByName(LA.MacroName)
	if (macroIndex == 0) then
		macroIndex = CreateMacro(LA.MacroName, 1, nil, nil, true);
		if LA.DebugMode then
			print("Never Locky macro did not exist, creating a new one with ID" .. macroIndex);
		end
	end
	
	--print('anything working?');
	local curseName = LA.GetSpellNameFromDropDownList(CurseAssignment);
	--print(curseName .. 'vs None');
	if (curseName == nil) then	
		if LA.DebugMode then
			print("No update applied because no curse selected");
		end
	else
		if LA.DebugMode then
			print("Updating macro ".. macroIndex .. " to the new assigment " .. curseName);
		end

		EditMacro(macroIndex, LA.MacroName, LA.GetSpellTextureFromDropDownList(CurseAssignment), LA.BuildMacroTexe(curseName), 1, 1);
		
		if LA.DebugMode then
			print("Update success!!!!!");
		end
	end
	-- CreateMacro("MyMacro", "INV_MISC_QUESTIONMARK", "/script CastSpellById(1);", 1);
	-- I think I can just pass in the texture in param 2?
end

function  LA.BuildMacroTexe(curseName)
	return "#showtooltip "..
	 curseName ..
	 "\n/run CastSpellByName(\""..curseName.."\");"
end
