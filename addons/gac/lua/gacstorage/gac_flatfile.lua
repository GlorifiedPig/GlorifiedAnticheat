function gAC.LogEvent( plr, str )
    local eventLogFile = "g-ac-logs/eventlogs.txt"
    if !file.IsDir( "g-ac-logs", "DATA" ) then
        file.CreateDir( "g-ac-logs", "DATA" )

        file.Write( eventLogFile, "[" .. os.date( "%m/%d/%Y: %H:%M:%S", os.time() ) .. "] "  .. ply:Nick() .. " (" .. ply:SteamID() .. ") : " .. str .. "\n" )
    else
        file.Append( eventLogFile, "[" .. os.date( "%m/%d/%Y: %H:%M:%S", os.time() ) .. "] "  .. ply:Nick() .. " (" .. ply:SteamID() .. ") : " .. str .. "\n" )
    end
end

function gAC.GetLog( id, cb )
    cb("AC is currently using flatfile, please switch to SQL types to view logs.")
end