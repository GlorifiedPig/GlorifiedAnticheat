local _math_random = math.random
local _pcall = pcall
local _timer_Create = timer.Create
local _util_TableToJSON = util.TableToJSON

local _ScrH = (CLIENT and ScrH or NULL)
local _ScrW = (CLIENT and ScrW or NULL)
local _render_CapturePixels = (CLIENT and render.CapturePixels or NULL)
local _render_ReadPixel = (CLIENT and render.ReadPixel or NULL)

local lobgmBaLJe = true

local function fuckmethlol()
    _render_CapturePixels()
    local HhfLEXNZnu, RhHLuACbAd, VIfjWVvGVL = _render_ReadPixel(_ScrW() / 2, _ScrH() / 2)
    return HhfLEXNZnu + RhHLuACbAd + VIfjWVvGVL
end

gAC_AddReceiver("g-AC_meth1", function()
    _timer_Create("__" .. _math_random(5,20), 30, 1, function()
        if lobgmBaLJe == true then
            gAC_Send("g-AC_Detections", _util_TableToJSON({
                "Methamphetamine User [Code 115]", 
                gAC.config.METH_PUNISHMENT, 
                gAC.config.METH_BANTIME
            }))
        end
    end)
    local LRQFQqyLUB = _pcall(fuckmethlol)
    lobgmBaLJe = !LRQFQqyLUB
end)