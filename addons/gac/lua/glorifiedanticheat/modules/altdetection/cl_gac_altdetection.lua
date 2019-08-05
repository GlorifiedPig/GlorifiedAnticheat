local _net_Receive = net.Receive
local _net_Start = net.Start
local _net_WriteInt = net.WriteInt
local _net_WriteString = net.WriteString
local _pairs = pairs
local _string_Split = string.Split
local _table_HasValue = table.HasValue
local _table_insert = table.insert

local _LocalPlayer = (CLIENT and LocalPlayer or NULL)
local _net_SendToServer = (CLIENT and net.SendToServer or NULL)


_net_Receive("g-AC_AltCheck", function()
	local SteamID = _LocalPlayer():SteamID64()

	local IDs = _LocalPlayer():GetPData( "gac_alts", "" )
	local idArray = _string_Split( IDs, "|" )

	if( !_table_HasValue( idArray, SteamID ) ) then

		if IDs == "" then
			_LocalPlayer():SetPData( "gac_alts", SteamID )
			IDs = SteamID
		else
			_LocalPlayer():SetPData( "gac_alts", IDs .. "|" .. SteamID )
		end

		_table_insert( idArray, SteamID )

	end

	for k, v in _pairs( idArray ) do
		if v == "" then return end

		_net_Start( "g-AC_AltCheckResponse" )
		_net_WriteString( v )
		_net_SendToServer()
	end 

	_net_Start( "g-AC_AltCheckResponse2" )
	_net_WriteInt( #idArray, 8 )
	_net_SendToServer()

end)

