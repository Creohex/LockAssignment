LA.CommModeWhisper = "WHISPER"
LA.CommTarget = UnitName("player")
LA.CommModeRaid = "RAID";


LA.CommAction = {}
LA.CommAction.SSonCD = "SSonCD"
LA.CommAction.BroadcastTable = "DataRefresh"
LA.CommAction.RequestAssignments = "GetAssignmentData"
LA.CommAction.AssigmentResponse = "AssignmentResponse"
LA.CommAction.AssignmentReset = "AssignmentReset"

function LA.CreateMessageFromTable(action, data, dataAge)
    --print("Creating outbound message.")
    local message = {}
    message.action = action
    message.data = data
    message.dataAge = dataAge
    message.author = UnitName("player")
    message.addonVersion = LA.Version
    local strMessage = table.serialize(message)
    --print("Message created successfully")
    return strMessage
end

function LA.RegisterForComms()
    LockAssignment:RegisterComm("NeverLockyComms")
end

--Message router where reveived messages land.
function LockAssignment:OnCommReceived(prefix, message, distribution, sender)
    if LA.DebugMode then
        print("Message Was Recieved by the Router");
    end
    local message = table.deserialize(message)

    local lockyversionstub = LA.GetLockyDataByName(message.author)
    if lockyversionstub ~=nil then
        lockyversionstub.AddonVersion = message.addonVersion
    end

    if message.addonVersion > LA.Version then
        LA.IsMyAddonOutOfDate = true;
        NeverLockyFrame.WarningTextFrame:Show();
        NLCommit_Button:Disable();
    end
    
    -- process the incoming message
    if message.action == LA.CommAction.SSonCD then
        if LA.DebugMode then
            print("SS on CD: ", message.data.Name, message.data.SSCooldown, message.data.SSonCD, message.dataAge)
        end
        local SendingWarlock = LA.GetLockyDataByName(message.author)
            if(SendingWarlock ~= nil) then
                if LA.DebugMode then
                    print("Updating SS data for", message.author);
                end
                SendingWarlock.LocalTime = message.dataAge
                SendingWarlock.MyTime = GetTime()
                SendingWarlock.SSonCD = "true";
                SendingWarlock.SSCooldown = message.data.SSCooldown
            end
        --UpdateLockySSCDByName(message.data.Name, message.data.SSCooldown)
    elseif message.action == LA.CommAction.BroadcastTable then

        local myData = LA.GetMyLockyData()
        if (myData~=nil)then
            for  lockyindex, lockydata in pairs(message.data) do
                if lockydata.Name == UnitName("player") then
                    if LA.IsMyDataDirty(lockydata) or LA.DebugMode then
                        LA.SetLockyCheckFrameAssignments(lockydata.CurseAssignment, lockydata.BanishAssignment, lockydata.SSAssignment)
                    else
                        --print("updating curse macro.")
                        LockAssignmentAssignCheckFrame.activeCurse = lockydata.CurseAssignment;
                        LA.SetupAssignmentMacro(LockAssignmentAssignCheckFrame.activeCurse);
                        LA.SendAssignmentAcknowledgement("true");
                    end
                end
            end
        end

        if LA.RaidMode then
            if LA.DebugMode then
                print("Received message from", message.author);
            end
            if message.author == LA.CommTarget then
                return;
            end
        end
        if LA.DebugMode then
            print("Recieved a broadcast message from", message.author)
        end

        

        if(LA.IsUIDirty(message.data)) then
            for k, v in pairs(message.data)do
                if LA.DebugMode then
                    for lk, lv in pairs(v) do
                        print(lk, lv)                    
                    end                    
                end
            end

            local myData = LA.GetMyLockyData()
            if (myData~=nil)then
                for  lockyindex, lockydata in pairs(message.data) do
                    if lockydata.Name == UnitName("player") then
                        if LA.IsMyDataDirty(lockydata) or LA.DebugMode then
                            LA.SetLockyCheckFrameAssignments(lockydata.CurseAssignment, lockydata.BanishAssignment, lockydata.SSAssignment)
                        else
                            print("updating curse macro.")
                            LockAssignmentAssignCheckFrame.activeCurse = lockydata.CurseAssignment;
                            LA.SetupAssignmentMacro(LockAssignmentAssignCheckFrame.activeCurse);
                            LA.SendAssignmentAcknowledgement("true");
                        end
                    end
                end
            end

            --LockAssignmentFriendsData = message.data
            LA.MergeAssignments(message.data);
            LA.LockAssignmentFriendsData = LA.UpdateWarlocks(LA.LockAssignmentFriendsData);
            LA.UpdateAllLockyFriendFrames()
            if LA.DebugMode then
                print("UI has been refreshed by request of broadcast message.")
            end               
        end 
        
        if myData.CurseAssignment == "None" and myData.BanishAssignment == "None" and myData.SSAssignment == "None" then
            LockyPersonalMonitorFrame:Hide();
        else
            LockyPersonalMonitorFrame:Show();
        end
    elseif message.action == LA.CommAction.RequestAssignments then
        if LA.RaidMode then
            if LA.DebugMode then
                print("Received Assignment Request message from", message.author);
            end
            local myself = LA.GetMyLockyData()
            if myself ~= nil then
                LA.BroadcastSSCooldown(myself)
            end
            if message.author == LA.CommTarget then
                if LA.DebugMode then
                    print("Message was from self, doing nothing.");
                end
                return;
            end
        end
        if LA.DebugMode then
            print("Assignment request recieved, sending out assignments.")
        end
        LA.BroadcastTable(LA.LockAssignmentFriendsData)
        
    elseif message.action == LA.CommAction.AssigmentResponse then
        -- When we recieve an assigment response we should stuff with that.
        if LA.DebugMode then
            print("Recieved an Ack message from", message.author);
        end

        local SendingWarlock = LA.GetLockyDataByName(message.author)
        if SendingWarlock~=nil then
            SendingWarlock.AcceptedAssignments = message.data.acknowledged
            LA.UpdateLockyFrame(SendingWarlock, LA.GetLockyFriendFrameById(SendingWarlock.LockyFrameLocation))
        end

    elseif message.action == LA.CommAction.AssignmentReset then
        if LA.DebugMode then
            print("Recieved assignment reset from", message.author)
        end
        LA.ResetAssignmentAcks(LA.LockAssignmentFriendsData);
        
    else
        if LA.DebugMode then
            print("The following message was recieved: ",sender, prefix, message)
        end
    end
