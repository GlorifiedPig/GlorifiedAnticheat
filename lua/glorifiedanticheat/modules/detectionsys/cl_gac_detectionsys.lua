function gAC.AddDetection( displayReason, shouldPunish, banTime )
	net.Start( "g-AC_DetectionClientside" )
	net.WriteTable( {displayReason, shouldPunish, banTime} )
	net.SendToServer()
end