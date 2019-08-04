local _net_Receive = net.Receive

local _util_AddNetworkString = (SERVER and util.AddNetworkString or NULL)

_util_AddNetworkString (gAC.Network.GlobalChannel)
_util_AddNetworkString ("g-AC_nonofurgoddamnbusiness")

_net_Receive (gAC.Network.GlobalChannel,
	function (bitCount, ply)
		gAC.DBGPrint("Received data from " .. ply:Nick () .. " (" .. ply:SteamID () .. ") via " .. gAC.Network.GlobalChannel .. ".")
		gAC.Network:HandleMessage(bitCount, ply)
	end
)

