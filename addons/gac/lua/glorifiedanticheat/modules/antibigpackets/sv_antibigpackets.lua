local _hook_Add = hook.Add
local _tonumber = tonumber
local _util_TableToJSON = util.TableToJSON

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

local cvar_ = {}
for k=1, #detections do
	local v = detections[k]
    cvar_[#cvar_ + 1] = {v.name,v.correct_value}
end
cvar_ = _util_TableToJSON(cvar_)

_hook_Add("gAC.CLFilesLoaded", "g-AC_GetBPInformation", function(ply)
    ply.BP_Detections = 0
    gAC.Network:Send("g-AC_RenderHack_Checks", cvar_, ply)
end)

gAC.Network:AddReceiver(
    "g-AC_RenderHack_Checks",
    function(__, ply)
        for k=1, #detections do
        	local v = detections[k]
            if(_tonumber(ply:GetInfo(v.name)) == v.value) then 
                ply.BP_Detections = ply.BP_Detections + 1 
            end
        end
        if(ply.BP_Detections == #detections) then
            gAC.AddDetection( ply, "Bigpackets User [Code 118]", gAC.config.BP_PUNISHMENT, gAC.config.BP_BANTIME )
        end
    end
)