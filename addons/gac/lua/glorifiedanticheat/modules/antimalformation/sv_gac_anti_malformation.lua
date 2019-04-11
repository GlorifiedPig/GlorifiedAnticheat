if(!gAC.config.ANTI_MALFORM) then return end

hook.Add("PlayerInitialSpawn", "g-AC_anti_malform", function(ply)
    timer.Simple(2, function()
        if !IsValid(ply) then return end
        if(tonumber(ply:GetInfo("cl_interp")) == 0) then -- Who would have this set to 0? Well, meth users :)
            gAC.AddDetection( ply, "Malformed Request", gAC.config.MALFORM_PUNISHMENT, gAC.config.MALFORM_BANTIME )
        end
    end)
end)
