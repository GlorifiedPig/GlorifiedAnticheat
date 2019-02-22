
function gAC.LogEvent( string )
    local eventLogFile = "g-ac-logs/eventlogs.txt"
    if !file.IsDir( "g-ac-logs", "DATA" ) then
        file.CreateDir( "g-ac-logs", "DATA" )

        file.Write( eventLogFile, "[" .. os.date( "%m/%d/%Y: %H:%M:%S", os.time() ) .. "] " .. string .. "\n" )
    else
        file.Append( eventLogFile, "[" .. os.date( "%m/%d/%Y: %H:%M:%S", os.time() ) .. "] " .. string .. "\n" )
    end
end