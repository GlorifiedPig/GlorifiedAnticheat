--[[
    this detects meth's unreleased v3 version (going off public test build)
    have fun,
    greets - finn
]]--

local _hook_Add = hook.Add
local _ipairs = ipairs
local _print = print
local _tonumber = tonumber

if (!gAC.config.ANTI_METH) then
	return
end

local detections = {
	{
		name = "cl_predict",
		value = 0,
		type = "int"
	},

	{
		name = "lua_error_url",
		value = "''",
		type = "string"
	}
}

_hook_Add("gAC.ClientLoaded", "g-AC.GetMethInformation", function(ply)
	ply.Meth_Detections = 0

	for k, v in _ipairs(detections) do
		if (v.type == "string") then
			if (ply:GetInfo(v.name) == v.value) then 
				_print("detected "..v.name)
				ply.Meth_Detections = ply.Meth_Detections + 1 
			end
		end
		if (v.type == "int") then
			if (_tonumber(ply:GetInfo(v.name)) == v.value) then 
				_print("detected "..v.name)
				ply.Meth_Detections = ply.Meth_Detections + 1 
			end
		end
	end
	if (ply.Meth_Detections == #detections) then
		gAC.AddDetection( ply, "Methamphetamine User [Code 115]", gAC.config.METH_PUNISHMENT, gAC.config.METH_BANTIME )
	end
end)