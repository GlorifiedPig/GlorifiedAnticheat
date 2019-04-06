gAC.isflyon = true

gAC.Network:AddReceiver(
    "G-ACcVarManipSV1",
    function(_, checkedVariables, plr)
        checkedVariables = util.JSONToTable(checkedVariables)
        if( ( checkedVariables[0] >= 1 && gAC.config.ALLOWCSLUA_CHECKS ) || ( checkedVariables[1] >= 1 && gAC.config.SVCHEATS_CHECKS ) ) then
            gAC.AddDetection( ply, "Anti C-var manipulation triggered [Code 100]", gAC.config.CVARMANIP_PUNISHMENT, gAC.config.CVARMANIP_BANTIME )
        end
        plr:SetNWBool( "HasReceivedVarManipResults", true )
    end
)


if( gAC.config.ALLOWCSLUA_CHECKS == true || gAC.config.SVCHEATS_CHECKS == true ) then
    timer.Create( "G-ACcVarManipSV2T", 5, 0, function()
        for k, v in pairs( player.GetAll() ) do
            gAC.CheckForConvarManipulation( v )
        end
    end )
end

local InitialVarManipResults = InitialVarManipResults or false
function gAC.CheckForConvarManipulation( ply )
    if ply:IsBot() then return end

    if( ply:GetNWBool( "HasReceivedVarManipResults" ) != false && InitialVarManipResults == false ) then
        InitialVarManipResults = true
        ply:SetNWBool( "HasReceivedVarManipResults", false )
    end

    gAC.Network:Send("G-ACcVarManipCS1", "", ply)

    if gAC.config.CVARMANIP_RETURN_PUNISHMENT then
        timer.Simple( 4, function()
            if( ply:IsValid() && !ply:IsTimingOut() && ply:PacketLoss() < 80 && ply.JoinTimeGAC != nil && ply:GetNWBool( "HasReceivedVarManipResults" ) == false && CurTime() >= ply.JoinTimeGAC + gAC.config.CVARMANIP_RETURN_JOINTIMER ) then
                gAC.AddDetection( ply, "C-var manipulation results haven't returned [Code 101]", gAC.config.CVARMANIP_PUNISHMENT, -1 )
            end
        end )
    end
end

if gAC.config.DISABLE_BAD_COMMANDS then
    hook.Add( "Initialize", "g-ACcVarManipSV3", function()
        RunConsoleCommand( "sv_allowcslua", 0 )
        RunConsoleCommand( "sv_cheats", 0 )
    end )
end

hook.Add( "PlayerInitialSpawn", "g-ACPlayerInitialSpawnJointimeChecker", function( ply )
    ply.JoinTimeGAC = CurTime()
end )