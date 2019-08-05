local _IsValid = IsValid
local _pairs = pairs


function gAC.PlayerHasAdminMessagePerm( ply )
    return gAC.PlayerHasUsergroupFromTable( ply, gAC.config.ADMIN_MESSAGE_USERGROUPS ) || ply:IsAdmin()
end

function gAC.PlayerHasUnbanPerm( ply )
    return gAC.PlayerHasUsergroupFromTable( ply, gAC.config.UNBAN_USERGROUPS ) || ply:IsSuperAdmin()
end

function gAC.PlayerHasUsergroupFromTable( ply, usergroups )

    if !_IsValid(ply) and ply == NULL then return true end

    for k, v in _pairs( usergroups ) do
        if( ply:IsUserGroup( v ) ) then return true end
    end

    return false

end