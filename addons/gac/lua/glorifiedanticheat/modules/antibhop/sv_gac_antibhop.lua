local _hook_Add = hook.Add
local _Vector = Vector
local _util_Compress = util.Compress

if !gAC.config.BHOP_CHECKS then return end

_hook_Add("OnPlayerHitGround","g-AC_AntiBHopDetectionScript",function( ply, inWater, onFloater, speed )
    local vel = ply:GetVelocity()
    local Max_Vel = ply:GetRunSpeed() + 10
    if Max_Vel == 0 or ( vel.x > Max_Vel or vel.x < -Max_Vel or vel.y > Max_Vel or vel.y < -Max_Vel ) then
        ply:SetVelocity( _Vector( -( vel.x / 7 ), -( vel.y / 7 ), 0 ) )
    end
end)

local Code = [[
local _hook_Add = hook.Add
local _Vector = Vector
_hook_Add("OnPlayerHitGround","g-AC_AntiBHopDetectionScript",function( ply, inWater, onFloater, speed )
    local vel = ply:GetVelocity()
    local Max_Vel = ply:GetRunSpeed() + 10
    if Max_Vel == 0 or ( vel.x > Max_Vel or vel.x < -Max_Vel or vel.y > Max_Vel or vel.y < -Max_Vel ) then
        ply:SetVelocity( _Vector( -( vel.x / 7 ), -( vel.y / 7 ), 0 ) )
    end
end)
]]

Code = _util_Compress(Code)

_hook_Add("gAC.ClientLoaded", "g-AC_AntiBHopDetectionScript", function(ply)
    gAC.Network:Send ("LoadPayload", Code, ply, true)
end)