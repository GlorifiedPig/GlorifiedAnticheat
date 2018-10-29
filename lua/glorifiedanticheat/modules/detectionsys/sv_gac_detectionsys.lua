
util.AddNetworkString( "g-ACReceiveClientMessage" )

function gAC.AddDetection( ply, displayReason, shouldPunish, banTime )

    gAC.AdminMessage( ply, displayReason, shouldPunish, banTime )
    if !shouldPunish then return end

    if( banTime >= 0 ) then
        gAC.AddBan( ply, displayReason, banTime )
    end

end

function gAC.AdminMessage( ply, displayReason, wasPunished, banTime )
    for k, v in pairs( player.GetAll() ) do
        if( v:IsAdmin() ) then
            net.Start( "g-ACReceiveClientMessage" )
            net.WriteTable( { ply:Nick(), displayReason, wasPunished, banTime } )
            net.Send( v )
        end
    end
end