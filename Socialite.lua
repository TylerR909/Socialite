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
    self:Print(msg)
end

function SCL.GetGroupPrefix()
    return (IsInRaid() and 'raid') or (IsInGroup() and 'party')
end

function SCL:GetVisibleGroupMemberGUIDs()
    self:Debug("Getting group members...")
    local numGroupMembers = GetNumGroupMembers()
    local groupPrefix = self.GetGroupPrefix()
    local groupMates = {}
    for i=1,numGroupMembers do
        if UnitIsPlayer(groupPrefix..i) and UnitIsVisible(groupPrefix..i) then 
            local playerGUID = UnitGUID(groupPrefix..i)
            tinsert(groupMates, playerGUID)
        end
    end
    return groupMates
end

function SCL:BossKill()
    if not self.db.global.config.tracking.bossKills then return end
    self:Debug("Tallying boss kill...")
    local groupGUIDs = SCL:GetVisibleGroupMemberGUIDs()
    for _,personGUID in pairs(groupGUIDs) do
        SCL:TallyBossKillCharacter(personGUID)
    end
end

function SCL:TallyBossKillCharacter(characterGUID)
    local char = self:VerifyCharacterByGUID(characterGUID)
    char.stats.bossKills = (char.stats.bossKills or 0) + 1
    char.lastSeen = GetServerTime()
    self:Debug("Boss kills with "..char.name..": "..char.stats.bossKills)
end

function SCL:DungeonComplete()
    if not self.db.global.config.tracking.lfg then return end
    self:Debug("Tallying dungeon finish...")
    local groupGUIDs = SCL:GetVisibleGroupMemberGUIDs()
    for _,personGUID in paiars(groupGUIDs) do
        SCL:TallyDungeonCompleteCharacter(personGUID)
    end
end

function SCL:TallyDungeonCompleteCharacter(personGUID)
    local char = self:VerifyCharacterByGUID(personGUID)
    char.stats.lfg = (char.stats.lfg or 0) + 1
    char.lastSeen = GetServerTime()
    self:Debug("Dungeons complete with "..char.name..": "..char.stats.lfg)
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
                bossKills = 0,
                lfg = 0,
                lfr = 0,
                bg = 0
            }
        }
    end

    return self.db.global.data[characterGUID]
end

function SCL:GenerateTooltipFromMouseover()
    self:Debug("Generating tooltip from mouseover")
    self:GenerateTooltip("mouseover")
end

function SCL:GenerateTooltipFromUnit(unit)
    self:Debug("Generating tooltip from unit "..unit)
    if unit == "mouseover" then return end
    self:GenerateTooltip(unit)
end

function SCL:GenerateTooltip(unit)
    if not UnitIsPlayer(unit) then return end
    if not self.shouldGenerateTooltipFromConfig(self.db.global.config.tooltip) then return end
    local unitGUID = UnitGUID(unit)
    if self.db.global.data[unitGUID] == nil then return end

    local config = self.db.global.config.tooltip
    local stats = self.db.global.data[unitGUID].stats
    local msgHeader = ("|cFFFF0000%s|r -> "):format(L["Socialite"])
    local msg = ""
    if config.bossKills and stats.bossKills > 0 then
        msg = msg..("%s: %d"):format(L["Bosses"], stats.bossKills)
    end
    if config.lfg and stats.lfg > 0 then
        if msg ~= "" then msg = msg..', ' end
        msg = msg..("%s: %d"):format(L["Dungeons"], stats.lfg)
    end

    GameTooltip:AddLine(msgHeader..msg)
    GameTooltip:Show()
end

function SCL.shouldGenerateTooltipFromConfig(config)
    return config.enabled and (
        config.bossKills 
        or config.lfg
        -- Not yet implemented
        -- or config.bg
        -- or config.lfr
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
                self:Debug(playerGUID.." hasn't been seen")
                -- Add to session, check if we know them
                self.db.char.session.peopleSeen[playerGUID] = true
                -- Notify if unit has been seen, and isn't guildie or friend
                if self.db.global.data[playerGUID]
                    and not UnitIsInMyGuild(groupPrefix..i)
                    -- Should be called UnitIsFriendly...
                    -- and not UnitIsFriend("player", groupPrefix..i) 
                then
                    self:Debug("Notifying...")
                    self:NotifyDuringSession(self.db.global.data[playerGUID])
                end
            end
        end
    end
end

function SCL:NotifyDuringSession(player)
    self:Debug("Notifying")
    if not self.db.global.config.notifications.onJoin then return end
    if self.db.global.config.notifications.onJoinSound then
        PlaySound(SOUNDKIT.TELL_MESSAGE, "Master")
    end
    -- "The last time you saw %s was on %s!
    --   You have killed %d bosses and finished
    --   %d dungeons together."
    self:Print((L["YouHaveSeenTemplate"]):format(
        player.name,
        date("%b %d %Y", player.lastSeen),
        player.stats.bossKills,
        player.stats.lfg
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
        handler = "BossKill",
        dbConfigClass = 'tracking',
        dbConfigOption = 'bossKills'
    -- }, {
    --     event = "CHALLENGE_MODE_COMPLETE",
    --     handler = "EchoEvent"
    -- }, {
    --     event = "LFG_COMPLETION_AWARD",
    --     handler = "EchoEvent"
    }, {
        event = "GROUP_JOINED",
        handler = "StartSession"
    }, {
        event = "GROUP_JOINED",
        handler = "UpdateSession"
    }, {
        event = "GROUP_LEFT",
        handler = "EndSession"
    }, {
        event = "GROUP_ROSTER_UPDATE",
        handler = "UpdateSession"
    }, {
        event = "UPDATE_MOUSEOVER_UNIT",
        handler = "GenerateTooltipFromMouseover"
    }, {
        event = "SCENARIO_COMPLETED",
        handler = "DungeonComplete"
    }, {
        event = "SCENARIO_COMPLETED",
        handler = "EchoEvent"
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

    self:SecureHook(GameTooltip, "SetUnit", function (_, unit)
        if not UnitIsVisible(unit) then
            self:GenerateTooltipFromUnit(unit)
        end  -- else let UPDATE_MOUSEOVER_UNIT handle it
    end)
end
