local AddonName, Addon = ...

local L = LibStub("AceLocale-3.0"):GetLocale(AddonName, true)

local optionsTable = {
    name = L["Socialite"],
    handler = SCL,
    type = 'group',
    args = {
        debug = {
            name = L["Debug"],
            desc = "",
            type = 'toggle',
            order = 0,
            hidden = false,
            set = function(_, val)
                SCL.debugEnabled = val
                SCL:Print(L["Debug"].." "..(function ()
                    if SCL.debugEnabled then
                        return ("|cFFFF0000%s|r"):format(L["Enabled"])
                    else
                        return ("|cFF00FF00%s|r"):format(L["Disabled"])
                    end
                end)())
                --@debug@
                SCL.db.global.debugEnabled = val
                --@end-debug@
            end,
            get = function() return SCL.debugEnabled end
        }
    }
}

function SCL:InitOpts()
    LibStub("AceConfig-3.0"):RegisterOptionsTable(AddonName, optionsTable, {"/scl", "/"..L["Socialite"]})
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(AddonName, L["Socialite"], nil)
end
