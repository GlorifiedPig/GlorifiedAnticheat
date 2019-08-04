local _SortedPairs = SortedPairs
local _file_Exists = file.Exists
local _file_Read = file.Read
local _hook_Add = hook.Add
local _hook_Run = hook.Run
local _pairs = pairs
local _string_Replace = string.Replace
local _string_match = string.match
local _util_Compress = util.Compress
local _util_JSONToTable = util.JSONToTable

gAC.FileQuery = gAC.FileQuery or {}

function gAC.AddQuery(filepath)
    local FileName = filepath
    if _string_match(_string_match( filepath, "^.+/(.+)$"), "^json") then return end
    local json_filepath = _string_match(filepath, "(.*/)") .. "json_" .. string.match( filepath, "^.+/(.+)$")
    if _file_Exists(json_filepath, "LUA") then
        local json = _util_JSONToTable(_file_Read(json_filepath, "LUA"))
        filepath = _file_Read(filepath, "LUA")
        for k, v in _pairs(json) do
            filepath = _string_Replace(filepath, k, "'" .. gAC.Encoder.Encode(v, gAC.Network.Global_Decoder) .. "'")
        end
        filepath = _string_Replace(filepath, "__DECODER_STR__", "local " .. gAC.Encoder.Decoder .. "=" .. gAC.Encoder.Unicode_String .. gAC.Network.Decoder_Var .. "('" .. gAC.Network.Decoder_Get .. "')")
        filepath = _string_Replace(filepath, "__DECODER_FUNC__", gAC.Encoder.Decoder_Func)
    else
        filepath = _file_Read(filepath, "LUA")
    end
	gAC.FileQuery[#gAC.FileQuery + 1] = _util_Compress(gAC.Network.Payload_002 .. filepath)
    gAC.DBGPrint("Added file " .. FileName .. " to file query")
end

_hook_Add("gAC.IncludesLoaded", "Decoder_Unloader", function()
    gAC.FileQuery[#gAC.FileQuery + 1] = _util_Compress("_G" .. gAC.Network.Decoder_Var .. " = _G" .. gAC.Network.Decoder_Var .. "('" .. gAC.Network.Decoder_Undo .. "')")
end)

_hook_Add("gAC.ClientLoaded", "SendFiles", function(ply)
    if #gAC.FileQuery > 0 then
        for k, v in _SortedPairs(gAC.FileQuery) do
            if gAC.FileQuery[k] == nil then continue end
            gAC.Network:Send ("LoadPayload", gAC.FileQuery[k], ply, true)
        end
        _hook_Run("gAC.CLFilesLoaded", ply)
    end
end)
