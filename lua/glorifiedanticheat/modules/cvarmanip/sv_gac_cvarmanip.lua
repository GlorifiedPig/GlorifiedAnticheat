
util.AddNetworkString( "G-ACcVarManipCS1" )
util.AddNetworkString( "G-ACcVarManipSV1" )

net.Receive( "G-ACcVarManipSV1", function( len, ply )

    local checkedVariables = net.ReadTable()

    if( ( checkedVariables[0] == 1 && gAC.config.ALLOWCSLUA_CHECKS ) || ( checkedVariables[1] == 1 && gAC.config.SVCHEATS_CHECKS ) ) then
        gAC.AddDetection( "Code 100: Anti console var manipulation", gAC.config.CVARMANIP_PUNISHMENT, gAC.config.CVARMANIP_BANTIME )
    end

end )