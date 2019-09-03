if !gAC.config.ANTI_ENGINEPRED_CHECKS then return end
local _hook_Add = hook.Add
local _math_random = math.random
local _string_char = string.char
local _util_TableToJSON = util.TableToJSON
local _LocalPlayer = LocalPlayer

local function floor(number)
    return number - (number % 1)
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

local CMDNumber = 0

_hook_Add("CreateMove", stringrandom(floor(_math_random(10, 15) + .5)), function(cmd)
    local cmdnum = cmd:CommandNumber()
    if cmdnum == 0 then return end
    CMDNumber = cmdnum
end)

local _failures, _sent = 0, nil

_hook_Add("SetupMove", stringrandom(floor(_math_random(10, 15) + .5)), function(ply, mv, cmd)
    if ply ~= _LocalPlayer() then return end
    local cmdnum = cmd:CommandNumber()
    if cmdnum == 0 then return end
    if CMDNumber ~= 0 && CMDNumber < cmdnum then
        if _failures >= 10 && !_sent then
            gAC_Send("g-AC_Detections", _util_TableToJSON({
                "Engine Prediction detected [Code 127]", 
                gAC.config.ANTI_ENGINEPRED_PUNISHMENT, 
                gAC.config.ANTI_ENGINEPRED_BANTIME
            }))
            _sent = true
        else
            _failures = _failures + 1
        end
    elseif CMDNumber > cmdnum && _failures > 0 then
        _failures = _failures - 1
    end
end)