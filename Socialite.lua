local AddonName, Addon = ...

SCL = LibStub("AceAddon-3.0"):NewAddon(AddonName,"AceEvent-3.0","AceConsole-3.0")
local AceGUI = LibStub("AceGUI-3.0")
-- local L = LibStub("AceLocale-3.0"):GetLocale(AddonName, true)

local events = {
        "BOSS_KILL",
        "CHALLENGE_MODE_COMPLETE",
        "LFG_COMPLETION_AWARD",
        "GROUP_JOINED",
        "GROUP_LEFT",
        "GROUP_ROSTER_UPDATE"
    };

function SCL:OnInitialize()
    self:Debug("SCL Initializing")
    for i,v in ipairs(events) do
        self:Debug('Registering event: '..v)
        self:RegisterEvent(v, function (...) self:EchoEvent(v, ...) end)
    end
end

function SCL:Debug(msg)
    if self.debugEnabled then
        self:Print(msg)
    end
end

function SCL:EchoEvent(event, ...)
    local msg = "EVENT: "..tostring(event)
    if ... then msg = msg.." with ARGS: " end
    for i=1, select('#', ...) do
        msg = msg.." "..tostring(select(i, ...))
    end
    SCL:Debug(msg)
end

--@debug@
    SCL.debugEnabled = true;

    function SCL:Dump()
        local f = AceGUI:Create("Frame")
        f:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
        f:SetTitle("SCL Data Dump")
        local editbox = AceGUI:Create("MultiLineEditBox")
        f:AddChild(editbox)
        editbox:SetText(table_to_string(events))
        editbox:SetFullWidth(true)
        editbox:SetFullHeight(true)
        editbox:SetNumLines(25)
    end

    function table_to_string(tbl)
        local result = "{\n"
        for k, v in pairs(tbl) do
            -- Check the key type (ignore any numerical keys - assume its an array)
            if type(k) == "string" then
                result = result.."[\""..k.."\"]".."="
            end

            -- Check the value type
            if type(v) == "table" then
                result = result..table_to_string(v)
            elseif type(v) == "boolean" then
                result = result..tostring(v)
            else
                result = result.."\""..v.."\""
            end
            result = result..",\n"
        end
        -- Remove leading commas from the result
        if result ~= "" then
            result = result:sub(1, result:len()-1)
        end
        return result.."\n}\n"
    end

--@end-debug@