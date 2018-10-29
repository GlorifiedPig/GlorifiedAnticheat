
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

function gAC.AddBan( ply, displayReason, banTime )
    ply:SetPData( "gAC_IsBanned", true )
    ply:SetPData( "gAC_BannedAtTime", CurTime() )
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

function gAC.BanCheck( ply )
    if( ply:GetPData( "gAC_IsBanned" ) == true ) then
        if( ( CurTime() >= ( ply:GetPData( "gAC_BannedAtTime" ) + ( ply:GetPData( "gAC_BanTime" ) * 60 ) ) ) && ply:GetPData( "gAC_BanTime" ) != 0 ) then
            gAC.RemoveBan( ply )

            gAC.AdminMessage( ply, "Player's ban expired.", false )
        else
            ply:Kick( gAC.GetFormattedBanText( ply:GetPData( "gAC_BanDisplayReason" ), ply:GetPData( "gAC_BanTime" ) ) )
        end
    end
end

hook.Add( "PlayerInitialSpawn", "g-ACPlayerInitialSPawnBanSys", function( ply )
    if( !gAC.config.DEVELOPER_DEBUG ) then
        gAC.BanCheck( ply )
    end
end )