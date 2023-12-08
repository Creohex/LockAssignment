--General global variables
LA = {};
LA.RaidMode = true;
LA.DebugMode = false;
LA.Version = 14
LA.UpdateFrame = CreateFrame("Frame", nil, UIParent)
LA.LockAssignmentWarlockFrameWidth = 500;
LA.LockAssignmentWarlockFrameHeight = 128
LA.LockAssignmentFrame_HasInitialized = false; -- Used to prevent reloads from redrawing the ui.
LA.LockAssignmentData_HasInitialized = false;
LA.LockAssignmentData_Timestamp = 0.0;
LA.LockAssignmentsData = {}; -- Global for storing the warlocks and thier assignements.
LA.LockAssignmentClock_UpdateInterval = 1.0; -- How often the OnUpdate code will run (in seconds)
LA.LockAssignmentSSCD_UpdateInterval = 5.0; -- How often to broadcast / check our SS cooldown.
LA.LockAssignmentSSCD_BroadcastInterval = 60.0; -- How often to broadcast / check our SS cooldown.
LA.HaveSSAssignment = false
if LockAssignment == nil then
	LockAssignment = LibStub("AceAddon-3.0"):NewAddon("LockAssignment", "AceComm-3.0")
end
LA.LockAssignmentAssignCheckFrame={}
LA.IsMyAddonOutOfDate=false;
LA.MacroName = "CurseAssignment";


function  LA.CreateWarlock(name, curse, banish, raidIndex)
	local Warlock = {}
	Warlock.Name = name
	Warlock.CurseAssignment = curse
	Warlock.BanishAssignment = banish
	Warlock.SSAssignment = "None"
	Warlock.SSCooldown=nil
	Warlock.AcceptedAssignments = "nil"
	Warlock.AssignmentFrameLocation = ""
	Warlock.SSonCD = "unknown"
	Warlock.LocalTime= 0
	Warlock.MyTime = 0
	if name == UnitName("player") then
		Warlock.AddonVersion = LA.Version
	else
		Warlock.AddonVersion = 0
	end
	Warlock.RaidIndex = raidIndex
	return Warlock
end

--Pulls all of the warlocks in the raid and initilizes thier assignment data.
function LA.RegisterWarlocks()
	local myRaidRank = 0
	local raidInfo = {}
	for i=1, 40 do
		local name, rank, _, _, _, fileName, _, _, _, _, _ = GetRaidRosterInfo(i);
		if not (name == nil) then
			if fileName == "WARLOCK" then
				if name == UnitName("player") then
					myRaidRank = rank
				end
				if LA.DebugMode then
					LA.print(name .. "-" .. fileName)
				end
				table.insert(raidInfo, LA.CreateWarlock(name, "None", "None", i))
			end
		end		
	end
	if myRaidRank < 1 then
		LACommit_Button:Disable();
	end
	if LA.GetTableLength(raidInfo) == 0 then
		LA.RaidMode = false;
		return LA.RegisterMySoloData();
	else
		LA.RaidMode = true;
	end

	return raidInfo
end

function  LA.IsAssignmentsTableDirty(AssignmentData)
	for _,v in pairs(AssignmentData) do
		local lock = LA.GetAssignmentDataByName(v.Name);
		if lock.CurseAssignment ~= v.CurseAssignment or
		lock.BanishAssignment ~= v.BanishAssignment or 
		lock.SSAssignment ~= v.SSAssignment then
			return true;
		end
	end
	return false;
end


function LA.IsMyDataDirty(AssignmentData)
	local myData = LA.GetMyData();
	if myData.CurseAssignment ~= AssignmentData.CurseAssignment or
		myData.BanishAssignment ~= AssignmentData.BanishAssignment or
		myData.SSAssignment ~= AssignmentData.SSAssignment then
			return true;
	end

	return false;
end

-- will merge any newcomers or remove any deserters from the table and return it while leaving assignments intact.
function LA.UpdateWarlocks(AssignmentsTable)
	local Newcomers = LA.RegisterWarlocks();
	--Register Newcomers
	for _, v in pairs(Newcomers) do
		if LA.WarlockIsInTable(v.Name, AssignmentsTable) then
			--Do nothing I think...
		else
			if LA.DebugMode then
				LA.print("Newcomer detected")
			end

			--Add the newcomer to the data.
			table.insert(AssignmentsTable, LA.CreateWarlock(v.Name, "None", "None", v.RaidIndex));
		end
	end
	--De-register deserters
	for _, v in pairs(AssignmentsTable) do
		if LA.WarlockIsInTable(v.Name, Newcomers) then
			--Do nothing I think...
		else
			--Remove the Deserter
			if LA.DebugMode then
				LA.print("Deserter detected")
			end
			local p = LA.GetAssignmentIndexByName(LA.LockAssignmentsData, v.Name)
			if not (p==nil) then
				table.remove(LA.LockAssignmentsData, p)
			end
		end
	end
	return AssignmentsTable;
