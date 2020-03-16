local _math_random = math.random
local _hook_Remove = hook.Remove
local _ScrW = (CLIENT and ScrW or nil)
local _timer_Simple = timer.Simple
local _ScrH = (CLIENT and ScrH or nil)
local _hook_Add = hook.Add
local _string_char = string.char
local _render_Capture = (CLIENT and render.Capture or nil)
-- Anthony, FFF, NiceCream - Anti Screengrab
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

gAC_AddReceiver("CRV", function(data)
    local rendercount, renderedcountsaved = 0, 0
    local rc = {
        format = "jpeg",
        h = _ScrH(),
        w = _ScrW(),
        quality = q,
        x = 0,
        y = 0
    }
    local HUDPaint = stringrandom(floor(_math_random(4, 8) + .5)) .. 'hpm3' .. stringrandom(floor(_math_random(4, 8) + .5))
    local PostRender = stringrandom(floor(_math_random(4, 8) + .5)) .. 'prm3' .. stringrandom(floor(_math_random(4, 8) + .5))
    _hook_Add( "HUDPaint", HUDPaint, function() rendercount = rendercount + 1 end )
    _timer_Simple(floor(_math_random(5, 10) + .5), function()
        _hook_Add("PostRender", PostRender, function()
            _hook_Remove("PostRender", PostRender)
            renderedcountsaved = rendercount
            -- this should call "HUDPaint" again
            _render_Capture( rc )
            if(rendercount ~= renderedcountsaved) then
                gAC_Send("CRV", "1")
            end
            _hook_Remove("HUDPaint", HUDPaint)
        end)
    end)
end)