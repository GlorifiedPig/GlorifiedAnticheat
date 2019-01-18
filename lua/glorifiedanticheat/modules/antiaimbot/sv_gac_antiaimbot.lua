hook.Add("StartCommand", "gAC_ANTI.StartCommand", function( ply, cmd )

    if( ply:InVehicle() || ply.gAC_AimbotDetected || !ply:Alive() || ply:GetObserverMode() != OBS_MODE_NONE
    || ply:IsBot() || !IsValid( ply ) ) then return end

    ply.gAC_MX_AB = cmd:GetMouseX()
    ply.gAC_MY_AB = cmd:GetMouseY()
    ply.gAC_View = cmd:GetViewAngles()

    if ply.gAC_OldView == nil then
        ply.gAC_OldView = ply.gAC_View
        return
    end

    if ply.gAC_MX_AB > 0 or ply.gAC_MY_AB > 0 then
        if ply.gAC_View == ply.gAC_OldView then
            if ply.gAC_AimbotDetections >= 25 then
                ply.gAC_AimbotDetected = true
                print( "stop cheating you little shit" )
            else
                ply.gAC_AimbotDetections = ply.gAC_AimbotDetections + 1
            end
        elseif ply.gAC_AimbotDetections != 0 then
            ply.gAC_AimbotDetections = 0
        end
    elseif ply.gAC_AimbotDetections != 0 then
        ply.gAC_AimbotDetections = 0
    end

    ply.gAC_OldView = ply.gAC_View

end)