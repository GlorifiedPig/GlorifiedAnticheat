net.Receive("gac_altcheck", function()
	local steamid = LocalPlayer():SteamID64()

	local ids = LocalPlayer():GetPData("gac_alts", "")
	local idArray = string.Split( ids, "|" )



	-- Add if not in Alt Database
	if(!table.HasValue(idArray, steamid)) then

		if ids == "" then
			LocalPlayer():SetPData("gac_alts", steamid)
			ids = steamid
		else
			LocalPlayer():SetPData("gac_alts", ids.."|"..steamid)
		end

		table.insert(idArray, steamid)

	end

	-- Check if one of the alts are banned
	for k, v in pairs(idArray) do
		if v == "" then return end

		net.Start("gac_altcheckresponse")
		net.WriteString(v)
		net.SendToServer()
	end 

	-- Send Alt Count to notify admins
	net.Start("gac_altcheckresponse2")
	net.WriteInt(#idArray, 8)
	net.SendToServer()


	-- Done :)


end)

