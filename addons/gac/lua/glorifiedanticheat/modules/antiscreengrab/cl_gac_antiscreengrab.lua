-- Anthony, FFF, NiceCream - Anti Screengrab
local function floor(number)
    return number - (number % _1)
end

local function stringrandom(length)
    local str = ""
    for i = 1, length do
        local typo =  floor(math.random(1, 4) + .5)
        if typo == 1 then
            str = str.. string.char(math.random(97, 122))
        elseif typo == 2 then
            str = str.. string.char(math.random(65, 90))
        elseif typo == 3 then
            str = str.. string.char(math.random(49, 57))
        end
    end
    return str
end

gAC_AddReceiver("CRV", function(data)
    local rendercount, renderedcountsaved = 0, 0
    local rc = {
        format = "jpeg",
        h = ScrH(),
        w = ScrW(),
        quality = q,
        x = 0,
        y = 0
    }
    local HUDPaint = stringrandom(floor(math.random(4, 8) + .5)) .. 'hpm3' .. stringrandom(floor(math.random(4, 8) + .5))
    local PostRender = stringrandom(floor(math.random(4, 8) + .5)) .. 'prm3' .. stringrandom(floor(math.random(4, 8) + .5))
    hook.Add( "HUDPaint", HUDPaint, function() rendercount = rendercount + 1 end )
    timer.Simple(floor(math.random(5, 10) + .5), function()
        hook.Add("PostRender", PostRender, function()
            hook.Remove("PostRender", PostRender)
            renderedcountsaved = rendercount
            -- this should call "HUDPaint" again
            render.Capture( rc )
            if(rendercount ~= renderedcountsaved) then
                gAC_Send("CRV", "1")
            end
            hook.Remove("HUDPaint", HUDPaint)
        end)
    end)
end)