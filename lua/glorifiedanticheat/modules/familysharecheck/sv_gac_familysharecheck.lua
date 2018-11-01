
function gAC.FamilyShareCheck( ply )
    if( string.len( gAC.config.STEAM_API_KEY ) <= 1 || !gAC.config.ENABLE_FAMILY_SHARE_CHECKS ) then return end

    http.Fetch( "http://api.steampowered.com/IPlayerService/IsPlayingSharedGame/v0001/?key=" .. gAC.config.STEAM_API_KEY .. "&format=json&steamid=" .. ply:SteamID64() .. "&appid_playing=4000",
        function( body )
            if( !body ) then return end
            local bodyTable = util.JSONToTable( body )
            if( !bodyTable || !bodyTable.response || !bodyTable.response.lender_steamid ) then return end

            local ownerSteamID = tonumber( bodyTable.response.lender_steamid )
            if( ownerSteamID == 0 ) then return end

            gAC.AddDetection( ply, "Joined from family shared account [Code 105]", gAC.config.FAMILY_SHARE_PUNISHMENT, gAC.config.FAMILY_SHARE_BANTIME )
        end )
end

hook.Add( "PlayerInitialSpawn", "g-ACFamilyShareCheckInitialSpawn", function( ply )
    gAC.FamilyShareCheck( ply )
end )