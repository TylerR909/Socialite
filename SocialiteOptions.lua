local AddonName, Addon = ...

local L = LibStub("AceLocale-3.0"):GetLocale(AddonName, true)

local defaultOptions = {
    global = {
        config = {
            tracking = {
                bossKills = true,
                lfg = true,
                bg = true,
                lfr = false
            },
            tooltip = {
                enabled = true,
                bossKills = true,
                lfg = true,
                bg = true,
                lfr = false
            },
            notifications = {
                onJoin = true,
                onJoinSound = true
            }
        },
        data = {}
    }
}

local orderNum = 0;
local function order() 
    orderNum = orderNum + 1;
    return orderNum
end

local function tcount(tbl)
    local count = 0;
    for _,_ in ipairs(tbl) do
        count = count + 1
    end
    return count
end

local optionsTable = {
    name = L["Socialite"],
    handler = SCL,
    type = 'group',
    args = {
        trackingHeader = {
            name = L["Track"],
            order = order(),
            type = "header",
        },
        trackingBossKills = {
            name = L["Bosses Killed"],
            type = "toggle",
            order = order(),
            set = function(_, val) SCL.db.global.config.tracking.bossKills = val end,
            get = function() return SCL.db.global.config.tracking.bossKills end
        }, 
        trackingLFGComplete = {
            name = L["LFG Complete"],
            type = "toggle",
            order = order(),
            set = function(_,val) SCL.db.global.config.tracking.lfg = val end,
            get = function() return SCL.db.global.config.tracking.lfg end
        }, 
        trackingLFRComplete = {
            name = L["LFR Complete"],
            type = "toggle",
            order = order(),
            disabled = true,
            set = function(_,val) SCL.db.global.config.tracking.lfr = val end,
            get = function() return SCL.db.global.config.tracking.lfr end
        },
        trackingBGComplete = {
            name = L["BG Complete"],
            type = "toggle",
            order = order(),
            disabled = true,
            set = function(_, val) SCL.db.global.config.tracking.bg = val end,
            get = function() return SCL.db.global.config.tracking.bg end
        },
        tooltipHeader = {
            name = L["Tooltip"],
            order = order(),
            type = "header",
        },
        tooltipEnabled = {
            name = L["Enabled"],
            order = order(),
            type = "toggle",
            set = function(_, val) SCL.db.global.config.tooltip.enabled = val end,
            get = function() return SCL.db.global.config.tooltip.enabled end
        },
        tooltipBossKills = {
            name = L["Bosses Killed"],
            type = "toggle",
            order = order(),
            disabled = function() return not SCL.db.global.config.tooltip.enabled end,
            set = function(_, val) SCL.db.global.config.tooltip.bossKills = val end,
            get = function() return SCL.db.global.config.tooltip.bossKills end
        }, 
        tooltipLFGComplete = {
            name = L["LFG Complete"],
            type = "toggle",
            order = order(),
            set = function(_,val) SCL.db.global.config.tooltip.lfg = val end,
            get = function() return SCL.db.global.config.tooltip.lfg end
        }, 
        tooltipLFRComplete = {
            name = L["LFR Complete"],
            type = "toggle",
            order = order(),
            disabled = true,
            set = function(_,val) SCL.db.global.config.tooltip.lfr = val end,
            get = function() return SCL.db.global.config.tooltip.lfr end
        },
        tooltipBGComplete = {
            name = L["BG Complete"],
            type = "toggle",
            order = order(),
            disabled = true,
            set = function(_, val) SCL.db.global.config.tooltip.bg = val end,
            get = function() return SCL.db.global.config.tooltip.bg end
        },
        notificationHeader = {
            name = L["Group Join Notifications"],
            order = order(),
            type = "header"
        },
        notificationOnJoin = {
            name = L["Enabled"],
            type = "toggle",
            order = order(),
            set = function(_, val) SCL.db.global.config.notifications.onJoin = val end,
            get = function() return SCL.db.global.config.notifications.onJoin end
        },
        notificationOnJoinSound = {
            name = L["Play Sound"],
            type = "toggle",
            order = order(),
            disabled = function () return not SCL.db.global.config.notifications.onJoin end,
            set = function(_, val)
                SCL.db.global.config.notifications.onJoinSound = val
                if val then
                    PlaySound(SOUNDKIT.TELL_MESSAGE, "Master")
                end
            end,
            get = function() return SCL.db.global.config.notifications.onJoinSound end
        },
        utilityHeader = {
            name = L["Utility"],
            type = "header",
            order = order()
        },
        -- First rendition pruned anyone over a year. It'll be awhile before that's relevant and
        -- there's no explanation as to what "Prune" does to the user, so disabling for now
        -- until I can add pruning options and more information about what it does.
        --@alpha@
        pruneHandler = {
            name = L["Prune"],
            type = "execute",
            order = order(),
            confirm = true,
            confirmText = L["Are you sure? This will delete data and may hang your client."],
            func = function() 
                SCL:Print("Starting prune...")
                local startCount = tcount(SCL.db.global.data)
                local oneYearAgo = GetServerTime() - 31557600
                for k,v in pairs(SCL.db.global.data) do
                    if v.lastSeen < oneYearAgo then
                        SCL:Debug(("Deleting %s-%s, last seen %s"):format(v.name, v.realm, v.lastSeen))
                        SCL.db.global.data[k] = nil
                    end
                end
                local endCount = tcount(SCL.db.global.data)
                SCL:Print(("Prune complete. %d of %d entries deleted."):format(startCount - endCount, startCount))
            end
        },
        --@end-alpha@
        debug = {
            name = L["Debug"],
            desc = "",
            type = 'toggle',
            order = order(),
            hidden = false,
            confirm = function(_, val) return val and "Are you sure? This is VERY spammy and will self-disable on next reload." end,
            set = function(_, val)
                SCL.debugEnabled = val
                SCL:Print(L["Debug"].." "..(function ()
                    if SCL.debugEnabled then
                        return ("|cFFFF0000%s|r"):format(L["Enabled"])
                    else
                        return ("|cFF00FF00%s|r"):format(L["Disabled"])
                    end
                end)())
                --@do-not-package@
                SCL.db.global.config.debugEnabled = val
                --@end-do-not-package@
            end,
            get = function() return SCL.debugEnabled end
        },
    }
}

function SCL:OpenOptionsFrame(input) 
    if not input or input:trim() == "" then
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    --@do-not-package@
    elseif input == "dump" then
        self:Dump()
    --@end-do-not-package@
    else
        LibStub("AceConfigCmd-3.0"):HandleCommand("scl", AddonName, input)
    end
end

function SCL:InitOpts()
    LibStub("AceConfig-3.0"):RegisterOptionsTable(AddonName, optionsTable)
    self.db = LibStub("AceDB-3.0"):New("SocialiteDB", defaultOptions, true)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(AddonName, L["Socialite"], nil)
    self:RegisterChatCommand("socialite", "OpenOptionsFrame")
    self:RegisterChatCommand("scl", "OpenOptionsFrame")
    if (GetLocale() ~= "enUS" and GetLocale() ~= "enGB") then
        self:Debug(("Registering non-enUS chat commands: /%s and /%s"):format(L["Socialite"], L["SCL"]))
        self:RegisterChatCommand(L["Socialite"], "OpenOptionsFrame")
        self:RegisterChatCommand(L["SCL"], "OpenOptionsFrame")
    end
end
