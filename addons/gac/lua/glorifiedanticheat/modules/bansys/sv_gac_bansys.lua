local _Color = Color
local _RunConsoleCommand = RunConsoleCommand
local _concommand_Add = concommand.Add
local _file_CreateDir = file.CreateDir
local _file_Delete = file.Delete
local _file_Exists = file.Exists
local _file_IsDir = file.IsDir
local _file_Write = file.Write
local _hook_Add = hook.Add
local _string_len = string.len
local _tonumber = tonumber
local _timer_Exists = timer.Exists
local _timer_Remove = timer.Remove
local _timer_Create = timer.Create
local _isstring = isstring
local _player_GetBySteamID = player.GetBySteamID


function gAC.GetFormattedBanText( displayReason, banTime )

    local banString = "_____"..gAC.config.BAN_MESSAGE_SYNTAX.."_____\n\nReason: '" .. displayReason .. "'\n\n"
    banTime = _tonumber( banTime )
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

function gAC.GetBanSyntax(code)
    return gAC.config.BAN_MESSAGE_SYNTAX or code
end

if gAC.config.BAN_TYPE == "custom" then
    function gAC.AddBan( ply, displayReason, banTime )
        banTime = _tonumber( banTime )
        ply:SetUPDataGAC( "gAC_IsBanned", true )
        ply:SetUPDataGAC( "gAC_BannedAtTime", os.time() )
        ply:SetUPDataGAC( "gAC_BanTime", banTime )
        ply:SetUPDataGAC( "gAC_BanDisplayReason", displayReason )

        ply:Kick( gAC.GetFormattedBanText( displayReason, banTime ) )

        if gAC.config.DELAYEDBANS then
            if _timer_Exists('gAC.DelayedBan-' .. ID) then return end
            if _timer_Exists('gAC.DelayedKick-' .. ID) then
                _timer_Remove('gAC.DelayedKick-' .. ID)
            end
            _timer_Create('gAC.DelayedBan-' .. ID, gAC.config.DELAYEDBANS_TIME, 1, function()
                local _ply = _player_GetBySteamID(ID)
                if _ply == false then return end
                ply:Kick( gAC.GetFormattedBanText( displayReason, banTime ) )
            end)
        else
            ply:Kick( gAC.GetFormattedBanText( displayReason, banTime ) )
        end
    end

    function gAC.RemoveBan( ply )
        ply:SetUPDataGAC( "gAC_IsBanned", false )
        ply:SetUPDataGAC( "gAC_BannedAtTime", 0 )
        ply:SetUPDataGAC( "gAC_BanTime", 1 )
        ply:SetUPDataGAC( "gAC_BanDisplayReason", "nil" )
    end

    function gAC.UnbanCommand( caller, plySID64 )
        if( !gAC.PlayerHasUnbanPerm( caller ) ) then return end
        if( !_file_IsDir( "g-ac", "DATA" ) ) then
            _file_CreateDir( "g-ac" )
        end

        if( _file_Exists( "g-ac/" .. plySID64 .. ".txt", "DATA" ) ) then gAC.ClientMessage( caller, "That player is already due for an unban.", _Color( 225, 150, 25 ) ) return end
        _file_Write( "g-ac/" .. plySID64 .. ".txt", "" )
        gAC.AdminMessage( plySID64, "Ban removed by " .. caller:Nick() .. "" )
    end

    function gAC.BanCheck( ply )
        if( _file_Exists( "g-ac/" .. ply:SteamID64() .. ".txt", "DATA" ) ) then
            _file_Delete( "g-ac/" .. ply:SteamID64() .. ".txt" )

            if( ply:GetUPDataGAC( "gAC_IsBanned" ) == true || ply:GetUPDataGAC( "gAC_IsBanned" ) == "true" || ply:GetUPDataGAC( "gAC_IsBanned" ) == 1 ) then
                gAC.RemoveBan( ply )

                gAC.AdminMessage( ply:Nick(), "Player's ban removed upon login (admin manually unbanned)", false )
                return
            end
        end

        if( ply:GetUPDataGAC( "gAC_IsBanned" ) == true || ply:GetUPDataGAC( "gAC_IsBanned" ) == "true" || ply:GetUPDataGAC( "gAC_IsBanned" ) == 1 ) then
            if( ( os.time() >= ( _tonumber( ply:GetUPDataGAC( "gAC_BannedAtTime" ) ) + ( tonumber( ply:GetUPDataGAC( "gAC_BanTime" ) ) * 60 ) ) ) && tonumber( ply:GetUPDataGAC( "gAC_BanTime" ) ) != 0 ) then
                gAC.RemoveBan( ply )

                gAC.AdminMessage( ply:Nick(), "Player's ban expired.", false )
            else
                ply:Kick( gAC.GetFormattedBanText( ply:GetUPDataGAC( "gAC_BanDisplayReason" ), ply:GetUPDataGAC( "gAC_BanTime" ) ) )
            end
        end
    end

    _hook_Add( "PlayerInitialSpawn", "g-ACPlayerInitialSpawnBanSys", function( ply )
        gAC.BanCheck( ply )
    end )

    _concommand_Add( "gac-unban", function( ply, cmd, args )
        if( !gAC.PlayerHasUnbanPerm( ply ) ) then gAC.ClientMessage( ply, "You don't have permission to do that!", _Color( 225, 150, 25 ) ) return end

        local steamid64 = args[1]
        
        if( steamid64 == "" || steamid64 == nil ) then gAC.ClientMessage( ply, "Please input a valid SteamID64.", _Color( 225, 150, 25 ) ) return end
        if( _string_len( steamid64 ) != 17 ) then gAC.ClientMessage( ply, "Please input a valid SteamID64.", _Color( 225, 150, 25 ) ) return end
        gAC.UnbanCommand( ply, steamid64 )
    end )
