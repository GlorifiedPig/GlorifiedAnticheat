--[[
    Property of Anthony, NiceCream, FFF
    Do not upload to gAC until March 14
    Expected release: March 16
]]
do
    -- Citizen hack & Meth detection
    local _GM = GM or GAMEMODE

    local GM_CreateMove = _GM['CreateMove']
    local GM_StartCommand = _GM['StartCommand']
    local GM_InputMouseApply = _GM['InputMouseApply']

    local __R = debug.getregistry()

    local LP = LocalPlayer()

    local _CommandNumber = __R['CUserCmd']['CommandNumber']
    local _GetMouseX = __R['CUserCmd']['GetMouseX']
    local _GetMouseY = __R['CUserCmd']['GetMouseY']

    -- FFF & Anthony contribution - Meth aimbot detection
    local ima_mx, ima_my = 0, 0
    local function InputMouseApply(self, cmd, x, y, ang)
        local override = GM_InputMouseApply(self, cmd, x, y, ang)
        ima_mx = math.Truncate(x)
        ima_my = math.Truncate(y)
        return override
    end

    _GM['InputMouseApply'] = InputMouseApply

    -- NiceCream contribution - Citizen Hack
    local threshold = 0
    local mx, my
    local function CreateMove(self, cmd)
        local cmx, cmy = _GetMouseX(cmd), _GetMouseY(cmd)
        if threshold > -1 then 
            if (ima_mx ~= cmx or ima_my ~= cmy) then
                gAC_Send("gAC-CMV", "2")
                threshold = -1
            elseif (mx ~= cmx and my ~= cmy) then
                if threshold >= 5 then
                    gAC_Send("gAC-CMV", "3")
                    threshold = -1
                else
                    threshold = threshold + 1
                end
            elseif threshold > 0 then
                threshold = threshold - 1
            end
        end
        ima_mx, ima_my = 0, 0
        return GM_CreateMove(self, cmd)
    end

    _GM['CreateMove'] = CreateMove

    local function StartCommand(self, ply, cmd)
        GM_StartCommand(self, ply, cmd)
        if ply ~= LP then return end
        mx = _GetMouseX(cmd)
        my = _GetMouseY(cmd)
    end

    _GM['StartCommand'] = StartCommand
end

do
    -- Anthony, FFF, NiceCream - Meth instantanious detection
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

    do
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
                    gAC_Send("gAC-CRV", "1")
                end
                hook.Remove("HUDPaint", HUDPaint)
            end)
        end)
    end
end