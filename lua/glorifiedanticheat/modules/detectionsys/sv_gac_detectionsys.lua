
function gAC.AddDetection( ply, displayReason, shouldPunish, banTime )
    if !gAC.isflyon then return end

    gAC.AdminMessage( ply, displayReason, shouldPunish, banTime )
    if !shouldPunish then return end

    if( banTime >= 0 ) then
        gAC.AddBan( ply, displayReason, banTime )
    end

end