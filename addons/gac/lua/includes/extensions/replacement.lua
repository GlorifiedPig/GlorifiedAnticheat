AddCSLuaFile("includes/init.lua")
AddCSLuaFile("includes/extensions/client/lang.lua")

local _BroadcastLua = BroadcastLua
local Player_Meta = FindMetaTable( "Player" )
local Player_Meta_SendLua = Player_Meta.SendLua

_G.BroadcastLua = function (code)
	if gAC and gAC.Network then
		gAC.Network:Broadcast("LoadString", code)
	else
		return _BroadcastLua(code)
	end
end

function Player_Meta:SendLua(code)
	if gAC and gAC.Network then
		gAC.Network:Send("LoadString", code, self)
	else
		return Player_Meta_SendLua(self, code)
	end
end