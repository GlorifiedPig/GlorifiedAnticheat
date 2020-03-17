local _util_JSONToTable = util.JSONToTable
local _print = print

function gAC.AddDetection( ply, displayReason, shouldPunish, banTime )
    if !gAC.Debug && gAC.config.IMMUNE_USERS[ply:SteamID64()] then return end

    gAC.AdminMessage( ply:Nick() .. " (" .. ply:SteamID() .. ")" , displayReason, shouldPunish, banTime )
    gAC.Print( "Detection from " .. ply:Nick() .. " (" .. ply:SteamID() .. ") -> " .. displayReason )
    gAC.SendDetectionWebhook( ply, displayReason, shouldPunish, banTime )

    if shouldPunish == 1 then
        punishmentT = banTime
    else
        punishmentT = -2
    end

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
    function(data, plr)
        data = _util_JSONToTable(data)
        gAC.AddDetection( plr, data[1], data[2], data[3] )
    end
)