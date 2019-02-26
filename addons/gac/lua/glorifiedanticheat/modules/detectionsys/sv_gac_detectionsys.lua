util.AddNetworkString("g-AC_DetectionClientside")

function gAC.AddDetection( ply, displayReason, shouldPunish, banTime )
    gAC.AdminMessage( ply, displayReason, shouldPunish, banTime )
    gAC.LogEvent( "Detection from " .. ply:Nick() .. " (" .. ply:SteamID() .. "): " .. displayReason )
    if !shouldPunish then return end

    if( banTime >= 0 ) then
        gAC.AddBan( ply, displayReason, banTime )
    elseif( banTime == -1 ) then
        gAC.Kick( ply, displayReason )
    end
end


net.Receive("g-AC_DetectionClientside", function(len, ply)
	local dTable = net.ReadTable()
	gAC.AddDetection( ply, dTable[1], dTable[2], dTable[3] )
end)