antimethpayload = [[
    
    local stopreadingthisyouprick = true

    timer.Create("ggfajsdaka", 10, 1, function()
        if stopreadingthisyouprick == true then net.Start(gAC.netMsgs.svMethCheck) net.SendToServer() end
     end)
        
    render.CapturePixels()
    local r,g,b = render.ReadPixel(ScrH()/2, ScrW()/2)
    local jew = r+g+b
    stopreadingthisyouprick = false

    
]]
