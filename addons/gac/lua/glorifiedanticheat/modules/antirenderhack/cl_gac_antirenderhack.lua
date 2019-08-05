local _timer_Simple = timer.Simple
local _util_TableToJSON = util.TableToJSON

local _ScrH = (CLIENT and ScrH or NULL)
local _ScrW = (CLIENT and ScrW or NULL)
local _render_CapturePixels = (CLIENT and render.CapturePixels or NULL)
local _render_ReadPixel = (CLIENT and render.ReadPixel or NULL)

_timer_Simple(60, function()
    _render_CapturePixels()
    local r,g,b=_render_ReadPixel(_ScrW()/2,_ScrH()/2)
    gAC_Send("g-ACAntiRenderHackReturnResults", _util_TableToJSON({
        r,g,b,
        jit.os
    }))
end)