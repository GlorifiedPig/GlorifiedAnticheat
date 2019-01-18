
function gAC.AddDetection( ply, displayReason, shouldPunish, banTime )
    if !gAC.isflyon then return end

    gAC.AdminMessage( ply, displayReason, shouldPunish, banTime )
    gAC.LogEvent( "Detection from " .. ply:Nick() .. ": " .. displayReason )
    if !shouldPunish then return end

    if( banTime >= 0 ) then
        gAC.AddBan( ply, displayReason, banTime )
    elseif( banTime == -1 ) then
        gAC.Kick( ply, displayReason )
    end

end