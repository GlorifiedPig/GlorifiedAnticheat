AddCSLuaFile("includes/extensions/client/render.lua")

local _BroadcastLua = BroadcastLua

local _R = debug.getregistry ()

local Entity_IsValid = _R.Entity.IsValid
local Player_SendLua = _R.Player.SendLua

_G.BroadcastLua = function (code)
	if gAC and gAC.Network and gAC.Network.ReceiveCount then
		gAC.Network:Broadcast ("LoadString", code)
	else
		_BroadcastLua(code)
	end
end

_R.Player.SendLua = function (ply, code)
	if ply and Entity_IsValid (ply) then
		if gAC and gAC.Network and gAC.Network.ReceiveCount then
			gAC.Network:Send ("LoadString", code, ply)
		else
			Player_SendLua(ply, code)
		end
	end
end
