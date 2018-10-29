
net.Receive( "g-ACReceiveClientMessage", function()

    local infoTable = net.ReadTable()
    local nick = infoTable[1]
    local displayReason = infoTable[2]
    local wasPunished = infoTable[3]
    local banTime = infoTable[4]
    
    chat.AddText( "" )
    chat.AddText( Color( 255, 55, 55 ), "[g-AC] ", Color( 15, 75, 185 ), "Detection from '", Color( 35, 135, 225 ), nick, Color( 15, 75, 185 ), "'" )
    chat.AddText( Color( 15, 75, 185 ), "Reasoning: '", Color( 35, 135, 225 ) , displayReason , Color( 15, 75, 185 ), "'" )
    if( wasPunished ) then
        if( banTime == -1 ) then
            chat.AddText( Color( 15, 75, 185 ), "Punishment: ", Color( 35, 135, 225 ), "Kick" )
        elseif( banTime == 0 ) then
            chat.AddText( Color( 15, 75, 185 ), "Punishment: ", Color( 35, 135, 225 ), "Permanent Ban" )
        elseif( banTime >= 0 ) then
            chat.AddText( Color( 15, 75, 185 ), "Punishment: ", Color( 35, 135, 225 ), "Temporary Ban (", banTime, " minutes)" )
        end
    end
    chat.AddText( "" )
end )