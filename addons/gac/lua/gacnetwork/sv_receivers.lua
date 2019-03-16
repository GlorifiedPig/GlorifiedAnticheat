util.AddNetworkString (gAC.Network.GlobalChannel)
util.AddNetworkString ("g-AC_nonofurgoddamnbusiness")

net.Receive (gAC.Network.GlobalChannel,
	function (bitCount, ply)
		if gAC.Debug then
			gAC.Print("Received data from " .. ply:Nick () .. " (" .. ply:SteamID () .. ") via " .. gAC.Network.GlobalChannel .. ".")
		end
		gAC.Network:HandleMessage(bitCount, ply)
	end
)

