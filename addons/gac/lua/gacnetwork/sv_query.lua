gAC.FileQuery = gAC.FileQuery or {}

function gAC.AddQuery(filepath)
    local FileName = filepath
	filepath = file.Read(filepath, "LUA")
	gAC.FileQuery[#gAC.FileQuery + 1] = util.Compress(gAC.Network.Payload_002 .. filepath)
    gAC.DBGPrint("Added file " .. FileName .. " to file query")
end

hook.Add("gAC.ClientLoaded", "SendPayload_LiveUpdates", function(ply)
    if #gAC.FileQuery > 0 then
        for k, v in SortedPairs(gAC.FileQuery) do
            if gAC.FileQuery[k] == nil then continue end
            gAC.Network:Send ("LoadPayload", gAC.FileQuery[k], ply, true)
        end
        hook.Run("gAC.CLFilesLoaded", ply)
    end
end)
