
function gAC.GetFormattedBanText( displayReason, banTime )
    local banString = "_____[ g-AC DETECTION ]_____\n\nReason: '" .. displayReason .. "'\n\n"
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

if gAC.config.BAN_TYPE != "ulx" then
    function gAC.AddBan( ply, displayReason, banTime )
        ply:SetPData( "gAC_IsBanned", true )
        ply:SetPData( "gAC_BannedAtTime", os.time() )
        ply:SetPData( "gAC_BanTime", banTime )
        ply:SetPData( "gAC_BanDisplayReason", displayReason )

        ply:Kick( gAC.GetFormattedBanText( displayReason, banTime ) )
    end

    function gAC.RemoveBan( ply )
        ply:SetPData( "gAC_IsBanned", false )
        ply:SetPData( "gAC_BannedAtTime", 0 )
        ply:SetPData( "gAC_BanTime", 1 )
        ply:SetPData( "gAC_BanDisplayReason", "nil" )
    end

    function gAC.UnbanCommand( caller, plySID64 )
        if( !gAC.PlayerHasUnbanPerm( caller ) ) then return end
        if( !file.IsDir( "g-AC", "DATA" ) ) then
            file.CreateDir( "g-AC" )
        end

        if( file.Exists( "g-AC/" .. plySID64 .. ".txt", "DATA" ) ) then gAC.ClientMessage( caller, "That player is already due for an unban.", Color( 225, 150, 25 ) ) return end
        file.Write( "g-AC/" .. plySID64 .. ".txt", "" )
        gAC.AdminMessage( plySID64, "Ban removed by " .. caller:Nick() .. "" )
    end

    function gAC.BanCheck( ply )
        if( file.Exists( "g-AC/" .. ply:SteamID64() .. ".txt", "DATA" ) ) then
            file.Delete( "g-AC/" .. ply:SteamID64() .. ".txt" )

            if( ply:GetPData( "gAC_IsBanned" ) ) then
                gAC.RemoveBan( ply )

                gAC.AdminMessage( ply:Nick(), "Player's ban removed upon login (admin manually unbanned)", false )
                return
            end
        end

        if( ply:GetPData( "gAC_IsBanned" ) == true ) then
            if( ( os.time() >= ( ply:GetPData( "gAC_BannedAtTime" ) + ( ply:GetPData( "gAC_BanTime" ) * 60 ) ) ) && ply:GetPData( "gAC_BanTime" ) != 0 ) then
                gAC.RemoveBan( ply )

                gAC.AdminMessage( ply:Nick(), "Player's ban expired.", false )
            else
                ply:Kick( gAC.GetFormattedBanText( ply:GetPData( "gAC_BanDisplayReason" ), ply:GetPData( "gAC_BanTime" ) ) )
            end
        end
    end

    hook.Add( "PlayerInitialSpawn", "g-ACPlayerInitialSPawnBanSys", function( ply )
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
        RunConsoleCommand( "ulx", "banid", ply:SteamID(), banTime, displayReason )
    end
end

function gAC.Kick( ply, displayReason )
    ply:Kick( gAC.GetFormattedBanText( displayReason, -1 ) )
end