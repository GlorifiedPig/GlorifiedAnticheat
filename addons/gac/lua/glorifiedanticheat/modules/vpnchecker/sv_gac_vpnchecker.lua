
if !gAC.config.VPN_CHECKER then return end
if true then return end -- this file is wip so please dont touch, i'm only pushing cause i gotta leave fast

hook.Add( "PlayerInitialSpawn", "g-ACPlayerInitialSpawnVPNChecker", function( ply, button )

    local vpnChance = 0
    local vpnTable = string.Split( ply:IPAddress(), ":" )
    PrintTable(vpnTable)

    if vpnTable[1] == "loopback" || vpnTable[1] == nil then return end
    http.Fetch( "http://check.getipintel.net/check.php?ip=" .. vpnTable[1] .. "&contact=killingpigs123@gmail.com",
    function( body, len, headers, code )
        print( "VPN: " .. body )
    end,
    function( error )
        print( "[g-AC] VPN checking failed on player " .. ply:Nick() .. " with code " .. error .. "." )
    end )

    --gAC.AddDetection( ply, "Suspicious keybind (" .. buttonName .. ") pressed [Code 102]", false )

end )