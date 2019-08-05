local _Color = Color
local _IsValid = IsValid
local _isstring = isstring
local _net_ReadTable = net.ReadTable
local _net_Receive = net.Receive
local _string_len = string.len

local _surface_PlaySound = (CLIENT and surface.PlaySound or NULL)


_net_Receive( "g-ACReceiveClientMessage1", function()

    local infoTable = _net_ReadTable()
    local ply = infoTable[1]
    local displayReason = infoTable[2]
    local wasPunished = infoTable[3]
    local banTime = infoTable[4]
    
    if( _isstring( ply ) && _string_len( ply ) == 17 ) then
        chat.AddText( _Color( 30, 150, 255 ), gAC.config.SYNTAX, _Color( 255, 50, 50 ), "Detection from '", _Color( 255, 0, 0 ), ply, _Color( 255, 50, 50 ), "'" )
    else
        if( !_isstring( ply ) && ply:IsValid() && ply:IsPlayer() ) then
            chat.AddText( _Color( 30, 150, 255 ), gAC.config.SYNTAX, _Color( 255, 50, 50 ), "Detection from '", _Color( 255, 0, 0 ), ply:Nick(), _Color( 255, 50, 50 ), "'" )
        end

        if( _isstring( ply ) ) then
            chat.AddText( _Color( 30, 150, 255 ), gAC.config.SYNTAX, _Color( 255, 50, 50 ), "Detection from '", _Color( 255, 0, 0 ), ply, _Color( 255, 50, 50 ), "'" )
        end
    end

    chat.AddText( _Color( 255, 50, 50 ), "Reasoning: '", _Color( 255, 0, 0 ), displayReason , _Color( 255, 50, 50 ), "'" )
    if( wasPunished ) then
        if( banTime == -1 ) then
            chat.AddText( _Color( 255, 50, 50 ), "Punishment: ", _Color( 255, 0, 0 ), "Kick" )
        elseif( banTime == 0 ) then
            chat.AddText( _Color( 255, 50, 50 ), "Punishment: ", _Color( 255, 0, 0 ), "Permanent Ban" )
        elseif( banTime >= 0 ) then
            chat.AddText( _Color( 255, 50, 50 ), "Punishment: ", _Color( 255, 0, 0 ), "Temporary Ban (" .. banTime .. " minutes)" )
        end
    end

    if gAC.config.ADMIN_MESSAGE_PING != "" then
        _surface_PlaySound(gAC.config.ADMIN_MESSAGE_PING)
    end
end )

_net_Receive( "g-ACReceiveClientMessage2", function()

    local infoTable = _net_ReadTable()
    local message = infoTable[1]
    local colour = infoTable[2]
    
    chat.AddText( _Color( 30, 150, 255 ), gAC.config.SYNTAX, colour, message )

end )