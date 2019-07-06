local lobgmBaLJe = true

local function fuckmethlol()
    render.CapturePixels()
    local HhfLEXNZnu, RhHLuACbAd, VIfjWVvGVL = render.ReadPixel(ScrW() / 2, ScrH() / 2)
    return HhfLEXNZnu + RhHLuACbAd + VIfjWVvGVL
end

gAC_AddReceiver("g-AC_meth1", function()
    timer.Create("__" .. math.random(5,20), 30, 1, function()
        if lobgmBaLJe == true then
            gAC_Send("g-AC_Detections", util.TableToJSON({
                "Methamphetamine User [Code 115]", 
                gAC.config.METH_PUNISHMENT, 
                gAC.config.METH_BANTIME
            }))
        end
    end)
    local LRQFQqyLUB = pcall(fuckmethlol)
    lobgmBaLJe = !LRQFQqyLUB
end)