end

--Takes in a table and sends the serialized verion across the wire.
function LA.BroadcastTable(LockyTable)
    if(LA.IsMyAddonOutOfDate)then
        return;
    end
    --stringify the locky table
    if LA.DebugMode then
        print("Sending out the assignment table")
    end
    local serializedTable = LA.CreateMessageFromTable(LA.CommAction.BroadcastTable, LockyTable, LockAssignmentData_Timestamp)
    if LA.RaidMode then
        LockAssignment:SendCommMessage("NeverLockyComms", serializedTable, LA.CommModeRaid)
    else
        LockAssignment:SendCommMessage("NeverLockyComms", serializedTable, LA.CommModeWhisper, LA.CommTarget)
    end
	--LockAssignment:SendCommMessage("NeverLockyComms", serializedTable, "WHISPER", "Brylack")
end

function LA.BroadcastSSCooldown(myself)
    LA.ForceUpdateSSCD();
    local serializedTable = LA.CreateMessageFromTable(LA.CommAction.SSonCD, myself, GetTime())
    if LA.RaidMode then
        LockAssignment:SendCommMessage("NeverLockyComms", serializedTable, LA.CommModeRaid)
    else
        LockAssignment:SendCommMessage("NeverLockyComms", serializedTable, LA.CommModeWhisper, LA.CommTarget)
    end
end

function LA.RequestAssignments()
    if LA.DebugMode then
        print("Requesting Updated Assignment Table")
    end
    local message = LA.CreateMessageFromTable(LA.CommAction.RequestAssignments, {},GetTime() )
    if LA.RaidMode then
        LockAssignment:SendCommMessage("NeverLockyComms", message, LA.CommModeRaid)
    else
        LockAssignment:SendCommMessage("NeverLockyComms", message, LA.CommModeWhisper, LA.CommTarget)
    end
end

function  LA.SendAssignmentAcknowledgement(answer)
    if LA.DebugMode then
        print("Sending assignment acknowledgement:", answer)
    end   
    
    if answer == "true"then        
        LA.UpdatePersonalMonitorFrame()
    end

    local message = LA.CreateMessageFromTable(LA.CommAction.AssigmentResponse, {acknowledged = answer}, GetTime());
    if LA.RaidMode then
        LockAssignment:SendCommMessage("NeverLockyComms", message, LA.CommModeRaid)
    else
        LockAssignment:SendCommMessage("NeverLockyComms", message, LA.CommModeWhisper, LA.CommTarget)
    end
end

function LA.SendAssignmentReset()
    if LA.DebugMode then
        print("Sending assignment reset command")
    end    
    local message = LA.CreateMessageFromTable(LA.CommAction.AssignmentReset, {}, GetTime());
    if LA.RaidMode then
        LockAssignment:SendCommMessage("NeverLockyComms", message, LA.CommModeRaid)
    else
        LockAssignment:SendCommMessage("NeverLockyComms", message, LA.CommModeWhisper, LA.CommTarget)
    end
end

function LA.CheckInstallVersion()
    
end