end

function LA.MergeAssignments(AssignmentsTable)
	for _,v in pairs(AssignmentsTable) do
		local lock = LA.GetAssignmentDataByName(v.Name);
		if lock~=nil then
			lock.SSAssignment = v.SSAssignment;
			lock.CurseAssignment = v.CurseAssignment;
			lock.BanishAssignment = v.BanishAssignment;
		end
	end
end

function  LA.ResetAssignmentAcks(AssignmentsTable)
	for _,v in pairs(AssignmentsTable) do
		local lock = LA.GetAssignmentDataByName(v.Name);
		lock.AcceptedAssignments = "nil";
	end
end

function LA.WarlockIsInTable(WarlockName, AssignmentsTable)
	for _, v in pairs(AssignmentsTable) do
		if (v.Name == WarlockName) then
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

RAID_CLASS_COLORS = {
	["WARRIOR"] = { r = 0.78, g = 0.61, b = 0.43, colorStr = "ffc79c6e" },
	["MAGE"]    = { r = 0.41, g = 0.8,  b = 0.94, colorStr = "ff69ccf0" },
	["ROGUE"]   = { r = 1,    g = 0.96, b = 0.41, colorStr = "fffff569" },
	["DRUID"]   = { r = 1,    g = 0.49, b = 0.04, colorStr = "ffff7d0a" },
	["HUNTER"]  = { r = 0.67, g = 0.83, b = 0.45, colorStr = "ffabd473" },
	["SHAMAN"]  = { r = 0.14, g = 0.35, b = 1.0,  colorStr = "ff0070de" },
	["PRIEST"]  = { r = 1,    g = 1,    b = 1,    colorStr = "ffffffff" },
	["WARLOCK"] = { r = 0.58, g = 0.51, b = 0.79, colorStr = "ff9482c9" },
	["PALADIN"] = { r = 0.96, g = 0.55, b = 0.73, colorStr = "fff58cba" },
}

function LA.GetClassColor(class)
	return RAID_CLASS_COLORS[class]
end

function LA.GetSSTargetsFromRaid()
	if LA.RaidMode then
		local results = {}
		local noneSSWithColor = {};
		noneSSWithColor.Name = "None";
		noneSSWithColor.Color = "ffffffff";
		table.insert(results, noneSSWithColor)
		for i=1, 40 do
			local name, _, _, _, _, class, _, _, _, _, _ = GetRaidRosterInfo(i);
			if not (name == nil) then
				local color = LA.GetClassColor(class);
				local ssWithColor = {};
				ssWithColor.Name = name;
				ssWithColor.Color = color.colorStr;
				table.insert(results, ssWithColor)
			end		
		end
		return results
	else
		local ssWithColor = {};
		ssWithColor.Name = "None";
		ssWithColor.Color = nil;
		return {ssWithColor};
	end
end

LA.SSTargets = LA.GetSSTargetsFromRaid();

function LA.GetSSTargets()
	return LA.SSTargets;
end

function LA.UpdateSSTargets()
	LA.SSTargets = LA.GetSSTargetsFromRaid();
--	LA.print ("SS Targets Updated success.")
end

function LA.GetMyData()
	for k, v in pairs(LA.LockAssignmentsData) do
		if LA.DebugMode then
			--LA.print(v.Name, " vs ", UnitName("player"));
		end
        if v.Name == UnitName("player") then
            return v
        end
	end	
end

function LA.GetMyAssignmentDataFromTable(assignmenDataTable)
	for k, v in pairs(assignmenDataTable) do
		if LA.DebugMode then
			--print(v.Name, " vs ", UnitName("player"));
		end
        if v.Name == UnitName("player") then
            return v
        end
    end
end

function  LA.GetAssignmentDataByName(name)
    for k, v in pairs(LA.LockAssignmentsData) do
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
			LA.print("Lock Assignment macro did not exist, creating a new one with ID" .. macroIndex);
		end
	end
	
	--print('anything working?');
	local curseName = LA.GetSpellNameFromDropDownList(CurseAssignment);
	--print(curseName .. 'vs None');
	if (curseName == nil) then	
		if LA.DebugMode then
			LA.print("No update applied because no curse selected");
		end
	else
		if LA.DebugMode then
			LA.print("Updating macro ".. macroIndex .. " to the new assigment " .. curseName);
		end

		EditMacro(macroIndex, LA.MacroName, LA.GetSpellTextureFromDropDownList(CurseAssignment), LA.BuildMacroTexe(curseName), 1, 1);
		
		if LA.DebugMode then
			LA.print("Macro updated");
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

function LA.print(message)
	DEFAULT_CHAT_FRAME:AddMessage(message)
end

function LA.print(message, ...)
	local printResult = message
	for i,v in ipairs(arg) do
		printResult = printResult .. " " .. tostring(v)
	end
	printResult = printResult
	DEFAULT_CHAT_FRAME:AddMessage(printResult)
end
