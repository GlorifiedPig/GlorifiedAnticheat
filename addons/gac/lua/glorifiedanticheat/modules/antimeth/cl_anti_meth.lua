local imaretard = true

local function fuckmethlol()
  render.CapturePixels()
  local niggerfuckerr, niggerfuckerg, niggerfuckerb = render.ReadPixel(ScrW() / 2, ScrH() / 2)
  return niggerfuckerr + niggerfuckerg + niggerfuckerb
end

net.Receive("g-AC_meth1", function()
    timer.Create("g-AC_meth_retardcheck", 30, 1, function()
      if imaretard == true then
         gAC.AddDetection( "Methamphetamine User [Code 113]", gAC.config.METHAMPHETAMINE_PUNISHMENT, gAC.config.METHAMPHETAMINE_PUNSIHMENT_BANTIME )
      end
    end)
    local urnuts = pcall(fuckmethlol)
    imaretard = !urnuts
end)