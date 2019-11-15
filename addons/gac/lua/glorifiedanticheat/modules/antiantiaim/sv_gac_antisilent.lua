if !gAC.config.ANTI_SILENT then return end
local _CurTime = CurTime
local _IsValid = IsValid
local _hook_Add = hook.Add
local _math_abs = math.abs
local _math_sqrt = math.sqrt

local Blacklisted_Weapons = {
    ["weapon_physgun"] = true,
    ["gmod_tool"] = true,
    ["weapon_physcannon"] = true,
    ["gmod_camera"] = true
}

local function floor(number)
    return number - (number % 1)
end

local function round(number, idp)
	local mult = 10 ^ ( idp or 0 )
	return floor( number * mult + .5 ) / mult
end

local function roundangle(ang, idp)
	ang.p = round(ang.p, idp)
    ang.y = round(ang.y, idp)
    ang.r = round(ang.r, idp)
    return ang
end

_hook_Add( "StartCommand", "gAC.AimSilent", function( ply, cmd )
    if( ply:InVehicle() || ply.gAC_AimbotDetected || !ply:Alive() || ply:GetObserverMode() != OBS_MODE_NONE
    || ply:IsBot() || !_IsValid( ply ) || ply:IsTimingOut() || ply:PacketLoss() > 80 ) then return end

    if( ply.JoinTimeGAC == nil || !( _CurTime() >= ply.JoinTimeGAC + 25 ) || ply.PlayerFullyAuthenticated != true ) then return end

    if _IsValid(ply:GetActiveWeapon()) && Blacklisted_Weapons[ply:GetActiveWeapon():GetClass()] then
        return 
    end

    local gAC_MX_AB = _math_abs( cmd:GetMouseX() )
    local gAC_MY_AB = _math_abs( cmd:GetMouseY() )
    local gAC_FM = _math_abs( cmd:GetForwardMove() )
    local gAC_SM = _math_abs( cmd:GetSideMove() )

    if !ply.Aim_Silent_Threshold then
        ply.Aim_Silent_Threshold = 0
        return
    end

    if gAC_MX_AB > 0 and gAC_MY_AB > 0 and gAC_FM > 0 and gAC_SM > 0 and round(_math_sqrt((gAC_FM^2) + (gAC_SM^2))) == 10000 then
        if ply.Aim_Silent_Threshold > 5 then
            ply.gAC_AimbotDetected = true
            gAC.AddDetection( ply, "Silent-Aim Detected [Code 129]", gAC.config.SILENT_PUNISHMENT, gAC.config.SILENT_BANTIME )
            return
        else
            ply.Aim_Silent_Threshold = ply.Aim_Silent_Threshold + 1
        end
    elseif ply.Aim_Silent_Threshold > 0 then
        ply.Aim_Silent_Threshold = ply.Aim_Silent_Threshold - 1
    end
end )