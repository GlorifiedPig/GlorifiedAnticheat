if !gAC.config.DEBUGLIB_CHECK then return end
gAC.Network:AddReceiver(
    "g-ACDebugLibResponse",
    function(_, data, plr)
        plr.gAC_DebugLib = nil
        if data == true then
            gAC.AddDetection( plr, 
                "Debug Library Check Failed [Code 121:2]",
                gAC.config.DEBUGLIB_FAIL_PUNISHMENT, 
                gAC.config.DEBUGLIB_FAIL_BANTIME 
            )
            return
        end
        local _ = nil
        _, data = pcall(util.JSONToTable, data)
        if !istable(data) then
            gAC.AddDetection( plr, 
                "Debug Library Check Failed [Code 121:3]",
                gAC.config.DEBUGLIB_FAIL_PUNISHMENT, 
                gAC.config.DEBUGLIB_FAIL_BANTIME 
            )
            return
        end
        if data[1] ~= true then
            gAC.AddDetection( plr, 
                "Debug Library Anomaly [Code 120:1]",
                gAC.config.DEBUGLIB_PUNISHMENT, 
                gAC.config.DEBUGLIB_BANTIME 
            )
            return
        end
        if data[2] ~= true then
            gAC.AddDetection( plr, 
                "Debug Library Anomaly [Code 120:2]",
                gAC.config.DEBUGLIB_PUNISHMENT, 
                gAC.config.DEBUGLIB_BANTIME 
            )
            return
        end
        if data[3] ~= 65474 then
            gAC.AddDetection( plr, 
                "Debug Library Anomaly [Code 120:3]",
                gAC.config.DEBUGLIB_PUNISHMENT, 
                gAC.config.DEBUGLIB_BANTIME 
            )
            return
        end
        if data[4] ~= 65474 then
            gAC.AddDetection( plr, 
                "Debug Library Anomaly [Code 120:4]",
                gAC.config.DEBUGLIB_PUNISHMENT, 
                gAC.config.DEBUGLIB_BANTIME 
            )
            return
        end
    end
)

hook.Add("gAC.CLFilesLoaded", "g-AC_verify_debuglib", function(ply)
    timer.Simple(20, function()
        if !IsValid(ply) then return end
        gAC.Network:Send("g-ACDebugLibResponse", "", ply)
        ply.gAC_DebugLib = true
        timer.Simple(gAC.config.DEBUGLIB_RESPONSE_TIME, function()
            if !IsValid(ply) then return end
            if !ply.gAC_DebugLib then return end
            gAC.AddDetection( ply, 
                "Debug Library Check Failed [Code 121:1]",
                gAC.config.DEBUGLIB_RESPONSE_PUNISHMENT, 
                gAC.config.DEBUGLIB_RESPONSE_BANTIME 
            )
        end)
    end)
end)