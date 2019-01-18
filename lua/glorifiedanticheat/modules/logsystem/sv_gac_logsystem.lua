
function gAC.LogEvent( string )
    local eventLogFile = "glorifiedanticheat/eventlogs.txt"
    if !file.IsDir( "glorifiedanticheat", "DATA" ) then
        file.CreateDir( "glorifiedanticheat", "DATA" )

        file.Write( eventLogFile, "[" .. os.date( "%m/%d/%Y: %H:%M:%S", os.time() ) .. "] " .. string .. "\n" )
    else
        file.Append( eventLogFile, "[" .. os.date( "%m/%d/%Y: %H:%M:%S", os.time() ) .. "] " .. string .. "\n" )
    end
end