local _file_Append = file.Append
local _file_CreateDir = file.CreateDir
local _file_IsDir = file.IsDir
local _file_Write = file.Write

function gAC.LogEvent( plr, str )
    local eventLogFile = "g-ac-logs/eventlogs.txt"
    if !_file_IsDir( "g-ac-logs", "DATA" ) then
        _file_CreateDir( "g-ac-logs", "DATA" )

        _file_Write( eventLogFile, "[" .. os.date( "%m/%d/%Y: %H:%M:%S", os.time() ) .. "] "  .. ply:Nick() .. " (" .. ply:SteamID() .. ") : " .. str .. "\n" )
    else
        _file_Append( eventLogFile, "[" .. os.date( "%m/%d/%Y: %H:%M:%S", os.time() ) .. "] "  .. ply:Nick() .. " (" .. ply:SteamID() .. ") : " .. str .. "\n" )
    end
end

function gAC.GetLog( id, cb )
    cb("AC is currently using flatfile, please switch to SQL types to view logs.")
end