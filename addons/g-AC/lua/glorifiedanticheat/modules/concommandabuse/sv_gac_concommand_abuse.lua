
util.AddNetworkString( "g-ACIllegalConCommand" )
util.AddNetworkString( "g-ACReceiveExploitList" )
util.AddNetworkString( "g-ACReceiveExploitListCS" )

if !gAC.config.ILLEGAL_CONCOMMAND_CHECKS then return end
net.Receive( "g-ACIllegalConCommand", function( len, ply )
    gAC.AddDetection( ply, "Illegal console command detected [Code 104]", gAC.config.ILLEGAL_CONCOMMAND_PUNISHMENT, gAC.config.ILLEGAL_CONCOMMAND_BANTIME )
end )

net.Receive( "g-ACReceiveExploitListCS", function( len, ply )
    net.Start( "g-ACReceiveExploitList" )
    net.WriteTable( gAC.config.EXPLOIT_LIST )
    net.Send( ply )
end )