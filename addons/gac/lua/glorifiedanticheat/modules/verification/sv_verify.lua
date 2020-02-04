local _IsValid = IsValid
local _hook_Add = hook.Add
local _isbool = isbool
local _isnumber = isnumber
local _pairs = pairs
local _CurTime = CurTime
local _player_GetHumans = player.GetHumans
local _timer_Simple = timer.Simple
local _util_TableToJSON = util.TableToJSON

--[[
    Considering how you can block certain functions and values in C++
    this is just to check if there was any alterations to gAC's config
    since ya know. LuaI has most of the code localized & protected except for the configs.

    oh and i know meth is going to try and block the global var 'gAC' because if it get's blocked
    all functions requiring the config file will fail.
]]

if !gAC.config.INTEGRITY_CHECKS then return end

local Configs = {}

for k, v in _pairs(gAC.config) do
    if gAC.config.INTEGRITY_INGORES[k] then continue end
    if _isbool(v) or _isnumber(v) then
        Configs[k] = v
    end
end

Configs = _util_TableToJSON(Configs)

_hook_Add("gAC.CLFilesLoaded", "g-AC_verify_initialspawn", function(ply)
    ply.GAC_IntegCheck = _CurTime() + gAC.config.INTEGRITY_CHECKS_INTERVAL
end)

_hook_Add("Think", "g-AC_IntergrityCheck", function()
    local plys = _player_GetHumans()
    local ct = _CurTime()
    for i=1, #plys do
        local v = plys[i]
        if v.GAC_IntegCheck and v.GAC_IntegCheck < ct then
            gAC.Network:Send("g-AC_ACVerify", Configs, v)
            v.GAC_IntegCheck = ct + gAC.config.INTEGRITY_CHECKS_INTERVAL
        end
    end
end)

gAC.Network:AddReceiver(
    "g-AC_ACVerify",
    function(data, plr)
        gAC.AddDetection( plr, "Integrity check failure [Code 117]", gAC.config.INTEGRITY_CHECKS_PUNISHMENT, gAC.config.INTEGRITY_CHECKS_BANTIME )
    end
)