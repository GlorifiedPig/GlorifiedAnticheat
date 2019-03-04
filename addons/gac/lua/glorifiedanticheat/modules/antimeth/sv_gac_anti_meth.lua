if(!gAC.config.ENABLE_METHAMPHETAMINE_CHECKS) then return end

util.AddNetworkString("deportmeplease")
util.AddNetworkString("deportedlul")

net.Receive("deportedlul", function(len, ply)
    gAC.AddDetection(ply, "Methamphetamine User [Code 113]", gAC.config.METHAMPHETAMINE_PUNISHMENT, gAC.config.METHAMPHETAMINE_PUNSIHMENT_BANTIME)
end)

hook.Add("PlayerInitialSpawn", "g-AC_meth_initialspawn", function(ply)
    timer.Simple(15, function()
        net.Start("deportmeplease")
        net.Send(ply)
    end)
end)


