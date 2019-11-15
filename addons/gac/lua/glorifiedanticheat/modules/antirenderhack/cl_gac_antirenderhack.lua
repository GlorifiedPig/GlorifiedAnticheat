local _timer_Simple = timer.Simple
local _util_TableToJSON = util.TableToJSON

local _ScrH = (CLIENT and ScrH or NULL)
local _ScrW = (CLIENT and ScrW or NULL)
local _render_CapturePixels = (CLIENT and render.CapturePixels or NULL)
local _render_Capture = (CLIENT and render.Capture or NULL)
local _render_ReadPixel = (CLIENT and render.ReadPixel or NULL)
local _vgui_Create = (CLIENT and vgui.Create or NULL)

_timer_Simple(45, function()
    _render_CapturePixels()
    local r,g,b=_render_ReadPixel(_ScrW()/2,_ScrH()/2)

    gAC_Send("g-ACAntiRenderHackReturnResults", _util_TableToJSON({
        r,g,b,
        jit.os
    }))
end)

_timer_Simple(75, function()
    local pnl = _vgui_Create('DPanel')
    pnl:SetSize(1, 1)
    pnl:SetVisible(true)
    local IsPainting = false
    function pnl:Paint()
    	IsPainting = true
    end

    _render_Capture({
		format = "jpeg",
		quality = 1,
		h = 1,
		w = 1,
		x = 0,
		y = 0,
	})

    _timer_Simple(0, function()
        if IsPainting == false then
            gAC_Send("g-ACAntiRenderHackReturnResults2", '1')
        end
        pnl:Remove()
    end)
end)