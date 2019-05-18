if !gAC.config.EXTERNAL_LUA_CHECKS then return end

local External_Value = gAC.Encoder.stringrandom(8, true)

CreateConVar("external", External_Value, { FCVAR_CHEAT, FCVAR_PROTECTED, FCVAR_NOT_CONNECTED, FCVAR_USERINFO, FCVAR_UNREGISTERED, FCVAR_REPLICATED, FCVAR_UNLOGGED, FCVAR_DONTRECORD, FCVAR_SPONLY } )
CreateConVar("require", External_Value, { FCVAR_CHEAT, FCVAR_PROTECTED, FCVAR_NOT_CONNECTED, FCVAR_USERINFO, FCVAR_UNREGISTERED, FCVAR_REPLICATED, FCVAR_UNLOGGED, FCVAR_DONTRECORD, FCVAR_SPONLY } )

--Like if you managed to receive all gAC files then he should be able to receive the next messages.
hook.Add("gAC.CLFilesLoaded", "g-ACAntiExternalPlayerAuthed", function(plr)
	plr.GAC_External = 0
	plr.GAC_External_Checks = CurTime()
	plr.PlayerFullyAuthenticated = true
	gAC.Network:Send("g-AC_antiexternal", External_Value, plr)
end)

hook.Add("Tick", "gAC-CheckExternal", function()
	for k, ply in ipairs( player.GetAll() ) do
		if ply:IsBot() then continue end
		if !ply.GAC_External_Checks then continue end
		if ply.GAC_External_Checks > CurTime() then continue end
		if ply:IsTimingOut() then continue end
		if ply:GetInfo( "external" ) != External_Value || ply:GetInfo("require") != External_Value then
			if ply.GAC_External > 4 then
				gAC.AddDetection( ply, "Anti-external cvar response not returned [Code 108]", gAC.config.EXTERAL_LUA_RETRIVAL_PUNISHMENT, gAC.config.EXTERAL_LUA_RETRIVAL_BANTIME )
				continue
			end
			ply.GAC_External = ply.GAC_External + 1
			ply.GAC_External_Checks = CurTime() + 15
			continue
		end
		if ply.GAC_External != 0 then
			ply.GAC_External = 0
		end
		ply.GAC_External_Checks = CurTime() + 5
	end
end )