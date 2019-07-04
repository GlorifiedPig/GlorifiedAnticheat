
if !gAC.config.CITIZEN_ESP_BREAKER then return end

hook.Add( "HUDPaint", "g-ACCitizenESPBreaker", function()

    render.RenderView( {
        angles = Angle( 90, 0, 0 ),
        origin = Vector( 0, 0, 0 ),
        x = 0, y = 0,
        w = 1, h = 1,
        drawhud = false,
        drawviewmodel = false
    } )

end )