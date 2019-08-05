local _hook_Add = hook.Add
local _print = print
local _string_Split = string.Split
local _http_Fetch = http.Fetch


if !gAC.config.VPN_CHECKER then return end

_hook_Add( "gAC.ClientLoaded", "g-ACPlayerInitialSpawnVPNChecker", function( ply )

    local vpnChance = 0
    local vpnTable = _string_Split( ply:IPAddress(), ":" )

    if vpnTable[1] == "loopback" || vpnTable[1] == nil then
        _print( "[g-AC] VPN check failed. Are you running a local or P2P server?" )
        return
    end
    
    _http_Fetch( "http://check.getipintel.net/check.php?ip=" .. vpnTable[1] .. "&contact=killingpigs123@gmail.com",
    function( body, len, headers, code )
        if body == "1" then
            gAC.AddDetection( ply, "Player joined using VPN [Code 122]", false )
        end
    end,
    function( error )
        _print( "[g-AC] VPN checking failed on player " .. ply:Nick() .. " with code " .. error .. "." )
    end )

end )