else
    local BannablePlys = {}

    function gAC.GetBanType(ply, banTime, displayReason)
        local ply = _isstring(ply) and ply or ply:SteamID()
        if gAC.config.BAN_TYPE == "ulx" then
            _RunConsoleCommand( "ulx", "banid", ply, banTime, displayReason )
        elseif gAC.config.BAN_TYPE == "d3a" then
            if( _tonumber( ply:GetUPDataGAC( "gAC_BanTime" ) ) != 0 ) then
                _RunConsoleCommand( "d3a", "ban", ply, banTime, "minutes", "'" .. displayReason .. "'" )
            else
                _RunConsoleCommand( "d3a", "perma", ply, "'" .. displayReason .. "'" )
            end
        elseif gAC.config.BAN_TYPE == "serverguard" then
            _RunConsoleCommand( "serverguard_ban", ply, banTime / 60, displayReason )
        elseif gAC.config.BAN_TYPE == "sam" then
            SAM.AddBan( ply, nil, banTime / 60, displayReason )
        elseif gAC.config.BAN_TYPE == "custom_func" then
            gAC.config.BAN_FUNC( ply, banTime, displayReason )
        end
    end

    function gAC.AddBan( ply, displayReason, banTime )
        if gAC.config.DELAYEDBANS then
            local ID = ply:SteamID()
            if _timer_Exists('gAC.DelayedBan-' .. ID) then return end
            if _timer_Exists('gAC.DelayedKick-' .. ID) then
                _timer_Remove('gAC.DelayedKick-' .. ID)
            end
            BannablePlys[ID] = {
                displayReason = displayReason,
                banTime = banTime
            }
            _timer_Create('gAC.DelayedBan-' .. ID, gAC.config.DELAYEDBANS_TIME, 1, function()
                gAC.GetBanType(ID, banTime, displayReason)
            end)
        else
            gAC.GetBanType(ply, banTime, displayReason)
        end
    end

    _hook_Add('PlayerDisconnected', 'gAC.BanDisconnected', function(ply)
        local ID = ply:SteamID()
        if BannablePlys[ID] then
            if _timer_Exists('gAC.DelayedBan-' .. ID) then
                _timer_Remove('gAC.DelayedBan-' .. ID)
            end
            gAC.GetBanType(ID, BannablePlys[ID].banTime, BannablePlys[ID].displayReason)
        end
    end)
end

function gAC.Kick( ply, displayReason )
    local ID = ply:SteamID()
    if gAC.config.DELAYEDKICKS then
        if _timer_Exists('gAC.DelayedKick-' .. ID) or _timer_Exists('gAC.DelayedBan-' .. ID) then return end
        _timer_Create('gAC.DelayedKick-' .. ID, gAC.config.DELAYEDKICKS_TIME, 1, function()
            local _ply = _player_GetBySteamID(ID)
            if _ply == false then return end
            if gAC.config.KICK_TYPE == "default" then
                _ply:Kick( gAC.GetFormattedBanText( displayReason, -1 ) )
            elseif gAC.config.KICK_TYPE == "custom_func" then
                gAC.config.KICK_FUNC( _ply, displayReason )
            end
        end)
    else
        if gAC.config.KICK_TYPE == "default" then
            ply:Kick( gAC.GetFormattedBanText( displayReason, -1 ) )
        elseif gAC.config.KICK_TYPE == "custom_func" then
            gAC.config.KICK_FUNC( ply, displayReason )
        end
    end
end