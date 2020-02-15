local _CurTime = CurTime
local _GetConVar = GetConVar
local _hook_Add = hook.Add
local _player_GetAll = player.GetAll
local _util_JSONToTable = util.JSONToTable

gAC.Network:AddReceiver(
    "G-ACcVarManipSV1",
    function(checkedVariables, plr)
        checkedVariables = _util_JSONToTable(checkedVariables)
        if( ( checkedVariables[0] != _GetConVar("sv_allowcslua"):GetInt() && gAC.config.ALLOWCSLUA_CHECKS ) || ( checkedVariables[1] != GetConVar("sv_cheats"):GetInt() && gAC.config.SVCHEATS_CHECKS ) ) then
            gAC.AddDetection( plr, "Anti C-var manipulation triggered [Code 100]", gAC.config.CVARMANIP_PUNISHMENT, gAC.config.CVARMANIP_BANTIME )
            plr.GAC_Cvar_Checks = nil
        end
        plr.HasReceivedVarManipResults = true
    end
)

if( gAC.config.ALLOWCSLUA_CHECKS == true || gAC.config.SVCHEATS_CHECKS == true ) then
    _hook_Add("Tick", "gAC-CheckCvars", function()
        local _IPAIRS_ = _player_GetAll()
        for k=1, #_IPAIRS_   do
        	local ply =_IPAIRS_[k]
            if ply:IsBot() then continue end
            if !ply.GAC_Cvar_Checks then continue end
            if ply:IsTimingOut() then continue end
            if ply.HasReceivedVarManipResults == nil && ply.GAC_Cvar_Checks > 0 && ply.GAC_Cvar_Checks <= _CurTime() then
                if ply.GAC_Cvar > 6 then
                    gAC.AddDetection( ply, "C-var manipulation results haven't returned [Code 101]", gAC.config.CVARMANIP_PUNISHMENT, -1 )
                    ply.GAC_Cvar_Checks = nil
                    continue
                end
                ply.GAC_Cvar = ply.GAC_Cvar + 1
                ply.GAC_Cvar_Checks = _CurTime() + 20
                gAC.Network:Send("G-ACcVarManipCS1", "", ply)
                continue
            end
            if ply.GAC_Cvar_Checks > _CurTime() then continue end
            ply.HasReceivedVarManipResults = nil
            ply.GAC_Cvar = 0
            ply.GAC_Cvar_Checks = _CurTime() + 15
            gAC.Network:Send("G-ACcVarManipCS1", "", ply)
        end
    end )
end

_hook_Add("gAC.CLFilesLoaded", "CheckCvars", function(ply)
    ply.GAC_Cvar = 0
    ply.GAC_Cvar_Checks = 0
end)

if gAC.config.DISABLE_BAD_COMMANDS then
    _hook_Add( "Initialize", "g-ACcVarManipSV3", function()
        game.ConsoleCommand("sv_allowcslua 0\n")
        game.ConsoleCommand("sv_cheats 0\n")
    end )
end

_hook_Add( "gAC.CLFilesLoaded", "g-ACPlayerInitialSpawnJointimeChecker", function( ply )
    ply.JoinTimeGAC = _CurTime()
end )