local _util_JSONToTable = util.JSONToTable
local _print = print
local _http_Post = http.Post

function gAC.AddDetection( ply, displayReason, shouldPunish, banTime )
    if !gAC.Debug && gAC.config.IMMUNE_USERS[ply:SteamID64()] then return end

    gAC.AdminMessage( ply:Nick() .. " (" .. ply:SteamID() .. ")" , displayReason, shouldPunish, banTime )
    gAC.Print("Detection from " .. ply:Nick() .. " (" .. ply:SteamID() .. ") -> " .. displayReason)
    if gAC.Debug then return end
    
    gAC.LogEvent( ply, displayReason )
    if !shouldPunish then return end

    if( banTime >= 0 ) then
        gAC.AddBan( ply, displayReason, banTime )
    elseif( banTime == -1 ) then
        gAC.Kick( ply, displayReason )
    end

    local punishmentT = 0
    if shouldPunish == 1 then
        punishmentT = banTime
    else
        punishmentT = -2
    end

    _http_Post( "https://stats.g-ac.dev/api/detection/add", { server_id = gAC.server_id, target = ply:SteamID64(), detection = displayReason, punishment = punishmentT }, function( result )
        local resp = util.JSONToTable(result)
        if(resp["success"] == "false") then
            gAC.Print("[Global Bans] Generating statistics report failed: "..resp["error"])
        else
            gAC.Print("[Global Bans] Stat report generated. ID: "..resp["id"])
        end
    end, function( failed )
        gAC.Print( "[Global Bans] Stats report failed: " .. failed )
    end )
end

gAC.Network:AddReceiver(
    "g-AC_Detections",
    function(data, plr)
        data = _util_JSONToTable(data)
        gAC.AddDetection( plr, data[1], data[2], data[3] )
    end
)