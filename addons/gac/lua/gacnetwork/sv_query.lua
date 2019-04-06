gAC.FileQuery = gAC.FileQuery or {}

function gAC.AddQuery(filepath)
    local FileName = filepath
	filepath = file.Read(filepath, "LUA")
	gAC.FileQuery[#gAC.FileQuery + 1] = filepath
    gAC.DBGPrint("Added file " .. FileName .. " to file query")
end

hook.Add("gAC.ClientLoaded", "SendPayload_LiveUpdates", function(ply)
    if #gAC.FileQuery > 0 then
        for k, v in SortedPairs(gAC.FileQuery) do
            if gAC.FileQuery[k] == nil then continue end
			gAC.Network:SendPayload (gAC.FileQuery[k], ply)
        end
        hook.Run("gAC.CLFilesLoaded", ply)
    end
end)
