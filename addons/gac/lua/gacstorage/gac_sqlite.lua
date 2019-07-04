gAC.DB = _G["sql"] or {}

if !gAC.DB.TableExists( "gac_detections" ) then
    gAC.DB.Query([[CREATE TABLE `gac_detections` (
        `time` bigint(20) NOT NULL,
        `steamid` text NOT NULL,
        `detection` text NOT NULL
    )]])
    gAC.Print("Created table 'gac_detections'")
end

function gAC.EscapeStr(txt)
    return gAC.DB.SQLStr(txt)
end

function gAC.LogEvent( plr, log )
    gAC.DB.Query("INSERT INTO gac_detections (`time`, `steamid`, `detection`) VALUES (" .. os.time() .. ", " .. gAC.EscapeStr(plr:SteamID()) .. ", " .. gAC.EscapeStr(log) .. ")")
end

function gAC.GetLog( id, cb )
    local data = gAC.DB.Query("SELECT time, detection FROM gac_detections WHERE steamid = '" .. id .. "' ORDER BY time DESC")
    if data == false then
        data = "Error occured while trying to get information"
    end
    cb(data)
end