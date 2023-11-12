function GetTableLng(tbl)
    local getN = 0
    for n in pairs(tbl) do
        getN = getN + 1
    end
    return getN
end

function PrintMessageToMainChatFrame(message)
    DEFAULT_CHAT_FRAME:AddMessage(message)
end

function PrintMessageToMainChatFrame(message, ...)
    DEFAULT_CHAT_FRAME:AddMessage(string.format(message, ...))
end
