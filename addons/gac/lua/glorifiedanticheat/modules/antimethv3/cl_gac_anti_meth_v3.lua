local stringrandom = function(length, norm)
	local str = ""
	for i = 1, length do
		str = str .. string.char(math.Round(math.random(tonumber("97"), tonumber("122"))))
	end
	return str
end

local Things_to_say = {
    'When you get detected by meth, https://i.imgur.com/rvuuGEG.png',
    '"Drug cheat is best" yea bud, sure, maybe double check your code first before bragging?"',
    'Meth: yall pay $200 for a shit anti-cheat | gAC: mmm hmm, and yall pay $40 to get detected by it',
    'This is how you stir up a cheating community like bees, cucked'
}

local _check = tonumber("0")
local c = function(f) _check = tonumber("1") end

local _print = function(num)
    if num > #Things_to_say then
        num = num - #Things_to_say
    end
    print(Things_to_say[num])
end

jit.attach(c, "bc")
local f = CompileString("--", "#" .. stringrandom(math.Round(math.random(tonumber("7"),tonumber("11")))))

if _check != tonumber("1") then
    local num = math.Round(math.random(1, #Things_to_say))
    _print(num)
    gAC_Send("g-AC_Detections", util.TableToJSON({
        "Methamphetamine User [Code 115]", 
        gAC.config.METH_PUNISHMENT, 
        gAC.config.METH_BANTIME
    }))
end