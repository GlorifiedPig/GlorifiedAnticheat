if !gAC.config.ANTI_METH then return end
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

_hook_Add( "StartCommand", "gAC.MethSilent", function( ply, cmd )
    if( ply:InVehicle() || ply.gAC_AimbotDetected || !ply:Alive() || ply:GetObserverMode() != OBS_MODE_NONE
    || ply:IsBot() || !_IsValid( ply ) || ply:IsTimingOut() || ply:PacketLoss() > 80 ) then return end

    if( ply.JoinTimeGAC == nil || !( _CurTime() >= ply.JoinTimeGAC + 25 ) || ply.PlayerFullyAuthenticated != true ) then return end

    if _IsValid(ply:GetActiveWeapon()) && Blacklisted_Weapons[ply:GetActiveWeapon():GetClass()] then
        return 
    end

    local gAC_View = cmd:GetViewAngles()
    local p, y, r = gAC_View.p, gAC_View.y, gAC_View.r
    local gAC_MX_AB = _math_abs( cmd:GetMouseX() )
    local gAC_MY_AB = _math_abs( cmd:GetMouseY() )

    if !ply.Meth_Silent_Last then
        ply.Meth_Silent_Last = gAC_View
        ply.Meth_Silent_MX_Last = gAC_MX_AB
        ply.Meth_Silent_MY_Last = gAC_MY_AB
        ply.Meth_Silent_Threshold = 0
        return
    end

    local rounded_oldview, rounded_newview = roundangle(ply.Meth_Silent_Last), roundangle(gAC_View)

    if gAC_MX_AB > 0 and gAC_MY_AB > 0 and roundangle(rounded_oldview, 2) == roundangle(rounded_newview, 2) then
        if ply.Meth_Silent_Threshold > 5 then
            ply.gAC_AimbotDetected = true
            gAC.AddDetection( ply, "Meth Silent-Aim Detected [Code 115]", gAC.config.METH_PUNISHMENT, gAC.config.METH_BANTIME )
            return
        else
            ply.Meth_Silent_Threshold = ply.Meth_Silent_Threshold + 1
        end
    elseif ply.Meth_Silent_Threshold > 0 then
        ply.Meth_Silent_Threshold = ply.Meth_Silent_Threshold - 1
    end

    ply.Meth_Silent_Last = gAC_View
    ply.Meth_Silent_MX_Last = gAC_MX_AB
    ply.Meth_Silent_MY_Last = gAC_MY_AB
end )