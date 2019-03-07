if(!gAC.config.ENABLE_METHAMPHETAMINE_CHECKS) then return end

util.AddNetworkString(gAC.netMsgs.clMethCheck)

hook.Add("PlayerInitialSpawn", "g-AC_meth_initialspawn", function(ply)
    timer.Simple(15, function()
        net.Start(gAC.netMsgs.clMethCheck)
        net.Send(ply)
    end)
end)


