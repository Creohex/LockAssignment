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
    --LA.print("Creating outbound message.")
    local message = {}
    message.action = action
    message.data = data
    message.dataAge = dataAge
    message.author = UnitName("player")
    message.addonVersion = LA.Version
    local strMessage = table.serialize(message)
    --LA.print("Message created successfully")
    return strMessage
end

function LA.RegisterForComms()
    LockAssignment:RegisterComm("LAComms")
end

--Message router where reveived messages land.
function LockAssignment:OnCommReceived(prefix, message, distribution, sender)
    if LA.DebugMode then
        LA.print("Message Was Recieved by the Router");
    end
    local message = table.deserialize(message)

    local assignmentVersionStub = LA.GetAssignmentDataByName(message.author)
    if assignmentVersionStub ~=nil then
        assignmentVersionStub.AddonVersion = message.addonVersion
    end

    if message.addonVersion > LA.Version then
        LA.IsMyAddonOutOfDate = true;
        LockAssignmentFrame.WarningTextFrame:Show();
        LACommit_Button:Disable();
    end
    
    -- process the incoming message
    if message.action == LA.CommAction.SSonCD then
        if LA.DebugMode then
            LA.print("SS on CD: ", message.data.Name, message.data.SSCooldown, message.data.SSonCD, message.dataAge)
        end
        local SendingWarlock = LA.GetAssignmentDataByName(message.author)
            if(SendingWarlock ~= nil) then
                if LA.DebugMode then
                    LA.print("Updating SS data for", message.author);
                end
                SendingWarlock.LocalTime = message.dataAge
                SendingWarlock.MyTime = GetTime()
                SendingWarlock.SSonCD = "true";
                SendingWarlock.SSCooldown = message.data.SSCooldown
            end
        --UpdateAssignmentSSCDByName(message.data.Name, message.data.SSCooldown)
    elseif message.action == LA.CommAction.BroadcastTable then

        local myData = LA.GetMyData()
        if (myData~=nil)then
            for _, assignmentData in pairs(message.data) do
                if assignmentData.Name == UnitName("player") then
                    if LA.IsMyDataDirty(assignmentData) or LA.DebugMode then
                        LA.SetLockAssignmentCheckFrame(assignmentData.CurseAssignment, assignmentData.BanishAssignment, assignmentData.SSAssignment)
                    else
                        --LA.print("updating curse macro.")
                        LockAssignmentAssignCheckFrame.activeCurse = assignmentData.CurseAssignment;
                        LA.SetupAssignmentMacro(LockAssignmentAssignCheckFrame.activeCurse);
                        LA.SendAssignmentAcknowledgement("true");
                    end
                end
            end
        end

        if LA.RaidMode then
            if LA.DebugMode then
                LA.print("Received message from", message.author);
            end
            if message.author == LA.CommTarget then
                return;
            end
        end
        if LA.DebugMode then
            LA.print("Recieved a broadcast message from", message.author)
        end

        

        if(LA.IsUIDirty(message.data)) then
            for k, v in pairs(message.data)do
                if LA.DebugMode then
                    for lk, lv in pairs(v) do
                        LA.print(lk, lv)
                    end                    
                end
            end

            local myData = LA.GetMyData()
            if (myData~=nil)then
                for _, assignmentData in pairs(message.data) do
                    if assignmentData.Name == UnitName("player") then
                        if LA.IsMyDataDirty(assignmentData) or LA.DebugMode then
                            LA.SetLockAssignmentCheckFrame(assignmentData.CurseAssignment, assignmentData.BanishAssignment, assignmentData.SSAssignment)
                        else
                            LA.print("updating curse macro.")
                            LockAssignmentAssignCheckFrame.activeCurse = assignmentData.CurseAssignment;
                            LA.SetupAssignmentMacro(LockAssignmentAssignCheckFrame.activeCurse);
                            LA.SendAssignmentAcknowledgement("true");
                        end
                    end
                end

                if myData.CurseAssignment == "None" and myData.BanishAssignment == "None" and myData.SSAssignment == "None" then
                    AssignmentPersonalMonitorFrame:Hide();
                else
                    AssignmentPersonalMonitorFrame:Show();
                end
            end

            --LockAssignmentsData = message.data
            LA.MergeAssignments(message.data);
            LA.LockAssignmentsData = LA.UpdateWarlocks(LA.LockAssignmentsData);
            LA.UpdateAllWarlockFrames()
            if LA.DebugMode then
                LA.print("UI has been refreshed by request of broadcast message.")
            end               
        end
    elseif message.action == LA.CommAction.RequestAssignments then
        if LA.RaidMode then
            if LA.DebugMode then
                LA.print("Received Assignment Request message from", message.author);
            end
            local myself = LA.GetMyData()
            if myself ~= nil then
                LA.BroadcastSSCooldown(myself)
            end
            if message.author == LA.CommTarget then
                if LA.DebugMode then
                    LA.print("Message was from self, doing nothing.");
                end
                return;
            end
        end
        if LA.DebugMode then
            LA.print("Assignment request recieved, sending out assignments.")
        end
        LA.BroadcastTable(LA.LockAssignmentsData)
        
    elseif message.action == LA.CommAction.AssigmentResponse then
        -- When we recieve an assigment response we should stuff with that.
        if LA.DebugMode then
            LA.print("Recieved an Ack message from", message.author);
        end

        local SendingWarlock = LA.GetAssignmentDataByName(message.author)
        if SendingWarlock~=nil then
            SendingWarlock.AcceptedAssignments = message.data.acknowledged
            LA.UpdateAssignmentFrame(SendingWarlock, LA.GetWarlockFrameById(SendingWarlock.AssignmentFrameLocation))
        end

    elseif message.action == LA.CommAction.AssignmentReset then
        if LA.DebugMode then
            LA.print("Recieved assignment reset from", message.author)
        end
        LA.ResetAssignmentAcks(LA.LockAssignmentsData);
        
    else
        if LA.DebugMode then
            LA.print("The following message was recieved: ",sender, prefix, message)
        end
    end
