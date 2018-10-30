
if !gAC.config.BHOP_CHECKS then return end

hook.Add("OnPlayerHitGround", "g-AC_AntiBHopDetectionScript", function( ply )
    ply:SetVelocity( -ply:GetVelocity() / 5 )
        
    if( ply:GetVelocity():Length() >= 500 ) then
        ply:SetVelocity( -ply:GetVelocity() / 3 )
    end
end)