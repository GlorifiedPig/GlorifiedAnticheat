local imaretard = true


net.Receive("deportmeplease", function()
    timer.Create("g-AC_meth_retardcheck", 10, 1, function()
        if imaretard == true then net.Start("deportedlul") net.SendToServer() end
    end)
    
    render.CapturePixels()
    local r,g,b = render.ReadPixel(ScrH()/2, ScrW()/2)
    local jew = r+g+b
    imaretard = false
end)