local _CurTime = CurTime
local _IsValid = IsValid
local _hook_Add = hook.Add
local _math_abs = math.abs
local _util_TraceLine = util.TraceLine

local _EyePos = (CLIENT and EyePos or NULL)

if !gAC.config.ENABLE_CPPAIMBOT_CHECKS then return end

local Blacklisted_Weapons = {
    ["weapon_physgun"] = true,
    ["gmod_tool"] = true,
    ["weapon_physcannon"] = true
}

local tr

_hook_Add( "StartCommand", "gAC_AntiCobalt.StartCommand", function( ply, cmd )

    if( ply:InVehicle() || ply.gAC_AimbotDetected || !ply:Alive() || ply:GetObserverMode() != OBS_MODE_NONE
    || ply:IsBot() || !_IsValid( ply ) || ply:IsTimingOut() || ply:PacketLoss() > 80 ) then return end

    if( ply.JoinTimeGAC == nil || !( _CurTime() >= ply.JoinTimeGAC + 25 ) || ply.PlayerFullyAuthenticated != true ) then return end

    if _IsValid(ply:GetActiveWeapon()) && Blacklisted_Weapons[ply:GetActiveWeapon():GetClass()] then 
        ply.gAC_CPPAimbotDetections = 0
        return 
    end

    ply.gAC_CPPMX = _math_abs( cmd:GetMouseX() )
    ply.gAC_CPPMY = _math_abs( cmd:GetMouseY() )
    ply.gAC_CPPAimView = cmd:GetViewAngles()

    if ply.gAC_CPPAimViewOld == nil then
        ply.gAC_CPPAimViewOld = ply.gAC_CPPAimView
        return
    end

    if ply.gAC_CPPAimbotDetections == nil then
        ply.gAC_CPPAimbotDetections = 0
    end

    if ply.gAC_CPPMX == 0 && ply.gAC_CPPMY == 0 then
        if ( ply.gAC_CPPAimView.p ~= ply.gAC_CPPAimViewOld.p && ply.gAC_CPPAimView.y ~= ply.gAC_CPPAimViewOld.y ) then
            tr = _util_TraceLine({start = ply:EyePos(), endpos = ply:EyePos() + ((ply.gAC_CPPAimView):Forward() * (4096 * 8) ), filter = ply})
        	if tr.Entity:IsPlayer() then
                if ply.gAC_CPPAimbotDetections >= 40 then
                    ply.gAC_AimbotDetected = true
                    gAC.AddDetection( ply, "C++ Aimbot detection triggered [Code 123]", gAC.config.CPPAIMBOT_PUNISHMENT, gAC.config.CPPAIMBOT_PUNSIHMENT_BANTIME )
                else
                    ply.gAC_CPPAimbotDetections = ply.gAC_CPPAimbotDetections + 1
                end
            elseif ply.gAC_CPPAimbotDetections != 0 then
                ply.gAC_CPPAimbotDetections = ply.gAC_CPPAimbotDetections - 1
            end
        elseif ply.gAC_CPPAimbotDetections != 0 then
            ply.gAC_CPPAimbotDetections = 0
        end
    elseif ply.gAC_CPPAimbotDetections != 0 then
        ply.gAC_CPPAimbotDetections = 0
    end

    ply.gAC_CPPAimViewOld = ply.gAC_CPPAimView

end )