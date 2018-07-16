local AddonName, Addon = ...

SCL = LibStub("AceAddon-3.0"):NewAddon(AddonName,"AceEvent-3.0","AceConsole-3.0","AceHook-3.0")
local AceGUI = LibStub("AceGUI-3.0")
-- local L = LibStub("AceLocale-3.0"):GetLocale(AddonName, true)

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
    self:Debug(msg)
end

function SCL:TallyBossKill()
    self:Debug("Tallying boss kill...")
    local numGroupMembers = GetNumGroupMembers()
    -- local groupPrefix = (function() if IsInRaid() then return "raid" else return "party" end end)()
    local groupPrefix = (IsInRaid() and 'raid') or (IsInGroup() and 'party')
    if not groupPrefix then self:Debug("Not in a group. Skipping tally."); return nil end
    self:Debug("Group prefix is: "..groupPrefix)
    for i=1,numGroupMembers do
        local playerGUID = UnitGUID(groupPrefix..i)
        self:Debug("Grabbed player GUID: "..playerGUID)
        SCL:TallyBossKillCharacter(playerGUID)
    end
end

function SCL:TallyBossKillCharacter(characterGUID)
    local char = self:VerifyCharacterByGUID(characterGUID)
    char.stats.bossKills = char.stats.bossKills + 1
    char.lastSeen = GetServerTime()
    self:Debug("Boss kills with "..char.name..": "..char.stats.bossKills)
end

function SCL:VerifyCharacterByGUID(characterGUID)
    local _,classId,_,_,_,characterName,characterRealm = GetPlayerInfoByGUID(characterGUID)

    if not self.db.global[characterGUID] then
        self:Debug("Adding "..characterName.." to SCL db")
        self.db.global[characterGUID] = {
            GUID = characterGuid,
            name = characterName,
            realm = characterRealm,
            classId = classId,
            BNPresenceID = nil,
            firstSeen = GetServerTime(),
            lastSeen = 0,
            stats = {
                bossKills = 0
            }
        }
    end

    return self.db.global[characterGUID]
end

function SCL:AddToTooltip(event, ...)
    self:Debug(event)
    local mouseoverGUID = UnitGUID('mouseover')
    if self.db.global[mouseoverGUID] == nil then return end
    local character = self.db.global[mouseoverGUID]
    GameTooltip:AddLine("|cFFFF0000SCL|r | Kills "..character.stats.bossKills)
end

--@debug@
    SCL.debugEnabled = true;

    function SCL:Dump()
        local f = AceGUI:Create("Frame")
        f:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
        f:SetTitle("SCL Data Dump")
        local editbox = AceGUI:Create("MultiLineEditBox")
        f:AddChild(editbox)
        editbox:SetText(table_to_string(self.db.global))
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

local eventMap = {
    {
        event = "BOSS_KILL",
        handler = "TallyBossKill"
    }, {
        event = "CHALLENGE_MODE_COMPLETE",
        handler = "EchoEvent"
    }, {
        event = "LFG_COMPLETION_AWARD",
        handler = "EchoEvent"
    }, {
        event = "GROUP_JOINED",
        handler = "EchoEvent"
    }, {
        event = "GROUP_LEFT",
        handler = "EchoEvent"
    }, {
        event = "GROUP_ROSTER_UPDATE",
        handler = "EchoEvent"
    }, {
        event = "UPDATE_MOUSEOVER_UNIT",
        handler = "AddToTooltip"
    }
}

function SCL:OnInitialize()
    self:Debug("SCL Initializing")
    self.db = LibStub("AceDB-3.0"):New("SocialiteDB")
    self.eventMap = eventMap
    for i,v in ipairs(eventMap) do
        self:Debug('Registering event: '..v.event)
        -- self:RegisterEvent(v.event, function (...) v.handler(v.event, ...) end)
        self:RegisterEvent(v.event, v.handler)
    end
    -- self:SecureHook(GameTooltip, "SetUnit", "AddToTooltip")
end
