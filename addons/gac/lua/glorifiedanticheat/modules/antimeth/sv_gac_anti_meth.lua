local _IsValid = IsValid
local _hook_Add = hook.Add
local _timer_Simple = timer.Simple

if !gAC.config.ANTI_METH then return end

--[[
    Once again, these god dam dev's of meth are fucking retarded.
    They keep thinking their 'drugged' cheat is superior when they cannot solve a simple fucking task
    of detouring the [redacted] function.
]]

_hook_Add("gAC.CLFilesLoaded", "g-AC_meth_initialspawn", function(ply)
    _timer_Simple(30, function()
        if !_IsValid(ply) then return end
        gAC.Network:Send("g-AC_meth1", "", ply)
    end)
end)