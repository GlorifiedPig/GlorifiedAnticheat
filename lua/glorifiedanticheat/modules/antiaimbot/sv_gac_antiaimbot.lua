if !gAC.config.AIMBOT_PUNISHMENT then return end

hook.Add( "StartCommand", "gAC_ANTI.StartCommand", function( ply, cmd )

    if( ply:InVehicle() || ply.gAC_AimbotDetected || !ply:Alive() || ply:GetObserverMode() != OBS_MODE_NONE
    || ply:IsBot() || !IsValid( ply ) || ply:IsTimingOut() || ply:PacketLoss() > 80 ) then return end

    if( ply.JoinTimeGAC == nil || !( CurTime() >= ply.JoinTimeGAC + 25 ) || ply.PlayerFullyAuthenticated != true ) then return end

    ply.gAC_MX_AB = math.abs( cmd:GetMouseX() )
    ply.gAC_MY_AB = math.abs( cmd:GetMouseY() )
    ply.gAC_View = cmd:GetViewAngles()

    if ply.gAC_OldView == nil then
        ply.gAC_OldView = ply.gAC_View
        return
    end

    if ply.gAC_AimbotDetections == nil then
        ply.gAC_AimbotDetections = 0
    end

    if ply.gAC_MX_AB > 0 or ply.gAC_MY_AB > 0 then
        if ply.gAC_View == ply.gAC_OldView then
            if ply.gAC_AimbotDetections >= 360 then
                ply.gAC_AimbotDetected = true
                gAC.AddDetection( ply, "Anti-aimbot detection triggered [Code 109]", gAC.config.AIMBOT_PUNISHMENT, gAC.config.AIMBOT_PUNSIHMENT_BANTIME )
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

end )