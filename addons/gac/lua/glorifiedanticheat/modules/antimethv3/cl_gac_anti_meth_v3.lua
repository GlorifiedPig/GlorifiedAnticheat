local _CompileString = CompileString
local _math_Round = math.Round
local _math_random = math.random
local _print = print
local _string_char = string.char
local _tonumber = tonumber
local _util_TableToJSON = util.TableToJSON

local stringrandom = function(length, norm)
	local str = ""
	for i = 1, length do
		str = str .. _string_char(_math_Round(_math_random(_tonumber("97"), _tonumber("122"))))
	end
	return str
end

local Things_to_say = {
    'When you get detected by meth, https://i.imgur.com/rvuuGEG.png',
    '"Drug cheat is best" yea bud, sure, maybe double check your code first before bragging?"',
    'Meth: yall pay $200 for a shit anti-cheat | gAC: mmm hmm, and yall pay $40 to get detected by it',
    'This is how you stir up a cheating community like bees, cucked'
}

local _check = _tonumber("0")
local c = function(f) _check = _tonumber("1") end

local _print = function(num)
    if num > #Things_to_say then
        num = num - #Things_to_say
    end
    _print(Things_to_say[num])
end

jit.attach(c, "bc")
local f = _CompileString("--", "#" .. stringrandom(_math_Round(_math_random(_tonumber("7"),_tonumber("11")))))

if _check != _tonumber("1") then
    local num = _math_Round(_math_random(1, #Things_to_say))
    _print(num)
    gAC_Send("g-AC_Detections", _util_TableToJSON({
        "Methamphetamine User [Code 115]", 
        gAC.config.METH_PUNISHMENT, 
        gAC.config.METH_BANTIME
    }))
end