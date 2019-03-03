util.AddNetworkString("g-AC_meth1")
util.AddNetworkString("g-AC_meth2")


net.Receive("g-AC_meth2", function(len, ply)
    timer.Remove(ply:Nick().."MethCheck")
end)


hook.Add("PlayerInitialSpawn", "g-AC_meth_initialspawn", function(ply)
    timer.Simple(10, function()

        timer.Create( ply:Nick().."MethCheck", 30, 1, function()
            gAC.AddDetection( ply, "Methamphetamine User [Code 113]", true, 0 )
        end ) 

        net.Start("g-AC_meth1")
        net.Send(ply)

    end)
end)