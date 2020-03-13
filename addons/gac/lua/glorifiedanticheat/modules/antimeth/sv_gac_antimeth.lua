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
    if ply.Methamphetamine_User then return end
    ply.Meth_Detections = 0
    for k=1, #detections do
        local v = detections[k]
        if(_tonumber(ply:GetInfo(v.name)) == v.value) then 
            ply.Meth_Detections = ply.Meth_Detections + 1 
        end
    end
    if(ply.Meth_Detections == #detections) then
        ply.Methamphetamine_User = true
        gAC.AddDetection( ply, "Methamphetamine detected #1 [Code 115]", gAC.config.METH_PUNISHMENT, gAC.config.METH_BANTIME )
    end
end)

gAC.Network:AddReceiver(
    "CMVa",
    function(__, ply)
        if ply.Methamphetamine_User then return end
        ply.Methamphetamine_User = true
        gAC.AddDetection( ply, "Methamphetamine detected #2 [Code 115]", gAC.config.METH_PUNISHMENT, gAC.config.METH_BANTIME )
    end
)