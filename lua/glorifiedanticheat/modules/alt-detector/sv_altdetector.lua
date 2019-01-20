util.AddNetworkString("gac_altcheck")
util.AddNetworkString("gac_altcheckresponse")
util.AddNetworkString("gac_altcheckresponse2")

hook.Add( "PlayerSpawn", "gac-alt-spawn", function()
	if(!gAC.config.ALT_DETECTION_CHECKS) then return end

	timer.Simple(15, function()
		net.Start("gac_altcheck")
		net.Send(ply)
	end)
end)



net.Receive("gac_altcheckresponse", function(len, ply)
	if(!gAC.config.ALT_DETECTION_CHECKS) then return end

	local steamID64 = net.ReadString()
	if ULib.bans[util.SteamIDFrom64(steamID64)] then
		gAC.AddDetection( ply, "Ban Evasion [Code 110]", true, gAC.config.ALT_DETECTION_BANTIME )
	end
end)

net.Receive("gac_altcheckresponse2", function(len, ply)
	if !gAC.config.ALT_DETECTION_NOTIFY_ALTS then return end
		
	local count = net.ReadInt(8)
	if count > 1 then
		gAC.AddDetection(ply, "Joined using "..count.." alts.", false, 0)
	end
end)