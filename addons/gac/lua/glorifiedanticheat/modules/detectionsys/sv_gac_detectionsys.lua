util.AddNetworkString("g-AC_DetectionCL")

function gAC.AddDetection( ply, displayReason, shouldPunish, banTime )
    if !gAC.Debug && gAC.config.IMMUNE_USERS[ply:SteamID64()] then return end

    gAC.AdminMessage( ply:Nick() .. " (" .. ply:SteamID() .. ")" , displayReason, shouldPunish, banTime )
    if gAC.Debug then return end
    
    gAC.LogEvent( ply, displayReason )
    if !shouldPunish then return end

    if( banTime >= 0 ) then
        gAC.AddBan( ply, displayReason, banTime )
    elseif( banTime == -1 ) then
        gAC.Kick( ply, displayReason )
    end
end

gAC.Network:AddReceiver(
    "g-AC_Detections",
    function(_, data, plr)
        data = util.JSONToTable(data)
        gAC.AddDetection( plr, data[1], data[2], data[3] )
    end
)