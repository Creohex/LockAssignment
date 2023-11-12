NL.CommModeWhisper = "WHISPER"
NL.CommTarget = UnitName("player")
NL.CommModeRaid = "RAID";


NL.CommAction = {}
NL.CommAction.SSonCD = "SSonCD"
NL.CommAction.BroadcastTable = "DataRefresh"
NL.CommAction.RequestAssignments = "GetAssignmentData"
NL.CommAction.AssigmentResponse = "AssignmentResponse"
NL.CommAction.AssignmentReset = "AssignmentReset"

function NL.CreateMessageFromTable(action, data, dataAge)
    --print("Creating outbound message.")
    local message = {}
    message.action = action
    message.data = data
    message.dataAge = dataAge
    message.author = UnitName("player")
    message.addonVersion = NL.Version
    local strMessage = table.serialize(message)
    --print("Message created successfully")
    return strMessage
end

function NL.RegisterForComms()   
    NeverLocky:RegisterComm("NeverLockyComms")    
end

--Message router where reveived messages land.
function NeverLocky:OnCommReceived(prefix, message, distribution, sender)
    if NL.DebugMode then
        print("Message Was Recieved by the Router");
    end
    local message = table.deserialize(message)

    local lockyversionstub = NL.GetLockyDataByName(message.author)
    if lockyversionstub ~=nil then
        lockyversionstub.AddonVersion = message.addonVersion
    end

    if message.addonVersion > NL.Version then
        NL.IsMyAddonOutOfDate = true;
        NeverLockyFrame.WarningTextFrame:Show();
        NLCommit_Button:Disable();
    end
    
    -- process the incoming message
    if message.action == NL.CommAction.SSonCD then
        if NL.DebugMode then
            print("SS on CD: ", message.data.Name, message.data.SSCooldown, message.data.SSonCD, message.dataAge)
        end
        local SendingWarlock = NL.GetLockyDataByName(message.author)
            if(SendingWarlock ~= nil) then
                if NL.DebugMode then 
                    print("Updating SS data for", message.author);
                end
                SendingWarlock.LocalTime = message.dataAge
                SendingWarlock.MyTime = GetTime()
                SendingWarlock.SSonCD = "true";
                SendingWarlock.SSCooldown = message.data.SSCooldown
            end
        --UpdateLockySSCDByName(message.data.Name, message.data.SSCooldown)
    elseif message.action == NL.CommAction.BroadcastTable then

        local myData = NL.GetMyLockyData()
        if (myData~=nil)then
            for  lockyindex, lockydata in pairs(message.data) do
                if lockydata.Name == UnitName("player") then
                    if NL.IsMyDataDirty(lockydata) or NL.DebugMode then                    
                        NL.SetLockyCheckFrameAssignments(lockydata.CurseAssignment, lockydata.BanishAssignment, lockydata.SSAssignment)
                    else
                        --print("updating curse macro.")
                        LockyAssignCheckFrame.activeCurse = lockydata.CurseAssignment;
                        NL.SetupAssignmentMacro(LockyAssignCheckFrame.activeCurse);
                        NL.SendAssignmentAcknowledgement("true");
                    end
                end
            end
        end

        if NL.RaidMode then
            if NL.DebugMode then
                print("Received message from", message.author);
            end
            if message.author == NL.CommTarget then            
                return;
            end
        end
        if NL.DebugMode then
            print("Recieved a broadcast message from", message.author)
        end

        

        if(NL.IsUIDirty(message.data)) then
            for k, v in pairs(message.data)do
                if NL.DebugMode then
                    for lk, lv in pairs(v) do
                        print(lk, lv)                    
                    end                    
                end
            end

            local myData = NL.GetMyLockyData()
            if (myData~=nil)then
                for  lockyindex, lockydata in pairs(message.data) do
                    if lockydata.Name == UnitName("player") then
                        if NL.IsMyDataDirty(lockydata) or NL.DebugMode then                    
                            NL.SetLockyCheckFrameAssignments(lockydata.CurseAssignment, lockydata.BanishAssignment, lockydata.SSAssignment)
                        else
                            print("updating curse macro.")
                            LockyAssignCheckFrame.activeCurse = lockydata.CurseAssignment;
                            NL.SetupAssignmentMacro(LockyAssignCheckFrame.activeCurse);
                            NL.SendAssignmentAcknowledgement("true");
                        end
                    end
                end
            end

            --LockyFriendsData = message.data            
            NL.MergeAssignments(message.data);
            NL.LockyFriendsData = NL.UpdateWarlocks(NL.LockyFriendsData);
            NL.UpdateAllLockyFriendFrames()
            if NL.DebugMode then
                print("UI has been refreshed by request of broadcast message.")
            end               
        end 
        
        if myData.CurseAssignment == "None" and myData.BanishAssignment == "None" and myData.SSAssignment == "None" then
            LockyPersonalMonitorFrame:Hide();
        else
            LockyPersonalMonitorFrame:Show();
        end
    elseif message.action == NL.CommAction.RequestAssignments then
        if NL.RaidMode then
            if NL.DebugMode then
                print("Received Assignment Request message from", message.author);
            end
            local myself = NL.GetMyLockyData()
            if myself ~= nil then
                NL.BroadcastSSCooldown(myself)
            end
            if message.author == NL.CommTarget then
                if NL.DebugMode then
                    print("Message was from self, doing nothing.");
                end
                return;
            end
        end
        if NL.DebugMode then
            print("Assignment request recieved, sending out assignments.")
        end
        NL.BroadcastTable(NL.LockyFriendsData)
        
    elseif message.action == NL.CommAction.AssigmentResponse then
        -- When we recieve an assigment response we should stuff with that.
        if NL.DebugMode then 
            print("Recieved an Ack message from", message.author);
        end

        local SendingWarlock = NL.GetLockyDataByName(message.author)
        if SendingWarlock~=nil then
            SendingWarlock.AcceptedAssignments = message.data.acknowledged
            NL.UpdateLockyFrame(SendingWarlock, NL.GetLockyFriendFrameById(SendingWarlock.LockyFrameLocation))
        end

    elseif message.action == NL.CommAction.AssignmentReset then
        if NL.DebugMode then
            print("Recieved assignment reset from", message.author)
        end
        NL.ResetAssignmentAcks(NL.LockyFriendsData);
        
    else
        if NL.DebugMode then
            print("The following message was recieved: ",sender, prefix, message)
        end
    end
