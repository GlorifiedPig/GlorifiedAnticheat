local function fuckmethlol()
  render.CapturePixels()
  local render_pixel_r, render_pixel_g, render_pixel_b = render.ReadPixel(ScrW() / 2, ScrH() / 2)
  return render_pixel_r + render_pixel_g + render_pixel_b
end

net.Receive("g-AC_meth1", function()
    fuckmethlol()

    net.Start("g-AC_meth2")
    net.SendToServer()
end)