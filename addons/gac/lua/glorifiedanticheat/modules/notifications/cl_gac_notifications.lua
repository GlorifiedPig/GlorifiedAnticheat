
net.Receive( "g-ACReceiveClientMessage1", function()

    local infoTable = net.ReadTable()
    local ply = infoTable[1]
    local displayReason = infoTable[2]
    local wasPunished = infoTable[3]
    local banTime = infoTable[4]
    
    if( isstring( ply ) && string.len( ply ) == 17 ) then
        chat.AddText( Color( 255, 55, 55 ), gAC.config.SYNTAX, Color( 15, 75, 185 ), "Detection from '", Color( 35, 135, 225 ), ply, Color( 15, 75, 185 ), "'" )
    else
        if( !isstring( ply ) && ply:IsValid() && ply:IsPlayer() ) then
            chat.AddText( Color( 255, 55, 55 ), gAC.config.SYNTAX, Color( 15, 75, 185 ), "Detection from '", Color( 35, 135, 225 ), ply:Nick(), Color( 15, 75, 185 ), "'" )
        end

        if( isstring( ply ) ) then
            chat.AddText( Color( 255, 55, 55 ), gAC.config.SYNTAX, Color( 15, 75, 185 ), "Detection from '", Color( 35, 135, 225 ), ply, Color( 15, 75, 185 ), "'" )
        end
    end

    chat.AddText( Color( 15, 75, 185 ), "Reasoning: '", Color( 35, 135, 225 ) , displayReason , Color( 15, 75, 185 ), "'" )
    if( wasPunished ) then
        if( banTime == -1 ) then
            chat.AddText( Color( 15, 75, 185 ), "Punishment: ", Color( 35, 135, 225 ), "Kick" )
        elseif( banTime == 0 ) then
            chat.AddText( Color( 15, 75, 185 ), "Punishment: ", Color( 35, 135, 225 ), "Permanent Ban" )
        elseif( banTime >= 0 ) then
            chat.AddText( Color( 15, 75, 185 ), "Punishment: ", Color( 35, 135, 225 ), "Temporary Ban (" .. banTime .. " minutes)" )
        end
    end
end )

net.Receive( "g-ACReceiveClientMessage2", function()

    local infoTable = net.ReadTable()
    local message = infoTable[1]
    local colour = infoTable[2]
    
    chat.AddText( Color( 255, 55, 55 ), gAC.config.SYNTAX, colour, message )

end )