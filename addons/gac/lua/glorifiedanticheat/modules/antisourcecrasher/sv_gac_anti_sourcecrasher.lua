local _hook_Add = hook.Add
local _next = next
local _player_GetBySteamID = player.GetBySteamID
local _require = require

-- CREDITS TO Octothorp TEAM FOR SLOG AND DETAILS.

if(!gAC.config.ENABLE_SOURCECRASHER_CHECKS) then return end
if(!system.IsLinux()) then return end

_require 'slog'
_require 'sourcenet'

local tag = 'stringcmd_exploit'

local maxL, maxN = 10000, 100
local tL, tN = {}, {}

local function punish(s)

	local pl = _player_GetBySteamID(s)
	if pl.kicked then return end
	
	pl.kicked = true
	gAC.AddDetection(pl, "Source Crasher [Code 113]", gAC.config.SOURCECRASHER_PUNISHMENT, gAC.config.SOURCECRASHER_PUNSIHMENT_BANTIME)
	if CNetChan and CNetChan(pl:EntIndex()) then
		CNetChan(pl:EntIndex()):Shutdown('Source Crasher [Code 113]')
	end

end

_hook_Add('ExecuteStringCommand', tag, function(s, c)

	local cL, cN = tL[s], tN[s]
	if not cL then cL = 0 end
	if not cN then cN = 0 end

	if cL > maxL or cN > maxN then
		punish(s)
		return true
	end

	tN[s] = cN + 1
	tL[s] = cL + #c

end)

_hook_Add('Tick', tag, function()

	for k, cL in _next, tL do
		tL[k] = nil
	end

	for k, cN in _next, tN do
		tN[k] = nil
	end

end)
