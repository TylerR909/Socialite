local AddonName, Addon = ...

SCL = LibStub("AceAddon-3.0"):NewAddon(AddonName,"AceEvent-3.0","AceConsole-3.0","AceHook-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(AddonName, true)

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
    if not self.db.global.config.tracking.bossKills then return end
    self:Debug("Tallying boss kill...")
    local numGroupMembers = GetNumGroupMembers()
    -- local groupPrefix = (function() if IsInRaid() then return "raid" else return "party" end end)()
    local groupPrefix = (IsInRaid() and 'raid') or (IsInGroup() and 'party')
    if not groupPrefix then self:Debug("Not in a group. Skipping tally."); return nil end
    self:Debug("Group prefix is: "..groupPrefix)
    for i=1,numGroupMembers do
        if UnitIsPlayer(groupPrefix..i) and UnitIsVisible(groupPrefix..i) then 
            local playerGUID = UnitGUID(groupPrefix..i)
            self:Debug("Grabbed player GUID: "..playerGUID)
            SCL:TallyBossKillCharacter(playerGUID)
        end
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

    if not self.db.global.data[characterGUID] then
        self:Debug("Adding "..characterName.." to SCL db")
        self.db.global.data[characterGUID] = {
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

    return self.db.global.data[characterGUID]
end

function SCL:GenerateTooltip(event, ...)
    if not UnitIsPlayer("mouseover") then return end
    if not self.shouldGenerateTooltipFromConfig(self.db.global.config.tooltip) then return end
    local mouseoverGUID = UnitGUID("mouseover")
    if self.db.global.data[mouseoverGUID] == nil then return end

    local character = self.db.global.data[mouseoverGUID]
    local msg = ("|cFFFF0000%s|r -> "):format(L["SCL"])
    if self.db.global.config.tooltip.bossKills then
        msg = msg + ("%s: %d"):format(L["Kills"], character.stats.bossKills)
    end

    GameTooltip:AddLine(msg)
    GameTooltip:Show()
end

function SCL.shouldGenerateTooltipFromConfig(config)
    return config.enabled and (
        config.bossKills or
        config.lfg or
        config.bg or
        config.lfr
    )
end

function SCL:StartSession()
    self:Debug("Starting a session...")
    self.db.char.session = {
        timeStarted = GetServerTime(),
        peopleSeen = {}
    }
end

function SCL:EndSession()
    if not self.db.char.session then return end
    self:Debug("Ending a session...")
    local timeEnded = GetServerTime()
    local timeStarted = self.db.char.session.timeStarted
    if timeStarted ~= nil then
        self:Debug(("Session lasted %d minutes"):format(
            floor((timeEnded - timeStarted) / 60)
        ))
    end
    self.db.char.session = nil
end

function SCL:UpdateSession()
    if not self.db.char.session then self:StartSession() end
    local numGroupMembers = GetNumGroupMembers()
    local groupPrefix = (IsInRaid() and 'raid') or (IsInGroup() and 'party')
    if not groupPrefix then self:Debug("Not in a group. Skipping tally."); return nil end

    for i=1,numGroupMembers do
        if UnitIsPlayer(groupPrefix..i) then 
            local playerGUID = UnitGUID(groupPrefix..i)
            if not self.db.char.session.peopleSeen[playerGUID] then
                -- Add to session, check if we know them
                self.db.char.session.peopleSeen[playerGUID] = true
                -- Notify if unit has been seen, and isn't guildie or friend
                if self.db.global.data[playerGUID]
                    and not UnitIsInMyGuild(groupPrefix..i)
                    and not UnitIsFriend("player", groupPrefix..i) 
                then
                    self:NotifyDuringSession(self.db.global.data[playerGUID])
                end
            end
        end
    end
end

function SCL:NotifyDuringSession(player)
    if not self.db.global.config.notifications.onJoin then return end
    if self.db.global.config.notifications.onJoinSound then
        PlaySound(SOUNDKIT.TELL_MESSAGE, "Master")
    end
    SCL:Print((L["YouHaveSeenTemplate"]):format(
        player.name,
        date("%B %d", player.lastSeen),
        player.stats.bossKills
    ))
end

--@do-not-package@
    function SCL:Dump()
        local f = AceGUI:Create("Frame")
        f:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
        f:SetTitle("SCL Data Dump")
        local editbox = AceGUI:Create("MultiLineEditBox")
        f:AddChild(editbox)
        editbox:SetText(table_to_string(self.db.global.data))
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
--@end-do-not-package@

local eventMap = {
    {
        event = "BOSS_KILL",
        handler = "TallyBossKill",
        dbConfigClass = 'tracking',
        dbConfigOption = 'bossKills'
    }, {
        event = "CHALLENGE_MODE_COMPLETE",
        handler = "EchoEvent"
    }, {
        event = "LFG_COMPLETION_AWARD",
        handler = "EchoEvent"
    }, {
        event = "GROUP_JOINED",
        handler = "StartSession"
    }, {
        event = "GROUP_LEFT",
        handler = "EndSession"
    }, {
        event = "GROUP_ROSTER_UPDATE",
        handler = "UpdateSession"
    }, {
        event = "UPDATE_MOUSEOVER_UNIT",
        handler = "GenerateTooltip"
    }
}

function SCL:OnInitialize()
    self:Debug("SCL Initializing")
    self:InitOpts()
    self.debugEnabled = false
    --@do-not-package@
    self.debugEnabled = self.db.global.config.debugEnabled or false
    C_Timer.After(4, function() self:Print("Debug "..tostring(self.debugEnabled)) end)
    --@end-do-not-package@
    self.eventMap = eventMap
    for i,v in ipairs(eventMap) do
        if v.dbConfigClass and v.dbConfigOption then
            if self.db.global.config[v.dbConfigClass][v.dbConfigOption] then
                self:Debug('Registering event: '..v.event)
                self:RegisterEvent(v.event, v.handler)
            else
                self:Debug(("Skipping %s as it's disabled"):format(v.event))
            end
        else
            self:Debug('Registering event: '..v.event)
            self:RegisterEvent(v.event, v.handler)
        end
    end
end
