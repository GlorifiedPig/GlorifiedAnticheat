
function gAC.GetFormattedBanText( displayReason, banTime )
    local banString = "_____"..gAC.config.BAN_MESSAGE_SYNTAX.."_____\n\nReason: '" .. displayReason .. "'\n\n"
    banTime = tonumber( banTime )
    if( banTime == -1 ) then
        banString = banString .. "Type: Kick"
    elseif( banTime >= 0 ) then
        if( banTime == 0 ) then
            banString = banString .. "Type: Permanent Ban\n\nPlease appeal if you believe this is false"
        else
            banString = banString .. "Type: Temporary Ban\n\nPlease appeal if you believe this is false"
        end
    end

    return banString
end

if gAC.config.BAN_TYPE == "custom" then
    function gAC.AddBan( ply, displayReason, banTime )
        banTime = tonumber( banTime )
        ply:SetUPDataGAC( "gAC_IsBanned", true )
        ply:SetUPDataGAC( "gAC_BannedAtTime", os.time() )
        ply:SetUPDataGAC( "gAC_BanTime", banTime )
        ply:SetUPDataGAC( "gAC_BanDisplayReason", displayReason )

        ply:Kick( gAC.GetFormattedBanText( displayReason, banTime ) )
    end

    function gAC.RemoveBan( ply )
        ply:SetUPDataGAC( "gAC_IsBanned", false )
        ply:SetUPDataGAC( "gAC_BannedAtTime", 0 )
        ply:SetUPDataGAC( "gAC_BanTime", 1 )
        ply:SetUPDataGAC( "gAC_BanDisplayReason", "nil" )
    end

    function gAC.UnbanCommand( caller, plySID64 )
        if( !gAC.PlayerHasUnbanPerm( caller ) ) then return end
        if( !file.IsDir( "g-ac", "DATA" ) ) then
            file.CreateDir( "g-ac" )
        end

        if( file.Exists( "g-ac/" .. plySID64 .. ".txt", "DATA" ) ) then gAC.ClientMessage( caller, "That player is already due for an unban.", Color( 225, 150, 25 ) ) return end
        file.Write( "g-ac/" .. plySID64 .. ".txt", "" )
        gAC.AdminMessage( plySID64, "Ban removed by " .. caller:Nick() .. "" )
    end

    function gAC.BanCheck( ply )
        if( file.Exists( "g-ac/" .. ply:SteamID64() .. ".txt", "DATA" ) ) then
            file.Delete( "g-ac/" .. ply:SteamID64() .. ".txt" )

            if( ply:GetUPDataGAC( "gAC_IsBanned" ) == true || ply:GetUPDataGAC( "gAC_IsBanned" ) == "true" || ply:GetUPDataGAC( "gAC_IsBanned" ) == 1 ) then
                gAC.RemoveBan( ply )

                gAC.AdminMessage( ply:Nick(), "Player's ban removed upon login (admin manually unbanned)", false )
                return
            end
        end

        if( ply:GetUPDataGAC( "gAC_IsBanned" ) == true || ply:GetUPDataGAC( "gAC_IsBanned" ) == "true" || ply:GetUPDataGAC( "gAC_IsBanned" ) == 1 ) then
            if( ( os.time() >= ( tonumber( ply:GetUPDataGAC( "gAC_BannedAtTime" ) ) + ( tonumber( ply:GetUPDataGAC( "gAC_BanTime" ) ) * 60 ) ) ) && tonumber( ply:GetUPDataGAC( "gAC_BanTime" ) ) != 0 ) then
                gAC.RemoveBan( ply )

                gAC.AdminMessage( ply:Nick(), "Player's ban expired.", false )
            else
                ply:Kick( gAC.GetFormattedBanText( ply:GetUPDataGAC( "gAC_BanDisplayReason" ), ply:GetUPDataGAC( "gAC_BanTime" ) ) )
            end
        end
    end

    hook.Add( "PlayerInitialSpawn", "g-ACPlayerInitialSpawnBanSys", function( ply )
        gAC.BanCheck( ply )
    end )

    concommand.Add( "gac-unban", function( ply, cmd, args )
        if( !gAC.PlayerHasUnbanPerm( ply ) ) then gAC.ClientMessage( ply, "You don't have permission to do that!", Color( 225, 150, 25 ) ) return end

        local steamid64 = args[1]
        
        if( steamid64 == "" || steamid64 == nil ) then gAC.ClientMessage( ply, "Please input a valid SteamID64.", Color( 225, 150, 25 ) ) return end
        if( string.len( steamid64 ) != 17 ) then gAC.ClientMessage( ply, "Please input a valid SteamID64.", Color( 225, 150, 25 ) ) return end
        gAC.UnbanCommand( ply, steamid64 )
    end )
else
    function gAC.AddBan( ply, displayReason, banTime )
        if gAC.config.BAN_TYPE == "ulx" then
            RunConsoleCommand( "ulx", "banid", ply:SteamID(), banTime, displayReason )
        elseif gAC.config.BAN_TYPE == "d3a" then
            if( tonumber( ply:GetUPDataGAC( "gAC_BanTime" ) ) != 0 ) then
                RunConsoleCommand( "d3a", "ban", ply:SteamID(), banTime, "minute", displayReason )
            else
                RunConsoleCommand( "d3a", "perma", ply:SteamID(), displayReason )
            end
        end
    end
end

function gAC.Kick( ply, displayReason )
    ply:Kick( gAC.GetFormattedBanText( displayReason, -1 ) )
end