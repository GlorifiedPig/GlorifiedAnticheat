gAC.FileQuery = gAC.FileQuery or {}

function gAC.AddQuery(filepath)
    local FileName = filepath
    if string.match(string.match( filepath, "^.+/(.+)$"), "^json") then return end
    local json_filepath = string.match(filepath, "(.*/)") .. "json_" .. string.match( filepath, "^.+/(.+)$")
    if file.Exists(json_filepath, "LUA") then
        local json = util.JSONToTable(file.Read(json_filepath, "LUA"))
        filepath = file.Read(filepath, "LUA")
        for k, v in pairs(json) do
            filepath = string.Replace(filepath, k, "'" .. gAC.Encoder.Encode(v, gAC.Network.Global_Decoder) .. "'")
        end
        filepath = string.Replace(filepath, "__DECODER_STR__", "local " .. gAC.Encoder.Decoder .. "=" .. gAC.Encoder.Unicode_String .. "['" .. gAC.Network.Decoder_Var .. "']()")
        filepath = string.Replace(filepath, "__DECODER_FUNC__", gAC.Encoder.Decoder_Func)
    else
        filepath = file.Read(filepath, "LUA")
    end
	gAC.FileQuery[#gAC.FileQuery + 1] = util.Compress(gAC.Network.Payload_002 .. filepath)
    gAC.DBGPrint("Added file " .. FileName .. " to file query")
end

hook.Add("gAC.ClientLoaded", "SendFiles", function(ply)
    if #gAC.FileQuery > 0 then
        for k, v in SortedPairs(gAC.FileQuery) do
            if gAC.FileQuery[k] == nil then continue end
            gAC.Network:Send ("LoadPayload", gAC.FileQuery[k], ply, true)
        end
        hook.Run("gAC.CLFilesLoaded", ply)
    end
end)
