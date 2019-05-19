gAC.Network:AddReceiver(
    "G-ACcVarManipSV1",
    function(_, checkedVariables, plr)
        checkedVariables = util.JSONToTable(checkedVariables)
        if( ( checkedVariables[0] != GetConVar("sv_allowcslua"):GetInt() && gAC.config.ALLOWCSLUA_CHECKS ) || ( checkedVariables[1] != GetConVar("sv_cheats"):GetInt() && gAC.config.SVCHEATS_CHECKS ) ) then
            gAC.AddDetection( plr, "Anti C-var manipulation triggered [Code 100]", gAC.config.CVARMANIP_PUNISHMENT, gAC.config.CVARMANIP_BANTIME )
        end
        plr.HasReceivedVarManipResults = true
    end
)

if( gAC.config.ALLOWCSLUA_CHECKS == true || gAC.config.SVCHEATS_CHECKS == true ) then
    hook.Add("Tick", "gAC-CheckCvars", function()
        for k, ply in ipairs( player.GetAll() ) do
            if ply:IsBot() then continue end
            if !ply.GAC_Cvar_Checks then continue end
            if !ply.GAC_Cvar then ply.GAC_Cvar = 0 end
            if ply.HasReceivedVarManipResults == nil && ply.GAC_Cvar_Checks > 0 && ply.GAC_Cvar_Checks <= CurTime() then
                if ply.GAC_Cvar > 4 then
                    gAC.AddDetection( ply, "C-var manipulation results haven't returned [Code 101]", gAC.config.CVARMANIP_PUNISHMENT, -1 )
                    ply.GAC_Cvar_Checks = nil
                    continue
                end
                ply.GAC_Cvar = ply.GAC_Cvar + 1
                ply.GAC_Cvar_Checks = CurTime() + 20
                gAC.Network:Send("G-ACcVarManipCS1", "", ply)
                continue
            end
            if ply.GAC_Cvar_Checks > CurTime() then continue end
            ply.HasReceivedVarManipResults = nil
            ply.GAC_Cvar = 0
            ply.GAC_Cvar_Checks = CurTime() + 15
            gAC.Network:Send("G-ACcVarManipCS1", "", ply)
        end
    end )
end

hook.Add("gAC.CLFilesLoaded", "CheckCvars", function(ply)
    ply.GAC_Cvar = 0
    ply.GAC_Cvar_Checks = 0
end)

if gAC.config.DISABLE_BAD_COMMANDS then
    hook.Add( "Initialize", "g-ACcVarManipSV3", function()
        game.ConsoleCommand("sv_allowcslua 0\n")
        game.ConsoleCommand("sv_cheats 0\n")
    end )
end

hook.Add( "gAC.CLFilesLoaded", "g-ACPlayerInitialSpawnJointimeChecker", function( ply )
    ply.JoinTimeGAC = CurTime()
end )