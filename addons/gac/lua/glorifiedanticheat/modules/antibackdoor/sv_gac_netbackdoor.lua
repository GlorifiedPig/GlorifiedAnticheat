local _net_Receive = net.Receive
local _pairs = pairs


if !gAC.config.BACKDOOR_NET_EXPLOIT_CHECKS then return end

for k, v in _pairs( gAC.config.BACKDOOR_NETS ) do
    _net_Receive( v, function( len, ply )
        gAC.AddDetection( ply, "Illegal net message called [Code 103]", gAC.config.BACKDOOR_EXPLOITATION_PUNISHMENT, gAC.config.BACKDOOR_EXPLOITATION_BANTIME )
    end )
end