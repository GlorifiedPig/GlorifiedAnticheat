local _Color = Color
local _IsValid = IsValid
local _MsgC = MsgC
local _net_Start = net.Start
local _net_WriteTable = net.WriteTable
local _pairs = pairs
local _player_GetAll = player.GetAll
local _print = print

local _PrintMessage = (SERVER and PrintMessage or NULL)
local _net_Broadcast = (SERVER and net.Broadcast or NULL)
local _net_Send = (SERVER and net.Send or NULL)
local _util_AddNetworkString = (SERVER and util.AddNetworkString or NULL)


_util_AddNetworkString( "g-ACReceiveClientMessage1" )
_util_AddNetworkString( "g-ACReceiveClientMessage2" )

function gAC.AdminMessage( ply, displayReason, wasPunished, banTime )
    for k, v in _pairs( _player_GetAll() ) do
        if( gAC.PlayerHasAdminMessagePerm( v ) ) then
            _net_Start( "g-ACReceiveClientMessage1" )
            _net_WriteTable( { ply, displayReason, wasPunished, banTime } )
            _net_Send( v )
        end
    end
end

function gAC.ClientMessage( ply, message, colour )
    if !_IsValid(ply) then
        _MsgC( _Color( 30, 150, 255 ), gAC.config.SYNTAX, colour, message .. "\n" )
    else
        _net_Start( "g-ACReceiveClientMessage2" )
        _net_WriteTable( { message, colour } )
        _net_Send( ply )
    end
end

function gAC.PrintMessage( ply, type, message )
    if _IsValid(ply) then
        ply:PrintMessage(type, message)
    else
        _print(message)
    end
end

function gAC.Broadcast( message, colour )
    _net_Start( "g-ACReceiveClientMessage2" )
    _net_WriteTable( { message, colour } )
    _net_Broadcast()
end