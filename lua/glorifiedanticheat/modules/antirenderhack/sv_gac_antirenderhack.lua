
util.AddNetworkString( "g-ACAntiRenderHackReturnResults" )

net.Receive( "g-ACAntiRenderHackReturnResults", function( len, ply )
    local screenColour = net.ReadColor()
    local os = net.ReadString()
    
    if ( screenColour.r != 0 || screenColour.g != 0 || screenColour.b != 0 ) && ( os == "Windows" ) then
        gAC.AddDetection( ply, "Anti render-hack detection triggered [Code 106]", gAC.config.RENDER_HACK_PUNISHMENT, gAC.config.RENDER_HACK_BANTIME )
    end
end )