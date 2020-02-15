if gAC.config.ENABLE_CITIZENHACK_CHECKS then
    gAC.Network:AddReceiver(
        "gAC-CMV",
        function(data, plr)
            if plr.gAC_AimbotDetected then return end
            gAC.AddDetection( plr, "C-Movement Manipulation Detected #2 [Code 129]", gAC.config.CITIZENHACK_PUNISHMENT, gAC.config.CITIZENHACK_PUNSIHMENT_BANTIME )
            plr.gAC_AimbotDetected = true
        end
    )
end

if !gAC.config.ANTI_MOVEMANIP then return end
local _CurTime = CurTime
local _IsValid = IsValid
local _hook_Add = hook.Add
local _math_abs = math.abs
local _math_sqrt = math.sqrt
local _math_sin = math.sin
local _math_cos = math.cos
local _math_tan = math.tan
local _math_asin = math.asin
local _math_acos = math.acos
local _math_atan = math.atan

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

local CMoveValueWhitelist = {
    [2500] = true,
    [5000] = true,
    [7500] = true
}

_hook_Add( "StartCommand", "gAC.MoveManip", function( ply, cmd )
    if( ply:InVehicle() || ply.gAC_AimbotDetected || !ply:Alive() || ply:GetObserverMode() != OBS_MODE_NONE
    || ply:IsBot() || !_IsValid( ply ) || ply:IsTimingOut() || ply:PacketLoss() > 80 ) then return end

    if( ply.JoinTimeGAC == nil || !( _CurTime() >= ply.JoinTimeGAC + 25 ) || ply.PlayerFullyAuthenticated != true ) then return end

    if _IsValid(ply:GetActiveWeapon()) && Blacklisted_Weapons[ply:GetActiveWeapon():GetClass()] then
        return 
    end

    local opp = _math_abs( cmd:GetForwardMove() )
    local adj = _math_abs( cmd:GetSideMove() )

    if !ply.MoveManip_Threshold then
        ply.MoveManip_Threshold = 0
        return
    end

    -- pythagorean theorem lmao.
    -- Gotta love SOH CAH TOA
    local hyp = _math_sqrt((opp^2) + (adj^2))
    local costheta = _math_acos( adj / hyp )
    local sintheta = _math_asin( opp / hyp )
    local taninverse = _math_tan( opp / adj ) ^ -1

    --[[
        (opp == 10000 and adj < 10000 and CMoveValueWhitelist[adj] ~= true and adj > 0 and round(hyp) > 10000)
        (adj == 10000 and opp < 10000 and CMoveValueWhitelist[opp] ~= true and opp > 0 and round(hyp) > 10000)
        (round(hyp) == 10000)
    ]]
    if ((opp == 10000 and adj < 10000 and CMoveValueWhitelist[adj] ~= true and adj > 0 and round(hyp) > 10000) or (adj == 10000 and opp < 10000 and CMoveValueWhitelist[opp] ~= true and opp > 0 and round(hyp) > 10000) or (round(hyp) == 10000)) and round(costheta / sintheta) == 1 and round((_math_sin(taninverse)^2) + (_math_cos(taninverse)^2)) == 1 then
        if ply.MoveManip_Threshold > 5 then
            ply.gAC_AimbotDetected = true
            gAC.AddDetection( ply, "C-Movement Manipulation Detected #1 [Code 129]", gAC.config.MOVEMANIP_PUNISHMENT, gAC.config.MOVEMANIP_BANTIME )
            return
        else
            ply.MoveManip_Threshold = ply.MoveManip_Threshold + 1
        end
    elseif ply.MoveManip_Threshold > 0 then
        ply.MoveManip_Threshold = ply.MoveManip_Threshold - 1
    end
end)