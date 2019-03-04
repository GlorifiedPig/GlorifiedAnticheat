util.AddNetworkString("g-AC_meth1")

hook.Add("PlayerInitialSpawn", "g-AC_meth_initialspawn", function(ply)
    timer.Simple(10, function()

        net.Start("g-AC_meth1")
        net.Send(ply)

    end)
end)