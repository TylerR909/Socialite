local AddonName, Addon = ...

SCL = LibStub("AceAddon-3.0"):NewAddon(AddonName,"AceEvent-3.0","AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(AddonName, true)

local events = {
        "BOSS_KILL",
        "CHALLENGE_MODE_COMPLETE",
        "LFG_COMPLETION_AWARD",
        "GROUP_JOINED",
        "GROUP_LEFT",
        "GROUP_ROSTER_UPDATE"
    };

function SCL:OnInitialize()
    self:Debug('SCL Loaded')
    for i,v in ipairs(events) do
        self:RegisterEvent(v, SCL.EchoEvent)
    end
end

function SCL:Debug(msg)
    if self.debugEnabled then
        self:Print(msg)
    end
end

function SCL:EchoEvent(event, ...)
    local args = ...
    local msg = "EVENT: "..event
    if args then msg = msg.." with args: "..args end
    SCL:Debug(msg)
end

--@debug@
    SCL.debugEnabled = true;
--@end-debug@