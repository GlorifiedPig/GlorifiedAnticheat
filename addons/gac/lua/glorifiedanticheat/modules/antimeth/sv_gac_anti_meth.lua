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
    timer.Simple(10, function()
        if tonumber(ply:GetInfo("cl_interp")) != 0.1 then
            gAC.AddDetection( ply, "Methamphetamine User [Code 113]", gAC.config.METH_PUNISHMENT, gAC.config.METH_BANTIME )
        end
    end)
end)