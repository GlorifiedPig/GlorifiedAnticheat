local _hook_Add = hook.Add
local _string_len = string.len
local _tonumber = tonumber
local _util_JSONToTable = util.JSONToTable
local _http_Fetch = http.Fetch


function gAC.FamilyShareCheck( ply )
    if( _string_len( gAC.config.STEAM_API_KEY ) <= 1 || !gAC.config.ENABLE_FAMILY_SHARE_CHECKS ) then return end

    _http_Fetch( "http://api.steampowered.com/IPlayerService/IsPlayingSharedGame/v0001/?key=" .. gAC.config.STEAM_API_KEY .. "&format=json&steamid=" .. ply:SteamID64() .. "&appid_playing=4000",
        function( body )
            if( !body ) then return end
            local bodyTable = _util_JSONToTable( body )
            if( !bodyTable || !bodyTable.response || !bodyTable.response.lender_steamid ) then return end

            local ownerSteamID = _tonumber( bodyTable.response.lender_steamid )
            if( ownerSteamID == 0 ) then return end

            gAC.AddDetection( ply, "Joined from family shared account [Code 105]", gAC.config.FAMILY_SHARE_PUNISHMENT, gAC.config.FAMILY_SHARE_BANTIME )
        end )
end

_hook_Add( "PlayerInitialSpawn", "g-ACFamilyShareCheckInitialSpawn", function( ply )
    gAC.FamilyShareCheck( ply )
end )