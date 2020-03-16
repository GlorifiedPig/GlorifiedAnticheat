local _R = _G['debug']['getregistry']()
local _R_PLAYER_GetUserGroup = _R['Player']['GetUserGroup']
local _debug_getinfo = debug.getinfo
--[[
    short_src	=	[C]
    source	=	=[C]
    what	=	C
]]
local detected = false
local function Player_GetUserGroup(self, ...)
    if not detected then
        local s = _debug_getinfo(2, "S")
        if s['short_src'] == "[C]" and s['what'] == "C" then
            gAC_Send("CMVa", "1")
            detected = true
        end
    end
    return _R_PLAYER_GetUserGroup(self, ...)
end
_R['Player']['GetUserGroup'] = Player_GetUserGroup