local _util_JSONToTable = util.JSONToTable

if !gAC.config.RENDER_HACK_CHECKS then return end

gAC.Network:AddReceiver("g-ACAntiRenderHackReturnResults",function(_, data, ply)
    data = _util_JSONToTable(data)        
    if ( data[1] != 0 || data[2] != 0 || data[3] != 0 ) && ( data[4] == "Windows" ) then
        gAC.AddDetection( ply, "Anti render-hack detection triggered #1 [Code 106]", gAC.config.RENDER_HACK_PUNISHMENT, gAC.config.RENDER_HACK_BANTIME )
    end
end )

gAC.Network:AddReceiver("g-ACAntiRenderHackReturnResults2",function(_, data, ply)
    gAC.AddDetection( ply, "Anti render-hack detection triggered #2 [Code 106]", gAC.config.RENDER_HACK_PUNISHMENT, gAC.config.RENDER_HACK_BANTIME )
end )