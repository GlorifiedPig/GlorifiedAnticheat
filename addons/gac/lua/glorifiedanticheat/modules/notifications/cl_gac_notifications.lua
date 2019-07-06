
net.Receive( "g-ACReceiveClientMessage1", function()

    local infoTable = net.ReadTable()
    local ply = infoTable[1]
    local displayReason = infoTable[2]
    local wasPunished = infoTable[3]
    local banTime = infoTable[4]
    
    if( isstring( ply ) && string.len( ply ) == 17 ) then
        chat.AddText( Color( 30, 150, 255 ), gAC.config.SYNTAX, Color( 255, 50, 50 ), "Detection from '", Color( 255, 0, 0 ), ply, Color( 255, 50, 50 ), "'" )
    else
        if( !isstring( ply ) && ply:IsValid() && ply:IsPlayer() ) then
            chat.AddText( Color( 30, 150, 255 ), gAC.config.SYNTAX, Color( 255, 50, 50 ), "Detection from '", Color( 255, 0, 0 ), ply:Nick(), Color( 255, 50, 50 ), "'" )
        end

        if( isstring( ply ) ) then
            chat.AddText( Color( 30, 150, 255 ), gAC.config.SYNTAX, Color( 255, 50, 50 ), "Detection from '", Color( 255, 0, 0 ), ply, Color( 255, 50, 50 ), "'" )
        end
    end

    chat.AddText( Color( 255, 50, 50 ), "Reasoning: '", Color( 255, 0, 0 ), displayReason , Color( 255, 50, 50 ), "'" )
    if( wasPunished ) then
        if( banTime == -1 ) then
            chat.AddText( Color( 255, 50, 50 ), "Punishment: ", Color( 255, 0, 0 ), "Kick" )
        elseif( banTime == 0 ) then
            chat.AddText( Color( 255, 50, 50 ), "Punishment: ", Color( 255, 0, 0 ), "Permanent Ban" )
        elseif( banTime >= 0 ) then
            chat.AddText( Color( 255, 50, 50 ), "Punishment: ", Color( 255, 0, 0 ), "Temporary Ban (" .. banTime .. " minutes)" )
        end
    end

    if gAC.config.ADMIN_MESSAGE_PING != "" then
        surface.PlaySound(gAC.config.ADMIN_MESSAGE_PING)
    end
end )

net.Receive( "g-ACReceiveClientMessage2", function()

    local infoTable = net.ReadTable()
    local message = infoTable[1]
    local colour = infoTable[2]
    
    chat.AddText( Color( 30, 150, 255 ), gAC.config.SYNTAX, colour, message )

end )