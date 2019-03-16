if !gAC.config.ANTI_METH then return end

--[[
    Once again, these god dam dev's of meth are fucking retarded.
    They keep thinking their 'drugged' cheat is superior when they cannot solve a simple fucking task
    of detouring the [redacted] function.
]]

hook.Add("gAC.CLFilesLoaded", "g-AC_meth_initialspawn", function(ply)
    timer.Simple(30, function()
        if !IsValid(ply) then return end
        gAC.Network:Send("g-AC_meth1", "", ply)
    end)
end)