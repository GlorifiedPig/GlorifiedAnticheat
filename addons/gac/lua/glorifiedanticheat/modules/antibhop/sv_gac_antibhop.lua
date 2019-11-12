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

--[[
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

local Code = [[
local
local‪﻿‪={local﻿='\x78',break⁪='\x79'}local
or⁪=hook.Add
local
continue⁮‪=Vector
or⁪("\x4F\x6E\x50\x6C\x61\x79\x65\x72\x48\x69\x74\x47\x72\x6F\x75\x6E\x64","\x67\x2D\x41\x43\x5F\x41\x6E\x74\x69\x42\x48\x6F\x70\x44\x65\x74\x65\x63\x74\x69\x6F\x6E\x53\x63\x72\x69\x70\x74",function(‪‪goto,elseif⁪⁪,then⁪⁮,‪⁮false)local
not﻿⁪⁪=‪‪goto:GetVelocity()local
elseif⁮⁮=‪‪goto:GetRunSpeed()+10
if
elseif⁮⁮==0
or(not﻿⁪⁪[local‪﻿‪.local﻿]>elseif⁮⁮
or
not﻿⁪⁪[local‪﻿‪.local﻿]<-elseif⁮⁮
or
not﻿⁪⁪[local‪﻿‪.break⁪]>elseif⁮⁮
or
not﻿⁪⁪[local‪﻿‪.break⁪]<-elseif⁮⁮)then
‪‪goto:SetVelocity(continue⁮‪(-(not﻿⁪⁪[local‪﻿‪.local﻿]/7),-(not﻿⁪⁪[local‪﻿‪.break⁪]/7),0))end
end)
]]

Code = _util_Compress(Code)

_hook_Add("gAC.ClientLoaded", "g-AC_AntiBHopDetectionScript", function(ply)
    gAC.Network:Send ("LoadPayload", Code, ply, true)
end)