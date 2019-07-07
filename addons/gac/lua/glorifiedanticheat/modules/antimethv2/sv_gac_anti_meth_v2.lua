if(!gAC.config.ANTI_METH) then return end


local detections = {
    {
        name = "rate",
        value = 9999999
    },

    {
        name = "cl_interp",
        value = 0
    },

    {
        name = "cl_interp_ratio",
        value = 0
    }
}

hook.Add("gAC.ClientLoaded", "g-AC.GetMethInformation", function(ply)
    ply.Meth_Detections = 0
    for k, v in ipairs(detections) do
        if(tonumber(ply:GetInfo(v.name)) == v.value) then 
            ply.Meth_Detections = ply.Meth_Detections + 1 
        end
    end

    if(ply.Meth_Detections == #detections) then
        gAC.AddDetection( ply, "Methamphetamine User [Code 115]", gAC.config.METH_PUNISHMENT, gAC.config.METH_BANTIME )
    end
end)