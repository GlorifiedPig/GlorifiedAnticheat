
function gAC.PlayerHasAdminMessagePerm( ply )
    return gAC.PlayerHasUsergroupFromTable( ply, gAC.config.ADMIN_MESSAGE_USERGROUPS ) || ply:IsAdmin()
end

function gAC.PlayerHasUnbanPerm( ply )
    return gAC.PlayerHasUsergroupFromTable( ply, gAC.config.UNBAN_USERGROUPS ) || ply:IsSuperAdmin()
end

function gAC.PlayerHasUsergroupFromTable( ply, usergroups )

    for k, v in pairs( usergroups ) do
        if( ply:IsUserGroup( v ) ) then return true end
    end

    return false

end