local _file_Append = file.Append
local _file_CreateDir = file.CreateDir
local _file_IsDir = file.IsDir
local _file_Write = file.Write

function gAC.LogEvent( ply, str )
    local ID64 = ply:SteamID64()
    local time = os.time()
    local eventLogFolder = 'g-ac-logs/' .. os.date('%d-%m-%Y', time)
    if !_file_Exists(eventLogFolder, 'DATA') then
        _file_CreateDir(eventLogFolder)
    end
    if _file_Exists(eventLogFolder .. '/' .. ID64 .. ".dat", 'DATA') then
        _file_Append(eventLogFolder .. '/' .. ID64 .. ".dat", "[" .. os.date( "%m/%d/%Y: %H:%M:%S", time ) .. "] "  .. ply:Nick() .. " (" .. ply:SteamID() .. ") : " .. str .. '\n')
    else
        _file_Write(eventLogFolder .. '/' .. ID64 .. ".dat", "[" .. os.date( "%m/%d/%Y: %H:%M:%S", time ) .. "] "  .. ply:Nick() .. " (" .. ply:SteamID() .. ") : " .. str .. '\n')
    end
end

function gAC.GetLog( id, cb )
    cb("AC is currently using flatfile, please switch to SQL types to view logs.")
end