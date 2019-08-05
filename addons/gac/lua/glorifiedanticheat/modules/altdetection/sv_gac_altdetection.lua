local _hook_Add = hook.Add
local _net_ReadInt = net.ReadInt
local _net_ReadString = net.ReadString
local _net_Receive = net.Receive
local _net_Start = net.Start
local _timer_Simple = timer.Simple
local _util_SteamIDFrom64 = util.SteamIDFrom64

local _net_Send = (SERVER and net.Send or NULL)
local _util_AddNetworkString = (SERVER and util.AddNetworkString or NULL)


_util_AddNetworkString( "g-AC_AltCheck" )
_util_AddNetworkString( "g-AC_AltCheckResponse" )
_util_AddNetworkString( "g-AC_AltCheckResponse2" )

_hook_Add( "PlayerSpawn", "gac-alt-spawn", function( ply )

	if( !gAC.config.ALT_DETECTION_CHECKS ) then return end

	_timer_Simple( 15, function()
		_net_Start( "g-AC_AltCheck" )
		_net_Send( ply )
	end )

end)

_net_Receive("g-AC_AltCheckResponse", function(len, ply)

	if( !gAC.config.ALT_DETECTION_CHECKS ) then return end

	local steamId64 = _net_ReadString()

	if ( ( gAC.config.BAN_TYPE == "custom" && GetUPDataGACSID64( "IsBanned", steamId64 ) == true ) || ( gAC.config.BAN_TYPE == "ulx" && ULib.bans[_util_SteamIDFrom64( steamId64 )] ) ) then
		gAC.AddDetection( ply, "Ban evasion [Code 110]", gAC.config.ALT_DETECTION_PUNISHMENT, gAC.config.ALT_DETECTION_BANTIME )
	end

end)

_net_Receive("g-AC_AltCheckResponse2", function( len, ply )
	if !gAC.config.ALT_DETECTION_NOTIFY_ALTS then return end
		
	local count = _net_ReadInt( 8 )
	if count > 1 then
		gAC.AddDetection( ply, "Joined using " .. count .. " alts.", false, 0 )
	end
end)