
net.Receive("g-AC_AltCheck", function()
	local SteamID = LocalPlayer():SteamID64()

	local IDs = LocalPlayer():GetPData( "gac_alts", "" )
	local idArray = string.Split( IDs, "|" )

	if( !table.HasValue( idArray, SteamID ) ) then

		if IDs == "" then
			LocalPlayer():SetPData( "gac_alts", SteamID )
			IDs = SteamID
		else
			LocalPlayer():SetPData( "gac_alts", IDs .. "|" .. SteamID )
		end

		table.insert( idArray, SteamID )

	end

	for k, v in pairs( idArray ) do
		if v == "" then return end

		net.Start( "g-AC_AltCheckResponse" )
		net.WriteString( v )
		net.SendToServer()
	end 

	net.Start( "g-AC_AltCheckResponse2" )
	net.WriteInt( #idArray, 8 )
	net.SendToServer()

end)

