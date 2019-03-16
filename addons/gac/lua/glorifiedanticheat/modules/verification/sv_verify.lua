--[[
    Considering how you can block certain functions and values in C++
    this is just to check if there was any alterations to gAC's config
    since ya know. LuaI has most of the code localized & protected except for the configs.

    oh and i know meth is going to try and block the global var 'gAC' because if it get's blocked
    all functions requiring the config file will fail.
]]

local Configs = {}

for k, v in pairs(gAC.config) do
    if isbool(v) or isnumber(v) then
        Configs[k] = v
    end
end

Configs = util.TableToJSON(Configs)

hook.Add("gAC.CLFilesLoaded", "g-AC_verify_initialspawn", function(ply)
    timer.Simple(30, function()
        if !IsValid(ply) then return end
        gAC.Network:Send("g-AC_ACVerify", Configs, ply)
    end)
end)