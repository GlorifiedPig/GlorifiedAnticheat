local _CreateConVar = CreateConVar
local _CurTime = CurTime
local _hook_Add = hook.Add
local _player_GetAll = player.GetAll

if !gAC.config.EXTERNAL_LUA_CHECKS then return end

local External_Value = gAC.Encoder.stringrandom(8, true)

_CreateConVar("external", External_Value, { FCVAR_CHEAT, FCVAR_PROTECTED, FCVAR_NOT_CONNECTED, FCVAR_USERINFO, FCVAR_UNREGISTERED, FCVAR_REPLICATED, FCVAR_UNLOGGED, FCVAR_DONTRECORD, FCVAR_SPONLY } )
_CreateConVar("require", External_Value, { FCVAR_CHEAT, FCVAR_PROTECTED, FCVAR_NOT_CONNECTED, FCVAR_USERINFO, FCVAR_UNREGISTERED, FCVAR_REPLICATED, FCVAR_UNLOGGED, FCVAR_DONTRECORD, FCVAR_SPONLY } )

--Like if you managed to receive all gAC files then he should be able to receive the next messages.
_hook_Add("gAC.CLFilesLoaded", "g-ACAntiExternalPlayerAuthed", function(plr)
	plr.GAC_External = 0
	plr.GAC_External_Checks = _CurTime() + 5
	plr.PlayerFullyAuthenticated = true
	gAC.Network:Send("g-AC_antiexternal", External_Value, plr)
end)

gAC.Network:AddReceiver("g-AC_External2",function(tabledata, ply)
	if ply.GAC_EXTERNALG then return end
	ply.GAC_EXTERNALG = true
	gAC.AddDetection( ply, "Global 'external' function detected [Code 107]", gAC.config.EXTERNAL_LUA_PUNISHMENT, gAC.config.EXTERNAL_LUA_BANTIME )
end)

_hook_Add("Tick", "gAC-CheckExternal", function()
	local _IPAIRS_ = _player_GetAll()
	for k=1, #_IPAIRS_   do
		local ply =_IPAIRS_[k]
		if ply:IsBot() then continue end
		if !ply.GAC_External_Checks then continue end
		if ply.GAC_External_Checks > _CurTime() then continue end
		if ply:IsTimingOut() then continue end
		if ply:GetInfo( "external" ) != External_Value || ply:GetInfo("require") != External_Value then
			if ply.GAC_External > 4 then
				gAC.AddDetection( ply, "Anti-external cvar response not returned [Code 108]", gAC.config.EXTERAL_LUA_RETRIVAL_PUNISHMENT, gAC.config.EXTERAL_LUA_RETRIVAL_BANTIME )
				ply.GAC_External_Checks = nil
				continue
			end
			ply.GAC_External = ply.GAC_External + 1
			ply.GAC_External_Checks = _CurTime() + 15
			continue
		end
		if ply.GAC_External != 0 then
			ply.GAC_External = 0
		end
		ply.GAC_External_Checks = _CurTime() + 5
	end
end )