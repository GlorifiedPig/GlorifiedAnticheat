function gAC.sendPayload(ply, payload, rsname)
    net.Start( gAC.netMsgs.clReceivePayload )
	net.WriteString( payload )
	net.WriteString( rsname )
	net.Send( ply )
end