end

--Takes in a table and sends the serialized verion across the wire.
function NL.BroadcastTable(LockyTable)
    if(NL.IsMyAddonOutOfDate)then
        return;
    end
    --stringify the locky table
    if NL.DebugMode then
        print("Sending out the assignment table")
    end
    local serializedTable = NL.CreateMessageFromTable(NL.CommAction.BroadcastTable, LockyTable, LockyData_Timestamp) 
    if NL.RaidMode then
        NeverLocky:SendCommMessage("NeverLockyComms", serializedTable, NL.CommModeRaid)
    else
        NeverLocky:SendCommMessage("NeverLockyComms", serializedTable, NL.CommModeWhisper, NL.CommTarget)
    end
	--NeverLocky:SendCommMessage("NeverLockyComms", serializedTable, "WHISPER", "Brylack")
end

function NL.BroadcastSSCooldown(myself)    
    NL.ForceUpdateSSCD();
    local serializedTable = NL.CreateMessageFromTable(NL.CommAction.SSonCD, myself, GetTime())
    if NL.RaidMode then
        NeverLocky:SendCommMessage("NeverLockyComms", serializedTable, NL.CommModeRaid)
    else
        NeverLocky:SendCommMessage("NeverLockyComms", serializedTable, NL.CommModeWhisper, NL.CommTarget)
    end
end

function NL.RequestAssignments()
    if NL.DebugMode then
        print("Requesting Updated Assignment Table")
    end
    local message = NL.CreateMessageFromTable(NL.CommAction.RequestAssignments, {},GetTime() )
    if NL.RaidMode then
        NeverLocky:SendCommMessage("NeverLockyComms", message, NL.CommModeRaid)
    else
        NeverLocky:SendCommMessage("NeverLockyComms", message, NL.CommModeWhisper, NL.CommTarget)
    end
end

function  NL.SendAssignmentAcknowledgement(answer)
    if NL.DebugMode then
        print("Sending assignment acknowledgement:", answer)
    end   
    
    if answer == "true"then        
        NL.UpdatePersonalMonitorFrame()
    end

    local message = NL.CreateMessageFromTable(NL.CommAction.AssigmentResponse, {acknowledged = answer}, GetTime());
    if NL.RaidMode then
        NeverLocky:SendCommMessage("NeverLockyComms", message, NL.CommModeRaid)
    else
        NeverLocky:SendCommMessage("NeverLockyComms", message, NL.CommModeWhisper, NL.CommTarget)
    end
end

function NL.SendAssignmentReset()
    if NL.DebugMode then
        print("Sending assignment reset command")
    end    
    local message = NL.CreateMessageFromTable(NL.CommAction.AssignmentReset, {}, GetTime());
    if NL.RaidMode then
        NeverLocky:SendCommMessage("NeverLockyComms", message, NL.CommModeRaid)
    else
        NeverLocky:SendCommMessage("NeverLockyComms", message, NL.CommModeWhisper, NL.CommTarget)
    end
end

function NL.CheckInstallVersion()
    
end