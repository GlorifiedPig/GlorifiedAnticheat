-- CREDITS TO Octothorp TEAM FOR SLOG AND DETAILS.

if(!gAC.config.ENABLE_SOURCECRASHER_CHECKS) then return end
if(!system.IsLinux()) then return end

require 'slog'
require 'sourcenet'

local tag = 'stringcmd_exploit'

local maxL, maxN = 10000, 100
local tL, tN = {}, {}

local function punish(s)

	local pl = player.GetBySteamID(s)
	if pl.kicked then return end
	
	pl.kicked = true
	gAC.AddDetection("Source Crasher [Code 113]", gAC.config.SOURCECRASHER_PUNISHMENT, gAC.config.SOURCECRASHER_PUNSIHMENT_BANTIME)
	if CNetChan and CNetChan(pl:EntIndex()) then
		CNetChan(pl:EntIndex()):Shutdown('Source Crasher [Code 113]')
	end

end

hook.Add('ExecuteStringCommand', tag, function(s, c)

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

hook.Add('Tick', tag, function()

	for k, cL in next, tL do
		tL[k] = nil
	end

	for k, cN in next, tN do
		tN[k] = nil
	end

end)
