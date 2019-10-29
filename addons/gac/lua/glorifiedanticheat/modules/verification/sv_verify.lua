local _IsValid = IsValid
local _hook_Add = hook.Add
local _isbool = isbool
local _isnumber = isnumber
local _pairs = pairs
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

local Blocked_Cfgs = {
    ['STEAM_API_KEY'] = true,
    ['ENABLE_FAMILY_SHARE_CHECKS'] = true,
    ['FAMILY_SHARE_PUNISHMENT'] = true,
    ['FAMILY_SHARE_BANTIME'] = true
}

for k, v in _pairs(gAC.config) do
    if Blocked_Cfgs[k] then continue end
    if _isbool(v) or _isnumber(v) then
        Configs[k] = v
    end
end

Configs = _util_TableToJSON(Configs)

_hook_Add("gAC.CLFilesLoaded", "g-AC_verify_initialspawn", function(ply)
    _timer_Simple(30, function()
        if !_IsValid(ply) then return end
        gAC.Network:Send("g-AC_ACVerify", Configs, ply)
    end)
end)