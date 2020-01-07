local _RunConsoleCommand = RunConsoleCommand
local _tonumber = tonumber
local _unpack = unpack
local _util_JSONToTable = util.JSONToTable

gAC_AddReceiver("g-AC_RenderHack_Checks", function(data)
    data = _util_JSONToTable(data)
    for k=1, #data do
    	local v = data[k]
        _RunConsoleCommand(_unpack({v[_tonumber(1)], v[_tonumber(2)]}))
    end
    gAC_Send("g-AC_RenderHack_Checks", "")
end)