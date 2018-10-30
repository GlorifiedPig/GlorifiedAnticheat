
util.AddNetworkString( "G-ACcVarManipCS1" )
util.AddNetworkString( "G-ACcVarManipSV1" )
util.AddNetworkString( "G-ACcVarManipSV2" )

net.Receive( "G-ACcVarManipSV1", function( len, ply )

    local checkedVariables = net.ReadTable()

    if( ( checkedVariables[0] == 1 && gAC.config.ALLOWCSLUA_CHECKS ) || ( checkedVariables[1] == 1 && gAC.config.SVCHEATS_CHECKS ) ) then
        gAC.AddDetection( ply, "Anti C-var manipulation triggered [Code 100]", gAC.config.CVARMANIP_PUNISHMENT, gAC.config.CVARMANIP_BANTIME )
    end
    ply:SetNWBool( "HasReceivedVarManipResults", true )

end )

if( gAC.config.ALLOWCSLUA_CHECKS == true || gAC.config.SVCHEATS_CHECKS == true ) then
    timer.Create( "G-ACcVarManipSV2T", 5, 0, function()
        for k, v in pairs( player.GetAll() ) do
            gAC.CheckForConvarManipulation( v )
        end
    end )
end

function gAC.CheckForConvarManipulation( ply )
    net.Start( "G-ACcVarManipCS1" )
    net.Send( ply )

    ply:SetNWBool( "HasReceivedVarManipResults", false )

    timer.Simple( 4, function()
        if( !ply:GetNWBool( "HasReceivedVarManipResults" ) ) then
            gAC.AddDetection( ply, "C-var manipulation results haven't returned [Code 101]", gAC.config.CVARMANIP_PUNISHMENT, -1 )
        end
    end )
end

if gAC.config.DISABLE_BAD_COMMANDS then
    hook.Add( "Initialize", "g-ACcVarManipSV3", function()
        RunConsoleCommand( "sv_allowcslua", 0 )
        RunConsoleCommand( "sv_cheats", 0 )
    end )
end