if !gAC.config.NEKO_LUA_CHECKS then return end

local Neko_Value = gAC.Encoder.stringrandom(5, true)

CreateConVar("neko_exit", Neko_Value, { FCVAR_CHEAT, FCVAR_PROTECTED, FCVAR_NOT_CONNECTED, FCVAR_USERINFO, FCVAR_UNREGISTERED, FCVAR_REPLICATED, FCVAR_UNLOGGED, FCVAR_DONTRECORD, FCVAR_SPONLY } )
CreateConVar("neko_list", Neko_Value, { FCVAR_CHEAT, FCVAR_PROTECTED, FCVAR_NOT_CONNECTED, FCVAR_USERINFO, FCVAR_UNREGISTERED, FCVAR_REPLICATED, FCVAR_UNLOGGED, FCVAR_DONTRECORD, FCVAR_SPONLY } )

--Like if you managed to receive all gAC files then he should be able to receive the next messages.
hook.Add("gAC.CLFilesLoaded", "g-ACAntiNekoPlayerAuthed", function(plr)
	plr.GAC_Neko = 0
	plr.GAC_Neko_Checks = CurTime() + 5
	gAC.Network:Send("g-AC_antineko", Neko_Value, plr)
end)

hook.Add("Tick", "gAC-CheckNeko", function()
	for k, ply in ipairs( player.GetAll() ) do
		if ply:IsBot() then continue end
		if !ply.GAC_Neko_Checks then continue end
		if ply.GAC_Neko_Checks > CurTime() then continue end
		if ply:IsTimingOut() then continue end
		if ply:GetInfo( "neko_exit" ) != Neko_Value || ply:GetInfo("neko_list") != Neko_Value then
			if ply.GAC_Neko > 4 then
				gAC.AddDetection( ply, "Anti-neko cvar response not returned [Code 113]", gAC.config.NEKO_LUA_RETRIVAL_PUNISHMENT, gAC.config.NEKO_LUA_RETRIVAL_BANTIME )
				ply.GAC_Neko_Checks = nil
				continue
			end
			ply.GAC_Neko = ply.GAC_Neko + 1
			ply.GAC_Neko_Checks = CurTime() + 15
			continue
		end
		if ply.GAC_Neko != 0 then
			ply.GAC_Neko = 0
		end
		ply.GAC_Neko_Checks = CurTime() + 5
	end
end )