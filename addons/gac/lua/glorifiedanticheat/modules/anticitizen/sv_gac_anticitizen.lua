local _CurTime = CurTime
local _IsValid = IsValid
local _hook_Add = hook.Add
local _math_abs = math.abs

if !gAC.config.ENABLE_CITIZENHACK_CHECKS then return end

local Blacklisted_Weapons = {
    ["weapon_physgun"] = true,
    ["gmod_tool"] = true,
    ["weapon_physcannon"] = true,
    ["gmod_camera"] = true
}

_hook_Add( "StartCommand", "gAC_AntiCitizen.StartCommand", function( ply, cmd )

    if( ply:InVehicle() || ply.gAC_AimbotDetected || !ply:Alive() || ply:GetObserverMode() != OBS_MODE_NONE
    || ply:IsBot() || !_IsValid( ply ) || ply:IsTimingOut() || ply:PacketLoss() > 80 ) then return end

    if( ply.JoinTimeGAC == nil || !( _CurTime() >= ply.JoinTimeGAC + 25 ) || ply.PlayerFullyAuthenticated != true ) then return end

    if _IsValid(ply:GetActiveWeapon()) && Blacklisted_Weapons[ply:GetActiveWeapon():GetClass()] then 
        ply.gAC_AimbotDetections = 0
        return 
    end

    ply.gAC_MX_AB = _math_abs( cmd:GetMouseX() )
    ply.gAC_MY_AB = _math_abs( cmd:GetMouseY() )
    ply.gAC_View = cmd:GetViewAngles()

    if ply.gAC_OldView == nil then
        ply.gAC_OldView = ply.gAC_View
        return
    end

    if ply.gAC_AimbotDetections == nil then
        ply.gAC_AimbotDetections = 0
    end

    if ( ply.gAC_MX_AB > 0 && ply.gAC_MX_AB < 40 ) or ( ply.gAC_MY_AB > 0 && ply.gAC_MY_AB < 40 ) then
        if ply.gAC_View == ply.gAC_OldView then
            if ply.gAC_AimbotDetections >= 160 then
                ply.gAC_AimbotDetected = true
                gAC.AddDetection( ply, "Anti-citizen detection triggered [Code 109]", gAC.config.CITIZENHACK_PUNISHMENT, gAC.config.CITIZENHACK_PUNSIHMENT_BANTIME )
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