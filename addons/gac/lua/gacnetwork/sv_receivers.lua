util.AddNetworkString (gAC.Network.GlobalChannel)
util.AddNetworkString ("g-AC_nonofurgoddamnbusiness")

net.Receive (gAC.Network.GlobalChannel,
	function (bitCount, ply)
		gAC.DBGPrint("Received data from " .. ply:Nick () .. " (" .. ply:SteamID () .. ") via " .. gAC.Network.GlobalChannel .. ".")
		gAC.Network:HandleMessage(bitCount, ply)
	end
)

