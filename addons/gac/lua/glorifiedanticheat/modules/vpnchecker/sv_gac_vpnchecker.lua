
if !gAC.config.VPN_CHECKER then return end

hook.Add( "PlayerInitialSpawn", "g-ACPlayerInitialSpawnVPNChecker", function( ply, button )

    local vpnChance = 0
    local vpnTable = string.Split( ply:IPAddress(), ":" )

    if vpnTable[1] == "loopback" || vpnTable[1] == nil then
        print( "[g-AC] VPN check failed. Are you running a local or P2P server?" )
        return
    end
    
    http.Fetch( "http://check.getipintel.net/check.php?ip=" .. vpnTable[1] .. "&contact=killingpigs123@gmail.com",
    function( body, len, headers, code )
        if body == "1" then
            gAC.AddDetection( ply, "Player joined using VPN [Code 122]", false )
        end
    end,
    function( error )
        print( "[g-AC] VPN checking failed on player " .. ply:Nick() .. " with code " .. error .. "." )
    end )

end )