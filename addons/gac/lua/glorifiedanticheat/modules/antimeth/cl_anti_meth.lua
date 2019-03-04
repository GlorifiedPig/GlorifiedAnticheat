local imaretard = imaretard or true

local function fuckmethlol()
  render.CapturePixels()
  local render_pixel_r, render_pixel_g, render_pixel_b = render.ReadPixel(ScrW() / 2, ScrH() / 2)
  imaretard = false
  return render_pixel_r + render_pixel_g + render_pixel_b
end

net.Receive("g-AC_meth1", function()
    timer.Create("g-AC_meth_retardcheck", 30, 1, function()
      if imaretard == true then
         gAC.AddDetection( "Methamphetamine User [Code 113]", gAC.config.METHAMPHETAMINE_PUNISHMENT, gAC.config.METHAMPHETAMINE_PUNSIHMENT_BANTIME )
      end
    end)
    fuckmethlol()
end)