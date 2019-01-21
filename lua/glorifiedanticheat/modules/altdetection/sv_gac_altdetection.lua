
util.AddNetworkString( "g-AC_AltCheck" )
util.AddNetworkString( "g-AC_AltCheckResponse" )
util.AddNetworkString( "g-AC_AltCheckResponse2" )

hook.Add( "PlayerSpawn", "gac-alt-spawn", function( ply )

	if( !gAC.config.ALT_DETECTION_CHECKS ) then return end

	timer.Simple( 15, function()
		net.Start( "g-AC_AltCheck" )
		net.Send( ply )
	end )

end)

net.Receive("g-AC_AltCheckResponse", function(len, ply)

	if( !gAC.config.ALT_DETECTION_CHECKS ) then return end

	local steamId64 = net.ReadString()

	if ( ( gAC.config.BAN_TYPE == "custom" && GetUPDataGACSID64( "IsBanned", steamId64 ) == true ) || ( gAC.config.BAN_TYPE == "ulx" && ULib.bans[util.SteamIDFrom64( steamId64 )] ) ) then
		gAC.AddDetection( ply, "Ban evasion [Code 110]", gAC.config.ALT_DETECTION_PUNISHMENT, gAC.config.ALT_DETECTION_BANTIME )
	end

end)

net.Receive("g-AC_AltCheckResponse2", function( len, ply )
	if !gAC.config.ALT_DETECTION_NOTIFY_ALTS then return end
		
	local count = net.ReadInt( 8 )
	if count > 1 then
		gAC.AddDetection( ply, "Joined using " .. count .. " alts.", false, 0 )
	end
end)