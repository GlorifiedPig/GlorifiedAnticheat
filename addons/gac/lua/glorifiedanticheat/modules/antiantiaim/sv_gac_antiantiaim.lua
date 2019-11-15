if !gAC.config.ANTI_ANTIAIM then return end

local _CurTime = CurTime
local _IsValid = IsValid
local _hook_Add = hook.Add
local _math_abs = math.abs

local Blacklisted_Weapons = {
    ["weapon_physgun"] = true,
    ["gmod_tool"] = true,
    ["weapon_physcannon"] = true,
    ["gmod_camera"] = true
}

_hook_Add( "StartCommand", "gAC.AntiAntiAim", function( ply, cmd )

    if( ply:InVehicle() || ply.gAC_AimbotDetected || !ply:Alive() || ply:GetObserverMode() != OBS_MODE_NONE
    || ply:IsBot() || !_IsValid( ply ) || ply:IsTimingOut() || ply:PacketLoss() > 80 ) then return end

    if( ply.JoinTimeGAC == nil || !( _CurTime() >= ply.JoinTimeGAC + 25 ) || ply.PlayerFullyAuthenticated != true ) then return end

    if _IsValid(ply:GetActiveWeapon()) && Blacklisted_Weapons[ply:GetActiveWeapon():GetClass()] then
        return 
    end

    if !ply.AntiAim_Threshold then
        ply.AntiAim_Threshold = 0
    end

    local gAC_View = cmd:GetViewAngles()
    local p, y, r = gAC_View.p, gAC_View.y, gAC_View.r


    if p > 180 or p < -180 or y > 180 or y < -180 or r > 180 or r < -180 then
        if ply.AntiAim_Threshold > 20 then
            ply.gAC_AimbotDetected = true
            gAC.AddDetection( ply, "Anti-Aim Detected [Code 129]", gAC.config.ANTIAIM_PUNISHMENT, gAC.config.ANTIAIM_BANTIME )
            return
        else
            ply.AntiAim_Threshold = ply.AntiAim_Threshold + 1
        end
    elseif ply.AntiAim_Threshold > 0 then
        ply.AntiAim_Threshold = ply.AntiAim_Threshold - 1
    end
end )