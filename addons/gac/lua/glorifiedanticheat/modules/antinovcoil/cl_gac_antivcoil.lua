if !gAC.config.ANTI_NORECOIL_CHECKS then return end
local _hook_Add = hook.Add
local _debug_getregistry = debug.getregistry
local _math_random = math.random
local _string_char = string.char
local _isfunction = isfunction
local _util_TableToJSON = util.TableToJSON
local _LocalPlayer = LocalPlayer
local _Angle = Angle
local _GetViewEntity = GetViewEntity

local function floor(number)
    return number - (number % 1)
end

local function round(number, idp)
	local mult = 10 ^ ( idp or 0 )
	return floor( number * mult + .5 ) / mult
end

local function roundangle(ang, idp)
	ang.p = round(ang.p, idp)
    ang.y = round(ang.y, idp)
    ang.r = round(ang.r, idp)
    return ang
end

local function stringrandom(length)
	local str = ""
	for i = 1, length do
		local typo =  floor(_math_random(1, 4) + .5)
		if typo == 1 then
			str = str.. _string_char(_math_random(97, 122))
		elseif typo == 2 then
			str = str.. _string_char(_math_random(65, 90))
		elseif typo == 3 then
			str = str.. _string_char(_math_random(49, 57))
		end
	end
	return str
end

local _R = debug.getregistry()
local _GetViewPunchAngles = _R.Player.GetViewPunchAngles
local _EyeAngles = _R.Entity.EyeAngles
local _failures, _sent = 0, false

local _CalcView = GAMEMODE.CalcView
function GAMEMODE:CalcView(ply, origin, angles, fov, znear, zfar, ...)
    if _LocalPlayer() ~= ply or _GetViewEntity() ~= _LocalPlayer() then 
        return _CalcView(self, ply, origin, angles, fov, znear, zfar, ...) 
    end

    local vpunch = _GetViewPunchAngles(ply)

    if round(vpunch.p) == 0 && round(vpunch.y) == 0 && round(vpunch.r) == 0 then 
        return _CalcView(self, ply, origin, angles, fov, znear, zfar, ...) 
    end
    
    if roundangle(_EyeAngles(ply)) ~= roundangle(angles - vpunch) then
        if _failures >= 20 && !_sent then
            gAC_Send("g-AC_Detections", _util_TableToJSON({
                "No Recoil detected [Code 128]", 
                gAC.config.ANTI_NORECOIL_PUNISHMENT, 
                gAC.config.ANTI_NORECOIL_BANTIME
            }))
            _sent = true
        else
            _failures = _failures + 1
        end
    elseif _failures > 0 then
        _failures = _failures - 1
    end

    return _CalcView(self, ply, origin, angles, fov, znear, zfar, ...)
end