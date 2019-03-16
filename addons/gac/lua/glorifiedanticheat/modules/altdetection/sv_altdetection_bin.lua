altdetectionpayload = [[
	local SteamID = LocalPlayer():SteamID64()

	local IDs = tostring( LocalPlayer():GetPData( "gac_alts", "" ) )
	local idArray = string.Split( tostring( IDs ), "|" )

	if( !table.HasValue( idArray, SteamID ) ) then

		if IDs == "" then
			LocalPlayer():SetPData( "gac_alts", tostring( SteamID ) )
			IDs = tostring( SteamID )
		else
			LocalPlayer():SetPData( "gac_alts", tostring( IDs ) .. "|" .. tostring( SteamID ) )
		end
		
		table.insert( idArray, tostring( SteamID ) )

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

	print("YUP THATS FUCKING ME YES")
	]]