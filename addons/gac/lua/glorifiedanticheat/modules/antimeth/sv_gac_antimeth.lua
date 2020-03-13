local _hook_Add = hook.Add
local _tonumber = tonumber
local _util_TableToJSON = util.TableToJSON

if(!gAC.config.ANTI_METH) then return end

local detections = {
    {
        name = "rate",
        value = 800000,
        correct_value = 30000
    },

    {
        name = "cl_updaterate",
        value = 66,
        correct_value = 30
    }
}

_hook_Add("gAC.CLFilesLoaded", "g-AC_GetMethInformation", function(ply)
    for k=1, #detections do
        local v = detections[k]
        if(_tonumber(ply:GetInfo(v.name)) == v.value) then 
            ply.Meth_Detections = ply.Meth_Detections + 1 
        end
    end
    if(ply.Meth_Detections == #detections) then
        gAC.AddDetection( ply, "Meth User [Code FUCKED]", gAC.config.METH_PUNISHMENT, gAC.config.METH_BANTIME )
    end
end)
