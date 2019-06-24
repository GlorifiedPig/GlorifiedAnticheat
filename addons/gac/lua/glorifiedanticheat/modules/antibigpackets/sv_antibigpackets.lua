if(!gAC.config.ANTI_BP) then return end


local detections = {

    {
        name = "cl_interp",
        value = 0,
        correct_value = 0.1
    },

    {
        name = "cl_interp_ratio",
        value = 1,
        correct_value = 2
    }
}

hook.Add("gAC.CLFilesLoaded", "g-AC.GetBPInformation", function(ply)
    timer.Simple(5, function()
        if !IsValid(ply) then return end
        ply.BP_Detections = 0
        for k, v in ipairs(detections) do
            gAC.Network:Send("g-AC_RenderHack_Checks", util.TableToJSON({v.name,v.correct_value}), ply)
        end
        timer.Simple(5, function()
            if !IsValid(ply) then return end
            for k, v in ipairs(detections) do
                if(tonumber(ply:GetInfo(v.name)) == v.value) then 
                    ply.BP_Detections = ply.BP_Detections + 1 
                end
            end
            if(ply.BP_Detections == #detections) then
                gAC.AddDetection( ply, "Bigpackets User [Code 118]", gAC.config.BP_PUNISHMENT, gAC.config.BP_BANTIME )
            end
        end)
    end)
end)