end

--Takes in a table and sends the serialized version across the wire.
function LA.BroadcastTable(AssignmentsTable)
    if(LA.IsMyAddonOutOfDate)then
        return;
    end
    --stringify the assignments table
    if LA.DebugMode then
        LA.print("Sending out the assignment table")
    end
    local serializedTable = LA.CreateMessageFromTable(LA.CommAction.BroadcastTable, AssignmentsTable, LockAssignmentData_Timestamp)
    if LA.RaidMode then
        LockAssignment:SendCommMessage("LAComms", serializedTable, LA.CommModeRaid)
    else
        LockAssignment:SendCommMessage("LAComms", serializedTable, LA.CommModeRaid, LA.CommTarget)
    end
	--LockAssignment:SendCommMessage("LAComms", serializedTable, "WHISPER", "John Doe")
end

function LA.BroadcastSSCooldown(myself)
    LA.ForceUpdateSSCD();
    local serializedTable = LA.CreateMessageFromTable(LA.CommAction.SSonCD, myself, GetTime())
    if LA.RaidMode then
        LockAssignment:SendCommMessage("LAComms", serializedTable, LA.CommModeRaid)
    else
        LockAssignment:SendCommMessage("LAComms", serializedTable, LA.CommModeRaid, LA.CommTarget)
    end
end

function LA.RequestAssignments()
    if LA.DebugMode then
        LA.print("Requesting Updated Assignment Table")
    end
    local message = LA.CreateMessageFromTable(LA.CommAction.RequestAssignments, {},GetTime() )
    if LA.RaidMode then
        LockAssignment:SendCommMessage("LAComms", message, LA.CommModeRaid)
    else
        LockAssignment:SendCommMessage("LAComms", message, LA.CommModeRaid, LA.CommTarget)
    end
end

function  LA.SendAssignmentAcknowledgement(answer)
    if LA.DebugMode then
        LA.print("Sending assignment acknowledgement:", answer)
    end   
    
    if answer == "true" then
        LA.UpdatePersonalMonitorFrame()
    end

    local message = LA.CreateMessageFromTable(LA.CommAction.AssigmentResponse, {acknowledged = answer}, GetTime());
    if LA.RaidMode then
        LockAssignment:SendCommMessage("LAComms", message, LA.CommModeRaid)
    else
        LockAssignment:SendCommMessage("LAComms", message, LA.CommModeRaid, LA.CommTarget)
    end
end

function LA.SendAssignmentReset()
    if LA.DebugMode then
        LA.print("Sending assignment reset command")
    end    
    local message = LA.CreateMessageFromTable(LA.CommAction.AssignmentReset, {}, GetTime());
    if LA.RaidMode then
        LockAssignment:SendCommMessage("LAComms", message, LA.CommModeRaid)
    else
        LockAssignment:SendCommMessage("LAComms", message, LA.CommModeRaid, LA.CommTarget)
    end
end

function LA.CheckInstallVersion()
    
end