function gAC.AddDetection( displayReason, shouldPunish, banTime )
	net.Start( gAC.netMsgs.addDetection )
	net.WriteTable( {displayReason, shouldPunish, banTime} )
	net.SendToServer()
end